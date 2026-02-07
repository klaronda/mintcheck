/**
 * Create Stripe Checkout session for Deep Vehicle Check.
 * Requires JWT verification OFF at gateway (verify_jwt: false) so the Authorization
 * header is forwarded; we validate the token inside with getUser(token).
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const VIN_NOT_RECOGNIZED = "VIN not recognized. We can't run a report for this VIN.";

/** VIN must be 17 chars, no I/O/Q (invalid in VINs). */
function isValidVINFormat(vin: string): boolean {
  if (vin.length !== 17) return false;
  const upper = vin.toUpperCase();
  if (/[IOQ]/.test(upper)) return false;
  return /^[A-HJ-NPR-Z0-9]{17}$/.test(upper);
}

/** Call NHTSA VPIC decode; returns true if VIN is recognized (has decode results). */
async function isVINRecognizedByNHTSA(vin: string): Promise<boolean> {
  const url = `https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/${encodeURIComponent(vin)}?format=json`;
  try {
    const res = await fetch(url, {
      method: "GET",
      headers: { "Accept": "application/json" },
    });
    if (!res.ok) return false;
    const data = (await res.json()) as { Results?: { Variable?: string; Value?: string }[] };
    const results = data?.Results ?? [];
    const hasModelYear = results.some(
      (r) => r?.Variable === "Model Year" && r?.Value != null && String(r.Value).trim() !== ""
    );
    return hasModelYear;
  } catch {
    return false;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Missing or invalid Authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.slice(7);
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user?.id) {
      console.error("create-deep-check-session auth failed:", authError?.message ?? "no user", authError);
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({}));
    const vin = typeof body?.vin === "string" ? body.vin.trim().toUpperCase() : "";
    if (!vin || !isValidVINFormat(vin)) {
      return new Response(
        JSON.stringify({ error: "VIN must be 17 characters and cannot contain I, O, or Q." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const recognized = await isVINRecognizedByNHTSA(vin);
    if (!recognized) {
      return new Response(
        JSON.stringify({ error: VIN_NOT_RECOGNIZED }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
    const priceId = Deno.env.get("STRIPE_DEEP_CHECK_PRICE_ID");
    if (!stripeSecretKey || !priceId) {
      return new Response(JSON.stringify({ error: "Server configuration error" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: row, error: insertError } = await supabase
      .from("deep_check_purchases")
      .insert({
        user_id: user.id,
        vin,
        status: "pending",
      })
      .select("id")
      .single();

    if (insertError || !row) {
      console.error("deep_check_purchases insert error:", insertError);
      return new Response(JSON.stringify({ error: "Failed to create purchase" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-06-20" });
    // After payment Stripe redirects here; {CHECKOUT_SESSION_ID} is replaced by Stripe
    const successUrl = "https://mintcheckapp.com/deep-check/success?session_id={CHECKOUT_SESSION_ID}";
    const cancelUrl = "https://mintcheckapp.com";

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      client_reference_id: user.id,
      metadata: { vin, purchase_id: row.id },
      customer_email: user.email ?? undefined,
    });

    await supabase
      .from("deep_check_purchases")
      .update({ stripe_session_id: session.id })
      .eq("id", row.id);

    return new Response(
      JSON.stringify({ url: session.url }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("create-deep-check-session error:", e);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
