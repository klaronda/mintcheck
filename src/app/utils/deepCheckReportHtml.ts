/**
 * Strip CARFAX (or third-party) branding and inject MintCheck styles into report HTML.
 * Keeps report content; removes scripts and overrides colors/typography to match MintCheck.
 */

const MINTCHECK_REPORT_STYLES = `
  /* MintCheck palette - override report branding */
  body {
    background: #F8F8F7 !important;
    color: #1a1a1a !important;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif !important;
    line-height: 1.5 !important;
  }
  a { color: #3EB489 !important; }
  a:hover { opacity: 0.9; }
  h1, h2, h3, h4, h5, h6 { color: #1a1a1a !important; font-weight: 600 !important; }
  table { border-color: #e5e5e5 !important; }
  th, td { border-color: #e5e5e5 !important; }
  /* Hide common third-party branding */
  img[src*="carfax"], img[src*="CARFAX"], img[alt*="CARFAX"], img[alt*="Carfax"],
  .carfax-logo, [class*="carfax-logo"], [id*="carfax-logo"],
  footer a[href*="carfax"], .report-footer a[href*="carfax"],
  [class*="branding"], [id*="branding"] {
    display: none !important;
  }
  /* Optional: hide "Powered by" / "Report provided by" text */
  .powered-by, [class*="powered-by"], [class*="report-provided"] {
    display: none !important;
  }
`;

/**
 * Remove script tags (security) and inject MintCheck override styles.
 * Does not strip content—only scripts and branding elements (via CSS hide).
 */
export function stripBrandingAndApplyMintCheckStyle(html: string): string {
  if (!html?.trim()) return html;

  let out = html;

  // Remove script tags and their content
  out = out.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '');

  // Inject our style block: after <head> or at start of <body>
  const styleBlock = `<style id="mintcheck-report-overrides">${MINTCHECK_REPORT_STYLES}</style>`;
  if (out.includes('</head>')) {
    out = out.replace('</head>', `${styleBlock}</head>`);
  } else if (out.includes('<body')) {
    out = out.replace(/<body(\s[^>]*)?>/, (m) => `${m}${styleBlock}`);
  } else {
    out = styleBlock + out;
  }

  return out;
}
