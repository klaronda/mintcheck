import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  const signature = req.headers.get("Stripe-Signature");
  if (!webhookSecret || !signature) {
    console.error("stripe-webhook: missing STRIPE_WEBHOOK_SECRET or Stripe-Signature");
    return new Response("Bad request", { status: 400 });
  }

  let rawBody: string;
  try {
    rawBody = await req.text();
  } catch {
    return new Response("Bad request", { status: 400 });
  }

  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
  if (!stripeSecretKey) {
    console.error("stripe-webhook: STRIPE_SECRET_KEY not set");
    return new Response("Server error", { status: 500 });
  }

  let event: Stripe.Event;
  try {
    event = await Stripe.webhooks.constructEventAsync(rawBody, signature, webhookSecret);
  } catch (err) {
    console.error("stripe-webhook signature verification failed:", err);
    return new Response("Invalid signature", { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;
    const sessionId = session.id;
    const metadataType = session.metadata?.type;
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    if (metadataType === "buyer_pass") {
      // --- Buyer Pass activation (supports stacking renewals) ---
      const now = new Date();
      const sixtyDaysMs = 60 * 24 * 60 * 60 * 1000;
      const userId = session.client_reference_id;

      // Check if user has an existing active buyer pass with time remaining
      let baseDate = now;
      if (userId) {
        const { data: existingSubs } = await supabase
          .from("subscriptions")
          .select("id, ended_at")
          .eq("user_id", userId)
          .eq("plan", "buyer_pass")
          .eq("status", "active")
          .gt("ended_at", now.toISOString())
          .neq("stripe_session_id", sessionId)
          .order("ended_at", { ascending: false })
          .limit(1);

        if (existingSubs && existingSubs.length > 0 && existingSubs[0].ended_at) {
          const existingEnd = new Date(existingSubs[0].ended_at);
          if (existingEnd > now) {
            baseDate = existingEnd; // Stack onto existing end date
            console.log(`stripe-webhook: stacking buyer_pass renewal onto existing end=${existingEnd.toISOString()}`);
          }
        }
      }

      const endedAt = new Date(baseDate.getTime() + sixtyDaysMs);

      const { error } = await supabase
        .from("subscriptions")
        .update({
          status: "active",
          started_at: now.toISOString(),
          ended_at: endedAt.toISOString(),
        })
        .eq("stripe_session_id", sessionId);

      if (error) {
        console.error("stripe-webhook update subscriptions (buyer_pass) error:", error);
      } else {
        console.log(`stripe-webhook: buyer_pass activated, session=${sessionId}, ends=${endedAt.toISOString()}`);
      }
    } else {
      // --- Deep Check (existing flow) ---
      const { error } = await supabase
        .from("deep_check_purchases")
        .update({ status: "paid" })
        .eq("stripe_session_id", sessionId);

      if (error) {
        console.error("stripe-webhook update deep_check_purchases error:", error);
      }

      // Trigger report generation (fire-and-forget so webhook returns quickly).
      const invokeSecret = Deno.env.get("DEEP_CHECK_INVOKE_SECRET");
      const purchaseId = session.metadata?.purchase_id;
      if (typeof purchaseId === "string" && purchaseId.trim() && invokeSecret) {
        const functionsUrl = `${supabaseUrl}/functions/v1/generate-deep-check-report`;
        fetch(functionsUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Internal-Secret": invokeSecret,
          },
          body: JSON.stringify({ purchase_id: purchaseId.trim() }),
        }).catch((err) => console.error("stripe-webhook: invoke generate-deep-check-report failed", err));
      } else if (typeof purchaseId === "string" && purchaseId.trim() && !invokeSecret) {
        console.error("stripe-webhook: DEEP_CHECK_INVOKE_SECRET not set, skipping report generation");
      }
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
