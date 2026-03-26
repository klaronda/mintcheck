/**
 * MintCheck Admin — Starter Kit orders.
 * One function does everything: list, update tracking, fulfill Buyer Pass, send shipping email.
 * Auth: x-admin-secret === ADMIN_FEEDBACK_SECRET, or JWT with profiles.role = admin.
 * Deploy with verify_jwt: false.
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

type Supabase = ReturnType<typeof createClient>;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-secret",
};

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const APP_NAME = "MintCheck";
const SUPPORT_EMAIL = "support@mintcheckapp.com";
const HELP_LINK = "https://mintcheckapp.com/support";
const PRIVACY_LINK = "https://mintcheckapp.com/privacy";
const TERMS_LINK = "https://mintcheckapp.com/terms";
const OBD_PORT_LINK = "https://mintcheckapp.com/support/obd-port";
const APP_STORE_LINK =
  "https://apps.apple.com/app/mintcheck-car-health-scanner/id6743753553";
const PRODUCT_IMG =
  "https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/Product/MC-01a.png";

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ─── Auth ────────────────────────────────────────────────────────────────────

async function isAdminAllowed(req: Request, supabase: Supabase): Promise<boolean> {
  const adminSecret = Deno.env.get("ADMIN_FEEDBACK_SECRET");
  const provided = req.headers.get("x-admin-secret");
  if (adminSecret && provided === adminSecret) return true;

  const auth = req.headers.get("Authorization");
  if (auth?.startsWith("Bearer ")) {
    const { data: { user }, error } = await supabase.auth.getUser(auth.slice(7));
    if (!error && user?.id) {
      const { data: p } = await supabase.from("profiles").select("role").eq("id", user.id).single();
      if (p?.role === "admin") return true;
    }
  }
  return false;
}

// ─── Fulfill (activate Buyer Pass) ──────────────────────────────────────────

async function fulfillOrder(supabase: Supabase, orderId: string): Promise<Response> {
  const { data: rows, error: fetchErr } = await supabase
    .from("starter_kit_orders").select("*").eq("id", orderId).limit(1);
  if (fetchErr) {
    console.error("fulfill fetch error:", fetchErr);
    return json({ error: "Database error loading order", detail: fetchErr.message, code: fetchErr.code }, 500);
  }
  const order = rows?.[0];
  if (!order) return json({ error: "Order not found" }, 404);
  if (order.status === "pass_activated") {
    return json({ ok: true, message: "Already fulfilled", buyer_pass_subscription_id: order.buyer_pass_subscription_id }, 200);
  }
  if (order.status !== "paid_pending_fulfillment") {
    return json({ error: `Cannot fulfill order in status ${order.status}` }, 400);
  }
  const userId = order.user_id as string | null;
  if (!userId) {
    return json({ error: "Order has no user_id. Link account first." }, 400);
  }

  const now = new Date();
  const sixtyDaysMs = 60 * 24 * 60 * 60 * 1000;

  // Partial unique index: only one active buyer_pass row per user.
  // We must UPDATE the existing active row instead of inserting a second one.
  const { data: activeRows, error: activeLookupErr } = await supabase
    .from("subscriptions")
    .select("id, ended_at")
    .eq("user_id", userId)
    .eq("plan", "buyer_pass")
    .eq("status", "active")
    .order("ended_at", { ascending: false })
    .limit(1);

  if (activeLookupErr) {
    console.error("fulfill active lookup error:", activeLookupErr);
    return json({ error: "Database error loading subscriptions", detail: activeLookupErr.message }, 500);
  }

  const activeRow = activeRows?.[0];
  let baseDate = now;
  if (activeRow?.ended_at) {
    const existingEnd = new Date(activeRow.ended_at as string);
    if (existingEnd > now) baseDate = existingEnd;
  }
  const endedAt = new Date(baseDate.getTime() + sixtyDaysMs);

  let subId: string;

  if (activeRow?.id) {
    // Extend the existing active row (stack 60 days)
    subId = activeRow.id as string;
    console.log(`fulfill: extending active buyer_pass ${subId}, new end=${endedAt.toISOString()}`);
    const { error: updErr } = await supabase
      .from("subscriptions")
      .update({ ended_at: endedAt.toISOString() })
      .eq("id", subId);
    if (updErr) {
      console.error("fulfill subscription update error:", updErr);
      return json({ error: "Failed to update Buyer Pass subscription", detail: updErr.message }, 500);
    }
  } else {
    // No active row — insert new one
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
      console.error("fulfill subscription insert error:", insErr);
      return json({ error: "Failed to create Buyer Pass subscription", detail: insErr?.message, code: insErr?.code, hint: insErr?.hint }, 500);
    }
    subId = subRow.id as string;
  }

  const { error: updOrderErr } = await supabase
    .from("starter_kit_orders")
    .update({ status: "pass_activated", pass_activated_at: now.toISOString(), buyer_pass_subscription_id: subId, updated_at: now.toISOString() })
    .eq("id", order.id);
  if (updOrderErr) {
    console.error("fulfill order update error:", updOrderErr);
    return json({ error: "Pass created but failed to update order row", detail: updOrderErr.message, buyer_pass_subscription_id: subId }, 500);
  }

  return json({ ok: true, buyer_pass_subscription_id: subId, ended_at: endedAt.toISOString() }, 200);
}

// ─── Shipping email ─────────────────────────────────────────────────────────

interface StripeAddress {
  line1?: string | null; line2?: string | null; city?: string | null;
  state?: string | null; postal_code?: string | null; country?: string | null;
}

function esc(s: string | null | undefined): string {
  if (!s) return "";
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function fmtAddr(a: StripeAddress | null | undefined): string {
  if (!a) return "N/A";
  const p: string[] = [];
  if (a.line1) p.push(esc(a.line1));
  if (a.line2) p.push(esc(a.line2));
  const cs = [a.city, a.state].filter(Boolean).join(", ");
  if (cs) p.push(esc(cs));
  if (a.postal_code) p.push(esc(a.postal_code));
  if (a.country && a.country !== "US") p.push(esc(a.country));
  return p.join("<br>") || "N/A";
}

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return "N/A";
  try { return new Date(iso).toLocaleDateString("en-US", { weekday: "long", year: "numeric", month: "long", day: "numeric" }); }
  catch { return "N/A"; }
}

function trackingUrl(carrier: string, num: string): string {
  const c = carrier.toLowerCase(), n = encodeURIComponent(num.trim()), raw = num.trim();
  if (c.includes("usps")) return `https://tools.usps.com/go/TrackConfirmAction?tLabels=${n}`;
  if (c.includes("ups"))  return `https://www.ups.com/track?tracknum=${n}`;
  if (c.includes("fedex")) return `https://www.fedex.com/fedextrack/?trknbr=${n}`;
  if (c.includes("dhl"))  return `https://www.dhl.com/en/express/tracking.html?AWB=${n}`;
  return `https://www.google.com/search?q=${encodeURIComponent(`${carrier} ${raw} tracking`)}`;
}

function shippingHtml(p: {
  name: string; email: string; phone: string; billingHtml: string;
  shipName: string; shipHtml: string; orderDate: string;
  carrier: string; tracking: string; trackUrl: string; passActive: boolean;
}): string {
  const nm = esc(p.name) || "Customer";
  const em = esc(p.email) || "";
  const ph = esc(p.phone) || "";
  const tl = 'style="padding:6px 0;color:#999;font-size:14px;vertical-align:top;width:110px"';
  const tv = 'style="padding:6px 0;color:#1A1A1A;font-size:14px;vertical-align:top"';
  const passBlurb = p.passActive
    ? `<p style="margin:0 0 12px;color:#666;font-size:14px;line-height:1.7">Your <strong>60-day Buyer Pass</strong> is active: scan up to <strong>10 vehicles per day</strong>. Follow the steps below once your kit arrives.</p>`
    : `<p style="margin:0 0 12px;color:#666;font-size:14px;line-height:1.7">Your kit includes a <strong>60-day Buyer Pass</strong> (up to 10 scans/day). If you don\u2019t see it in the app yet, it may activate shortly\u2014reply to this email if you need help.</p>`;
  const step = (n: number, title: string, desc: string) =>
    `<tr><td style="padding:10px 12px 10px 0;vertical-align:top;width:32px"><div style="width:28px;height:28px;border-radius:50%;background:#3EB489;color:#FFF;font-size:14px;font-weight:600;text-align:center;line-height:28px">${n}</div></td><td style="padding:10px 0;color:#1A1A1A;font-size:14px;line-height:1.6"><strong>${title}</strong><br><span style="color:#666">${desc}</span></td></tr>`;
  return `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>Your MintCheck order has shipped</title></head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;background:#F8F8F7">
<table role="presentation" style="width:100%;border-collapse:collapse"><tr><td align="center" style="padding:40px 20px">
<table role="presentation" style="width:100%;max-width:600px;border-collapse:collapse">
<tr><td style="background:#FFF;padding:32px 32px 24px;border-radius:4px 4px 0 0">
  <div style="color:#3EB489;font-size:24px;font-weight:600;margin-bottom:8px">${APP_NAME}</div>
  <h2 style="margin:0;color:#1A1A1A;font-size:24px;font-weight:600">Your kit is on the way</h2>
</td></tr>
<tr><td style="background:#FFF;padding:0 32px 32px">
  <p style="margin:0 0 24px;color:#666;font-size:15px;line-height:1.7">Great news\u2014your <strong>MintCheck Starter Kit</strong> has shipped! Track your package below.</p>
  <table role="presentation" style="width:100%;border-collapse:collapse;background:#F4FBF8;border:1px solid #D4EDDF;border-radius:8px;margin-bottom:28px">
    <tr><td style="padding:24px">
      <p style="margin:0 0 6px;color:#999;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.5px">Shipment</p>
      <p style="margin:0 0 8px;color:#1A1A1A;font-size:15px;line-height:1.6"><strong>${esc(p.carrier)}</strong><br><span style="color:#666;font-family:ui-monospace,monospace">${esc(p.tracking)}</span></p>
      <a href="${esc(p.trackUrl)}" style="display:inline-block;padding:12px 28px;background:#3EB489;color:#FFF;text-decoration:none;border-radius:6px;font-size:14px;font-weight:600">Track your package</a>
    </td></tr>
  </table>
  <table role="presentation" style="width:100%;border-collapse:collapse;margin-bottom:24px">
    <tr><td ${tl}>Name</td><td ${tv}>${nm}</td></tr>
    ${em ? `<tr><td ${tl}>Email</td><td ${tv}>${em}</td></tr>` : ""}
    ${ph ? `<tr><td ${tl}>Phone</td><td ${tv}>${ph}</td></tr>` : ""}
    <tr><td ${tl}>Order date</td><td ${tv}>${p.orderDate}</td></tr>
  </table>
  <table role="presentation" style="width:100%;border-collapse:collapse;margin-bottom:28px"><tr>
    <td style="width:50%;vertical-align:top;padding-right:12px">
      <p style="margin:0 0 6px;color:#999;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.5px">Shipping address</p>
      <p style="margin:0;color:#1A1A1A;font-size:14px;line-height:1.6">${esc(p.shipName)}<br>${p.shipHtml}</p>
    </td>
    <td style="width:50%;vertical-align:top;padding-left:12px">
      <p style="margin:0 0 6px;color:#999;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.5px">Billing address</p>
      <p style="margin:0;color:#1A1A1A;font-size:14px;line-height:1.6">${p.billingHtml}</p>
    </td>
  </tr></table>
  <table role="presentation" style="width:100%;border-collapse:collapse;background:#FCFCFB;border:1px solid #E5E5E5;border-radius:8px;margin-bottom:28px"><tr>
    <td style="padding:20px;width:90px;vertical-align:top"><img src="${PRODUCT_IMG}" alt="MintCheck Scanner" style="width:80px;height:auto;border-radius:4px"></td>
    <td style="padding:20px 20px 20px 0;vertical-align:top">
      <p style="margin:0 0 4px;color:#1A1A1A;font-size:16px;font-weight:600">MintCheck Starter Kit (MC-01)</p>
      <p style="margin:0;color:#666;font-size:14px;line-height:1.6">Includes:<br>&bull; Wi-Fi OBD-II Scanner<br>&bull; 60-Day Buyer Pass (scan up to 10 vehicles per day)</p>
    </td>
  </tr></table>
  <h3 style="margin:0 0 12px;color:#1A1A1A;font-size:18px;font-weight:600">Your Buyer Pass &amp; Quick Start</h3>
  ${passBlurb}
  <table role="presentation" style="width:100%;border-collapse:collapse">
    ${step(1, "Download the app", `Get MintCheck from the <a href="${APP_STORE_LINK}" style="color:#3EB489;text-decoration:none">App Store</a> (iPhone only for now).`)}
    ${step(2, "Sign in with your account", "Use the same email you used at checkout so your scans and Buyer Pass stay linked.")}
    ${step(3, "Turn on the car", "Start the engine or turn the ignition to the ON position.")}
    ${step(4, "Insert your MintCheck scanner", `Plug it into the OBD-II port (usually under the dash). <a href="${OBD_PORT_LINK}" style="color:#3EB489;text-decoration:none">Help me find it</a>`)}
    ${step(5, "Follow the steps in the app", "Connect to the scanner\u2019s Wi-Fi and tap Scan. Results in about 30 seconds.")}
  </table>
  <table role="presentation" style="width:100%;border-collapse:collapse;background:#F4FBF8;border:1px solid #D4EDDF;border-radius:8px;margin-top:32px"><tr><td style="padding:24px">
    <p style="margin:0 0 6px;color:#1A1A1A;font-size:16px;font-weight:600">Shopping for a used car?</p>
    <p style="margin:0 0 16px;color:#666;font-size:14px;line-height:1.6">Get a <strong>Deep Check Report</strong> on any vehicle before you buy. Enter a VIN in the MintCheck app to see accident history, title status, recall notices, and more.</p>
    <a href="https://mintcheckapp.com" style="display:inline-block;padding:12px 28px;background:#3EB489;color:#FFF;text-decoration:none;border-radius:6px;font-size:14px;font-weight:600">Learn More in the App</a>
  </td></tr></table>
</td></tr>
<tr><td style="background:#F8F8F7;padding:32px;text-align:center;border-radius:0 0 4px 4px;border-top:1px solid #E5E5E5">
  <p style="margin:0 0 8px;color:#999;font-size:13px;line-height:1.6">Questions? Reply to this email or reach us at <a href="mailto:${SUPPORT_EMAIL}" style="color:#3EB489;text-decoration:none">${SUPPORT_EMAIL}</a></p>
  <p style="margin:0 0 16px;color:#999;font-size:13px;line-height:1.6">&copy; 2026 ${APP_NAME}. All rights reserved.</p>
  <p style="margin:0;color:#999;font-size:13px;line-height:1.6"><a href="${HELP_LINK}" style="color:#3EB489;text-decoration:none">Support</a> &bull; <a href="${PRIVACY_LINK}" style="color:#3EB489;text-decoration:none">Privacy</a> &bull; <a href="${TERMS_LINK}" style="color:#3EB489;text-decoration:none">Terms</a></p>
</td></tr>
</table></td></tr></table></body></html>`;
}

async function sendShippingEmail(supabase: Supabase, orderId: string): Promise<{ ok: boolean; error?: string }> {
  const { data: order, error: oErr } = await supabase
    .from("starter_kit_orders").select("*").eq("id", orderId).single();
  if (oErr || !order) return { ok: false, error: "Order not found" };
  if (order.shipping_confirmation_sent_at) return { ok: true };

  const carrier = String(order.tracking_carrier ?? "").trim();
  const tracking = String(order.tracking_number ?? "").trim();
  const toEmail = order.customer_email as string | null;
  if (!carrier || !tracking) return { ok: false, error: "Carrier and tracking number required" };
  if (!toEmail) return { ok: false, error: "No customer email" };

  let shipName = String(order.customer_name ?? "").trim() || "Customer";
  let shipAddrHtml = '<span style="color:#666">Same as on your order confirmation.</span>';
  let billHtml = shipAddrHtml;
  let phone = "";

  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
  const sid = order.stripe_session_id as string;
  if (stripeKey && sid) {
    try {
      const stripe = new Stripe(stripeKey, { apiVersion: "2023-10-16", httpClient: Stripe.createFetchHttpClient() });
      const sess = await stripe.checkout.sessions.retrieve(sid);
      const det = sess.customer_details, ship = sess.shipping_details;
      if (ship?.name || ship?.address) {
        if (ship?.name) shipName = String(ship.name).trim();
        shipAddrHtml = fmtAddr(ship?.address as StripeAddress | null);
      } else if (det?.name || det?.address) {
        if (det?.name) shipName = String(det.name).trim();
        shipAddrHtml = fmtAddr(det?.address as StripeAddress | null);
      }
      billHtml = fmtAddr(det?.address as StripeAddress | null);
      phone = det?.phone ? String(det.phone).trim() : "";
    } catch (e) { console.error("shipping email: Stripe retrieve failed", e); }
  }

  const passActive = order.status === "pass_activated" || Boolean(order.pass_activated_at) || Boolean(order.buyer_pass_subscription_id);
  const tUrl = trackingUrl(carrier, tracking);
  const orderNumber = typeof order.order_number === "string" ? order.order_number : null;

  const html = shippingHtml({
    name: String(order.customer_name ?? "").trim() || "Customer",
    email: toEmail, phone, billingHtml: billHtml,
    shipName, shipHtml: shipAddrHtml,
    orderDate: fmtDate(order.created_at as string),
    carrier, tracking, trackUrl: tUrl, passActive,
  });

  const resendKey = Deno.env.get("RESEND_API_KEY");
  if (!resendKey) { console.error("RESEND_API_KEY not set"); return { ok: false, error: "Email not configured" }; }

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: "MintCheck Orders <orders@mintcheckapp.com>",
      to: [toEmail], bcc: ["contact@mintcheckapp.com"], reply_to: SUPPORT_EMAIL,
      subject: orderNumber ? `MintCheck Order #${orderNumber} Has Shipped` : "Your MintCheck Starter Kit has shipped", html,
    }),
  });

  if (!res.ok) {
    const t = await res.text();
    console.error("Resend error", res.status, t);
    return { ok: false, error: `Resend ${res.status}: ${t}` };
  }

  const nowIso = new Date().toISOString();
  await supabase.from("starter_kit_orders")
    .update({ shipping_confirmation_sent_at: nowIso, updated_at: nowIso })
    .eq("id", orderId);

  console.log(`shipping email sent to ${toEmail} order=${orderId}`);
  return { ok: true };
}

// ─── Main handler ───────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  if (!(await isAdminAllowed(req, supabase))) return json({ error: "Unauthorized" }, 401);

  try {
    // ── GET: list orders ──
    if (req.method === "GET") {
      const url = new URL(req.url);
      const st = url.searchParams.get("status");
      let q = supabase.from("starter_kit_orders").select("*").order("created_at", { ascending: false }).limit(200);
      if (st?.trim()) q = q.eq("status", st.trim());
      const { data, error } = await q;
      if (error) { console.error("list error:", error); return json({ error: error.message }, 500); }
      return json({ orders: data ?? [] }, 200);
    }

    // ── PATCH: update tracking / user_id ──
    if (req.method === "PATCH") {
      let body: Record<string, unknown>;
      try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

      const id = typeof body.id === "string" ? body.id.trim() : "";
      if (!id) return json({ error: "id required" }, 400);

      const hasCarrier = Object.prototype.hasOwnProperty.call(body, "tracking_carrier");
      const hasTracking = Object.prototype.hasOwnProperty.call(body, "tracking_number");
      const hasUser = Object.prototype.hasOwnProperty.call(body, "user_id");
      if (!hasCarrier && !hasTracking && !hasUser) return json({ error: "Nothing to update" }, 400);

      const { data: existing, error: fetchErr } = await supabase
        .from("starter_kit_orders")
        .select("id, shipped_at, user_id, status, tracking_carrier, tracking_number")
        .eq("id", id).single();
      if (fetchErr || !existing) return json({ error: "Order not found" }, 404);

      const nowIso = new Date().toISOString();
      const updates: Record<string, unknown> = { updated_at: nowIso };

      if (hasCarrier) {
        const c = body.tracking_carrier;
        updates.tracking_carrier = typeof c === "string" && c.trim() ? c.trim() : null;
      }
      if (hasTracking) {
        const t = body.tracking_number;
        updates.tracking_number = typeof t === "string" && t.trim() ? t.trim() : null;
      }

      const mergedTracking = (hasTracking
        ? (typeof body.tracking_number === "string" ? body.tracking_number.trim() : "")
        : String(existing.tracking_number ?? "")) || "";
      if (mergedTracking && !existing.shipped_at) updates.shipped_at = nowIso;

      if (hasUser) {
        const raw = body.user_id;
        if (raw === null || raw === "") return json({ error: "user_id cannot be cleared" }, 400);
        if (typeof raw !== "string") return json({ error: "user_id must be a string UUID" }, 400);
        const uid = raw.trim();
        if (!UUID_RE.test(uid)) return json({ error: "user_id must be a valid UUID" }, 400);
        if (existing.status !== "paid_pending_fulfillment") return json({ error: "user_id can only be set while status is paid_pending_fulfillment" }, 400);
        const { data: authUser, error: authErr } = await supabase.auth.admin.getUserById(uid);
        if (authErr || !authUser?.user?.id) return json({ error: "No Auth user found for that user_id" }, 400);
        updates.user_id = uid;
      }

      const { data: updated, error: updErr } = await supabase
        .from("starter_kit_orders").update(updates).eq("id", id).select("*").single();
      if (updErr) { console.error("patch error:", updErr); return json({ error: updErr.message }, 500); }

      let orderPayload = updated;

      // Auto-send shipping email when carrier + tracking are saved
      const carrierOut = String(updated.tracking_carrier ?? "").trim();
      const trackingOut = String(updated.tracking_number ?? "").trim();
      const emailOut = updated.customer_email as string | null | undefined;
      if (carrierOut && trackingOut && emailOut && !updated.shipping_confirmation_sent_at) {
        try {
          const r = await sendShippingEmail(supabase, id);
          if (!r.ok) console.error("shipping email failed:", r.error);
          else {
            const { data: refetched } = await supabase.from("starter_kit_orders").select("*").eq("id", id).single();
            if (refetched) orderPayload = refetched;
          }
        } catch (e) { console.error("shipping email error:", e); }
      }

      return json({ order: orderPayload }, 200);
    }

    // ── POST: fulfill ──
    if (req.method === "POST") {
      let body: { action?: string; order_id?: string };
      try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }
      if (body.action !== "fulfill") return json({ error: "Unknown action" }, 400);
      const orderId = typeof body.order_id === "string" ? body.order_id.trim() : "";
      if (!orderId) return json({ error: "order_id required" }, 400);

      try {
        return await fulfillOrder(supabase, orderId);
      } catch (e) {
        console.error("fulfill error:", e);
        return json({ error: "Fulfill failed", detail: e instanceof Error ? e.message : String(e) }, 500);
      }
    }

    return json({ error: "Method not allowed" }, 405);
  } catch (e) {
    console.error("admin-starter-kit-orders error:", e);
    return json({ error: "Internal server error" }, 500);
  }
});
