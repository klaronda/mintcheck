/**
 * Extract CARFAX structured data (vhr) from report HTML.
 * The CARFAX HTML embeds JSON in a script: window.__INITIAL__DATA__ = { "vhr": { ... } };
 * Returns { vhr } for use with VehicleHistoryReport, or null if extraction fails.
 * Handles live HTML with different whitespace/formatting (e.g. split across lines).
 */
export function extractCarfaxVhrFromHtml(html: string): { vhr: unknown } | null {
  if (!html?.trim()) return null;

  // Try exact marker first, then regex that allows whitespace (live HTML may be minified or split)
  const exactMarker = 'window.__INITIAL__DATA__';
  let idx = html.indexOf(exactMarker);
  let afterMarker: string;
  let skipLength: number;

  if (idx !== -1) {
    skipLength = exactMarker.length;
    afterMarker = html.slice(idx + skipLength);
  } else {
    const flexibleMatch = html.match(/\bwindow\s*\.\s*__INITIAL__DATA__\s*=\s*/);
    if (!flexibleMatch) return null;
    idx = flexibleMatch.index!;
    skipLength = flexibleMatch[0].length;
    afterMarker = html.slice(idx + skipLength);
  }

  const jsonStartIdx = afterMarker.search(/\{/);
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
