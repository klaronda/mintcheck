import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DEEP_LINK_BASE = "https://mintcheckapp.com";
const APP_NAME = "MintCheck";
const HELP_LINK = "https://mintcheckapp.com/support";
const PRIVACY_LINK = "https://mintcheckapp.com/privacy";
const TERMS_LINK = "https://mintcheckapp.com/terms";

function getEmailConfirmationHtml(actionUrl: string, userEmail: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Confirm your ${APP_NAME} email</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">${APP_NAME}</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Tap the button to verify your email.</h2>
            </td>
          </tr>
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                After confirming (${userEmail}), you'll be sent back to the ${APP_NAME} app. If the ${APP_NAME} app doesn't automatically open, tap the link in your browser.
              </p>
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0;">
                <tr>
                  <td align="left">
                    <a href="${actionUrl}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">Confirm Email</a>
                  </td>
                </tr>
              </table>
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 24px 0;">
                <tr>
                  <td style="background-color: #FCFCFB; padding: 16px; border-radius: 4px; border: 1px solid #E5E5E5;">
                    <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 14px; font-weight: 600;">For your security</p>
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
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">&copy; 2026 ${APP_NAME}. All rights reserved.</p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
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
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({})) as {
      email?: string;
      password?: string;
      first_name?: string;
      last_name?: string;
    };

    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    const password = typeof body.password === "string" ? body.password : "";
    const firstName = typeof body.first_name === "string" ? body.first_name.trim() : "";
    const lastName = typeof body.last_name === "string" ? body.last_name.trim() : "";

    if (!email || !password) {
      return new Response(
        JSON.stringify({ error: "Email and password are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (password.length < 6) {
      return new Response(
        JSON.stringify({ error: "Password must be at least 6 characters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const resendFrom = Deno.env.get("RESEND_FROM_EMAIL") || "MintCheck <noreply@mintcheckapp.com>";

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // 1. Create user via admin API — does NOT trigger Supabase's built-in confirmation email
    const { data: userData, error: createError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: false,
    });

    if (createError) {
      const msg = createError.message?.toLowerCase() ?? "";
      if (msg.includes("already") || msg.includes("duplicate") || msg.includes("exists")) {
        return new Response(
          JSON.stringify({ error: "An account with this email already exists. Try signing in." }),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      console.error("createUser error:", createError);
      return new Response(
        JSON.stringify({ error: "Could not create account. Please try again." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const userId = userData.user.id;

    // 2. Update profile with name
    if (firstName || lastName) {
      await supabase
        .from("profiles")
        .update({ first_name: firstName, last_name: lastName })
        .eq("id", userId);
    }

    // 3. Generate confirmation link (does not send any email)
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: "signup",
      email,
    });

    if (linkError || !linkData?.properties) {
      console.error("generateLink error:", linkError);
      return new Response(
        JSON.stringify({ error: "Account created but couldn't send confirmation email. Tap 'Resend' to try again." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Send branded confirmation email via Resend
    const { hashed_token } = linkData.properties;
    const actionUrl = `${DEEP_LINK_BASE}/auth/confirm?token=${encodeURIComponent(hashed_token)}&type=signup`;
    const html = getEmailConfirmationHtml(actionUrl, email);

    if (resendApiKey) {
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
      }
    } else {
      console.warn("RESEND_API_KEY not set; confirmation email not sent");
    }

    return new Response(
      JSON.stringify({ success: true, user_id: userId, needs_confirmation: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("create-account error:", e);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
