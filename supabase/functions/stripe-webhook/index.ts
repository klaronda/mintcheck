import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";
import * as Sentry from "https://deno.land/x/sentry/index.mjs";

const _SENTRY_DSN = Deno.env.get("SENTRY_DSN");
let _sentryReady = false;
function _ensureSentry() {
  if (_sentryReady) return;
  _sentryReady = true;
  if (!_SENTRY_DSN) return;
  Sentry.init({ dsn: _SENTRY_DSN, defaultIntegrations: false, tracesSampleRate: 1.0, environment: Deno.env.get("SENTRY_ENVIRONMENT") || "production" });
  Sentry.setTag("region", Deno.env.get("SB_REGION") ?? "unknown");
  Sentry.setTag("execution_id", Deno.env.get("SB_EXECUTION_ID") ?? "unknown");
}
function captureException(err: unknown, context?: Record<string, unknown>) {
  _ensureSentry();
  if (!_SENTRY_DSN) return;
  Sentry.withScope((scope: { setExtras: (extras: Record<string, unknown>) => void }) => { if (context) scope.setExtras(context); Sentry.captureException(err); });
}
async function sentryFlush() { if (!_SENTRY_DSN) return; await Sentry.flush(2000); }

/** Parse client_reference_id as Supabase user UUID when present. */
function parseUserIdFromSession(session: Stripe.Checkout.Session): string | null {
  const ref = session.client_reference_id;
  if (typeof ref !== "string" || !ref.trim()) return null;
  const uuidRe =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRe.test(ref.trim()) ? ref.trim() : null;
}

async function handleStarterKitOrder(params: {
  supabase: ReturnType<typeof createClient>;
  supabaseUrl: string;
  session: Stripe.Checkout.Session;
  sessionId: string;
}): Promise<void> {
  const { supabase, supabaseUrl, session, sessionId } = params;
  const userId = parseUserIdFromSession(session);
  const email = session.customer_details?.email ?? null;
  const name = session.customer_details?.name ?? null;

  const { data: prior } = await supabase
    .from("starter_kit_orders")
    .select("id, confirmation_email_sent_at")
    .eq("stripe_session_id", sessionId)
    .maybeSingle();

  const shipAddr = session.shipping_details?.address ?? session.customer_details?.address;
  const shippingCountry = shipAddr?.country ?? null;
  const shippingState = shipAddr?.state ?? null;

  const nowIso = new Date().toISOString();
  const { error: upsertErr } = await supabase.from("starter_kit_orders").upsert(
    {
      stripe_session_id: sessionId,
      user_id: userId,
      customer_email: email,
      customer_name: name,
      shipping_country: shippingCountry,
      shipping_state: shippingState,
      status: "paid_pending_fulfillment",
      updated_at: nowIso,
    },
    { onConflict: "stripe_session_id" }
  );

  if (upsertErr) {
    console.error("stripe-webhook starter_kit_orders upsert error:", upsertErr);
    captureException(upsertErr, { fn: "stripe-webhook", step: "starter_kit_orders_upsert", sessionId });
    return;
  }

  // Generate order number if not already set
  const { error: onErr } = await supabase.rpc("generate_order_number_for_order", {
    p_session_id: sessionId,
  });
  if (onErr) {
    // Fallback: call generate_order_number directly via raw SQL
    console.error("stripe-webhook: rpc generate_order_number_for_order failed, trying direct SQL", onErr);
    captureException(onErr, { fn: "stripe-webhook", step: "generate_order_number_rpc", sessionId });
    await supabase.from("starter_kit_orders")
      .update({ order_number: null })
      .eq("stripe_session_id", sessionId)
      .is("order_number", null);
  }

  // Fetch the order to get order_number for the email subject
  const { data: orderRow } = await supabase
    .from("starter_kit_orders")
    .select("order_number")
    .eq("stripe_session_id", sessionId)
    .maybeSingle();
  const orderNumber = orderRow?.order_number as string | null;

  if (prior?.confirmation_email_sent_at) {
    console.log(`stripe-webhook: starter_kit email already sent, session=${sessionId}`);
    return;
  }

  const invokeSecret = Deno.env.get("DEEP_CHECK_INVOKE_SECRET");
  if (!invokeSecret) {
    console.error("stripe-webhook: DEEP_CHECK_INVOKE_SECRET not set, skipping starter-kit email");
    captureException(new Error("DEEP_CHECK_INVOKE_SECRET not set"), { fn: "stripe-webhook", step: "starter_kit_email_secret" });
    return;
  }

  const functionsUrl = `${supabaseUrl}/functions/v1/send-starter-kit-confirmation`;
  try {
    const res = await fetch(functionsUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Internal-Secret": invokeSecret,
      },
      body: JSON.stringify({
        name: session.customer_details?.name ?? null,
        email: session.customer_details?.email ?? null,
        phone: session.customer_details?.phone ?? null,
        billing_address: session.customer_details?.address ?? null,
        shipping: session.shipping_details ?? null,
        created: session.created,
        order_number: orderNumber,
      }),
    });
    if (!res.ok) {
      const t = await res.text();
      console.error("stripe-webhook: send-starter-kit-confirmation failed", res.status, t);
      captureException(new Error(`send-starter-kit-confirmation HTTP ${res.status}`), { fn: "stripe-webhook", step: "send_confirmation_email", status: res.status, body: t });
      return;
    }
  } catch (err) {
    console.error("stripe-webhook: invoke send-starter-kit-confirmation failed", err);
    captureException(err, { fn: "stripe-webhook", step: "send_confirmation_invoke" });
    return;
  }

  await supabase
    .from("starter_kit_orders")
    .update({ confirmation_email_sent_at: nowIso, updated_at: nowIso })
    .eq("stripe_session_id", sessionId);

  console.log(`stripe-webhook: starter_kit order recorded + email sent, session=${sessionId}`);
}

serve(async (req) => {
  try {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  const signature = req.headers.get("Stripe-Signature");
  if (!webhookSecret || !signature) {
    console.error("stripe-webhook: missing STRIPE_WEBHOOK_SECRET or Stripe-Signature");
    captureException(new Error("Missing STRIPE_WEBHOOK_SECRET or Stripe-Signature"), { fn: "stripe-webhook" });
    await sentryFlush();
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
    captureException(new Error("STRIPE_SECRET_KEY not set"), { fn: "stripe-webhook" });
    await sentryFlush();
    return new Response("Server error", { status: 500 });
  }

  let event: Stripe.Event;
  try {
    event = await Stripe.webhooks.constructEventAsync(rawBody, signature, webhookSecret);
  } catch (err) {
    console.error("stripe-webhook signature verification failed:", err);
    captureException(err, { fn: "stripe-webhook", step: "signature_verification" });
    await sentryFlush();
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

    const starterKitLinkId = Deno.env.get("STRIPE_STARTER_KIT_PAYMENT_LINK_ID");
    const isPaymentLinkStarterKit =
      Boolean(starterKitLinkId && session.payment_link === starterKitLinkId);
    const isAppStarterKit = metadataType === "starter_kit";

    if (isPaymentLinkStarterKit || isAppStarterKit) {
      await handleStarterKitOrder({ supabase, supabaseUrl, session, sessionId });
    } else if (metadataType === "buyer_pass") {
      const now = new Date();
      const sixtyDaysMs = 60 * 24 * 60 * 60 * 1000;
      const userId = session.client_reference_id;

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
            baseDate = existingEnd;
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
        captureException(error, { fn: "stripe-webhook", step: "buyer_pass_update", sessionId });
      } else {
        console.log(`stripe-webhook: buyer_pass activated, session=${sessionId}, ends=${endedAt.toISOString()}`);
      }
    } else {
      const { error } = await supabase
        .from("deep_check_purchases")
        .update({ status: "paid" })
        .eq("stripe_session_id", sessionId);

      if (error) {
        console.error("stripe-webhook update deep_check_purchases error:", error);
        captureException(error, { fn: "stripe-webhook", step: "deep_check_update", sessionId });
      }

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
        }).catch((err) => {
          console.error("stripe-webhook: invoke generate-deep-check-report failed", err);
          captureException(err, { fn: "stripe-webhook", step: "generate_deep_check_invoke" });
        });
      } else if (typeof purchaseId === "string" && purchaseId.trim() && !invokeSecret) {
        console.error("stripe-webhook: DEEP_CHECK_INVOKE_SECRET not set, skipping report generation");
        captureException(new Error("DEEP_CHECK_INVOKE_SECRET not set for report generation"), { fn: "stripe-webhook", step: "deep_check_secret" });
      }
    }
  }

  await sentryFlush();
  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
  } catch (err) {
    console.error("stripe-webhook unhandled error:", err);
    captureException(err, { fn: "stripe-webhook", step: "unhandled" });
    await sentryFlush();
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
