/**
 * Transform CARFAX report HTML for MintCheck iframe: apply exactly 17 changes in order.
 * Input: raw response HTML as received. Output: rebranded HTML with MintCheck header/footer.
 * No other changes — only these steps so report structure (e.g. table cells) stays intact.
 *
 * When new CARFAX HTML breaks the iframe: fix selectors and CSS in this file.
 * Check (1) order of operations in stripBrandingAndApplyMintCheckStyle,
 * (2) regexes / removeOneOuterDiv / removeOneOuterDivById / removeOneSectionById,
 * (3) MINTCHECK_STYLES rules for new classes. Test with a report that uses the iframe
 * (e.g. one without __INITIAL__DATA__).
 */

const MINTCHECK_LOGO_URL =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo-text/lockup-white.svg';

const STICKY_HEADER_HTML = `<div class="mintcheck-iframe-header" style="position:sticky;top:0;z-index:999;background:#3FB488;padding:16px 24px;margin:0 -24px 0 -24px;display:flex;align-items:center;gap:20px;flex-wrap:wrap;box-sizing:border-box;"><img src="${MINTCHECK_LOGO_URL}" alt="MintCheck" style="height:40px;width:auto;max-width:180px;flex-shrink:0;display:block;" /><p style="margin:0;font-size:13px;color:rgba(255,255,255,0.95);line-height:1.5;flex:1;min-width:200px;">Not every accident or repair is reported. This report is one tool—always get a vehicle inspection and test drive before buying. Vehicle history data provided by our partners at CARFAX.</p></div>`;

const FOOTER_HTML = `<footer class="mintcheck-report-footer" style="margin-top:24px;padding:16px 0;font-size:11px;color:#666;line-height:1.5;">
<p style="margin:0 0 8px 0;">CARFAX DEPENDS ON ITS SOURCES FOR THE ACCURACY AND RELIABILITY OF ITS INFORMATION. THEREFORE, NO RESPONSIBILITY IS ASSUMED BY CARFAX OR ITS AGENTS FOR ERRORS OR OMISSIONS IN THIS REPORT. CARFAX FURTHER EXPRESSLY DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.</p>
<p style="margin:0;">© 2026 CARFAX, Inc., part of S&P Global. All rights reserved.</p>
<p style="margin:4px 0 0 0;">Report generated ${new Date().toLocaleString()}</p>
</footer>`;

const CLOSER_HTML = `<div class="mintcheck-closer" style="margin-top:24px;padding:24px 20px;text-align:center;background:#3FB488;border-radius:4px;"><img src="${MINTCHECK_LOGO_URL}" alt="MintCheck" style="height:32px;width:auto;max-width:140px;display:inline-block;filter:brightness(0) invert(1);" /></div>`;

/** CSS: hide report header, info icons, non-MintCheck images; section headers and badges to mint; reduce space under sticky header. */
const MINTCHECK_STYLES = `
  body { background:#F8F8F7 !important; color:#1A1A1A !important; padding-left:24px !important; padding-right:24px !important; padding-top:0 !important; margin:0 !important; }
  .mintcheck-iframe-header + * { margin-top:8px !important; }
  [class*="section-header-logo"], [class*="sectionHeaderLogo"], [class*="report-header-logo"], [class*="reportHeaderLogo"],
  [class*="info-icon"], [class*="infoIcon"], [aria-label*="info"], [title*="information"] { display:none !important; }
  img:not([src*="lockup-white.svg"]) { display:none !important; }
  .mintcheck-report-footer, .mintcheck-closer { display:block !important; }
  #history-overview { padding-left:16px !important; padding-right:16px !important; }
  .history-overview-cell { padding-left:16px !important; padding-right:16px !important; margin-top:2px !important; margin-bottom:2px !important; min-height:0 !important; height:auto !important; padding-top:6px !important; padding-bottom:6px !important; }
  .history-overview-text-cell { min-height:0 !important; line-height:1.4 !important; }
  .history-overview-text-cell::before { content:"• " !important; margin-right:6px !important; }
  .summary-section-logo-text { padding-left:16px !important; padding-right:16px !important; }
  #history-overview > span, #history-overview > a.visually-hidden { display:none !important; }
  .section-header { background:#3FB488 !important; color:#fff !important; }
  .section-header .section-header-title-text, .section-header .section-header-subtitle-text { color:rgba(255,255,255,0.95) !important; }
  .cfx-icon__chevronRight, .history-overview-chevron-right, [class*="chevronRight"], [class*="chevron-right"] { display:none !important; }
  .history-overview-icon-cell { display:none !important; }
  .help-center-block { display:none !important; }
  button.cip-tab-link, a.cip-tab-link { color:#1a1a1a !important; text-decoration:none !important; }
  .slider-bar { fill:#3FB488 !important; }
  [class*="severity-scale"] .slider-bar, .severity-scale-header .slider-bar { fill:#fff !important; }
  .arrows-container-wrapper { padding-left:16px !important; padding-right:16px !important; }
  .arrows-container-wrapper .arrows-container,
  .arrows-container-wrapper .arrows-container-arrows,
  .arrows-container-wrapper .arrows-container-arrow { padding-left:16px !important; padding-right:16px !important; }
  .cfx-icon__infoCircleOutline, .more-information-modal { display:none !important; }
  button.cip-tab-link, a.cip-tab-link { pointer-events:none !important; cursor:default !important; color:#1a1a1a !important; text-decoration:none !important; }
  /* Reliability section: structure and mint styling when CARFAX HTML is unstyled */
  .reliability-section-content { margin:16px 0 !important; padding:0 !important; }
  .reliability-forecast-title { font-size:1.1rem !important; font-weight:600 !important; color:#1A1A1A !important; margin-bottom:12px !important; }
  .reliability-forecast-title span { display:inline-block !important; }
  .reliability-slider-container { margin:12px 0 16px 0 !important; }
  .product-slider { display:flex !important; width:100% !important; gap:0 !important; border-radius:4px !important; overflow:hidden !important; border:1px solid #E5E5E5 !important; }
  .product-slider_segment { flex:1 !important; text-align:center !important; min-width:0 !important; }
  .product-slider_bar { height:8px !important; min-height:8px !important; }
  .product-slider_bar__fair { background:#E8E8E8 !important; }
  .product-slider_bar__good { background:#B8E6D5 !important; }
  .product-slider_bar__great { background:#3FB488 !important; position:relative !important; }
  .product-slider_dot { position:absolute !important; right:4px !important; top:50% !important; transform:translateY(-50%) !important; width:10px !important; height:10px !important; border-radius:50% !important; background:#fff !important; border:2px solid #3FB488 !important; box-sizing:border-box !important; }
  .product-slider_text { font-size:0.85rem !important; color:#1A1A1A !important; margin-top:4px !important; padding:0 4px !important; }
  .product-slider_text strong { color:#3FB488 !important; }
  .reliability-foxpert { margin:16px 0 !important; }
  .call-out-medium.reliability-foxpert-textbox { background:#E6F4EE !important; border-left:4px solid #3FB488 !important; padding:12px 16px !important; border-radius:0 4px 4px 0 !important; color:#1A1A1A !important; font-size:0.95rem !important; line-height:1.5 !important; }
  .reliability-impact-factors-container { margin-top:20px !important; }
  .reliability-impact-factors-header { font-size:1rem !important; font-weight:600 !important; color:#1A1A1A !important; margin-bottom:12px !important; }
  .reliability-impact-factors-header span span { color:#3FB488 !important; }
  .reliability-impact-factors-rows { display:flex !important; flex-direction:column !important; gap:8px !important; }
  .reliablity-impact-factor-row { background:#F8F8F7 !important; padding:10px 14px !important; border-radius:4px !important; border:1px solid #E5E5E5 !important; }
  .reliablity-impact-factor-text-container div:first-child { font-size:0.95rem !important; color:#1A1A1A !important; }
  .impact-subtext { font-size:0.85rem !important; color:#666 !important; margin-top:2px !important; }
`;

/**
 * Remove first outer div whose class contains classFragment (match by depth).
 */
function removeOneOuterDiv(html: string, classFragment: string): string {
  const escaped = classFragment.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const openRe = new RegExp(
    `<div\\s+[^>]*class\\s*=\\s*["'][^"']*${escaped}[^"']*["'][^>]*>`,
    'i'
  );
  const m = html.match(openRe);
  if (!m || m.index === undefined) return html;
  const start = m.index;
  let pos = start + m[0].length;
  let depth = 1;
  while (pos < html.length && depth > 0) {
    const nextDiv = html.indexOf('<div', pos);
    const nextClose = html.indexOf('</div>', pos);
    if (nextClose === -1) break;
    if (nextDiv !== -1 && nextDiv < nextClose) {
      depth += 1;
      pos = nextDiv + 4;
    } else {
      depth -= 1;
      pos = nextClose + 6;
    }
  }
  return html.slice(0, start) + html.slice(pos);
}

/**
 * Remove first outer div whose id attribute equals or contains idFragment (match by depth).
 */
function removeOneOuterDivById(html: string, idFragment: string): string {
  const escaped = idFragment.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const openRe = new RegExp(
    `<div\\s+[^>]*id\\s*=\\s*["'][^"']*${escaped}[^"']*["'][^>]*>`,
    'i'
  );
  const m = html.match(openRe);
  if (!m || m.index === undefined) return html;
  const start = m.index;
  let pos = start + m[0].length;
  let depth = 1;
  while (pos < html.length && depth > 0) {
    const nextDiv = html.indexOf('<div', pos);
    const nextClose = html.indexOf('</div>', pos);
    if (nextClose === -1) break;
    if (nextDiv !== -1 && nextDiv < nextClose) {
      depth += 1;
      pos = nextDiv + 4;
    } else {
      depth -= 1;
      pos = nextClose + 6;
    }
  }
  return html.slice(0, start) + html.slice(pos);
}

/**
 * Remove first <section id="...idFragment..."> ... </section> (single section, no nesting).
 */
function removeOneSectionById(html: string, idFragment: string): string {
  const escaped = idFragment.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const openRe = new RegExp(
    `<section\\s+[^>]*id\\s*=\\s*["'][^"']*${escaped}[^"']*["'][^>]*>`,
    'i'
  );
  const m = html.match(openRe);
  if (!m || m.index === undefined) return html;
  const start = m.index;
  const afterOpen = start + m[0].length;
  const endTag = html.indexOf('</section>', afterOpen);
  if (endTag === -1) return html;
  return html.slice(0, start) + html.slice(endTag + '</section>'.length);
}

export function stripBrandingAndApplyMintCheckStyle(html: string): string {
  if (!html?.trim()) return html;

  // Start from the response HTML exactly as received; apply only these 17 steps.
  let out = html;

  // ——— 1. Remove scripts (security) ———
  out = out.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '');

  // ——— 2. Remove specific HTML blocks (do not replace text inside them) ———
  // Banner and report header (top bar with logo / Run NMVTIS) — removes gap
  out = removeOneOuterDivById(out, 'banner-and-header-spacing-wrapper');
  // Item 6: buyback guarantee module — single div.buyback-guarantee-row-cell
  out = removeOneOuterDiv(out, 'buyback-guarantee-row-cell');
  // Item 15: glossary section
  out = removeOneSectionById(out, 'glossary-section');
  // Item 14: price bubble
  out = removeOneOuterDiv(out, 'report-price-bubble');
  // Item 13: View Details button in H1
  out = out.replace(
    /<a\s+[^>]*class\s*=\s*["'][^"']*view-details-button[^"']*["'][^>]*>[\s\S]*?<\/a>/gi,
    ''
  );
  // Item 7: Guaranteed language divs
  out = out.replace(
    /<div\s+[^>]*class\s*=\s*["'][^"']*common-section-cell-text-guaranteed[^"']*["'][^>]*>\s*Guaranteed\s*<\/div>/gi,
    ''
  );
  // Help center block (Have Questions? carfax.com / carfaxonline.com)
  out = removeOneOuterDiv(out, 'help-center-block');

  // ——— 3. Item 11: Remove "Glossary" span in section headers ———
  out = out.replace(/<span>Glossary<\/span>/gi, '');

  // ——— 4. Item 12: Remove all ™ ———
  out = out.replace(/™/g, '');

  // ——— 5. Item 9: Remove all links — <a>inner</a> → inner (loop until no <a) ———
  while (/<a\b[\s\S]*?<\/a>/i.test(out)) {
    out = out.replace(/<a\b[^>]*>([\s\S]*?)<\/a>/gi, '$1');
  }

  // Original warranty line: make plain text (strip button/link wrapper)
  out = out.replace(
    /<(button|a)\b[^>]*>\s*Original warranty estimated to have expired\.\s*<\/\1>/gi,
    'Original warranty estimated to have expired.'
  );
  // Remove "View Details" and "View More Details" text (links don't work)
  out = out.replace(/\bView Details\b/gi, '');
  out = out.replace(/\bView More Details\b/gi, '');

  // ——— 6. Item 1: #3F77D1 → Mint #3FB488 ———
  out = out.replace(/#3F77D1/gi, '#3FB488');

  // ——— 7. Item 10: #F3F8FD → Safe background #E6F4EE ———
  out = out.replace(/#F3F8FD/gi, '#E6F4EE');

  // ——— 7b. Additional blue → Mint: rect fill, circle stroke (#1976D2); severity slider (#3777BC)
  out = out.replace(/#1976D2/gi, '#3FB488');
  out = out.replace(/#3777BC/gi, '#3FB488');

  // ——— 8. Item 3: Remove PNG/SVG (and common image) tags from markup (before injecting our logo) ———
  out = out.replace(/<img\b[^>]*\bsrc\s*=\s*["'][^"']*\.(png|svg|jpg|jpeg|gif|webp)["'][^>]*\/?>/gi, '');

  // ——— 9. Item 16: Remove old footer now (while text still says "CARFAX DEPENDS") so we can match it ———
  out = out.replace(/<footer\b[^>]*>[\s\S]*?<\/footer>/gi, '');
  out = out.replace(
    /<(div|section)\b[^>]*>[\s\S]*?CARFAX DEPENDS ON ITS SOURCES[\s\S]*?all rights reserved\.[\s\S]*?<\/\1>/gi,
    ''
  );

  // ——— 10. Item 5: CARFAX → MintCheck (body only; we inject header/footer next with "CARFAX" verbatim) ———
  out = out.replace(/\bCARFAX\b/g, 'MintCheck');
  out = out.replace(/\bCarfax\b/g, 'MintCheck');

  // ——— 11. Items 2 + 4: Sticky header — inject at start of <body>; CSS hides report's sticky header ———
  if (out.includes('<body')) {
    out = out.replace(/<body(\s[^>]*)?>/, (_, rest) => `<body${rest || ''}>${STICKY_HEADER_HTML}`);
  } else {
    out = STICKY_HEADER_HTML + out;
  }

  // ——— 12. Item 8: Info icons — hidden via MINTCHECK_STYLES ———

  // ——— 13. Item 16 + 17: Inject new footer (verbatim CARFAX) + MintCheck closer before </body> ———
  if (out.includes('</body>')) {
    out = out.replace('</body>', `${FOOTER_HTML}${CLOSER_HTML}</body>`);
  } else {
    out = out + FOOTER_HTML + CLOSER_HTML;
  }

  // ——— 14. Inject global CSS (after </head> or start of body); items 16+17 done above ———
  const styleBlock = `<style id="mintcheck-report-overrides">${MINTCHECK_STYLES}</style>`;
  if (out.includes('</head>')) {
    out = out.replace('</head>', `${styleBlock}</head>`);
  } else if (out.includes('<body')) {
    out = out.replace(/<body(\s[^>]*)?>/, (m) => m + styleBlock);
  } else {
    out = styleBlock + out;
  }

  return out;
}
