/**
 * Send Starter Kit shipping + tracking email (Resend). Invoked internally when admin saves carrier + tracking.
 * Auth: X-Internal-Secret (DEEP_CHECK_INVOKE_SECRET). Loads Stripe Checkout Session for address replay.
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

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

interface StripeAddress {
  line1?: string | null;
  line2?: string | null;
  city?: string | null;
  state?: string | null;
  postal_code?: string | null;
  country?: string | null;
}

function esc(s: string | null | undefined): string {
  if (!s) return "";
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function formatAddress(addr: StripeAddress | null | undefined): string {
  if (!addr) return "N/A";
  const parts: string[] = [];
  if (addr.line1) parts.push(esc(addr.line1));
  if (addr.line2) parts.push(esc(addr.line2));
  const cityState = [addr.city, addr.state].filter(Boolean).join(", ");
  if (cityState) parts.push(esc(cityState));
  if (addr.postal_code) parts.push(esc(addr.postal_code));
  if (addr.country && addr.country !== "US") parts.push(esc(addr.country));
  return parts.join("<br>") || "N/A";
}

function formatOrderDate(iso: string | null | undefined): string {
  if (!iso) return "N/A";
  try {
    const d = new Date(iso);
    return d.toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  } catch {
    return "N/A";
  }
}

function buildTrackingUrl(carrier: string, trackingNumber: string): string {
  const c = carrier.toLowerCase();
  const raw = trackingNumber.trim();
  const n = encodeURIComponent(raw);
  if (c.includes("usps")) {
    return `https://tools.usps.com/go/TrackConfirmAction?tLabels=${n}`;
  }
  if (c.includes("ups")) {
    return `https://www.ups.com/track?tracknum=${n}`;
  }
  if (c.includes("fedex")) {
    return `https://www.fedex.com/fedextrack/?trknbr=${n}`;
  }
  if (c.includes("dhl")) {
    return `https://www.dhl.com/en/express/tracking.html?AWB=${n}`;
  }
  return `https://www.google.com/search?q=${encodeURIComponent(`${carrier} ${raw} tracking`)}`;
}

function quickStartRows(): string {
  return `<table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td style="padding: 10px 12px 10px 0; vertical-align: top; width: 32px;">
        <div style="width: 28px; height: 28px; border-radius: 50%; background-color: #3EB489; color: #FFFFFF; font-size: 14px; font-weight: 600; text-align: center; line-height: 28px;">1</div>
      </td>
      <td style="padding: 10px 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">
        <strong>Download the app</strong><br>
        <span style="color: #666666;">Get MintCheck from the <a href="${APP_STORE_LINK}" style="color: #3EB489; text-decoration: none;">App Store</a> (iPhone only for now).</span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px 12px 10px 0; vertical-align: top;">
        <div style="width: 28px; height: 28px; border-radius: 50%; background-color: #3EB489; color: #FFFFFF; font-size: 14px; font-weight: 600; text-align: center; line-height: 28px;">2</div>
      </td>
      <td style="padding: 10px 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">
        <strong>Sign in with your account</strong><br>
        <span style="color: #666666;">Use the same email you used at checkout so your scans and Buyer Pass stay linked.</span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px 12px 10px 0; vertical-align: top;">
        <div style="width: 28px; height: 28px; border-radius: 50%; background-color: #3EB489; color: #FFFFFF; font-size: 14px; font-weight: 600; text-align: center; line-height: 28px;">3</div>
      </td>
      <td style="padding: 10px 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">
        <strong>Turn on the car</strong><br>
        <span style="color: #666666;">Start the engine or turn the ignition to the ON position.</span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px 12px 10px 0; vertical-align: top;">
        <div style="width: 28px; height: 28px; border-radius: 50%; background-color: #3EB489; color: #FFFFFF; font-size: 14px; font-weight: 600; text-align: center; line-height: 28px;">4</div>
      </td>
      <td style="padding: 10px 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">
        <strong>Insert your MintCheck scanner</strong><br>
        <span style="color: #666666;">Plug it into the OBD-II port (usually under the dash, near the steering column). <a href="${OBD_PORT_LINK}" style="color: #3EB489; text-decoration: none;">Help me find it</a></span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px 12px 10px 0; vertical-align: top;">
        <div style="width: 28px; height: 28px; border-radius: 50%; background-color: #3EB489; color: #FFFFFF; font-size: 14px; font-weight: 600; text-align: center; line-height: 28px;">5</div>
      </td>
      <td style="padding: 10px 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">
        <strong>Follow the steps in the app</strong><br>
        <span style="color: #666666;">Connect to the scanner\u2019s Wi-Fi and tap Scan. You\u2019ll have results in about 30 seconds.</span>
      </td>
    </tr>
  </table>`;
}

function deepCheckBlock(): string {
  return `<table role="presentation" style="width: 100%; border-collapse: collapse; background-color: #F4FBF8; border: 1px solid #D4EDDF; border-radius: 8px; margin-top: 32px;">
    <tr>
      <td style="padding: 24px;">
        <p style="margin: 0 0 6px 0; color: #1A1A1A; font-size: 16px; font-weight: 600;">Shopping for a used car?</p>
        <p style="margin: 0 0 16px 0; color: #666666; font-size: 14px; line-height: 1.6;">
          Get a <strong>Deep Check Report</strong> on any vehicle before you buy. Enter a VIN in the MintCheck app to see accident history, title status, recall notices, and more \u2013 all in one report.
        </p>
        <a href="https://mintcheckapp.com" style="display: inline-block; padding: 12px 28px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 6px; font-size: 14px; font-weight: 600;">Learn More in the App</a>
      </td>
    </tr>
  </table>`;
}

function buildShippingEmailHtml(params: {
  customerName: string;
  customerEmail: string;
  phone: string;
  billingHtml: string;
  shippingName: string;
  shippingHtml: string;
  orderDateStr: string;
  carrier: string;
  trackingNumber: string;
  trackUrl: string;
  passActive: boolean;
}): string {
  const name = esc(params.customerName) || "Customer";
  const email = esc(params.customerEmail) || "";
  const phone = esc(params.phone) || "";
  const tdLabel =
    'style="padding: 6px 0; color: #999999; font-size: 14px; vertical-align: top; width: 110px;"';
  const tdValue =
    'style="padding: 6px 0; color: #1A1A1A; font-size: 14px; vertical-align: top;"';

  const passSection = params.passActive
    ? `<p style="margin: 0 0 12px 0; color: #666666; font-size: 14px; line-height: 1.7;">
        Your <strong>60-day Buyer Pass</strong> is active: scan up to <strong>10 vehicles per day</strong> with full MintCheck reports. When the kit arrives, follow the steps below to connect your scanner and run your first scan.
      </p>`
    : `<p style="margin: 0 0 12px 0; color: #666666; font-size: 14px; line-height: 1.7;">
        Your kit includes a <strong>60-day Buyer Pass</strong> (up to 10 full scans per day). If you don\u2019t see it in the app yet, it may activate shortly\u2014check MintCheck or reply to this email if you need help. Once it\u2019s active, use the Quick Start below after you plug in the scanner.
      </p>`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your MintCheck order has shipped</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">

          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">${APP_NAME}</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Your kit is on the way</h2>
            </td>
          </tr>

          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 32px 32px;">
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Hi ${name}\u2014great news: your <strong>MintCheck Starter Kit</strong> has shipped. Use the button below to track your package. Your order summary and shipping address are below for your records.
              </p>

              <table role="presentation" style="width: 100%; border-collapse: collapse; background-color: #F4FBF8; border: 1px solid #D4EDDF; border-radius: 8px; margin-bottom: 28px;">
                <tr>
                  <td style="padding: 24px;">
                    <p style="margin: 0 0 6px 0; color: #999999; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">Shipment</p>
                    <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 15px; line-height: 1.6;">
                      <strong>${esc(params.carrier)}</strong><br>
                      <span style="color: #666666; font-family: ui-monospace, monospace;">${esc(params.trackingNumber)}</span>
                    </p>
                    <a href="${esc(params.trackUrl)}" style="display: inline-block; padding: 12px 28px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 6px; font-size: 14px; font-weight: 600;">Track your package</a>
                  </td>
                </tr>
              </table>

              <table role="presentation" style="width: 100%; border-collapse: collapse; margin-bottom: 24px;">
                <tr><td ${tdLabel}>Name</td><td ${tdValue}>${name}</td></tr>
                ${email ? `<tr><td ${tdLabel}>Email</td><td ${tdValue}>${email}</td></tr>` : ""}
                ${phone ? `<tr><td ${tdLabel}>Phone</td><td ${tdValue}>${phone}</td></tr>` : ""}
                <tr><td ${tdLabel}>Order date</td><td ${tdValue}>${params.orderDateStr}</td></tr>
              </table>

              <table role="presentation" style="width: 100%; border-collapse: collapse; margin-bottom: 28px;">
                <tr>
                  <td style="width: 50%; vertical-align: top; padding-right: 12px;">
                    <p style="margin: 0 0 6px 0; color: #999999; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">Shipping address</p>
                    <p style="margin: 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">${esc(params.shippingName)}<br>${params.shippingHtml}</p>
                  </td>
                  <td style="width: 50%; vertical-align: top; padding-left: 12px;">
                    <p style="margin: 0 0 6px 0; color: #999999; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">Billing address</p>
                    <p style="margin: 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">${params.billingHtml}</p>
                  </td>
                </tr>
              </table>

              <table role="presentation" style="width: 100%; border-collapse: collapse; background-color: #FCFCFB; border: 1px solid #E5E5E5; border-radius: 8px; margin-bottom: 28px;">
                <tr>
                  <td style="padding: 20px; width: 90px; vertical-align: top;">
                    <img src="${PRODUCT_IMG}" alt="MintCheck Scanner" style="width: 80px; height: auto; border-radius: 4px;">
                  </td>
                  <td style="padding: 20px 20px 20px 0; vertical-align: top;">
                    <p style="margin: 0 0 4px 0; color: #1A1A1A; font-size: 16px; font-weight: 600;">MintCheck Starter Kit (MC-01)</p>
                    <p style="margin: 0; color: #666666; font-size: 14px; line-height: 1.6;">
                      Includes:<br>
                      &bull; Wi-Fi OBD-II Scanner<br>
                      &bull; 60-Day Buyer Pass (scan up to 10 vehicles per day)
                    </p>
                  </td>
                </tr>
              </table>

              <h3 style="margin: 0 0 12px 0; color: #1A1A1A; font-size: 18px; font-weight: 600;">Your Buyer Pass &amp; Quick Start</h3>
              ${passSection}
              ${quickStartRows()}

              ${deepCheckBlock()}
            </td>
          </tr>

          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                Questions? Reply to this email or reach us at <a href="mailto:${SUPPORT_EMAIL}" style="color: #3EB489; text-decoration: none;">${SUPPORT_EMAIL}</a>
              </p>
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">&copy; 2026 ${APP_NAME}. All rights reserved.</p>
              <p style="margin: 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="${HELP_LINK}" style="color: #3EB489; text-decoration: none;">Support</a> &bull;
                <a href="${PRIVACY_LINK}" style="color: #3EB489; text-decoration: none;">Privacy</a> &bull;
                <a href="${TERMS_LINK}" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const invokeSecret = Deno.env.get("DEEP_CHECK_INVOKE_SECRET");
  const incomingSecret = req.headers.get("X-Internal-Secret");
  if (!invokeSecret || incomingSecret !== invokeSecret) {
    return new Response("Unauthorized", { status: 401 });
  }

  let body: { order_id?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const orderId = typeof body.order_id === "string" ? body.order_id.trim() : "";
  if (!orderId) {
    return new Response(JSON.stringify({ error: "order_id required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: order, error: orderErr } = await supabase
    .from("starter_kit_orders")
    .select("*")
    .eq("id", orderId)
    .single();

  if (orderErr || !order) {
    return new Response(JSON.stringify({ error: "Order not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (order.shipping_confirmation_sent_at) {
    return new Response(JSON.stringify({ ok: true, message: "Already sent" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const carrier = String(order.tracking_carrier ?? "").trim();
  const trackingNumber = String(order.tracking_number ?? "").trim();
  const toEmail = order.customer_email as string | null;

  if (!carrier || !trackingNumber) {
    return new Response(JSON.stringify({ error: "Carrier and tracking number required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
  if (!toEmail) {
    return new Response(JSON.stringify({ error: "Order has no customer email" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
  let shippingNameRaw = String(order.customer_name ?? "").trim() || "Customer";
  let shippingHtml =
    "<span style=\"color:#666666;\">Same as on your order confirmation.</span>";
  let billingHtml =
    "<span style=\"color:#666666;\">Same as on your order confirmation.</span>";
  let phoneRaw = "";
  const sessionId = order.stripe_session_id as string;

  if (stripeSecretKey && sessionId) {
    try {
      const stripe = new Stripe(stripeSecretKey, {
        apiVersion: "2023-10-16",
        httpClient: Stripe.createFetchHttpClient(),
      });
      const session = await stripe.checkout.sessions.retrieve(sessionId);
      const details = session.customer_details;
      const ship = session.shipping_details;
      if (ship?.name || ship?.address) {
        if (ship?.name) shippingNameRaw = String(ship.name).trim();
        shippingHtml = formatAddress(ship?.address as StripeAddress | null);
      } else if (details?.name || details?.address) {
        if (details?.name) shippingNameRaw = String(details.name).trim();
        shippingHtml = formatAddress(details?.address as StripeAddress | null);
      }
      billingHtml = formatAddress(details?.address as StripeAddress | null);
      phoneRaw = details?.phone ? String(details.phone).trim() : "";
    } catch (e) {
      console.error("send-starter-kit-shipping: Stripe retrieve failed", e);
    }
  }

  const passActive =
    order.status === "pass_activated" ||
    Boolean(order.pass_activated_at) ||
    Boolean(order.buyer_pass_subscription_id);

  const trackUrl = buildTrackingUrl(carrier, trackingNumber);
  const html = buildShippingEmailHtml({
    customerName: String(order.customer_name ?? "").trim() || "Customer",
    customerEmail: toEmail,
    phone: phoneRaw,
    billingHtml,
    shippingName: shippingNameRaw,
    shippingHtml,
    orderDateStr: formatOrderDate(order.created_at as string),
    carrier,
    trackingNumber,
    trackUrl,
    passActive,
  });

  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const resendFrom =
    Deno.env.get("RESEND_FROM_EMAIL") || "MintCheck <noreply@mintcheckapp.com>";

  if (!resendApiKey) {
    console.error("send-starter-kit-shipping: RESEND_API_KEY not set");
    return new Response(JSON.stringify({ error: "Email not configured" }), {
      status: 503,
      headers: { "Content-Type": "application/json" },
    });
  }

  const emailRes = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: resendFrom,
      to: [toEmail],
      bcc: ["contact@mintcheckapp.com"],
      reply_to: SUPPORT_EMAIL,
      subject: "Your MintCheck Starter Kit has shipped",
      html,
    }),
  });

  if (!emailRes.ok) {
    const errText = await emailRes.text();
    console.error("send-starter-kit-shipping: Resend error", emailRes.status, errText);
    return new Response(JSON.stringify({ error: "Failed to send email", detail: errText }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  const nowIso = new Date().toISOString();
  await supabase
    .from("starter_kit_orders")
    .update({ shipping_confirmation_sent_at: nowIso, updated_at: nowIso })
    .eq("id", orderId);

  console.log(`send-starter-kit-shipping: sent to ${toEmail} order=${orderId}`);
  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
