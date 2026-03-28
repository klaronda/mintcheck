import { rewrite } from "@vercel/functions";

const BOT_UA =
  /facebookexternalhit|Facebot|Twitterbot|LinkedInBot|Slackbot|TelegramBot|WhatsApp|Discordbot|Googlebot|bingbot|Applebot|iMessageLinkPreview|Pinterestbot|redditbot|Embedly|Quora Link Preview/i;

const SITE = "https://mintcheckapp.com";
const DEFAULT_OG_IMAGE =
  "https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/OG_mintcheck.png";
const SUPPORT_HERO =
  "https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=1200&h=400&fit=crop";
const BUYER_PASS_HERO =
  "https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/buyer-pass_help.png";

interface ArticleMeta {
  title: string;
  desc: string;
  image: string;
}

const SUPPORT_ARTICLES: Record<string, ArticleMeta> = {
  "obd-port": {
    title: "Finding your OBD-II port",
    desc: "The OBD-II port is a standardized 16-pin connector found in all cars manufactured after 1996.",
    image: SUPPORT_HERO,
  },
  "where-to-get-scanner": {
    title: "Where to get an OBD-II WiFi Scanner",
    desc: "To use MintCheck, you need a WiFi OBD-II scanner that plugs into your car\u2019s diagnostic port.",
    image: SUPPORT_HERO,
  },
  "connect-scanner": {
    title: "How to connect your OBD-II scanner",
    desc: "Follow these steps to connect your OBD-II scanner and start a vehicle scan.",
    image: SUPPORT_HERO,
  },
  "understanding-results": {
    title: "Understanding your scan results",
    desc: "MintCheck breaks down your scan results into easy-to-understand sections.",
    image: SUPPORT_HERO,
  },
  "buyer-pass": {
    title: "How the Buyer Pass works",
    desc: "Buyer Pass is a 60-day subscription for shopping multiple used cars with unlimited scans.",
    image: BUYER_PASS_HERO,
  },
  "trouble-codes": {
    title: "What are trouble codes (DTCs)?",
    desc: "Diagnostic Trouble Codes are standardized codes your car\u2019s computer generates when it detects a problem.",
    image: SUPPORT_HERO,
  },
  "recently-cleared": {
    title: "Why does it say \u2018codes recently cleared\u2019?",
    desc: "When MintCheck detects that diagnostic codes were recently cleared, it means someone reset the vehicle\u2019s onboard computer memory.",
    image: SUPPORT_HERO,
  },
  faq: {
    title: "Frequently Asked Questions",
    desc: "Common questions about MintCheck, OBD-II scanners, and vehicle diagnostics.",
    image: SUPPORT_HERO,
  },
};

const BLOG_ARTICLES: Record<string, ArticleMeta> = {
  "check-engine-light": {
    title: "Understanding Your Car\u2019s Check Engine Light",
    desc: "Learn what causes the check engine light to turn on and when you should be concerned.",
    image: "https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=1200&h=400&fit=crop",
  },
  "used-car-warning-signs": {
    title: "5 Signs You Should Walk Away from a Used Car",
    desc: "Before you buy that used car, watch out for these warning signs that could save you thousands in repairs.",
    image: "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=1200&h=400&fit=crop",
  },
  "diagnostic-check-frequency": {
    title: "How Often Should You Check Your Car\u2019s Diagnostics?",
    desc: "Regular diagnostic checks can help you catch problems early and save money on repairs.",
    image: "https://images.unsplash.com/photo-1625047509248-ec889cbff17f?w=1200&h=400&fit=crop",
  },
  "cost-of-ignoring-problems": {
    title: "The Real Cost of Ignoring Car Problems",
    desc: "That small issue you\u2019re ignoring could turn into a major repair bill.",
    image: "https://images.unsplash.com/photo-1523365237953-703b97e20c8f?w=1200&h=400&fit=crop",
  },
};

function escHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function ogResponse(title: string, desc: string, image: string, url: string, type = "article"): Response {
  const t = escHtml(title);
  const d = escHtml(desc);
  const html = `<!DOCTYPE html>
<html><head>
<meta charset="utf-8"/>
<title>${t}</title>
<meta property="og:type" content="${type}"/>
<meta property="og:title" content="${t}"/>
<meta property="og:description" content="${d}"/>
<meta property="og:image" content="${escHtml(image)}"/>
<meta property="og:url" content="${escHtml(url)}"/>
<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:title" content="${t}"/>
<meta name="twitter:description" content="${d}"/>
<meta name="twitter:image" content="${escHtml(image)}"/>
</head><body></body></html>`;
  return new Response(html, {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8" },
  });
}

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
    return ogResponse(
      "MintCheck Starter Kit \u2013 $34.99",
      "Wi-Fi scanner + 60-day unlimited scanning pass. Know the real health of any car.",
      "https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/Product/MC-01a.png",
      `${SITE}/starter-kit`,
      "product",
    );
  }

  const supportMatch = pathname.match(/^\/support\/([^/]+)$/);
  if (supportMatch) {
    const article = SUPPORT_ARTICLES[supportMatch[1]];
    if (article) {
      return ogResponse(
        `${article.title} | Support | MintCheck`,
        article.desc,
        article.image,
        `${SITE}/support/${supportMatch[1]}`,
      );
    }
  }

  const blogMatch = pathname.match(/^\/blog\/([^/]+)$/);
  if (blogMatch) {
    const article = BLOG_ARTICLES[blogMatch[1]];
    if (article) {
      return ogResponse(
        `${article.title} | Blog | MintCheck`,
        article.desc,
        article.image,
        `${SITE}/blog/${blogMatch[1]}`,
      );
    }
  }
}

export const config = {
  matcher: [
    "/report/:path*",
    "/deep-check/report/:path*",
    "/starter-kit",
    "/support/:slug",
    "/blog/:slug",
  ],
};
