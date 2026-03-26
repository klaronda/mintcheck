import { serve } from "https://deno.land/std@0.194.0/http/server.ts";

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

interface RequestBody {
  name?: string | null;
  email?: string | null;
  phone?: string | null;
  billing_address?: StripeAddress | null;
  shipping?: { name?: string | null; address?: StripeAddress | null } | null;
  created?: number | null;
  order_number?: string | null;
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

function formatDate(ts: number | null | undefined): string {
  if (!ts) return "N/A";
  const d = new Date(ts * 1000);
  return d.toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
    timeZoneName: "short",
  });
}

function buildEmailHtml(data: RequestBody): string {
  const name = esc(data.name) || "Customer";
  const email = esc(data.email) || "";
  const phone = esc(data.phone) || "";
  const billingHtml = formatAddress(data.billing_address);
  const shippingName = esc(data.shipping?.name) || name;
  const shippingHtml = formatAddress(data.shipping?.address);
  const dateStr = formatDate(data.created);

  const tdLabel =
    'style="padding: 6px 0; color: #999999; font-size: 14px; vertical-align: top; width: 110px;"';
  const tdValue =
    'style="padding: 6px 0; color: #1A1A1A; font-size: 14px; vertical-align: top;"';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Order Confirmed – ${APP_NAME}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">

          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">${APP_NAME}</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Order Confirmed</h2>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 32px 32px;">
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Your MintCheck Starter Kit order has been placed. Here\u2019s a summary of your purchase.
              </p>

              <!-- Order details -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin-bottom: 24px;">
                <tr><td ${tdLabel}>Name</td><td ${tdValue}>${name}</td></tr>
                ${email ? `<tr><td ${tdLabel}>Email</td><td ${tdValue}>${email}</td></tr>` : ""}
                ${phone ? `<tr><td ${tdLabel}>Phone</td><td ${tdValue}>${phone}</td></tr>` : ""}
                <tr><td ${tdLabel}>Date</td><td ${tdValue}>${dateStr}</td></tr>
              </table>

              <!-- Addresses side by side -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin-bottom: 28px;">
                <tr>
                  <td style="width: 50%; vertical-align: top; padding-right: 12px;">
                    <p style="margin: 0 0 6px 0; color: #999999; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">Shipping To</p>
                    <p style="margin: 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">${shippingName}<br>${shippingHtml}</p>
                  </td>
                  <td style="width: 50%; vertical-align: top; padding-left: 12px;">
                    <p style="margin: 0 0 6px 0; color: #999999; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">Billing Address</p>
                    <p style="margin: 0; color: #1A1A1A; font-size: 14px; line-height: 1.6;">${billingHtml}</p>
                  </td>
                </tr>
              </table>

              <!-- Product -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; background-color: #FCFCFB; border: 1px solid #E5E5E5; border-radius: 8px; margin-bottom: 24px;">
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

              <!-- 60-day pass callout -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; border: 2px solid #3EB489; border-radius: 8px; margin-bottom: 32px;">
                <tr>
                  <td style="padding: 20px;">
                    <p style="margin: 0 0 4px 0; color: #3EB489; font-size: 15px; font-weight: 600;">60-Day Pass</p>
                    <p style="margin: 0; color: #666666; font-size: 14px; line-height: 1.6;">
                      Your 60-day Buyer Pass (up to 10 full scans per day) will be activated when your device ships. We\u2019ll send you a shipping confirmation with tracking details.
                    </p>
                  </td>
                </tr>
              </table>

              <!-- Quick Start Guide -->
              <h3 style="margin: 0 0 16px 0; color: #1A1A1A; font-size: 18px; font-weight: 600;">Quick Start Guide</h3>
              <table role="presentation" style="width: 100%; border-collapse: collapse;">
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
                    <strong>Create your account</strong><br>
                    <span style="color: #666666;">Sign up with your email to get started.</span>
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
              </table>

              <!-- Deep Check awareness -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; background-color: #F4FBF8; border: 1px solid #D4EDDF; border-radius: 8px; margin-top: 32px;">
                <tr>
                  <td style="padding: 24px;">
                    <p style="margin: 0 0 6px 0; color: #1A1A1A; font-size: 16px; font-weight: 600;">Shopping for a used car?</p>
                    <p style="margin: 0 0 16px 0; color: #666666; font-size: 14px; line-height: 1.6;">
                      Get a <strong>Deep Check Report</strong> on any vehicle before you buy. Enter a VIN in the MintCheck app to see accident history, title status, recall notices, and more \u2013 all in one report.
                    </p>
                    <a href="https://mintcheckapp.com" style="display: inline-block; padding: 12px 28px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 6px; font-size: 14px; font-weight: 600;">Learn More in the App</a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
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

  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const resendFrom = "MintCheck Orders <orders@mintcheckapp.com>";

  if (!resendApiKey) {
    console.error("send-starter-kit-confirmation: RESEND_API_KEY not set");
    return new Response("Email not configured", { status: 503 });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const toEmail = body.email;
  if (!toEmail) {
    console.error("send-starter-kit-confirmation: no email in payload");
    return new Response("Missing email", { status: 400 });
  }

  const html = buildEmailHtml(body);

  const orderNum = body.order_number;
  const subject = orderNum
    ? `MintCheck Order #${orderNum} Confirmed`
    : "Your MintCheck Starter Kit order is confirmed";

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
      subject,
      html,
    }),
  });

  if (!emailRes.ok) {
    const errText = await emailRes.text();
    console.error("send-starter-kit-confirmation: Resend error", emailRes.status, errText);
    return new Response("Failed to send email", { status: 502 });
  }

  console.log(`send-starter-kit-confirmation: sent to ${toEmail}`);
  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
