import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DEEP_LINK_BASE = "https://mintcheckapp.com";
const APP_NAME = "MintCheck";
const HELP_LINK = "https://mintcheckapp.com/help";
const PRIVACY_LINK = "https://mintcheckapp.com/privacy";
const TERMS_LINK = "https://mintcheckapp.com/terms";

// Email confirmation template (aligned with guidelines); variables: actionUrl, userEmail.
function getEmailConfirmationHtml(actionUrl: string, userEmail: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Confirm your MintCheck email</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Confirm your MintCheck email</h2>
            </td>
          </tr>
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">Hi,</p>
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Please confirm your email address for your ${APP_NAME} account (${userEmail}) by clicking the button below. Open the link on your iPhone in the MintCheck app to activate your account.
              </p>
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0;">
                <tr>
                  <td align="center">
                    <a href="${actionUrl}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">Confirm Email</a>
                  </td>
                </tr>
              </table>
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 24px 0;">
                <tr>
                  <td style="background-color: #FCFCFB; padding: 16px; border-radius: 4px; border: 1px solid #E5E5E5;">
                    <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 14px; font-weight: 600;">Security Notice</p>
                    <p style="margin: 0; color: #666666; font-size: 14px; line-height: 1.6;">
                      This link will expire in 24 hours. If you didn't request this, you can safely ignore this email.
                    </p>
                  </td>
                </tr>
              </table>
              <p style="margin: 24px 0 0 0; color: #999999; font-size: 13px; line-height: 1.7;">
                If the button doesn't work, copy and paste this link into your browser:<br>
                <a href="${actionUrl}" style="color: #3EB489; text-decoration: none; word-break: break-all;">${actionUrl}</a>
              </p>
            </td>
          </tr>
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">© 2026 MintCheck. All rights reserved.</p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="${HELP_LINK}" style="color: #3EB489; text-decoration: none;">Help Center</a> •
                <a href="${PRIVACY_LINK}" style="color: #3EB489; text-decoration: none;">Privacy</a> •
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
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({})) as { email?: string; type?: string };
    const email = typeof body.email === "string" ? body.email.trim() : "";
    const type = body.type === "email_change" ? "email_change_new" : "signup";

    if (!email) {
      return new Response(
        JSON.stringify({ error: "Missing email" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const resendFrom = Deno.env.get("RESEND_FROM_EMAIL") || "MintCheck <noreply@mintcheckapp.com>";

    if (!resendApiKey) {
      console.warn("RESEND_API_KEY not set; confirmation email not sent");
      return new Response(
        JSON.stringify({ error: "Email service not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Generate link: signup (resend confirmation) or email_change_new
    const linkType = type === "email_change_new" ? "email_change_new" : "signup";
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: linkType,
      email,
    } as { type: "signup" | "email_change_new"; email: string });

    if (linkError || !linkData?.properties) {
      console.error("generateLink error:", linkError);
      return new Response(
        JSON.stringify({ error: "Could not generate confirmation link" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { hashed_token, verification_type } = linkData.properties;
    const confirmType = verification_type === "email_change_new" ? "email_change" : "signup";
    const actionUrl = `${DEEP_LINK_BASE}/auth/confirm?token=${encodeURIComponent(hashed_token)}&type=${confirmType}`;

    const html = getEmailConfirmationHtml(actionUrl, email);

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: resendFrom,
        to: [email],
        subject: "Confirm your MintCheck email",
        html,
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error("Resend error:", res.status, errText);
      return new Response(
        JSON.stringify({ error: "Could not send email. Try again." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("send-confirmation-email error:", e);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
