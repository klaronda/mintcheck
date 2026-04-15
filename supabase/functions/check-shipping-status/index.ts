/**
 * check-shipping-status
 *
 * Called every 2 hours by pg_cron via pg_net. For each starter_kit_order that
 * has a tracking number but hasn't reached "delivered" yet, polls the USPS v3
 * tracking API for the current status. When a package is delivered, sends a
 * delivery confirmation email via Resend.
 *
 * Env: USPS_CLIENT_ID, USPS_CLIENT_SECRET (from developer.usps.com)
 * Auth: X-Internal-Secret header (DEEP_CHECK_INVOKE_SECRET).
 * Deploy with verify_jwt: false.
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const APP_NAME = "MintCheck";
const SUPPORT_EMAIL = "support@mintcheckapp.com";
const HELP_LINK = "https://mintcheckapp.com/support";
const PRIVACY_LINK = "https://mintcheckapp.com/privacy";
const TERMS_LINK = "https://mintcheckapp.com/terms";
const APP_STORE_LINK =
  "https://apps.apple.com/us/app/mintcheck/id6759132070";
const PRODUCT_IMG =
  "https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/Product/MC-01a.png";

const USPS_TOKEN_URL = "https://apis.usps.com/oauth2/v3/token";
const USPS_TRACKING_URL = "https://apis.usps.com/tracking/v3/tracking";

type OurStatus = "in_transit" | "out_for_delivery" | "delivered" | "failed";

function mapUspsCategory(cat: string | undefined | null): OurStatus | null {
  if (!cat) return null;
  const lc = cat.toLowerCase();
  if (lc === "delivered") return "delivered";
  if (lc === "out for delivery") return "out_for_delivery";
  if (lc === "in transit" || lc === "accepted" || lc === "pre-shipment" || lc === "origin post is preparing shipment")
    return "in_transit";
  if (lc === "alert" || lc === "return to sender" || lc === "undeliverable")
    return "failed";
  return null;
}

// ─── USPS OAuth ──────────────────────────────────────────────────────────────

let cachedToken: { token: string; expiresAt: number } | null = null;

async function getUspsToken(clientId: string, clientSecret: string): Promise<string> {
  if (cachedToken && Date.now() < cachedToken.expiresAt - 60_000) {
    return cachedToken.token;
  }

  const res = await fetch(USPS_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      client_id: clientId,
      client_secret: clientSecret,
    }),
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`USPS OAuth failed: ${res.status} ${txt}`);
  }

  const data = await res.json();
  const token = data.access_token as string;
  const expiresIn = (data.expires_in as number) ?? 28800;
  cachedToken = { token, expiresAt: Date.now() + expiresIn * 1000 };
  return token;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function esc(s: string | null | undefined): string {
  if (!s) return "";
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function trackingUrl(carrier: string, num: string): string {
  const c = carrier.toLowerCase(),
    n = encodeURIComponent(num.trim()),
    raw = num.trim();
  if (c.includes("usps"))
    return `https://tools.usps.com/go/TrackConfirmAction?tLabels=${n}`;
  if (c.includes("ups"))
    return `https://www.ups.com/track?tracknum=${n}`;
  if (c.includes("fedex"))
    return `https://www.fedex.com/fedextrack/?trknbr=${n}`;
  if (c.includes("dhl"))
    return `https://www.dhl.com/en/express/tracking.html?AWB=${n}`;
  return `https://www.google.com/search?q=${encodeURIComponent(
    `${carrier} ${raw} tracking`
  )}`;
}

function deliveryEmailHtml(p: {
  name: string;
  carrier: string;
  tracking: string;
  trackUrl: string;
  orderNumber: string | null;
}): string {
  const nm = esc(p.name) || "Customer";
  return `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>Your MintCheck Starter Kit has been delivered</title></head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;background:#F8F8F7">
<table role="presentation" style="width:100%;border-collapse:collapse"><tr><td align="center" style="padding:40px 20px">
<table role="presentation" style="width:100%;max-width:600px;border-collapse:collapse">
<tr><td style="background:#FFF;padding:32px 32px 24px;border-radius:4px 4px 0 0">
  <div style="color:#3EB489;font-size:24px;font-weight:600;margin-bottom:8px">${APP_NAME}</div>
  <h2 style="margin:0;color:#1A1A1A;font-size:24px;font-weight:600">Your Starter Kit has been delivered!</h2>
</td></tr>
<tr><td style="background:#FFF;padding:0 32px 32px">
  <p style="margin:0 0 24px;color:#666;font-size:15px;line-height:1.7">Hi ${nm}, your <strong>MintCheck Starter Kit</strong> has been delivered. Time to scan some cars!</p>
  <table role="presentation" style="width:100%;border-collapse:collapse;background:#F4FBF8;border:1px solid #D4EDDF;border-radius:8px;margin-bottom:28px">
    <tr><td style="padding:24px">
      <p style="margin:0 0 6px;color:#999;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.5px">Delivery confirmed</p>
      <p style="margin:0 0 8px;color:#1A1A1A;font-size:15px;line-height:1.6"><strong>${esc(p.carrier)}</strong><br><span style="color:#666;font-family:ui-monospace,monospace">${esc(p.tracking)}</span></p>
      <a href="${esc(p.trackUrl)}" style="display:inline-block;padding:12px 28px;background:#3EB489;color:#FFF;text-decoration:none;border-radius:6px;font-size:14px;font-weight:600">View delivery details</a>
    </td></tr>
  </table>
  <table role="presentation" style="width:100%;border-collapse:collapse;background:#FCFCFB;border:1px solid #E5E5E5;border-radius:8px;margin-bottom:28px"><tr>
    <td style="padding:20px;width:90px;vertical-align:top"><img src="${PRODUCT_IMG}" alt="MintCheck Scanner" style="width:80px;height:auto;border-radius:4px"></td>
    <td style="padding:20px 20px 20px 0;vertical-align:top">
      <p style="margin:0 0 4px;color:#1A1A1A;font-size:16px;font-weight:600">MintCheck Starter Kit (MC-01)</p>
      <p style="margin:0;color:#666;font-size:14px;line-height:1.6">Wi-Fi OBD-II Scanner + 60-Day Buyer Pass</p>
    </td>
  </tr></table>
  <h3 style="margin:0 0 12px;color:#1A1A1A;font-size:18px;font-weight:600">Quick Start</h3>
  <p style="margin:0 0 16px;color:#666;font-size:14px;line-height:1.7">Open the <a href="${APP_STORE_LINK}" style="color:#3EB489;text-decoration:none">MintCheck app</a>, plug your scanner into the car\u2019s OBD-II port, connect to the scanner\u2019s Wi-Fi, and tap <strong>Scan</strong>. Results in about 30 seconds.</p>
  <p style="margin:0 0 16px;color:#666;font-size:14px;line-height:1.7">Need help finding the OBD-II port? <a href="${HELP_LINK}/obd-port" style="color:#3EB489;text-decoration:none">See our guide</a>.</p>
</td></tr>
<tr><td style="background:#F8F8F7;padding:32px;text-align:center;border-radius:0 0 4px 4px;border-top:1px solid #E5E5E5">
  <p style="margin:0 0 8px;color:#999;font-size:13px;line-height:1.6">Questions? Reply to this email or reach us at <a href="mailto:${SUPPORT_EMAIL}" style="color:#3EB489;text-decoration:none">${SUPPORT_EMAIL}</a></p>
  <p style="margin:0 0 16px;color:#999;font-size:13px;line-height:1.6">&copy; 2026 ${APP_NAME}. All rights reserved.</p>
  <p style="margin:0;color:#999;font-size:13px;line-height:1.6"><a href="${HELP_LINK}" style="color:#3EB489;text-decoration:none">Support</a> &bull; <a href="${PRIVACY_LINK}" style="color:#3EB489;text-decoration:none">Privacy</a> &bull; <a href="${TERMS_LINK}" style="color:#3EB489;text-decoration:none">Terms</a></p>
</td></tr>
</table></td></tr></table></body></html>`;
}

// ─── Main ────────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const expectedSecret = Deno.env.get("DEEP_CHECK_INVOKE_SECRET");
  const providedSecret = req.headers.get("X-Internal-Secret");
  if (!expectedSecret || providedSecret !== expectedSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const uspsClientId = Deno.env.get("USPS_CLIENT_ID");
  const uspsClientSecret = Deno.env.get("USPS_CLIENT_SECRET");
  if (!uspsClientId || !uspsClientSecret) {
    console.error("check-shipping-status: USPS_CLIENT_ID / USPS_CLIENT_SECRET not set");
    return new Response(
      JSON.stringify({ error: "USPS credentials not configured" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  const resendKey = Deno.env.get("RESEND_API_KEY");
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const { data: orders, error: fetchErr } = await supabase
    .from("starter_kit_orders")
    .select(
      "id, tracking_number, tracking_carrier, shipping_status, customer_email, customer_name, order_number, delivery_email_sent_at"
    )
    .not("tracking_number", "is", null)
    .or("shipping_status.is.null,shipping_status.neq.delivered");

  if (fetchErr) {
    console.error("check-shipping-status: fetch error", fetchErr);
    return new Response(
      JSON.stringify({ error: fetchErr.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  if (!orders || orders.length === 0) {
    return new Response(
      JSON.stringify({ checked: 0, updated: 0, delivered: 0 }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  }

  let uspsToken: string;
  try {
    uspsToken = await getUspsToken(uspsClientId, uspsClientSecret);
  } catch (e) {
    console.error("check-shipping-status: USPS auth failed", e);
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : "USPS auth failed" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  let updated = 0;
  let delivered = 0;
  const errors: string[] = [];

  for (const order of orders) {
    const trackingNumber = String(order.tracking_number).trim();
    if (!trackingNumber) continue;

    try {
      const res = await fetch(
        `${USPS_TRACKING_URL}/${encodeURIComponent(trackingNumber)}?expand=DETAIL`,
        {
          headers: { Authorization: `Bearer ${uspsToken}` },
        }
      );

      if (!res.ok) {
        const txt = await res.text();
        console.error(
          `USPS tracking error for ${trackingNumber}: ${res.status} ${txt}`
        );
        errors.push(`${trackingNumber}: USPS ${res.status}`);
        continue;
      }

      const data = await res.json();
      const statusCategory: string | undefined =
        data?.statusCategory ?? data?.trackingEvents?.[0]?.eventType ?? undefined;
      const mapped = mapUspsCategory(statusCategory);
      if (!mapped) continue;

      if (mapped === order.shipping_status) continue;

      const nowIso = new Date().toISOString();
      const updates: Record<string, unknown> = {
        shipping_status: mapped,
        updated_at: nowIso,
      };

      const { error: updErr } = await supabase
        .from("starter_kit_orders")
        .update(updates)
        .eq("id", order.id);

      if (updErr) {
        console.error(`update error for order ${order.id}:`, updErr);
        errors.push(`${order.id}: DB update failed`);
        continue;
      }

      updated++;
      console.log(
        `check-shipping-status: ${order.id} ${trackingNumber} → ${mapped}`
      );

      if (
        mapped === "delivered" &&
        !order.delivery_email_sent_at &&
        order.customer_email &&
        resendKey
      ) {
        const carrier = String(order.tracking_carrier ?? "USPS").trim();
        const tUrl = trackingUrl(carrier, trackingNumber);
        const orderNumber =
          typeof order.order_number === "string"
            ? order.order_number
            : null;
        const html = deliveryEmailHtml({
          name: String(order.customer_name ?? "").trim() || "Customer",
          carrier,
          tracking: trackingNumber,
          trackUrl: tUrl,
          orderNumber,
        });

        const subject = orderNumber
          ? `MintCheck Order #${orderNumber} Has Been Delivered`
          : "Your MintCheck Starter Kit has been delivered!";

        try {
          const emailRes = await fetch("https://api.resend.com/emails", {
            method: "POST",
            headers: {
              Authorization: `Bearer ${resendKey}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              from: "MintCheck Orders <orders@mintcheckapp.com>",
              to: [order.customer_email],
              bcc: ["contact@mintcheckapp.com"],
              reply_to: SUPPORT_EMAIL,
              subject,
              html,
            }),
          });

          if (emailRes.ok) {
            await supabase
              .from("starter_kit_orders")
              .update({
                delivery_email_sent_at: nowIso,
                updated_at: nowIso,
              })
              .eq("id", order.id);
            console.log(
              `delivery email sent to ${order.customer_email} order=${order.id}`
            );
            delivered++;
          } else {
            const t = await emailRes.text();
            console.error(
              `delivery email Resend error for ${order.id}: ${emailRes.status} ${t}`
            );
          }
        } catch (e) {
          console.error(`delivery email send error for ${order.id}:`, e);
        }
      }
    } catch (e) {
      console.error(`check-shipping-status error for ${order.id}:`, e);
      errors.push(
        `${order.id}: ${e instanceof Error ? e.message : String(e)}`
      );
    }
  }

  const result = {
    checked: orders.length,
    updated,
    delivered,
    ...(errors.length > 0 ? { errors } : {}),
  };
  console.log("check-shipping-status result:", JSON.stringify(result));

  return new Response(JSON.stringify(result), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
