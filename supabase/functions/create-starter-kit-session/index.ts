/**
 * Create Stripe Checkout for MintCheck Starter Kit (hardware + deferred Buyer Pass).
 * Auth required. Pass activates later via fulfill-starter-kit-order, not on payment.
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const DEFAULT_SUCCESS_URL =
  "https://mintcheckapp.com/starter-kit/success?session_id={CHECKOUT_SESSION_ID}";

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
        "create-starter-kit-session auth failed:",
        authError?.message ?? "no user"
      );
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
    const priceId =
      Deno.env.get("STRIPE_STARTER_KIT_PRICE_ID") ??
      "price_1TFKoXI2Le6kJlyuKQMfZa4f";
    if (!stripeSecretKey || !priceId) {
      console.error(
        "create-starter-kit-session: missing STRIPE_SECRET_KEY or STRIPE_STARTER_KIT_PRICE_ID"
      );
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const successUrl =
      Deno.env.get("STRIPE_STARTER_KIT_SUCCESS_URL") ?? DEFAULT_SUCCESS_URL;
    const cancelUrl =
      Deno.env.get("STRIPE_STARTER_KIT_CANCEL_URL") ??
      "https://mintcheckapp.com/starter-kit";

    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-06-20" });

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl.includes("{CHECKOUT_SESSION_ID}")
        ? successUrl
        : `${successUrl}${
            successUrl.includes("?") ? "&" : "?"
          }session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: cancelUrl,
      client_reference_id: user.id,
      customer_email: user.email ?? undefined,
      metadata: { type: "starter_kit" },
      shipping_address_collection: {
        allowed_countries: ["US", "CA"],
      },
      phone_number_collection: { enabled: true },
    });

    return new Response(JSON.stringify({ url: session.url }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const errMsg = e instanceof Error ? e.message : String(e);
    const errType = (e as { type?: string })?.type ?? (e as { code?: string })?.code ?? "unknown";
    console.error("create-starter-kit-session error:", errType, errMsg, e);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: errMsg, type: errType }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
