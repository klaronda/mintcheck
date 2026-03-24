import type { VercelRequest, VercelResponse } from "@vercel/node";

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL || "";
const KEY =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.VITE_SUPABASE_ANON_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  "";
const OG_IMAGE_DEFAULT =
  "https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/OpenGraph_deepcheck.png";
const SITE = "https://mintcheckapp.com";

function esc(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const code = (req.query.code as string)?.trim();
  if (!code || !SUPABASE_URL) {
    return res.redirect(302, SITE);
  }

  const canonicalUrl = `${SITE}/deep-check/report/${code}`;

  if (!KEY) {
    return res.redirect(302, canonicalUrl);
  }

  try {
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/deep_check_reports?report_code=eq.${encodeURIComponent(code)}&select=year_make_model`,
      {
        headers: {
          apikey: KEY,
          Authorization: `Bearer ${KEY}`,
        },
      }
    );

    if (!response.ok) {
      return res.redirect(302, canonicalUrl);
    }

    const rows = await response.json();
    if (!Array.isArray(rows) || rows.length === 0) {
      return res.redirect(302, canonicalUrl);
    }

    const yearMakeModel = rows[0].year_make_model || "";
    const ogTitle = yearMakeModel
      ? `${yearMakeModel} — Deep Vehicle Check | MintCheck`
      : "Deep Vehicle Check | MintCheck";
    const ogDescription = yearMakeModel
      ? `View the full vehicle history report for a ${yearMakeModel}, powered by MintCheck.`
      : "View the full vehicle history report powered by MintCheck.";

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>${esc(ogTitle)}</title>
<meta property="og:type" content="article" />
<meta property="og:title" content="${esc(ogTitle)}" />
<meta property="og:description" content="${esc(ogDescription)}" />
<meta property="og:image" content="${OG_IMAGE_DEFAULT}" />
<meta property="og:url" content="${esc(canonicalUrl)}" />
<meta property="og:site_name" content="MintCheck" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="${esc(ogTitle)}" />
<meta name="twitter:description" content="${esc(ogDescription)}" />
<meta name="twitter:image" content="${OG_IMAGE_DEFAULT}" />
<meta http-equiv="refresh" content="0;url=${esc(canonicalUrl)}" />
</head>
<body>
<p>Redirecting to <a href="${esc(canonicalUrl)}">${esc(yearMakeModel || "report")}</a>…</p>
</body>
</html>`;

    res.setHeader("Content-Type", "text/html; charset=utf-8");
    res.setHeader("Cache-Control", "s-maxage=300, stale-while-revalidate=600");
    return res.status(200).send(html);
  } catch {
    return res.redirect(302, canonicalUrl);
  }
}
