import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};

const REPORT_BASE = "https://mintcheckapp.com";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const resendFrom = Deno.env.get("RESEND_FROM_EMAIL") || "MintCheck <noreply@mintcheckapp.com>";

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: "Server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!resendApiKey) {
    return new Response(JSON.stringify({ error: "Email not configured" }), {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: { code?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const code = typeof body?.code === "string" ? body.code.trim() : "";
  if (!code) {
    return new Response(JSON.stringify({ error: "Missing code" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: reportRow, error: reportErr } = await supabase
    .from("deep_check_reports")
    .select("id, purchase_id, year_make_model")
    .eq("report_code", code)
    .maybeSingle();

  if (reportErr || !reportRow) {
    return new Response(JSON.stringify({ error: "Report not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const purchaseId = (reportRow as { purchase_id: string }).purchase_id;
  const yearMakeModel = (reportRow as { year_make_model?: string | null }).year_make_model?.trim() || null;

  const { data: purchaseRow, error: purchaseErr } = await supabase
    .from("deep_check_purchases")
    .select("user_id, vin")
    .eq("id", purchaseId)
    .maybeSingle();

  if (purchaseErr || !purchaseRow) {
    return new Response(JSON.stringify({ error: "Report not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const userId = (purchaseRow as { user_id: string }).user_id;
  const { data: { user: authUser } } = await supabase.auth.admin.getUserById(userId);
  const email = authUser?.email;
  if (!email) {
    return new Response(JSON.stringify({ error: "Could not send email" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const vin = (purchaseRow as { vin?: string }).vin ?? "";
  const vinLast6 = String(vin).trim().slice(-6);
  const subject = yearMakeModel
    ? `Your Deep Vehicle Check: ${yearMakeModel} (VIN ***${vinLast6})`
    : `Your Deep Vehicle Check report is ready (VIN ***${vinLast6})`;
  const bodyIntro = yearMakeModel
    ? `Your report for <strong>${yearMakeModel}</strong> (VIN ending in ${vinLast6}) is ready to view. Open the link below to see accident history, title status, and more.`
    : `Your report for the vehicle you checked (VIN ending in ${vinLast6}) is ready to view. Open the link below to see accident history, title status, and more.`;

  const reportUrl = `${REPORT_BASE}/deep-check/report/${encodeURIComponent(code)}`;
  const html = `<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Your Deep Vehicle Check is ready</title></head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#F8F8F7;">
<table role="presentation" style="width:100%;border-collapse:collapse;">
<tr><td align="center" style="padding:40px 20px;">
<table role="presentation" style="width:100%;max-width:600px;border-collapse:collapse;">
<tr><td style="background:#fff;padding:32px;border-radius:4px 4px 0 0;"><div style="color:#3EB489;font-size:24px;font-weight:600;">MintCheck</div><h2 style="margin:0;color:#1A1A1A;font-size:24px;font-weight:600;">Your Deep Vehicle Check is ready</h2></td></tr>
<tr><td style="background:#fff;padding:0 32px 40px;">
<p style="margin:0 0 20px;color:#666;font-size:15px;line-height:1.7;">${bodyIntro}</p>
<table role="presentation" style="width:100%;margin:32px 0;"><tr><td align="center"><a href="${reportUrl}" style="display:inline-block;padding:16px 40px;background:#3EB489;color:#fff;text-decoration:none;border-radius:4px;font-size:15px;font-weight:600;">View Report</a></td></tr></table>
<p style="margin:24px 0 0;color:#999;font-size:13px;">If the button doesn't work: <a href="${reportUrl}" style="color:#3EB489;">${reportUrl}</a></p>
</td></tr>
<tr><td style="background:#F8F8F7;padding:32px;text-align:center;border-radius:0 0 4px 4px;border-top:1px solid #E5E5E5;"><p style="margin:0;color:#999;font-size:13px;">© 2026 MintCheck. All rights reserved.</p></td></tr>
</table></td></tr></table></body></html>`;

  const emailRes = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: resendFrom,
      to: [email],
      subject,
      html,
    }),
  });

  if (!emailRes.ok) {
    console.error("email-deep-check-report: Resend error", await emailRes.text());
    return new Response(JSON.stringify({ error: "Failed to send email" }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  await supabase
    .from("deep_check_reports")
    .update({ report_emailed_at: new Date().toISOString() })
    .eq("report_code", code);

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
