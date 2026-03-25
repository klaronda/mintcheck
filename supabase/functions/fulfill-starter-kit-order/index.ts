/**
 * Activate 60-day Buyer Pass for a Starter Kit order (call when hardware ships).
 * Auth: X-Internal-Secret (same as DEEP_CHECK_INVOKE_SECRET / other internal functions).
 *
 * Body: { "order_id": "<uuid>" } or { "stripe_session_id": "cs_..." }
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-internal-secret",
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
    return new Response(JSON.stringify({ error: "Database error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
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

  let baseDate = now;
  const { data: existingSubs } = await supabase
    .from("subscriptions")
    .select("id, ended_at")
    .eq("user_id", userId)
    .eq("plan", "buyer_pass")
    .eq("status", "active")
    .gt("ended_at", now.toISOString())
    .order("ended_at", { ascending: false })
    .limit(1);

  if (existingSubs && existingSubs.length > 0 && existingSubs[0].ended_at) {
    const existingEnd = new Date(existingSubs[0].ended_at as string);
    if (existingEnd > now) {
      baseDate = existingEnd;
      console.log(
        `fulfill-starter-kit-order: stacking onto existing buyer_pass end=${existingEnd.toISOString()}`
      );
    }
  }

  const endedAt = new Date(baseDate.getTime() + sixtyDaysMs);

  const { data: subRow, error: insErr } = await supabase
    .from("subscriptions")
    .insert({
      user_id: userId,
      plan: "buyer_pass",
      status: "active",
      provider: "starter_kit",
      started_at: now.toISOString(),
      ended_at: endedAt.toISOString(),
      stripe_session_id: `starter_kit_order:${order.id}`,
    })
    .select("id")
    .single();

  if (insErr || !subRow) {
    console.error("fulfill-starter-kit-order subscriptions insert error:", insErr);
    return new Response(
      JSON.stringify({
        error: "Failed to create Buyer Pass subscription",
        detail: insErr?.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const subId = subRow.id as string;

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
  }

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
});
