import { rewrite } from "@vercel/functions";

const BOT_UA =
  /facebookexternalhit|Facebot|Twitterbot|LinkedInBot|Slackbot|TelegramBot|WhatsApp|Discordbot|Googlebot|bingbot|Applebot|iMessageLinkPreview|Pinterestbot|redditbot|Embedly|Quora Link Preview/i;

export default function middleware(request: Request) {
  const ua = request.headers.get("user-agent") || "";
  if (!BOT_UA.test(ua)) return;

  const url = new URL(request.url);
  const { pathname } = url;

  const scanMatch = pathname.match(/^\/report\/([^/]+)/);
  if (scanMatch) {
    const dest = new URL("/api/og-report", request.url);
    dest.searchParams.set("code", scanMatch[1]);
    return rewrite(dest);
  }

  const deepCheckMatch = pathname.match(/^\/deep-check\/report\/([^/]+)/);
  if (deepCheckMatch) {
    const dest = new URL("/api/og-deep-check", request.url);
    dest.searchParams.set("code", deepCheckMatch[1]);
    return rewrite(dest);
  }

  if (pathname === "/starter-kit") {
    const ogImage =
      "https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/Product/MC-01a.png";
    const ogTitle = "MintCheck Starter Kit \u2013 $30";
    const ogDesc =
      "Wi-Fi scanner + 60-day unlimited scanning pass. Know the real health of any car.";
    const ogUrl = "https://mintcheckapp.com/starter-kit";

    const html = `<!DOCTYPE html>
<html><head>
<meta charset="utf-8"/>
<title>${ogTitle}</title>
<meta property="og:type" content="product"/>
<meta property="og:title" content="${ogTitle}"/>
<meta property="og:description" content="${ogDesc}"/>
<meta property="og:image" content="${ogImage}"/>
<meta property="og:url" content="${ogUrl}"/>
<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:title" content="${ogTitle}"/>
<meta name="twitter:description" content="${ogDesc}"/>
<meta name="twitter:image" content="${ogImage}"/>
</head><body></body></html>`;

    return new Response(html, {
      status: 200,
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }
}

export const config = {
  matcher: ["/report/:path*", "/deep-check/report/:path*", "/starter-kit"],
};
