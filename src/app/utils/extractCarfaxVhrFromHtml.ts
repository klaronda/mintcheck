/**
 * Extract CARFAX structured data (vhr) from report HTML.
 * The CARFAX HTML embeds JSON in a script: window.__INITIAL__DATA__ = { "vhr": { ... } };
 * Returns { vhr } for use with VehicleHistoryReport, or null if extraction fails.
 */
export function extractCarfaxVhrFromHtml(html: string): { vhr: unknown } | null {
  if (!html?.trim()) return null;

  const marker = 'window.__INITIAL__DATA__';
  const idx = html.indexOf(marker);
  if (idx === -1) return null;

  const afterMarker = html.slice(idx + marker.length);
  const eqMatch = afterMarker.match(/^\s*=\s*/);
  if (!eqMatch) return null;

  const jsonStartIdx = afterMarker.indexOf('{', eqMatch.length);
  if (jsonStartIdx === -1) return null;

  const jsonStart = jsonStartIdx;
  const str = afterMarker;
  let depth = 0;
  let inString = false;
  let escape = false;
  let jsonEnd = -1;

  for (let i = jsonStart; i < str.length; i++) {
    const c = str[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (c === '\\' && inString) {
      escape = true;
      continue;
    }
    if (c === '"') {
      inString = !inString;
      continue;
    }
    if (!inString) {
      if (c === '{') depth++;
      else if (c === '}') {
        depth--;
        if (depth === 0) {
          jsonEnd = i;
          break;
        }
      }
    }
  }

  if (jsonEnd === -1) return null;

  const jsonStr = str.slice(jsonStart, jsonEnd + 1);
  try {
    const parsed = JSON.parse(jsonStr) as { vhr?: unknown };
    if (parsed && typeof parsed.vhr === 'object' && parsed.vhr !== null) {
      return { vhr: parsed.vhr };
    }
  } catch {
    return null;
  }
  return null;
}
