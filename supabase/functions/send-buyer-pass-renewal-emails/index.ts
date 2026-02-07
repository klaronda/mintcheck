/**
 * send-buyer-pass-renewal-emails
 *
 * Called daily by pg_cron via pg_net. Queries for Buyer Pass subscriptions that
 * are expiring within 7 days or already expired, sends the appropriate email
 * via Resend, and stamps the sent_at column to prevent duplicates.
 *
 * Auth: X-Internal-Secret header (same pattern as generate-deep-check-report).
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // --- Auth: internal secret ---
  const expectedSecret = Deno.env.get("BUYER_PASS_RENEWAL_SECRET");
  const providedSecret = req.headers.get("X-Internal-Secret");
  if (!expectedSecret || providedSecret !== expectedSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const resendFrom =
    Deno.env.get("RESEND_FROM_EMAIL") || "MintCheck <noreply@mintcheckapp.com>";
  const extendLink =
    Deno.env.get("BUYER_PASS_EXTEND_LINK") ||
    "https://buy.stripe.com/test_9B6cN5bDycqZbKdcFJdby01";

  if (!resendApiKey) {
    console.error("send-buyer-pass-renewal-emails: RESEND_API_KEY not set");
    return new Response(JSON.stringify({ error: "Email not configured" }), {
      status: 500,
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const now = new Date();
  const sevenDaysFromNow = new Date(
    now.getTime() + 7 * 24 * 60 * 60 * 1000
  ).toISOString();
  const nowISO = now.toISOString();

  let totalExpiringSent = 0;
  let totalExpiredSent = 0;

  // ─── 1. Expiring (7-day reminder) ────────────────────────────────
  // Active passes whose ended_at is between now and now+7 days,
  // and we haven't sent the reminder yet.
  const { data: expiring, error: expiringErr } = await supabase
    .from("subscriptions")
    .select("id, user_id, ended_at")
    .eq("plan", "buyer_pass")
    .eq("status", "active")
    .is("expiring_email_sent_at", null)
    .gte("ended_at", nowISO)
    .lte("ended_at", sevenDaysFromNow);

  if (expiringErr) {
    console.error("expiring query error:", expiringErr);
  }

  if (expiring && expiring.length > 0) {
    for (const sub of expiring) {
      // Before sending, check if the user has a *newer* active pass that extends beyond this one.
      // If so, skip — they renewed early.
      const { data: newerPass } = await supabase
        .from("subscriptions")
        .select("id")
        .eq("user_id", sub.user_id)
        .eq("plan", "buyer_pass")
        .eq("status", "active")
        .gt("ended_at", sub.ended_at)
        .neq("id", sub.id)
        .limit(1);

      if (newerPass && newerPass.length > 0) {
        // They renewed — skip sending and just stamp it
        await supabase
          .from("subscriptions")
          .update({ expiring_email_sent_at: nowISO })
          .eq("id", sub.id);
        continue;
      }

      const email = await getUserEmail(supabase, sub.user_id);
      if (!email) continue;

      const sent = await sendEmail(
        resendApiKey,
        resendFrom,
        email,
        "Your Buyer Pass expires in 7 days",
        getExpiringHtml(extendLink)
      );

      if (sent) {
        await supabase
          .from("subscriptions")
          .update({ expiring_email_sent_at: nowISO })
          .eq("id", sub.id);
        totalExpiringSent++;
      }
    }
  }

  // ─── 2. Expired ──────────────────────────────────────────────────
  // Active passes whose ended_at < now and we haven't sent the expired email.
  const { data: expired, error: expiredErr } = await supabase
    .from("subscriptions")
    .select("id, user_id, ended_at")
    .eq("plan", "buyer_pass")
    .eq("status", "active")
    .is("expired_email_sent_at", null)
    .lt("ended_at", nowISO);

  if (expiredErr) {
    console.error("expired query error:", expiredErr);
  }

  if (expired && expired.length > 0) {
    for (const sub of expired) {
      // Check if user has a newer active pass (they renewed before this ran)
      const { data: newerPass } = await supabase
        .from("subscriptions")
        .select("id")
        .eq("user_id", sub.user_id)
        .eq("plan", "buyer_pass")
        .eq("status", "active")
        .gt("ended_at", nowISO)
        .neq("id", sub.id)
        .limit(1);

      if (newerPass && newerPass.length > 0) {
        // They renewed — mark this row expired, stamp email, skip sending
        await supabase
          .from("subscriptions")
          .update({ status: "expired", expired_email_sent_at: nowISO })
          .eq("id", sub.id);
        continue;
      }

      const email = await getUserEmail(supabase, sub.user_id);
      if (!email) continue;

      const sent = await sendEmail(
        resendApiKey,
        resendFrom,
        email,
        "Your Buyer Pass has expired",
        getExpiredHtml(extendLink)
      );

      if (sent) {
        await supabase
          .from("subscriptions")
          .update({ status: "expired", expired_email_sent_at: nowISO })
          .eq("id", sub.id);
        totalExpiredSent++;
      }
    }
  }

  console.log(
    `send-buyer-pass-renewal-emails: expiring=${totalExpiringSent}, expired=${totalExpiredSent}`
  );

  return new Response(
    JSON.stringify({
      expiring_sent: totalExpiringSent,
      expired_sent: totalExpiredSent,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});

// ─── Helpers ──────────────────────────────────────────────────────

async function getUserEmail(
  supabase: ReturnType<typeof createClient>,
  userId: string
): Promise<string | null> {
  try {
    const {
      data: { user },
    } = await supabase.auth.admin.getUserById(userId);
    return user?.email ?? null;
  } catch (e) {
    console.error(`getUserEmail(${userId}) error:`, e);
    return null;
  }
}

async function sendEmail(
  apiKey: string,
  from: string,
  to: string,
  subject: string,
  html: string
): Promise<boolean> {
  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ from, to: [to], subject, html }),
    });
    if (!res.ok) {
      const errText = await res.text();
      console.error(`Resend error (${to}): ${res.status} ${errText}`);
      return false;
    }
    return true;
  } catch (e) {
    console.error(`sendEmail(${to}) error:`, e);
    return false;
  }
}

// ─── Email Templates ──────────────────────────────────────────────

function getExpiringHtml(extendLink: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Buyer Pass expires in 7 days</title>
  <!--[if !mso]><!--><meta http-equiv="X-UA-Compatible" content="IE=edge"><!--<![endif]-->
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <!-- Preheader -->
  <div style="display: none; max-height: 0; overflow: hidden; font-size: 1px; line-height: 1px; color: #F8F8F7;">
    Keep scanning &mdash; extend for another 60 days.
  </div>

  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">

          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Your Buyer Pass is almost up</h2>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Still shopping for a car? Your Buyer Pass expires in <strong style="color: #1A1A1A;">7 days</strong>. Extend now so you don't lose access while you're still looking.
              </p>

              <p style="margin: 0 0 16px 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">
                What you get with Buyer Pass:
              </p>

              <ul style="margin: 0 0 24px 0; padding-left: 20px; color: #666666; font-size: 15px; line-height: 1.7;">
                <li style="margin-bottom: 10px;">Scan unlimited vehicles</li>
                <li style="margin-bottom: 10px;">Up to 10 scans per day</li>
                <li style="margin-bottom: 10px;">Engine, battery, and fuel system health on every car</li>
                <li style="margin-bottom: 10px;">Buy with confidence &mdash; know what you're getting</li>
              </ul>

              <!-- CTA -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0 24px 0;">
                <tr>
                  <td align="center">
                    <a href="${extendLink}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">Extend for Another 60 Days</a>
                  </td>
                </tr>
              </table>

              <p style="margin: 0 0 12px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Just $14.99 for another 60 days of unlimited scanning.
              </p>

              <p style="margin: 0; color: #666666; font-size: 15px; line-height: 1.7;">
                The MintCheck Team
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                &copy; 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="https://mintcheckapp.com/support" style="color: #3EB489; text-decoration: none;">Help Center</a> &bull;
                <a href="https://mintcheckapp.com/privacy" style="color: #3EB489; text-decoration: none;">Privacy</a> &bull;
                <a href="https://mintcheckapp.com/terms" style="color: #3EB489; text-decoration: none;">Terms</a>
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

function getExpiredHtml(extendLink: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Buyer Pass has expired</title>
  <!--[if !mso]><!--><meta http-equiv="X-UA-Compatible" content="IE=edge"><!--<![endif]-->
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <!-- Preheader -->
  <div style="display: none; max-height: 0; overflow: hidden; font-size: 1px; line-height: 1px; color: #F8F8F7;">
    Pick up where you left off &mdash; $14.99 for 60 more days.
  </div>

  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">

          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #C94A4A; font-size: 24px; font-weight: 600;">Your Buyer Pass has expired</h2>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Your 60-day Buyer Pass has ended. Pick up right where you left off with another Buyer Pass:
              </p>

              <ul style="margin: 0 0 24px 0; padding-left: 20px; color: #666666; font-size: 15px; line-height: 1.7;">
                <li style="margin-bottom: 10px;">Scan unlimited vehicles</li>
                <li style="margin-bottom: 10px;">Up to 10 scans per day</li>
                <li style="margin-bottom: 10px;">Engine, battery, and fuel system health on every car</li>
                <li style="margin-bottom: 10px;">Buy with confidence &mdash; know what you're getting</li>
              </ul>

              <!-- CTA -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0 24px 0;">
                <tr>
                  <td align="center">
                    <a href="${extendLink}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">Get Another 60 Days</a>
                  </td>
                </tr>
              </table>

              <p style="margin: 0 0 12px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Just $14.99 &mdash; no subscription, no commitment.
              </p>

              <p style="margin: 0; color: #666666; font-size: 15px; line-height: 1.7;">
                The MintCheck Team
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                &copy; 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="https://mintcheckapp.com/support" style="color: #3EB489; text-decoration: none;">Help Center</a> &bull;
                <a href="https://mintcheckapp.com/privacy" style="color: #3EB489; text-decoration: none;">Privacy</a> &bull;
                <a href="https://mintcheckapp.com/terms" style="color: #3EB489; text-decoration: none;">Terms</a>
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
