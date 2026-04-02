/**
 * Activate 60-day Buyer Pass for a Starter Kit order (call when hardware ships).
 * Auth: X-Internal-Secret (same as DEEP_CHECK_INVOKE_SECRET / other internal functions).
 *
 * Body: { "order_id": "<uuid>" } or { "stripe_session_id": "cs_..." }
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
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

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-internal-secret",
};

serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const invokeSecret = Deno.env.get("DEEP_CHECK_INVOKE_SECRET");
    const provided = req.headers.get("X-Internal-Secret");
    if (!invokeSecret || provided !== invokeSecret) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let body: { order_id?: string; stripe_session_id?: string };
    try {
      body = await req.json();
    } catch {
      return new Response(JSON.stringify({ error: "Invalid JSON" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const orderId = typeof body.order_id === "string" ? body.order_id.trim() : "";
    const sessionId =
      typeof body.stripe_session_id === "string" ? body.stripe_session_id.trim() : "";

    if (!orderId && !sessionId) {
      return new Response(
        JSON.stringify({ error: "Provide order_id or stripe_session_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    let query = supabase.from("starter_kit_orders").select("*");
    if (orderId) {
      query = query.eq("id", orderId);
    } else {
      query = query.eq("stripe_session_id", sessionId);
    }

    const { data: rows, error: fetchErr } = await query.limit(1);
    if (fetchErr) {
      console.error("fulfill-starter-kit-order fetch error:", fetchErr);
      captureException(fetchErr, { fn: "fulfill-starter-kit-order", step: "fetch_order" });
      return new Response(
        JSON.stringify({
          error: "Database error loading order",
          detail: fetchErr.message,
          code: fetchErr.code,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

  const order = rows?.[0];
  if (!order) {
    return new Response(JSON.stringify({ error: "Order not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (order.status === "pass_activated") {
    return new Response(
      JSON.stringify({
        ok: true,
        message: "Already fulfilled",
        buyer_pass_subscription_id: order.buyer_pass_subscription_id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (order.status !== "paid_pending_fulfillment") {
    return new Response(
      JSON.stringify({ error: `Cannot fulfill order in status ${order.status}` }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const userId = order.user_id as string | null;
  if (!userId) {
    return new Response(
      JSON.stringify({
        error:
          "Order has no user_id (guest checkout). Link account or fulfill manually in Supabase.",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const now = new Date();
  const sixtyDaysMs = 60 * 24 * 60 * 60 * 1000;

  const { data: activeRows, error: activeLookupErr } = await supabase
    .from("subscriptions")
    .select("id, ended_at")
    .eq("user_id", userId)
    .eq("plan", "buyer_pass")
    .eq("status", "active")
    .order("ended_at", { ascending: false })
    .limit(1);

  if (activeLookupErr) {
    console.error("fulfill-starter-kit-order active subscription lookup error:", activeLookupErr);
    captureException(activeLookupErr, { fn: "fulfill-starter-kit-order", step: "active_subscription_lookup" });
    return new Response(
      JSON.stringify({
        error: "Database error loading subscriptions",
        detail: activeLookupErr.message,
        code: activeLookupErr.code,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const activeRow = activeRows?.[0];

  let baseDate = now;
  if (activeRow?.ended_at) {
    const existingEnd = new Date(activeRow.ended_at as string);
    if (existingEnd > now) {
      baseDate = existingEnd;
      console.log(
        `fulfill-starter-kit-order: stacking onto existing buyer_pass end=${existingEnd.toISOString()}`
      );
    }
  }

  const endedAt = new Date(baseDate.getTime() + sixtyDaysMs);
  const syntheticSessionId = `starter_kit_order:${order.id}`;

  const { data: syntheticRow, error: reuseLookupErr } = await supabase
    .from("subscriptions")
    .select("id, status")
    .eq("stripe_session_id", syntheticSessionId)
    .eq("user_id", userId)
    .maybeSingle();

  if (reuseLookupErr) {
    console.error("fulfill-starter-kit-order reuse lookup error:", reuseLookupErr);
    captureException(reuseLookupErr, { fn: "fulfill-starter-kit-order", step: "reuse_lookup" });
    return new Response(
      JSON.stringify({
        error: "Database error checking existing subscription",
        detail: reuseLookupErr.message,
        code: reuseLookupErr.code,
        hint:
          "Ensure subscriptions.stripe_session_id exists (run migrations) and RLS allows service role.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const updateSubEndedAt = (subscriptionId: string) =>
    supabase
      .from("subscriptions")
      .update({ ended_at: endedAt.toISOString() })
      .eq("id", subscriptionId);

  const existingBySession =
    syntheticRow?.id && syntheticRow.status === "active" ? syntheticRow : null;

  let subId: string;
  if (existingBySession?.id) {
    subId = existingBySession.id as string;
    console.log(
      `fulfill-starter-kit-order: reusing existing subscription ${subId} for ${syntheticSessionId}`
    );
    const { error: updErr } = await updateSubEndedAt(subId);
    if (updErr) {
      console.error("fulfill-starter-kit-order subscription update error (reuse):", updErr);
      captureException(updErr, { fn: "fulfill-starter-kit-order", step: "subscription_update_reuse" });
      return new Response(
        JSON.stringify({
          error: "Failed to update Buyer Pass subscription",
          detail: updErr.message,
          code: updErr.code,
          hint: updErr.hint,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
  } else if (activeRow?.id) {
    subId = activeRow.id as string;
    console.log(
      `fulfill-starter-kit-order: extending existing active buyer_pass row ${subId} (only one active row allowed per user)`
    );
    const { error: updErr } = await updateSubEndedAt(subId);
    if (updErr) {
      console.error("fulfill-starter-kit-order subscription update error (extend):", updErr);
      captureException(updErr, { fn: "fulfill-starter-kit-order", step: "subscription_update_extend" });
      return new Response(
        JSON.stringify({
          error: "Failed to update Buyer Pass subscription",
          detail: updErr.message,
          code: updErr.code,
          hint: updErr.hint,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
  } else {
    const { data: subRow, error: insErr } = await supabase
      .from("subscriptions")
      .insert({
        user_id: userId,
        plan: "buyer_pass",
        status: "active",
        provider: "starter_kit",
        started_at: now.toISOString(),
        ended_at: endedAt.toISOString(),
        stripe_session_id: syntheticSessionId,
      })
      .select("id")
      .single();

    if (insErr || !subRow) {
      console.error("fulfill-starter-kit-order subscriptions insert error:", insErr);
      captureException(insErr, { fn: "fulfill-starter-kit-order", step: "subscription_insert" });
      return new Response(
        JSON.stringify({
          error: "Failed to create Buyer Pass subscription",
          detail: insErr?.message,
          code: insErr?.code,
          hint: insErr?.hint,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    subId = subRow.id as string;
  }

  const { error: updOrderErr } = await supabase
    .from("starter_kit_orders")
    .update({
      status: "pass_activated",
      pass_activated_at: now.toISOString(),
      buyer_pass_subscription_id: subId,
      updated_at: now.toISOString(),
    })
    .eq("id", order.id);

  if (updOrderErr) {
    console.error("fulfill-starter-kit-order order update error:", updOrderErr);
    captureException(updOrderErr, { fn: "fulfill-starter-kit-order", step: "order_status_update" });
    return new Response(
      JSON.stringify({
        error: "Pass updated but failed to update order row",
        detail: updOrderErr.message,
        code: updOrderErr.code,
        buyer_pass_subscription_id: subId,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  await sentryFlush();
  return new Response(
    JSON.stringify({
      ok: true,
      buyer_pass_subscription_id: subId,
      ended_at: endedAt.toISOString(),
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
  } catch (e) {
    console.error("fulfill-starter-kit-order unhandled error:", e);
    captureException(e, { fn: "fulfill-starter-kit-order", step: "unhandled" });
    await sentryFlush();
    return new Response(
      JSON.stringify({
        error: "Internal error in fulfill-starter-kit-order",
        detail: e instanceof Error ? e.message : String(e),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
