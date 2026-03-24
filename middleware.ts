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
}

export const config = {
  matcher: ["/report/:path*", "/deep-check/report/:path*"],
};
