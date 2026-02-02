/**
 * Strip CARFAX (or third-party) branding and inject MintCheck styles into report HTML.
 * Keeps report content; removes scripts and overrides colors/typography to match MintCheck.
 */

/** MintCheck-aligned disclaimer replacing the long CARFAX disclaimer. */
const MINTCHECK_DISCLAIMER =
  'This vehicle history report is based on information available to MintCheck at the time of the report. Not every accident or repair is reported. Use this report together with a vehicle inspection and test drive when deciding on a used vehicle.';

/** Top-of-report disclaimer (replaces glossary context). */
const TOP_DISCLAIMER_HTML = `<div class="mintcheck-top-disclaimer" style="font-size: 13px; color: #666666; line-height: 1.5; padding: 12px 16px; margin-bottom: 16px; background: #FCFCFB; border-left: 4px solid #3EB489; border-radius: 0 4px 4px 0;">Not every accident or repair is reported. This report is one tool—always get a vehicle inspection and test drive before buying.</div>`;

/** Regex: long CARFAX disclaimer (flexible date/time). */
const CARFAX_DISCLAIMER_REGEX =
  /This\s+CARFAX\s+Vehicle\s+History\s+Report\s+is\s+based\s+only\s+on\s+information\s+supplied\s+to\s+CARFAX\s+and\s+available\s+as\s+of[\s\S]*?to\s+make\s+a\s+better\s+decision\s+about\s+your\s+next\s+used\s+car\.?/gi;

/** Regex: Buyback Guarantee sentence (remove). */
const BUYBACK_GUARANTEE_REGEX =
  /This\s+vehicle\s+does\s+not\s+qualify\s+for\s+the\s+CARFAX\s+Buyback\s+Guarantee\.?/gi;

const MINTCHECK_REPORT_STYLES = `
  /* MintCheck palette - override report branding (Style Guide) */
  body {
    background: #F8F8F7 !important;
    color: #1A1A1A !important;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif !important;
    line-height: 1.5 !important;
  }
  a {
    color: #2D9970 !important;
    text-decoration: underline !important;
    text-underline-offset: 2px !important;
  }
  a:hover { opacity: 0.9; }
  h1, h2, h3, h4, h5, h6 { color: #1A1A1A !important; font-weight: 600 !important; }
  table { border-color: #E5E5E5 !important; }
  th, td { border-color: #E5E5E5 !important; }
  /* Mint green section headers (override blue) */
  th,
  [class*="section-header"], [class*="report-header"], [class*="header"],
  .header, [id*="header"] {
    background: #3EB489 !important;
    color: #ffffff !important;
    border-color: #2D9970 !important;
  }
  /* Hide common third-party branding */
  img[src*="carfax"], img[src*="CARFAX"], img[alt*="CARFAX"], img[alt*="Carfax"],
  .carfax-logo, [class*="carfax-logo"], [id*="carfax-logo"],
  footer a[href*="carfax"], .report-footer a[href*="carfax"],
  [class*="branding"], [id*="branding"] {
    display: none !important;
  }
  .powered-by, [class*="powered-by"], [class*="report-provided"] {
    display: none !important;
  }
  /* Hide glossary, follow us, signature, footer */
  footer, [class*="footer"], [class*="follow-us"], [class*="follow_us"],
  [class*="signature"], [class*="social-links"], [id*="glossary"],
  [class*="glossary"], .mintcheck-hidden {
    display: none !important;
  }
`;

/**
 * Remove script tags (security), replace CARFAX copy with MintCheck copy,
 * inject top disclaimer, and apply MintCheck override styles.
 */
export function stripBrandingAndApplyMintCheckStyle(html: string): string {
  if (!html?.trim()) return html;

  let out = html;

  // Remove script tags and their content
  out = out.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '');

  // Replace long CARFAX disclaimer with MintCheck copy
  out = out.replace(CARFAX_DISCLAIMER_REGEX, MINTCHECK_DISCLAIMER);

  // "reported to CARFAX" / "reported to Carfax" -> "reported to MintCheck"
  out = out.replace(/reported\s+to\s+Carfax/gi, 'reported to MintCheck');

  // Remove Buyback Guarantee sentence
  out = out.replace(BUYBACK_GUARANTEE_REGEX, '');

  // Blue header hex in HTML -> Mint green (inline styles / stylesheets in string)
  out = out.replace(/#0066cc/gi, '#3EB489');
  out = out.replace(/#0070c0/gi, '#3EB489');

  // Inject top disclaimer after <body> or <body ...>
  if (out.includes('<body')) {
    out = out.replace(/<body(\s[^>]*)?>/, (m) => `${m}${TOP_DISCLAIMER_HTML}`);
  } else {
    out = TOP_DISCLAIMER_HTML + out;
  }

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
