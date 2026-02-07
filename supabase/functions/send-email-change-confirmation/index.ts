import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DEEP_LINK_BASE = "https://mintcheckapp.com";
const APP_NAME = "MintCheck";

function getEmailChangeConfirmationHtml(actionUrl: string, newEmail: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Confirm your new email</title></head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#F8F8F7;">
<table role="presentation" style="width:100%;border-collapse:collapse;">
<tr><td align="center" style="padding:40px 20px;">
<table role="presentation" style="width:100%;max-width:600px;border-collapse:collapse;">
<tr><td style="background:#fff;padding:32px;border-radius:4px 4px 0 0;"><div style="color:#3EB489;font-size:24px;font-weight:600;">MintCheck</div><h2 style="margin:0;color:#1A1A1A;font-size:24px;font-weight:600;">Confirm your new email</h2></td></tr>
<tr><td style="background:#fff;padding:0 32px 40px;">
<p style="margin:0 0 20px;color:#666;font-size:15px;line-height:1.7;">Please confirm your new email address for your ${APP_NAME} account (${newEmail}) by clicking the button below:</p>
<table role="presentation" style="width:100%;margin:32px 0;"><tr><td align="center"><a href="${actionUrl}" style="display:inline-block;padding:16px 40px;background:#3EB489;color:#fff;text-decoration:none;border-radius:4px;font-size:15px;font-weight:600;">Confirm Email</a></td></tr></table>
<p style="margin:24px 0 0;color:#999;font-size:13px;">If the button doesn't work: <a href="${actionUrl}" style="color:#3EB489;">${actionUrl}</a></p>
</td></tr>
<tr><td style="background:#F8F8F7;padding:32px;text-align:center;border-radius:0 0 4px 4px;border-top:1px solid #E5E5E5;"><p style="margin:0;color:#999;font-size:13px;">© 2026 MintCheck. All rights reserved.</p></td></tr>
</table></td></tr></table></body></html>`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json().catch(() => ({})) as { new_email?: string };
    const newEmail = typeof body.new_email === "string" ? body.new_email.trim() : "";

    if (!newEmail) {
      return new Response(
        JSON.stringify({ error: "Missing new_email" }),
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

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired session" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Generate email change link for the new address (type email_change_new sends to new email)
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: "email_change_new",
      email: newEmail,
    } as { type: "email_change_new"; email: string });

    if (linkError || !linkData?.properties) {
      console.error("generateLink email_change_new error:", linkError);
      return new Response(
        JSON.stringify({ error: "Could not generate email change link" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { hashed_token } = linkData.properties;
    const actionUrl = `${DEEP_LINK_BASE}/auth/confirm?token=${encodeURIComponent(hashed_token)}&type=email_change`;
    const html = getEmailChangeConfirmationHtml(actionUrl, newEmail);

    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ error: "Email service not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: resendFrom,
        to: [newEmail],
        subject: "Confirm your new MintCheck email",
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
    console.error("send-email-change-confirmation error:", e);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
