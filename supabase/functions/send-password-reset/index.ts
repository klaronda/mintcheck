import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DEEP_LINK_BASE = "https://mintcheckapp.com";

// Inline password reset template (MintCheck style); variable: {{resetPasswordLink}}
function getPasswordResetHtml(resetUrl: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Reset Your MintCheck Password</title></head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#F8F8F7;">
<table role="presentation" style="width:100%;border-collapse:collapse;">
<tr><td align="center" style="padding:40px 20px;">
<table role="presentation" style="width:100%;max-width:600px;border-collapse:collapse;">
<tr><td style="background:#fff;padding:32px;border-radius:4px 4px 0 0;"><div style="color:#3EB489;font-size:24px;font-weight:600;">MintCheck</div><h2 style="margin:0;color:#1A1A1A;font-size:24px;font-weight:600;">Reset your password</h2></td></tr>
<tr><td style="background:#fff;padding:0 32px 40px;">
<p style="margin:0 0 20px;color:#666;font-size:15px;line-height:1.7;">We received a request to reset your password for your MintCheck account. Click the button below to create a new password:</p>
<table role="presentation" style="width:100%;margin:32px 0;"><tr><td align="center"><a href="${resetUrl}" style="display:inline-block;padding:16px 40px;background:#3EB489;color:#fff;text-decoration:none;border-radius:4px;font-size:15px;font-weight:600;">Reset Password</a></td></tr></table>
<p style="margin:24px 0 0;color:#999;font-size:13px;">This link will expire in 24 hours. If you didn't request a reset, you can safely ignore this email.</p>
<p style="margin:16px 0 0;color:#999;font-size:13px;">If the button doesn't work: <a href="${resetUrl}" style="color:#3EB489;">${resetUrl}</a></p>
</td></tr>
<tr><td style="background:#F8F8F7;padding:32px;text-align:center;border-radius:0 0 4px 4px;border-top:1px solid #E5E5E5;"><p style="margin:0;color:#999;font-size:13px;">© 2026 MintCheck. All rights reserved.</p></td></tr>
</table></td></tr></table></body></html>`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({})) as { email?: string };
    const email = typeof body.email === "string" ? body.email.trim() : "";

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

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: "recovery",
      email,
    });

    if (linkError || !linkData?.properties) {
      // Do not reveal whether the email exists; always return success
      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { hashed_token } = linkData.properties;
    const resetUrl = `${DEEP_LINK_BASE}/auth/reset?token=${encodeURIComponent(hashed_token)}`;
    const html = getPasswordResetHtml(resetUrl);

    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: resendFrom,
        to: [email],
        subject: "Reset your MintCheck password",
        html,
      }),
    });
    // Always return success (do not reveal if email exists)
    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("send-password-reset error:", e);
    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
