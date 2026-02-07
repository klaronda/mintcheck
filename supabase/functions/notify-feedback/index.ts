import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type FeedbackRow = {
  id: string;
  created_at: string;
  user_id: string | null;
  category: string;
  message: string | null;
  email: string | null;
  context: Record<string, unknown>;
  status: string;
  source: string;
};

function formatJson(obj: unknown): string {
  try {
    return JSON.stringify(obj, null, 2);
  } catch {
    return String(obj);
  }
}

function buildEmailSubject(feedback: FeedbackRow): string {
  const ctx = feedback.context as Record<string, unknown>;
  const platform = (ctx["platform"] as string | undefined) ?? "unknown";
  const internetStatus = (ctx["internet_status"] as string | undefined) ?? "unknown";
  return `MintCheck Feedback — ${feedback.category} — ${platform} — ${internetStatus}`;
}

function buildEmailHtml(feedback: FeedbackRow): string {
  const ctx = feedback.context as Record<string, unknown>;

  const appVersion = (ctx["app_version"] as string | undefined) ?? "unknown";
  const platform = (ctx["platform"] as string | undefined) ?? "unknown";
  const deviceModel = (ctx["device_model"] as string | undefined) ?? "unknown";
  const osVersion = (ctx["os_version"] as string | undefined) ?? "unknown";
  const locale = (ctx["locale"] as string | undefined) ?? "unknown";
  const timezone = (ctx["timezone"] as string | undefined) ?? "unknown";

  const screen = (ctx["screen"] as string | undefined) ?? "unknown";
  const internetStatus = (ctx["internet_status"] as string | undefined) ?? "unknown";
  const obdTransport = (ctx["obd_transport"] as string | undefined) ?? "unknown";
  const obdStatus = (ctx["obd_status"] as string | undefined) ?? "unknown";

  const scanState = (ctx["scan_state"] as string | undefined) ?? "unknown";
  const scanStep = (ctx["scan_step"] as string | undefined) ?? "unknown";
  const scanProgress = (ctx["scan_progress_percent"] as number | undefined) ?? null;
  const reportId = (ctx["report_id"] as string | undefined) ?? null;

  const errorCode = (ctx["error_code"] as string | undefined) ?? null;
  const errorMessage = (ctx["error_message"] as string | undefined) ?? null;

  const breadcrumbs = (ctx["breadcrumbs"] as unknown[]) ?? [];

  const message = feedback.message ?? "(no message)";
  const email = feedback.email ?? "(not provided)";

  const breadcrumbsHtml =
    breadcrumbs.length === 0
      ? "<em>none</em>"
      : `<pre style=\"background:#0b1020;padding:12px;border-radius:4px;color:#f5f5f5;font-size:12px;white-space:pre-wrap;\">${formatJson(
          breadcrumbs,
        )}</pre>`;

  const contextHtml = `<pre style=\"background:#0b1020;padding:12px;border-radius:4px;color:#f5f5f5;font-size:12px;white-space:pre-wrap;\">${formatJson(
    feedback.context,
  )}</pre>`;

  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>MintCheck Feedback</title>
  </head>
  <body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#0B1020;color:#F5F5F5;">
    <table role="presentation" style="width:100%;border-collapse:collapse;">
      <tr>
        <td align="center" style="padding:32px 16px;">
          <table role="presentation" style="width:100%;max-width:720px;border-collapse:collapse;background:#111827;border-radius:12px;overflow:hidden;border:1px solid #1F2937;">
            <tr>
              <td style="padding:20px 24px;border-bottom:1px solid #1F2937;">
                <div style="color:#34D399;font-size:20px;font-weight:600;margin-bottom:4px;">MintCheck Feedback</div>
                <div style="font-size:13px;color:#9CA3AF;">${feedback.category} • ${platform} • ${internetStatus}</div>
              </td>
            </tr>
            <tr>
              <td style="padding:20px 24px;border-bottom:1px solid #1F2937;">
                <h2 style="margin:0 0 8px;font-size:16px;color:#F9FAFB;">Summary</h2>
                <p style="margin:0 0 4px;font-size:13px;"><strong>Category:</strong> ${feedback.category}</p>
                <p style="margin:0 0 4px;font-size:13px;"><strong>Source:</strong> ${feedback.source}</p>
                <p style="margin:0 0 4px;font-size:13px;"><strong>User email:</strong> ${email}</p>
                <p style="margin:8px 0 0;font-size:13px;"><strong>Message:</strong></p>
                <p style="margin:4px 0 0;font-size:13px;white-space:pre-wrap;">${message}</p>
              </td>
            </tr>
            <tr>
              <td style="padding:20px 24px;border-bottom:1px solid #1F2937;">
                <h3 style="margin:0 0 8px;font-size:14px;color:#F9FAFB;">App & Device</h3>
                <p style="margin:0 0 4px;font-size:13px;">
                  <strong>App version:</strong> ${appVersion}<br/>
                  <strong>Platform:</strong> ${platform}<br/>
                  <strong>Device:</strong> ${deviceModel}<br/>
                  <strong>OS version:</strong> ${osVersion}<br/>
                  <strong>Locale / Timezone:</strong> ${locale} / ${timezone}
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:20px 24px;border-bottom:1px solid #1F2937;">
                <h3 style="margin:0 0 8px;font-size:14px;color:#F9FAFB;">Session & Connectivity</h3>
                <p style="margin:0 0 4px;font-size:13px;">
                  <strong>Screen:</strong> ${screen}<br/>
                  <strong>Internet status:</strong> ${internetStatus}<br/>
                  <strong>OBD transport:</strong> ${obdTransport}<br/>
                  <strong>OBD status:</strong> ${obdStatus}
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:20px 24px;border-bottom:1px solid #1F2937;">
                <h3 style="margin:0 0 8px;font-size:14px;color:#F9FAFB;">Scan Context</h3>
                <p style="margin:0 0 4px;font-size:13px;">
                  <strong>Scan state:</strong> ${scanState}<br/>
                  <strong>Scan step:</strong> ${scanStep}<br/>
                  <strong>Progress:</strong> ${scanProgress ?? "unknown"}%<br/>
                  <strong>Report ID:</strong> ${reportId ?? "(none)"}
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:20px 24px;border-bottom:1px solid #1F2937;">
                <h3 style="margin:0 0 8px;font-size:14px;color:#F9FAFB;">Error (if any)</h3>
                <p style="margin:0 0 4px;font-size:13px;">
                  <strong>Error code:</strong> ${errorCode ?? "(none)"}<br/>
                  <strong>Error message:</strong> ${errorMessage ?? "(none)"}
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:20px 24px;border-bottom:1px solid #1F2937;">
                <h3 style="margin:0 0 8px;font-size:14px;color:#F9FAFB;">Breadcrumbs</h3>
                ${breadcrumbsHtml}
              </td>
            </tr>
            <tr>
              <td style="padding:20px 24px;">
                <h3 style="margin:0 0 8px;font-size:14px;color:#F9FAFB;">Full Context (JSON)</h3>
                ${contextHtml}
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
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const resendFrom = Deno.env.get("RESEND_FROM_EMAIL") || "MintCheck <noreply@mintcheckapp.com>";
    const feedbackTo = Deno.env.get("FEEDBACK_TEAM_EMAIL") || Deno.env.get("SUPPORT_EMAIL");

    if (!resendApiKey || !feedbackTo) {
      console.error("Resend or feedback recipient not configured");
      return new Response(
        JSON.stringify({ error: "Email service not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const body = (await req.json().catch(() => ({}))) as { feedbackId?: string };
    const feedbackId = body.feedbackId;

    if (!feedbackId) {
      return new Response(
        JSON.stringify({ error: "Missing feedbackId" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data, error } = await supabase
      .from("feedback")
      .select("*")
      .eq("id", feedbackId)
      .single<FeedbackRow>();

    if (error || !data) {
      console.error("Failed to load feedback", error);
      return new Response(
        JSON.stringify({ error: "Feedback not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const subject = buildEmailSubject(data);
    const html = buildEmailHtml(data);

    const emailRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: resendFrom,
        to: [feedbackTo],
        subject,
        html,
      }),
    });

    if (!emailRes.ok) {
      const text = await emailRes.text();
      console.error("Resend error:", emailRes.status, text);
      return new Response(
        JSON.stringify({ error: "Failed to send email" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("notify-feedback error:", e);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

