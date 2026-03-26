/**
 * Shared Starter Kit fulfillment (Buyer Pass row + order update).
 * Bundled with admin-starter-kit-orders to avoid Edge→Edge fetch failures.
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

type Supabase = ReturnType<typeof createClient>;

export async function executeFulfillStarterKitOrder(
  supabase: Supabase,
  orderId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  let query = supabase.from("starter_kit_orders").select("*").eq("id", orderId);

  const { data: rows, error: fetchErr } = await query.limit(1);
  if (fetchErr) {
    console.error("fulfill_core fetch order error:", fetchErr);
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
      console.log(`fulfill_core: stacking onto existing buyer_pass end=${existingEnd.toISOString()}`);
    }
  }

  const endedAt = new Date(baseDate.getTime() + sixtyDaysMs);
  const syntheticSessionId = `starter_kit_order:${order.id}`;

  const { data: existingBySession, error: reuseLookupErr } = await supabase
    .from("subscriptions")
    .select("id")
    .eq("stripe_session_id", syntheticSessionId)
    .maybeSingle();

  if (reuseLookupErr) {
    console.error("fulfill_core reuse lookup error:", reuseLookupErr);
    return new Response(
      JSON.stringify({
        error: "Database error checking existing subscription",
        detail: reuseLookupErr.message,
        code: reuseLookupErr.code,
        hint: "Ensure subscriptions.stripe_session_id exists (run migrations).",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  let subId: string;
  if (existingBySession?.id) {
    subId = existingBySession.id as string;
    console.log(`fulfill_core: reusing subscription ${subId} for ${syntheticSessionId}`);
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
      console.error("fulfill_core subscriptions insert error:", insErr);
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
    console.error("fulfill_core order update error:", updOrderErr);
    return new Response(
      JSON.stringify({
        error: "Pass created but failed to update order row",
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
}
