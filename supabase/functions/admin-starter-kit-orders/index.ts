/**
 * MintCheck Admin: list / update tracking / link user_id / fulfill Starter Kit orders.
 * Auth matches list-feedback: x-admin-secret === ADMIN_FEEDBACK_SECRET, or JWT user with profiles.role = admin.
 *
 * Deploy with verify_jwt: false (same as list-feedback) if using secret-only from the web admin UI.
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-secret",
};

type StarterKitOrderRow = Record<string, unknown>;

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

async function isAdminAllowed(
  req: Request,
  supabase: ReturnType<typeof createClient>
): Promise<boolean> {
  const adminSecret = Deno.env.get("ADMIN_FEEDBACK_SECRET");
  const providedSecret = req.headers.get("x-admin-secret");
  if (adminSecret && providedSecret === adminSecret) {
    return true;
  }
  const authHeader = req.headers.get("Authorization");
  if (authHeader?.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (!authError && user?.id) {
      const { data: profile } = await supabase
        .from("profiles")
        .select("role")
        .eq("id", user.id)
        .single();
      if (profile?.role === "admin") return true;
    }
  }
  return false;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  if (!(await isAdminAllowed(req, supabase))) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    if (req.method === "GET") {
      const url = new URL(req.url);
      const statusFilter = url.searchParams.get("status");
      let q = supabase
        .from("starter_kit_orders")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(200);
      if (statusFilter && statusFilter.trim()) {
        q = q.eq("status", statusFilter.trim());
      }
      const { data, error } = await q.returns<StarterKitOrderRow[]>();
      if (error) {
        console.error("admin-starter-kit-orders list error:", error);
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      return new Response(JSON.stringify({ orders: data ?? [] }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (req.method === "PATCH") {
      let body: Record<string, unknown>;
      try {
        body = await req.json();
      } catch {
        return new Response(JSON.stringify({ error: "Invalid JSON" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const id = typeof body.id === "string" ? body.id.trim() : "";
      if (!id) {
        return new Response(JSON.stringify({ error: "id required" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const hasTrackingCarrier = Object.prototype.hasOwnProperty.call(body, "tracking_carrier");
      const hasTrackingNumber = Object.prototype.hasOwnProperty.call(body, "tracking_number");
      const hasUserId = Object.prototype.hasOwnProperty.call(body, "user_id");

      if (!hasTrackingCarrier && !hasTrackingNumber && !hasUserId) {
        return new Response(
          JSON.stringify({
            error: "Provide tracking_carrier and/or tracking_number and/or user_id to update",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      const { data: existing, error: fetchErr } = await supabase
        .from("starter_kit_orders")
        .select("id, shipped_at, user_id, status, tracking_carrier, tracking_number")
        .eq("id", id)
        .single();

      if (fetchErr || !existing) {
        return new Response(JSON.stringify({ error: "Order not found" }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const nowIso = new Date().toISOString();
      const updates: Record<string, unknown> = {
        updated_at: nowIso,
      };

      if (hasTrackingCarrier) {
        const c = body.tracking_carrier;
        updates.tracking_carrier =
          typeof c === "string" && c.trim() ? c.trim() : null;
      }
      if (hasTrackingNumber) {
        const t = body.tracking_number;
        updates.tracking_number =
          typeof t === "string" && t.trim() ? t.trim() : null;
      }

      const mergedTracking =
        (hasTrackingNumber
          ? (typeof body.tracking_number === "string" ? body.tracking_number.trim() : "")
          : String(existing.tracking_number ?? "")) || "";

      if (mergedTracking && !existing.shipped_at) {
        updates.shipped_at = nowIso;
      }

      if (hasUserId) {
        const raw = body.user_id;
        if (raw === null || raw === "") {
          return new Response(
            JSON.stringify({ error: "user_id cannot be cleared; omit the field to leave unchanged" }),
            {
              status: 400,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
          );
        }
        if (typeof raw !== "string") {
          return new Response(JSON.stringify({ error: "user_id must be a string UUID" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
        const uid = raw.trim();
        if (!UUID_RE.test(uid)) {
          return new Response(JSON.stringify({ error: "user_id must be a valid UUID" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
        if (existing.status !== "paid_pending_fulfillment") {
          return new Response(
            JSON.stringify({
              error: "user_id can only be set while order status is paid_pending_fulfillment",
            }),
            {
              status: 400,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
          );
        }
        const { data: authUser, error: authErr } = await supabase.auth.admin.getUserById(uid);
        if (authErr || !authUser?.user?.id) {
          console.error("admin-starter-kit-orders getUserById:", authErr?.message);
          return new Response(
            JSON.stringify({
              error: "No Auth user found for that user_id (check Supabase Authentication → Users)",
            }),
            {
              status: 400,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
          );
        }
        updates.user_id = uid;
      }

      const { data: updated, error: updErr } = await supabase
        .from("starter_kit_orders")
        .update(updates)
        .eq("id", id)
        .select("*")
        .single();

      if (updErr) {
        console.error("admin-starter-kit-orders patch error:", updErr);
        return new Response(JSON.stringify({ error: updErr.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      return new Response(JSON.stringify({ order: updated }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (req.method === "POST") {
      let body: { action?: string; order_id?: string };
      try {
        body = await req.json();
      } catch {
        return new Response(JSON.stringify({ error: "Invalid JSON" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (body.action !== "fulfill") {
        return new Response(JSON.stringify({ error: "Unknown action" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const orderId = typeof body.order_id === "string" ? body.order_id.trim() : "";
      if (!orderId) {
        return new Response(JSON.stringify({ error: "order_id required" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const invokeSecret = Deno.env.get("DEEP_CHECK_INVOKE_SECRET");
      if (!invokeSecret) {
        return new Response(JSON.stringify({ error: "DEEP_CHECK_INVOKE_SECRET not configured" }), {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const fulfillUrl = `${supabaseUrl}/functions/v1/fulfill-starter-kit-order`;
      const fr = await fetch(fulfillUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Internal-Secret": invokeSecret,
        },
        body: JSON.stringify({ order_id: orderId }),
      });
      const text = await fr.text();
      let payload: unknown;
      try {
        payload = JSON.parse(text);
      } catch {
        payload = { raw: text };
      }
      return new Response(JSON.stringify(payload), {
        status: fr.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("admin-starter-kit-orders error:", e);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
