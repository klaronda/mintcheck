/**
 * Create Stripe Checkout session for Buyer Pass (60-day unlimited scanning).
 * Validates JWT, creates a pending subscription row, returns Stripe checkout URL.
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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
    // --- Auth ---
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid Authorization" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = authHeader.slice(7);
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);
    if (authError || !user?.id) {
      console.error(
        "create-buyer-pass-session auth failed:",
        authError?.message ?? "no user"
      );
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // --- Check for existing active buyer pass ---
    // Allow renewal when 7 or fewer days remain; block if more than 7 days left.
    const { data: existing } = await supabase
      .from("subscriptions")
      .select("id, status, ended_at")
      .eq("user_id", user.id)
      .eq("plan", "buyer_pass")
      .eq("status", "active")
      .limit(1);

    if (existing && existing.length > 0) {
      const sub = existing[0];
      const endedAt = sub.ended_at ? new Date(sub.ended_at) : null;
      if (endedAt && endedAt > new Date()) {
        const msRemaining = endedAt.getTime() - Date.now();
        const daysRemaining = msRemaining / (1000 * 60 * 60 * 24);
        if (daysRemaining > 7) {
          return new Response(
            JSON.stringify({
              error:
                "You already have an active Buyer Pass with more than 7 days remaining. Check your dashboard for details.",
            }),
            {
              status: 400,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }
        // <= 7 days remaining — allow renewal (will be stacked by webhook)
        console.log(`create-buyer-pass-session: allowing renewal, ${Math.ceil(daysRemaining)} days remaining`);
      }
    }

    // --- Stripe config ---
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
    const priceId = Deno.env.get("STRIPE_BUYER_PASS_PRICE_ID");
    if (!stripeSecretKey || !priceId) {
      console.error(
        "create-buyer-pass-session: missing STRIPE_SECRET_KEY or STRIPE_BUYER_PASS_PRICE_ID"
      );
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // --- Create pending subscription row ---
    const { data: row, error: insertError } = await supabase
      .from("subscriptions")
      .insert({
        user_id: user.id,
        plan: "buyer_pass",
        status: "pending",
        provider: "stripe",
      })
      .select("id")
      .single();

    if (insertError || !row) {
      console.error("subscriptions insert error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to create subscription" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // --- Create Stripe Checkout session ---
    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-06-20" });
    // Deep link so Stripe redirect opens the app directly (no "Open MintCheck" tap)
    const successUrl =
      "mintcheck://buyer-pass/success?session_id={CHECKOUT_SESSION_ID}";
    const cancelUrl = "https://mintcheckapp.com";

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      client_reference_id: user.id,
      metadata: { type: "buyer_pass", subscription_id: row.id },
      customer_email: user.email ?? undefined,
    });

    // Store stripe_session_id on the subscription row
    await supabase
      .from("subscriptions")
      .update({ stripe_session_id: session.id })
      .eq("id", row.id);

    return new Response(JSON.stringify({ url: session.url }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const errMsg = e instanceof Error ? e.message : String(e);
    const errType = e?.type ?? e?.code ?? "unknown";
    console.error("create-buyer-pass-session error:", errType, errMsg, e);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: errMsg, type: errType }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
