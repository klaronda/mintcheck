/**
 * Build a minimal vhr-like object from live CARFAX HTML when window.__INITIAL__DATA__
 * is not present (e.g. CheapCARFAX API response). This allows us to "pull content out"
 * and re-render with VehicleHistoryReport (MintCheck style) instead of showing the iframe.
 * Runs in browser (uses DOMParser).
 */

const VIN_REGEX = /\b([A-HJ-NPR-Z0-9]{17})\b/;
/** Title often: "CARFAX Vehicle History Report for this 2007 HONDA CR-V LX: JHLRE38307C062034" */
const TITLE_YMM_VIN = /for this\s+(.+?)\s*:\s*([A-HJ-NPR-Z0-9]{17})\s*$/i;
const TITLE_YMM_ONLY = /for this\s+(.+?)(?:\s*:\s*[A-HJ-NPR-Z0-9]{17})?\s*$/i;

export interface ParsedVhrResult {
  vhr: Record<string, unknown>;
}

/**
 * Parse HTML string into a minimal vhr structure for VehicleHistoryReport.
 * Returns null if we cannot build at least vehicle info (so we need yearMakeModel or parseable title).
 */
export function parseCarfaxHtmlToVhr(
  html: string,
  yearMakeModelFromApi?: string | null
): ParsedVhrResult | null {
  if (!html?.trim()) return null;
  if (typeof document === 'undefined' || typeof DOMParser === 'undefined') return null;

  const doc = new DOMParser().parseFromString(html, 'text/html');
  const titleEl = doc.querySelector('title');
  const titleText = (titleEl?.textContent ?? '').trim();

  let yearMakeModel = yearMakeModelFromApi?.trim() ?? '';
  let vin = '';

  const titleVinMatch = titleText.match(TITLE_YMM_VIN);
  if (titleVinMatch) {
    yearMakeModel = titleVinMatch[1].trim();
    vin = titleVinMatch[2];
  } else if (titleText) {
    const ymmOnly = titleText.match(TITLE_YMM_ONLY);
    if (ymmOnly) yearMakeModel = yearMakeModel || ymmOnly[1].trim();
    const vinInTitle = titleText.match(VIN_REGEX);
    if (vinInTitle) vin = vinInTitle[1];
  }
  if (!yearMakeModel && yearMakeModelFromApi) yearMakeModel = yearMakeModelFromApi.trim();

  if (!vin) {
    const bodyText = doc.body?.textContent ?? '';
    const vinMatch = bodyText.match(/\bVIN[:\s]+\s*([A-HJ-NPR-Z0-9]{17})\b/i) ?? bodyText.match(VIN_REGEX);
    if (vinMatch) vin = vinMatch[1];
  }

  if (!yearMakeModel && !vin) return null;

  const historyOverviewRows: { name: string; text: string }[] = [];

  const bodyText = doc.body?.innerText ?? doc.body?.textContent ?? '';
  const serviceMatch = bodyText.match(/(\d+)\s*Service\s+history\s+records?/i);
  if (serviceMatch) {
    historyOverviewRows.push({ name: 'service', text: `${serviceMatch[1]} Service history records` });
  }
  const ownersMatch = bodyText.match(/(\d+)\s*Previous\s+owners?/i);
  if (ownersMatch) {
    historyOverviewRows.push({ name: 'ownershipCount', text: `${ownersMatch[1]} Previous owners` });
  }
  if (/Personal\s+vehicle/i.test(bodyText)) {
    historyOverviewRows.push({ name: 'ownershipType', text: 'Personal vehicle' });
  }
  if (/Accident\s+reported/i.test(bodyText)) {
    historyOverviewRows.push({ name: 'accidentReported', text: 'Accident reported' });
  }
  const lastOdo = findLastOdometerReading(bodyText);
  if (lastOdo) {
    historyOverviewRows.push({ name: 'lastOdoReported', text: `${lastOdo} Last reported odometer reading` });
  }
  const stateMatch = bodyText.match(/Last\s+owned\s+in\s+([A-Z]{2})/i);
  if (stateMatch) {
    historyOverviewRows.push({ name: 'stateRegistered', text: `Last owned in ${stateMatch[1]}` });
  }
  if (hasActualBrandedTitle(bodyText)) {
    historyOverviewRows.push({ name: 'damageBrandedTitle', text: 'Branded title' });
  }

  const accidentRecords = deduplicateAccidentRecords(parseAccidentSection(doc));
  const additionalHistoryRows = parseAdditionalHistorySection(doc, bodyText);
  const titleHistoryRows = parseTitleHistorySection(doc, bodyText);
  const { ownershipRows, detailsBlocks } = parseOwnershipAndDetails(doc, bodyText, ownersMatch ? parseInt(ownersMatch[1], 10) : 0);

  const headerSection: Record<string, unknown> = {
    vehicleInformationSection: {
      yearMakeModel: yearMakeModel || undefined,
      vin: vin || undefined,
    },
    historyOverview: { rows: historyOverviewRows },
  };

  const vhr: Record<string, unknown> = {
    headerSection,
    titleHistorySection: { rows: titleHistoryRows },
    additionalHistorySection: { rows: additionalHistoryRows },
    ownershipHistorySection: { rows: ownershipRows },
    accidentDamageSection: { accidentDamageRecords: accidentRecords },
    detailsSection: { ownerBlocks: { ownerBlocks: detailsBlocks } },
  };

  return { vhr };
}

/**
 * True only when the report actually indicates a branded title (Salvage, Junk, Rebuilt).
 * Excludes negative phrasing like "No salvage reported", "No rebuilt title", "not a salvage".
 */
function hasActualBrandedTitle(bodyText: string): boolean {
  const lower = bodyText.toLowerCase();
  if (/no\s+salvage|no\s+rebuilt|no\s+junk|not\s+(?:a\s+)?salvage|not\s+rebuilt|no\s+branded|salvage\s+reported\s+to\s+no/i.test(lower)) return false;
  if (/\b(salvage|junk|rebuilt)\s+(?:title|designation|vehicle)/i.test(lower)) return true;
  if (/\btitle\s*[:\s]+\s*(salvage|junk|rebuilt)/i.test(lower)) return true;
  if (/\bbranded\s+title\b/i.test(lower) && !/no\s+branded/i.test(lower)) return true;
  return false;
}

/** Extract a canonical event description for dedupe: e.g. "Damage reported: minor damage". */
function canonicalEventTitle(rawTitle: string): string {
  const noise = /Event\s*\d+|View\s+More\s+Details|Damage\s+Severity\s+Scale|More\s+information|\d{1,2}\/\d{1,2}\/\d{2,4}/gi;
  const trimmed = rawTitle.replace(noise, ' ').replace(/\s+/g, ' ').trim();
  const match = trimmed.match(/(?:Damage|Accident|Collision|Airbag)[^.]*(?::\s*[^.]+)?/i)
    ?? trimmed.match(/(?:reported|minor|major|structural)[^.]*/i);
  return (match ? match[0] : trimmed).slice(0, 80) || 'Event reported';
}

/** Deduplicate accident records by date + canonical title; keep one per event and use canonical title for display. */
function deduplicateAccidentRecords(records: Record<string, unknown>[]): Record<string, unknown>[] {
  const byKey = new Map<string, Record<string, unknown>>();
  for (const r of records) {
    const date = String((r.date as string) ?? '').trim();
    const rawTitle = String((r.eventTitleText as { en?: string })?.en ?? '').trim();
    const canonical = canonicalEventTitle(rawTitle);
    const key = `${date}|${canonical}`;
    const existing = byKey.get(key);
    const rawLen = rawTitle.length;
    const existingRaw = existing ? String((existing.eventTitleText as { en?: string })?.en ?? '').length : 0;
    if (!existing || rawLen > existingRaw) {
      const groups = (r.comments as { commentsGroups?: { outerLine?: unknown; innerLines?: unknown[] }[] })?.commentsGroups ?? [];
      const firstGroup = groups[0];
      const innerLines = Array.isArray(firstGroup?.innerLines) ? firstGroup.innerLines : [];
      byKey.set(key, {
        date: r.date,
        eventTitleText: { en: canonical },
        comments: {
          commentsGroups: [{ outerLine: { commentsTextLine: { text: canonical } }, innerLines }],
        },
      });
    }
  }
  return Array.from(byKey.values());
}

/** Find the most likely "last reported" odometer value (prefer "last" context or last occurrence in doc). */
function findLastOdometerReading(bodyText: string): string | null {
  const allMatches: { value: string; index: number; hasLast: boolean }[] = [];
  const re = /(\d{1,3}(?:,\d{3})*)\s*(?:mi|miles?)(?:\s+(?:last\s+reported|odometer))?|(?:last\s+reported\s+odometer[^\d]*)(\d{1,3}(?:,\d{3})*)/gi;
  let m: RegExpExecArray | null;
  while ((m = re.exec(bodyText)) !== null) {
    const raw = (m[1] ?? m[2] ?? '').trim();
    const num = parseInt(raw.replace(/,/g, ''), 10);
    if (raw && !Number.isNaN(num) && num > 0 && num < 3000000) {
      const snippet = bodyText.slice(Math.max(0, m.index - 100), m.index + 120);
      const hasLast = /last\s+reported|odometer\s+reading|most\s+recent\s+odometer/i.test(snippet);
      allMatches.push({ value: raw, index: m.index, hasLast });
    }
  }
  const withLast = allMatches.filter((x) => x.hasLast);
  if (withLast.length > 0) return withLast[withLast.length - 1].value;
  if (allMatches.length > 0) return allMatches[allMatches.length - 1].value;
  return null;
}

/** Known Additional History row labels in CARFAX reports (order preserved). */
const ADDITIONAL_HISTORY_LABELS = [
  'Total Loss',
  'Structural Damage',
  'Airbag Deployment',
  'Odometer Rollback',
  'Accident / Damage',
  'Manufacturer Recall',
  'Fleet / Rental / Lease',
  'Service History',
] as const;

/**
 * Build Additional History rows (green-check style). Uses body text to find
 * "No ... reported" or recommendation text after each known label.
 */
function parseAdditionalHistorySection(doc: Document, bodyText: string): Record<string, unknown>[] {
  const rows: Record<string, unknown>[] = [];
  const normalizedBody = ` ${bodyText.replace(/\s+/g, ' ')} `;

  for (const label of ADDITIONAL_HISTORY_LABELS) {
    const labelIdx = normalizedBody.toLowerCase().indexOf(` ${label.toLowerCase()} `.replace(/\s+/g, ' '));
    if (labelIdx === -1) continue;

    const afterLabel = normalizedBody.slice(labelIdx + label.length + 1, labelIdx + 600);
    const noReportedMatch = afterLabel.match(/No\s+([^.]+?)\s+reported\s+to\s+(?:MintCheck|CARFAX|Carfax)/i)
      ?? afterLabel.match(/No\s+([^.]+?)\s+reported/i)
      ?? afterLabel.match(/No\s+([^.]+?)\s+found/i);
    const recommendMatch = afterLabel.match(/(?:MintCheck|We)\s+recommends?[^.]+\./i)
      ?? afterLabel.match(/recommend[s]?[^.]+(?:inspection|specialist)[^.]*\./i);
    const yesReportedMatch = afterLabel.match(/(?:Yes|Reported|Damage|Total\s+loss)\s+(?:reported|found|detected)/i);

    let description = '';
    let status: 'Normal' | 'Alert' = 'Normal';

    if (noReportedMatch) {
      description = `No ${noReportedMatch[1].trim()} reported to MintCheck.`;
    } else if (recommendMatch) {
      description = recommendMatch[0].trim().replace(/\b(CARFAX|Carfax)\b/gi, 'MintCheck');
      status = 'Normal';
    } else if (yesReportedMatch) {
      description = afterLabel.slice(0, 120).trim().replace(/\s+/g, ' ');
      if (description.length > 100) description = description.slice(0, 97) + '...';
      status = 'Alert';
    } else {
      const snippet = afterLabel.slice(0, 150).trim().replace(/\s+/g, ' ');
      if (snippet && !/^[\d\s]+$/.test(snippet)) {
        description = snippet.length > 120 ? snippet.slice(0, 117) + '...' : snippet;
      }
    }

    if (!description && label === 'Total Loss') description = 'No total loss reported to MintCheck.';
    if (!description && label === 'Structural Damage') description = 'MintCheck recommends that you have this vehicle inspected by a collision repair specialist.';

    rows.push({
      combinedCell: { status },
      translatedTitle: { en: label },
      description: {
        translatedTextDisplay: { translatedDisplay: { en: { text: description || `See report for ${label}.` } } },
      },
    });
  }

  if (rows.length === 0) {
    rows.push(
      {
        combinedCell: { status: 'Normal' },
        translatedTitle: { en: 'Total Loss' },
        description: {
          translatedTextDisplay: { translatedDisplay: { en: { text: 'No total loss reported to MintCheck.' } } },
        },
      },
      {
        combinedCell: { status: 'Normal' },
        translatedTitle: { en: 'Structural Damage' },
        description: {
          translatedTextDisplay: { translatedDisplay: { en: { text: 'MintCheck recommends that you have this vehicle inspected by a collision repair specialist.' } } },
        },
      }
    );
  }

  return rows;
}

/**
 * Build Title History rows from DOM or body text (e.g. "No issues", "Salvage", "Rebuilt").
 */
function parseTitleHistorySection(doc: Document, bodyText: string): Record<string, unknown>[] {
  const rows: Record<string, unknown>[] = [];
  const lower = bodyText.toLowerCase();

  if (/no\s+(?:title\s+)?issues|clean\s+title|no\s+problems\s+reported\s+to\s+(?:the\s+)?(?:dmv|title)/i.test(bodyText)) {
    rows.push({
      combinedCell: { status: 'Normal' },
      translatedTitle: { en: 'No title issues reported' },
      description: { translatedTextDisplay: { translatedDisplay: { en: { text: 'No issues reported to the DMV.' } } } },
    });
  }
  if (hasActualBrandedTitle(bodyText)) {
    const alertText = lower.includes('salvage') ? 'Salvage title reported' : lower.includes('rebuilt') ? 'Rebuilt title reported' : lower.includes('junk') ? 'Junk title reported' : 'Branded title reported';
    rows.push({
      combinedCell: { status: 'Alert', translatedText: { en: alertText } },
      translatedTitle: { en: alertText },
      description: { translatedTextDisplay: { translatedDisplay: { en: { text: 'Vehicle has a branded title. Have it inspected before purchase.' } } } },
    });
  }

  const titleHeadings = doc.querySelectorAll('h1, h2, h3, h4, [class*="section"], [class*="title"]');
  for (const h of Array.from(titleHeadings)) {
    const text = (h.textContent ?? '').toLowerCase();
    if (!text.includes('title') || text.includes('vehicle history report')) continue;
    const container = h.closest('section, [class*="section"], div') ?? h.parentElement;
    if (!container) continue;
    const blockText = (container.textContent ?? '').trim();
    const hasAlert = hasActualBrandedTitle(blockText);
    if (blockText.length > 50 && blockText.length < 2000 && (/(?:no\s+issues|clean|title)/i.test(blockText) || hasAlert)) {
      const titleLine = blockText.split(/\n/).find((l) => /no\s+issues|salvage|rebuilt|clean|branded|title/i.test(l.trim())) ?? blockText.slice(0, 80);
      if (rows.length === 0 || hasAlert) {
        rows.push({
          combinedCell: { status: hasAlert ? 'Alert' : 'Normal' },
          translatedTitle: { en: titleLine.trim().slice(0, 80) },
          description: { translatedTextDisplay: { translatedDisplay: { en: { text: blockText.slice(0, 200).replace(/\s+/g, ' ').trim() } } } },
        });
      }
      break;
    }
  }

  return rows;
}

/**
 * Try to parse an ownership/additional-history style table (row label + one cell per owner).
 */
function parseOwnershipTableFromDom(doc: Document, ownerCount: number): Record<string, unknown>[] {
  const n = Math.max(1, Math.min(ownerCount || 1, 15));
  const tables = doc.querySelectorAll('table');
  for (const table of Array.from(tables)) {
    const thead = table.querySelector('thead');
    const headerCells = thead?.querySelectorAll('th');
    const ownerCols = headerCells ? Array.from(headerCells).filter((th) => /Owner|Owners\s*\d/i.test(th.textContent ?? '')).length : 0;
    const colCount = ownerCols > 0 ? ownerCols : (headerCells?.length ?? 0) - 1;
    if (colCount < 1) continue;
    const tbody = table.querySelector('tbody');
    const rows = tbody?.querySelectorAll('tr') ?? table.querySelectorAll('tr');
    const parsed: Record<string, unknown>[] = [];
    for (const tr of Array.from(rows)) {
      const tds = tr.querySelectorAll('td');
      if (tds.length < 2) continue;
      const firstCell = (tds[0].textContent ?? '').trim();
      if (!firstCell || firstCell.length > 100) continue;
      const cells = Array.from(tds).slice(1, 1 + n).map((td) => {
        const text = (td.textContent ?? '').trim();
        const isCheck = /✓|✔|yes|check|passed/i.test(text) || (text === '' && td.querySelector('svg, [class*="check"], [class*="icon"]'));
        const isNo = /no|—|–|-|none/i.test(text) && text.length < 10;
        return {
          translatedText: { en: text || (isCheck ? 'Yes' : isNo ? 'No' : '—') },
          emptyCell: !text && !isCheck,
        };
      });
      while (cells.length < n) cells.push({ translatedText: { en: '—' }, emptyCell: true });
      parsed.push({
        description: { translatedTextDisplay: { translatedDisplay: { en: { text: firstCell } } } },
        cells,
      });
    }
    if (parsed.length > 0) return parsed;
  }
  return [];
}

/**
 * Parse Ownership History table rows and Detailed History owner blocks from the report.
 * Uses owner count from overview and scans for "Owner 1", "Owner 2", dates and events.
 */
function parseOwnershipAndDetails(
  doc: Document,
  bodyText: string,
  ownerCount: number
): { ownershipRows: Record<string, unknown>[]; detailsBlocks: Record<string, unknown>[] } {
  const n = Math.max(1, Math.min(ownerCount || 1, 15));
  let ownershipRows = parseOwnershipTableFromDom(doc, ownerCount);
  const detailsBlocks: Record<string, unknown>[] = [];

  if (ownershipRows.length === 0) {
    const rowLabels = ['Length of ownership', 'Miles driven per year', 'Vehicle use'];
    for (const label of rowLabels) {
      const cells = Array.from({ length: n }, () => ({ translatedText: { en: '—' }, emptyCell: true }));
      ownershipRows.push({
        description: { translatedTextDisplay: { translatedDisplay: { en: { text: label } } } },
        cells,
      });
    }
  }

  const ownerSectionHeadings = doc.querySelectorAll('h1, h2, h3, h4, [class*="section"], [class*="owner"], [class*="Owner"]');
  const ownerBlocks: { label: string; year?: string; type?: string; events: { date: string; text: string }[] }[] = [];

  for (const h of Array.from(ownerSectionHeadings)) {
    const headingText = (h.textContent ?? '').trim();
    const ownerMatch = headingText.match(/Owner(?:s)?\s*(\d+(?:\s*[-–]\s*\d+)?)/i) ?? headingText.match(/Owner\s*(\d+)/i);
    if (!ownerMatch) continue;
    const container = h.closest('section, [class*="section"], div') ?? h.parentElement;
    if (!container) continue;
    const blockText = (container.textContent ?? '').trim();
    if (blockText.length > 500) continue;
    const yearMatch = blockText.match(/(?:purchased|owned)\s*(?:in|from)?\s*(\d{4})/i) ?? blockText.match(/\b(19|20)\d{2}\b/);
    const typeMatch = blockText.match(/personal|lease|rental|fleet|commercial/i);
    const dateLines = blockText.match(/\d{1,2}\/\d{1,2}\/\d{2,4}[^\n]*/g) ?? [];
    const events = dateLines.slice(0, 8).map((line) => {
      const dateMatch = line.match(/(\d{1,2}\/\d{1,2}\/\d{2,4})/);
      const date = dateMatch ? dateMatch[1] : '';
      const text = line.replace(/^\d{1,2}\/\d{1,2}\/\d{2,4}\s*/, '').trim().slice(0, 120);
      return { date, text: text || 'Event reported' };
    });
    ownerBlocks.push({
      label: ownerMatch[0],
      year: yearMatch ? yearMatch[0].replace(/.*?(\d{4}).*/, '$1') : undefined,
      type: typeMatch ? typeMatch[0] : 'Personal',
      events,
    });
  }

  if (ownerBlocks.length === 0 && (ownerCount > 0 || /Owner\s*1|Previous\s+owners/i.test(bodyText))) {
    for (let i = 0; i < Math.min(n, 3); i++) {
      ownerBlocks.push({
        label: i === 0 && n > 1 ? 'Owners 1-2' : `Owner ${i + 1}`,
        events: [],
      });
    }
  }

  for (const block of ownerBlocks.slice(0, 10)) {
    const records = block.events.map((ev) => ({
      dateDisplay: ev.date,
      comments: {
        commentsGroups: [{ outerLine: { commentsTextLine: { text: ev.text } }, innerLines: [] }],
      },
    }));
    detailsBlocks.push({
      tab: {
        translatedOwner: { en: block.label },
        purchaseYear: block.year ? { purchaseYear: block.year } : undefined,
        ownerType: { translatedOwnerType: { en: block.type ?? 'Personal vehicle' } },
      },
      records: { records },
    });
  }

  return { ownershipRows, detailsBlocks };
}

function parseAccidentSection(doc: Document): Record<string, unknown>[] {
  const records: Record<string, unknown>[] = [];
  const bodyText = doc.body?.innerText ?? doc.body?.textContent ?? '';
  const hasAccidentInReport = /Accident\s+reported|accident|collision|damage/i.test(bodyText);

  const headings = doc.querySelectorAll('h1, h2, h3, h4, [class*="section"], [class*="header"]');
  for (let i = 0; i < headings.length; i++) {
    const h = headings[i];
    const text = (h.textContent ?? '').toLowerCase();
    if (!text.includes('accident') && !text.includes('damage')) continue;
    const container = h.closest('section, [class*="section"], div') ?? h.parentElement;
    if (!container) continue;
    const allBlocks = container.querySelectorAll('[class*="event"], [class*="record"], [class*="accident"]');
    const leafBlocks = Array.from(allBlocks).filter((block) => {
      const nested = block.querySelectorAll('[class*="event"], [class*="record"], [class*="accident"]');
      return nested.length === 0;
    });
    const toProcess = leafBlocks.length > 0 ? leafBlocks : Array.from(allBlocks);
    for (const block of toProcess) {
      const blockText = (block.textContent ?? '').trim();
      if (!blockText || blockText.length > 1500) continue;
      const dateMatch = blockText.match(/(\d{1,2}\/\d{1,2}\/\d{2,4})/);
      const hasAccident = /accident|collision|damage|airbag/i.test(blockText);
      if (!hasAccident && !dateMatch) continue;
      const lines = blockText.split(/\n/).map((s) => s.trim()).filter(Boolean);
      const titleLine = lines.find((l) => /(?:Damage|Accident|Collision)\s+reported|minor\s+damage|major\s+damage/i.test(l))
        ?? lines.find((l) => /accident|collision|damage|reported/i.test(l))
        ?? lines[0];
      const bulletLines = lines.filter((l) => l.startsWith('-') || l.startsWith('•')).map((l) => l.replace(/^[-•]\s*/, ''));
      const outerLine = titleLine ?? 'Event reported';
      const innerLines = bulletLines.slice(0, 10).map((t) => ({ commentsTextLine: { text: t, alert: false } }));
      records.push({
        date: dateMatch ? dateMatch[1] : '',
        eventTitleText: { en: outerLine },
        comments: {
          commentsGroups: [{ outerLine: { commentsTextLine: { text: outerLine } }, innerLines }],
        },
      });
    }
    if (records.length > 0) break;
  }
  if (records.length === 0 && hasAccidentInReport) {
    records.push({
      date: '',
      eventTitleText: { en: 'Accident reported' },
      comments: { commentsGroups: [{ outerLine: { commentsTextLine: { text: 'Accident reported' } }, innerLines: [] }] },
    });
  }
  return records;
}
