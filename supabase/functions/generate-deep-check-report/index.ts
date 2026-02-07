import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const CHEAPCARFAX_BASE = "https://panel.cheapcarfax.net/api";

/** Extract vhr object from CARFAX HTML (script: window.__INITIAL__DATA__ = { "vhr": {...} }). */
function extractVhrFromHtml(html: string): Record<string, unknown> | null {
  if (!html?.trim()) return null;
  const marker = "window.__INITIAL__DATA__";
  const idx = html.indexOf(marker);
  if (idx === -1) return null;
  const afterMarker = html.slice(idx + marker.length);
  const eqMatch = afterMarker.match(/^\s*=\s*/);
  if (!eqMatch) return null;
  const jsonStartIdx = afterMarker.indexOf("{", eqMatch.length);
  if (jsonStartIdx === -1) return null;
  let depth = 0;
  let inString = false;
  let escape = false;
  let jsonEnd = -1;
  for (let i = jsonStartIdx; i < afterMarker.length; i++) {
    const c = afterMarker[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (c === "\\" && inString) {
      escape = true;
      continue;
    }
    if (c === '"') {
      inString = !inString;
      continue;
    }
    if (!inString) {
      if (c === "{") depth++;
      else if (c === "}") {
        depth--;
        if (depth === 0) {
          jsonEnd = i;
          break;
        }
      }
    }
  }
  if (jsonEnd === -1) return null;
  const jsonStr = afterMarker.slice(jsonStartIdx, jsonEnd + 1);
  try {
    const parsed = JSON.parse(jsonStr) as { vhr?: unknown };
    if (parsed && typeof parsed.vhr === "object" && parsed.vhr !== null) {
      return parsed.vhr as Record<string, unknown>;
    }
  } catch {
    // ignore
  }
  return null;
}

/** Derive recommendation_status from vhr: problems_reported if branded title or accident damage, else history_available. */
function getRecommendationStatus(vhr: Record<string, unknown>): "problems_reported" | "history_available" {
  const headerSection = vhr.headerSection as Record<string, unknown> | undefined;
  const historyOverview = (headerSection?.historyOverview as { rows?: unknown[] })?.rows ?? [];
  const hasBrandedTitle = historyOverview.some(
    (r: { name?: string }) => (r as { name?: string }).name === "damageBrandedTitle"
  );
  const accidentSection = vhr.accidentDamageSection as { accidentDamageRecords?: unknown[] } | undefined;
  const accidentCount = accidentSection?.accidentDamageRecords?.length ?? 0;
  const hasAlert = !!hasBrandedTitle || accidentCount > 0;
  return hasAlert ? "problems_reported" : "history_available";
}

function generateReportCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
  const bytes = new Uint8Array(12);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => chars[b % chars.length]).join("");
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  // Only allow calls from stripe-webhook (shared secret); avoids gateway 403 when using service role Bearer
  const expectedSecret = Deno.env.get("DEEP_CHECK_INVOKE_SECRET");
  const providedSecret = req.headers.get("X-Internal-Secret");
  if (!expectedSecret || providedSecret !== expectedSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const apiKey = Deno.env.get("CHEAPCARFAX_API_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!apiKey || !supabaseUrl || !serviceRoleKey) {
    console.error("generate-deep-check-report: missing CHEAPCARFAX_API_KEY or Supabase env");
    return new Response(JSON.stringify({ error: "Server configuration error" }), { status: 500 });
  }

  let body: { purchase_id?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), { status: 400 });
  }

  const purchaseId = typeof body?.purchase_id === "string" ? body.purchase_id.trim() : "";
  if (!purchaseId) {
    return new Response(JSON.stringify({ error: "Missing purchase_id" }), { status: 400 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: purchase, error: fetchErr } = await supabase
    .from("deep_check_purchases")
    .select("id, vin, status, user_id")
    .eq("id", purchaseId)
    .single();

  if (fetchErr || !purchase) {
    console.error("generate-deep-check-report: purchase not found", purchaseId, fetchErr);
    return new Response(JSON.stringify({ error: "Purchase not found" }), { status: 404 });
  }

  if (purchase.status !== "paid") {
    return new Response(JSON.stringify({ ok: true, message: "Already processed or not paid" }), { status: 200 });
  }

  const vin = String(purchase.vin ?? "").trim().toUpperCase();
  if (vin.length !== 17) {
    await supabase
      .from("deep_check_purchases")
      .update({ status: "report_failed", report_error: "Invalid VIN length" })
      .eq("id", purchaseId);
    return new Response(JSON.stringify({ error: "Invalid VIN" }), { status: 400 });
  }

  const url = `${CHEAPCARFAX_BASE}/carfax/vin/${encodeURIComponent(vin)}/html`;
  const fixieUrl = Deno.env.get("FIXIE_URL"); // optional: http://user:pass@host:port (from Fixie dashboard)
  // CheapCARFAX/Cloudflare blocks User-Agent containing "Deno" (Supabase Edge = Deno). Use a custom UA so we don't match their block rule.
  let fetchOptions: RequestInit & { client?: ReturnType<typeof Deno.createHttpClient> } = {
    method: "GET",
    headers: {
      "x-api-key": apiKey,
      "Accept": "application/json",
      "User-Agent": "MintCheck-DeepCheck/1.0 (https://mintcheckapp.com)",
    },
  };
  if (fixieUrl?.startsWith("http")) {
    try {
      const parsed = new URL(fixieUrl);
      const proxyUrl = `${parsed.protocol}//${parsed.hostname}:${parsed.port || (parsed.protocol === "https:" ? "443" : "80")}`;
      fetchOptions.client = Deno.createHttpClient({
        proxy: {
          url: proxyUrl,
          basicAuth: parsed.username
            ? { username: decodeURIComponent(parsed.username), password: decodeURIComponent(parsed.password || "") }
            : undefined,
        },
      });
      console.log("generate-deep-check-report: proxy used (Fixie)", purchaseId);
    } catch (e) {
      console.warn("generate-deep-check-report: FIXIE_URL parse failed, fetching without proxy", e);
    }
  } else {
    console.log("generate-deep-check-report: no FIXIE_URL, fetching without proxy", purchaseId);
  }
  let res: Response;
  try {
    res = await fetch(url, fetchOptions);
  } catch (e) {
    console.error("generate-deep-check-report: fetch failed", e);
    await supabase
      .from("deep_check_purchases")
      .update({ status: "report_failed", report_error: "Report provider unavailable" })
      .eq("id", purchaseId);
    return new Response(JSON.stringify({ error: "Fetch failed" }), { status: 502 });
  }

  const contentType = res.headers.get("content-type") ?? "";
  const text = await res.text();

  // Reject Cloudflare challenge or non-JSON (e.g. HTML "Just a moment...")
  if (!contentType.includes("application/json") || text.trimStart().startsWith("<")) {
    const isCloudflare = text.includes("Just a moment") || text.includes("cloudflare") || text.includes("challenge");
    const errMsg = isCloudflare
      ? "Report provider blocked (Cloudflare challenge)"
      : res.status === 401
        ? "Report provider: Unauthorized (check API key)"
        : res.status === 400
          ? "Report provider: Bad request"
          : res.status >= 500
            ? `Report provider error ${res.status}`
            : "Report provider temporarily unavailable";
    console.error("generate-deep-check-report: non-JSON response", res.status, contentType?.slice(0, 50), text?.slice(0, 200));
    await supabase
      .from("deep_check_purchases")
      .update({ status: "report_failed", report_error: errMsg })
      .eq("id", purchaseId);
    return new Response(JSON.stringify({ error: errMsg }), { status: res.status >= 400 ? res.status : 502 });
  }

  let json: { yearMakeModel?: string; id?: string; html?: string; message?: string };
  try {
    json = JSON.parse(text);
  } catch {
    console.error("generate-deep-check-report: invalid JSON", text?.slice(0, 300));
    await supabase
      .from("deep_check_purchases")
      .update({ status: "report_failed", report_error: "Invalid response from report provider" })
      .eq("id", purchaseId);
    return new Response(JSON.stringify({ error: "Invalid response" }), { status: 502 });
  }

  if (res.status !== 200 || !json.html) {
    const msg =
      typeof json.message === "string"
        ? json.message
        : res.status === 401
          ? "Report provider: Unauthorized (check CHEAPCARFAX_API_KEY)"
          : res.status === 402
            ? "Report provider: Payment required"
            : res.status >= 500
              ? `Report provider error ${res.status}`
              : "Could not generate report";
    console.error("generate-deep-check-report: API error", res.status, JSON.stringify(json).slice(0, 500));
    await supabase
      .from("deep_check_purchases")
      .update({ status: "report_failed", report_error: msg })
      .eq("id", purchaseId);
    return new Response(JSON.stringify({ error: msg }), { status: res.status >= 400 ? res.status : 502 });
  }

  const reportCode = generateReportCode();
  const yearMakeModel = typeof json.yearMakeModel === "string" ? json.yearMakeModel : null;

  const { error: insertErr } = await supabase.from("deep_check_reports").insert({
    purchase_id: purchaseId,
    report_code: reportCode,
    html_content: json.html,
    year_make_model: yearMakeModel,
  });

  if (insertErr) {
    console.error("generate-deep-check-report: insert deep_check_reports error", insertErr);
    await supabase
      .from("deep_check_purchases")
      .update({ status: "report_failed", report_error: "Failed to save report" })
      .eq("id", purchaseId);
    return new Response(JSON.stringify({ error: "Failed to save report" }), { status: 500 });
  }

  const reportUrl = `https://mintcheckapp.com/deep-check/report/${reportCode}`;
  let recommendationStatus: "problems_reported" | "history_available" = "history_available";
  const vhr = extractVhrFromHtml(json.html);
  if (vhr) {
    recommendationStatus = getRecommendationStatus(vhr);
  }
  const { error: updateErr } = await supabase
    .from("deep_check_purchases")
    .update({ status: "report_ready", report_url: reportUrl, recommendation_status: recommendationStatus })
    .eq("id", purchaseId);

  if (updateErr) {
    console.error("generate-deep-check-report: update deep_check_purchases error", updateErr);
    return new Response(JSON.stringify({ error: "Failed to update purchase" }), { status: 500 });
  }

  // Email user when report is ready (so they can open from email if they left the app)
  const userId = (purchase as { user_id?: string }).user_id;
  if (userId) {
    try {
      const { data: { user: authUser } } = await supabase.auth.admin.getUserById(userId);
      const email = authUser?.email;
      const resendApiKey = Deno.env.get("RESEND_API_KEY");
      const resendFrom = Deno.env.get("RESEND_FROM_EMAIL") || "MintCheck <noreply@mintcheckapp.com>";
      if (resendApiKey && email) {
        const html = `<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Your Deep Vehicle Check is ready</title></head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#F8F8F7;">
<table role="presentation" style="width:100%;border-collapse:collapse;">
<tr><td align="center" style="padding:40px 20px;">
<table role="presentation" style="width:100%;max-width:600px;border-collapse:collapse;">
<tr><td style="background:#fff;padding:32px;border-radius:4px 4px 0 0;"><div style="color:#3EB489;font-size:24px;font-weight:600;">MintCheck</div><h2 style="margin:0;color:#1A1A1A;font-size:24px;font-weight:600;">Your Deep Vehicle Check is ready</h2></td></tr>
<tr><td style="background:#fff;padding:0 32px 40px;">
<p style="margin:0 0 20px;color:#666;font-size:15px;line-height:1.7;">Your vehicle history report is ready to view. Open the link below to see accident history, title status, and more.</p>
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
            subject: "Your Deep Vehicle Check report is ready",
            html,
          }),
        });
        if (emailRes.ok) {
          await supabase
            .from("deep_check_reports")
            .update({ report_emailed_at: new Date().toISOString() })
            .eq("report_code", reportCode);
          console.log("generate-deep-check-report: report-ready email sent to user", purchaseId);
        }
      }
    } catch (e) {
      console.warn("generate-deep-check-report: failed to send report-ready email", e);
    }
  }

  return new Response(JSON.stringify({ ok: true, report_url: reportUrl }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
