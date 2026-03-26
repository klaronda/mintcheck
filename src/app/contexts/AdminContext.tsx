import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

export interface Article {
  id: string;
  type: 'support' | 'blog';
  title: string;
  slug: string;
  cardDescription: string;
  summary: string;
  heroImage: string;
  body: string;
  category?: 'Device Help' | 'Using the App' | 'Vehicle Support';
  published: boolean;
  createdAt: string;
  updatedAt: string;
}

interface AdminContextType {
  articles: Article[];
  addArticle: (article: Omit<Article, 'id' | 'createdAt' | 'updatedAt'>) => void;
  updateArticle: (id: string, article: Partial<Article>) => void;
  deleteArticle: (id: string) => void;
  getArticle: (slug: string) => Article | undefined;
  getSupportArticles: () => Article[];
  getBlogArticles: () => Article[];
  getArticlesByCategory: (category: string) => Article[];
}

const AdminContext = createContext<AdminContextType | undefined>(undefined);

/** Bumped when bundled support articles change — refreshes merged localStorage */
const STORAGE_KEY = 'mintcheck_articles_v4';
const AUTH_KEY = 'mintcheck_admin_auth';

const SUPPORT_HERO_IMAGE = 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=1200&h=400&fit=crop';
const BUYER_PASS_HERO_IMAGE =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/buyer-pass_help.png';

function isMarkdownListLine(line: string): boolean {
  return line.startsWith('- ') || line.startsWith('* ');
}

function listItemInner(line: string): string {
  if (line.startsWith('- ')) return line.slice(2);
  if (line.startsWith('* ')) return line.slice(2);
  return line;
}

/** Escape HTML entities (for text nodes and attribute values). */
function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/** Inline **bold**, `[label](url)` links, and escaped plain text (for paragraph lines). */
function formatParagraphLine(line: string): string {
  const escape = escapeHtml;
  const linkRe = /\[([^\]]+)\]\(([^)]+)\)/g;
  let result = '';
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = linkRe.exec(line)) !== null) {
    result += formatPlainWithBold(line.slice(last, m.index));
    const href = m[2];
    const isExternal = /^https?:\/\//.test(href);
    result += isExternal
      ? `<a href="${escape(href)}" target="_blank" rel="noopener noreferrer">${escape(m[1])}</a>`
      : `<a href="${escape(href)}">${escape(m[1])}</a>`;
    last = linkRe.lastIndex;
  }
  result += formatPlainWithBold(line.slice(last));
  return result;
}

function formatPlainWithBold(s: string): string {
  if (!s) return '';
  const escape = escapeHtml;
  const parts = s.split(/(\*\*[^*]+\*\*)/g);
  return parts
    .map((p) => {
      if (/^\*\*[^*]+\*\*$/.test(p)) {
        return `<strong>${escape(p.slice(2, -2))}</strong>`;
      }
      return escape(p);
    })
    .join('');
}

/** Convert app-style markdown (bold, paragraphs, lists) to HTML for article body */
function markdownToHtml(md: string): string {
  const escape = escapeHtml;
  const normalized = md.trim().replace(/\r\n/g, '\n').replace(/\r/g, '\n');
  const blocks = normalized.split(/\n\n+/);
  const out: string[] = [];
  for (const block of blocks) {
    const lines = block.split('\n').map((l) => l.trim()).filter(Boolean);
    if (lines.length === 0) continue;
    const singleLine = lines.length === 1 && lines[0];
    if (singleLine && /^\*\*[^*]+\*\*$/.test(singleLine)) {
      out.push(`<h3>${escape(singleLine.slice(2, -2))}</h3>`);
      continue;
    }
    const listLines = lines.filter((l) => isMarkdownListLine(l));
    const otherLines = lines.filter((l) => !isMarkdownListLine(l));
    const listItemHtml = (l: string) => `<li>${formatParagraphLine(listItemInner(l))}</li>`;
    if (listLines.length === lines.length && listLines.length > 0) {
      out.push('<ul>' + listLines.map(listItemHtml).join('') + '</ul>');
      continue;
    }
    if (otherLines.length > 0) {
      const introHtml = otherLines.map((l) => formatParagraphLine(l)).join('\n');
      out.push('<p>' + introHtml.replace(/\n/g, '</p><p>') + '</p>');
    }
    if (listLines.length > 0) {
      out.push('<ul>' + listLines.map(listItemHtml).join('') + '</ul>');
    }
  }
  return out.join('');
}

function firstSummary(content: string, maxLen = 140): string {
  const plain = content.replace(/\*\*[^*]*\*\*/g, '').replace(/\n/g, ' ').trim();
  const match = plain.match(/^[^.!?]+[.!?]?/);
  const first = match ? match[0].trim() : plain.slice(0, maxLen);
  return first.length > maxLen ? first.slice(0, maxLen - 3) + '...' : first;
}

/**
 * Support articles — parity with iOS `SupportView.swift` + `OBDHelpSheet` in DeviceConnectionView.
 * Slugs match app `SupportArticle.id` where applicable.
 */
const APP_SUPPORT_ARTICLES: Array<{
  id: string;
  title: string;
  content: string;
  category: 'Device Help' | 'Using the App' | 'Vehicle Support';
  heroImage?: string;
}> = [
  {
    id: 'obd-port',
    title: 'Finding your OBD-II port',
    category: 'Device Help',
    content: `**Where is the OBD-II Port?**

The OBD-II port is a standardized 16-pin connector found in all cars manufactured after 1996. It's typically located under the dashboard on the driver's side, near the steering column.

**Common Locations**

- **Most Common:** Under the dashboard, left of the steering wheel
- **Alternative:** Under the dashboard, right of the steering wheel
- **Less Common:** Near the center console or behind the ashtray area
- **Rare:** Under the hood near the engine bay

**Tips for Finding It**

- Use a flashlight to look under the dashboard
- It's usually within arm's reach of the driver's seat
- Check your vehicle's owner manual for the exact location
- Some vehicles have a protective cover that needs to be removed

**Need more help?**

If you're having trouble locating the port, ask the seller or check online resources for your specific vehicle make and model.`,
  },
  {
    id: 'where-to-get-scanner',
    title: 'Where to get an OBD-II WiFi Scanner',
    category: 'Device Help',
    content: `To use MintCheck, you need a WiFi OBD-II scanner. It's a small device that plugs into your car's diagnostic port and sends data to your phone over WiFi.

**MintCheck Starter Kit – $34.99** (US shipping included)

The easiest way to get started is with the MintCheck Starter Kit. It includes a WiFi OBD-II scanner and a 60-day unlimited scanning pass so you can scan as many vehicles as you want. [Buy the MintCheck Starter Kit](/starter-kit).

**Will other scanners work?**

Yes. Any ELM327-compatible WiFi OBD-II scanner should work with MintCheck. Just make sure it connects via WiFi – Bluetooth scanners are not compatible.`,
  },
  {
    id: 'connect-scanner',
    title: 'How to connect your OBD-II scanner',
    category: 'Device Help',
    content: `Follow these steps to connect your OBD-II scanner and start a vehicle scan:

**Step 1: Locate the OBD-II port**
Find the port under the dashboard on the driver's side. See our "Finding your OBD-II port" article for detailed instructions.

**Step 2: Plug in the scanner**
Insert your OBD-II scanner firmly into the port. It should click into place.

**Step 3: Turn on the ignition**
Turn your vehicle's ignition to the "ON" position. The engine does not need to be running for most scans.

**Step 4: Connect to the scanner**

For WiFi scanners:
- Open your phone's Settings
- Go to WiFi settings
- Connect to the scanner's network (usually named "OBDII", "WiFi_OBD", or similar)
- Return to MintCheck

For Bluetooth scanners:
- Bluetooth car scanners are not currently supported by the MintCheck app.

**Step 5: Start the scan**
Tap "Start Scan" in MintCheck to begin the diagnostic check. The scan typically takes 30-60 seconds.

**Troubleshooting:**
- Make sure the scanner is fully inserted
- Ensure the ignition is on (not just accessories)
- Try reconnecting to the scanner's Wi-Fi
- If MintCheck can't reach your scanner, open **Settings** → **MintCheck**, turn on **Local Network**, or tap **Allow** when iOS asks during a scan
- Restart the scanner by unplugging and re-plugging it`,
  },
  {
    id: 'understanding-results',
    title: 'Understanding your scan results',
    category: 'Using the App',
    content: `After scanning a vehicle, MintCheck provides a comprehensive health report. Here's how to interpret your results:

**Overall Recommendation**

[[RECOMMENDATION_BADGES]]

Safe (Green): No significant issues detected. The vehicle's systems appear to be in good working order.

Caution (Yellow): Some concerns were found that warrant attention. Review the details carefully before making a decision.

Walk Away (Red): Significant issues detected. We recommend not purchasing this vehicle without a professional inspection or further investigation.

**What We Found**
This section summarizes the key findings from the scan, including:
- Diagnostic trouble codes (DTCs) if any
- Whether codes were recently cleared
- Estimated repair costs for any issues

**System Details**
Detailed information about each vehicle system:
- Engine: RPM, load, temperatures
- Fuel System: Fuel trims, fuel system status
- Emissions: Readiness monitors, oxygen sensors
- Electrical: Battery voltage, system status

**Vehicle Details**
Information about the vehicle including:
- Make, model, and year
- VIN (if provided)
- Fuel type and engine specifications

**More Model Details**
Free safety information from NHTSA including:
- Active recalls for this vehicle
- Crash test safety ratings`,
  },
  {
    id: 'buyer-pass',
    title: 'How the Buyer Pass works',
    category: 'Using the App',
    heroImage: BUYER_PASS_HERO_IMAGE,
    content: `**What it is**

The Buyer Pass is for people shopping for a used car who want to run MintCheck on many vehicles over a period of time—not just one car.

**What you get**

- **60 days** of access starting when your purchase is activated in the app.
- **Up to 10 full vehicle scans per calendar day.** The count resets each day.
- You can scan **different VINs**; you're not limited to a single vehicle like the free tier.

**Price**

**$14.99** for the full 60 days. You pay once through secure checkout in the browser, then return to MintCheck.

**Free scans vs Buyer Pass**

- **Free:** Up to **3 scans total**, tied to how the free tier works in the app (typically your first vehicle).
- **Buyer Pass:** Multiple vehicles, with the **10 scans per day** limit, for **60 days**.

**One-time scan**

If you only need **one** more scan and don't want a pass, you can buy a **single scan** in the app (In-App Purchase).

**After you buy**

When your pass activates, your **"Scans today"** counter resets so you start fresh at **0 / 10** for that day.

**Renewal**

You can renew from the dashboard or Settings when your pass is near the end or after it expires.

**Something wrong?**

If checkout succeeded but the app doesn't show an active pass within a few minutes, email **support@mintcheckapp.com** with the email you used to sign in.`,
  },
  {
    id: 'trouble-codes',
    title: 'What are trouble codes (DTCs)?',
    category: 'Vehicle Support',
    content: `Diagnostic Trouble Codes (DTCs) are standardized codes stored by your vehicle's computer when it detects a malfunction.

**Understanding code prefixes:**

P-codes (Powertrain): Engine, transmission, and drivetrain issues. These are the most common codes.

B-codes (Body): Issues with body systems like airbags, seat belts, and interior electronics.

C-codes (Chassis): Problems with ABS, traction control, and suspension systems.

U-codes (Network): Communication issues between the vehicle's computer modules.

**Code severity:**

Not all codes are equally serious:
- Some indicate minor issues that don't affect drivability
- Others point to significant problems requiring immediate attention
- Multiple related codes may indicate a single underlying issue

**What MintCheck provides:**

When we find trouble codes, we show:
- The code number and description
- Estimated repair cost range
- Severity level (how urgent the repair is)

**Important note:**

A code indicates a system malfunction was detected, but doesn't always pinpoint the exact failed component. Professional diagnosis may be needed for complex issues.`,
  },
  {
    id: 'recently-cleared',
    title: "Why does it say 'codes recently cleared'?",
    category: 'Vehicle Support',
    content: `When MintCheck detects that diagnostic codes were recently cleared, it means someone reset the vehicle's onboard computer memory.

**Why this matters:**

Clearing codes erases the vehicle's diagnostic history, which could hide:
- Previous warning lights or problems
- Recurring issues that keep coming back
- Problems the seller may not have disclosed

**Legitimate reasons for clearing codes:**

- After completing a repair (normal practice)
- After disconnecting the battery
- Following a recent service appointment

**Potentially concerning reasons:**

- Hiding problems before a sale
- Temporarily turning off the check engine light
- Avoiding disclosure of known issues

**What to do:**

1. Ask the seller directly why codes were cleared
2. Request service records showing recent repairs
3. Consider having the vehicle inspected by a mechanic
4. Drive the vehicle for a few days if possible - problems often resurface

**Our recommendation:**

We flag "recently cleared codes" as a caution because you can't see the full diagnostic history. It's not automatically a red flag, but it warrants additional questions before purchasing.`,
  },
  {
    id: 'faq',
    title: 'Frequently Asked Questions',
    category: 'Using the App',
    content: `**Do I need a special scanner?**
Any ELM327-compatible OBD-II scanner will work with MintCheck. We recommend WiFi scanners for the easiest connection experience. You can find compatible scanners for $15-30 online.

**Will this work on any car?**
MintCheck works with all vehicles from 1996 and newer sold in the United States. All these vehicles are required by law to have standardized OBD-II ports.

**How accurate are the scan results?**
The diagnostic data comes directly from the vehicle's computer, so it's as accurate as what a mechanic would see. The information reflects the current state of the vehicle's systems.

**Can I scan my own car?**
Absolutely! MintCheck is great for monitoring your own vehicle's health, not just for buying used cars. Regular scans can help you catch issues early.

**How long does a scan take?**
A typical scan takes 30-60 seconds. Some vehicles may take slightly longer depending on how many systems need to be checked.

**What if the scan finds problems?**
Review the details carefully. For minor issues, you may choose to proceed with the purchase and address them later. For significant problems, consider negotiating the price or walking away.

**Do scans expire?**
Scan results are kept for 180 days. After that, they're automatically deleted. You can always run a new scan on a vehicle.

**Can I share my scan results?**
Yes. From your results screen, tap **Share Report** once the scan has finished saving. You can email the report to yourself or anyone else (with an optional message) and optionally create a **shareable link** to a web page at mintcheckapp.com—recipients don't need the MintCheck app to view it. The page shows how fresh the scan is; for sharing with a seller or lender, it's best while the scan is still **current** (about two weeks from the scan date). If sending fails right after a scan, wait a moment and try again. You can manage shared links from **Settings** while signed in.

**What is Buyer Pass?**
Buyer Pass is a **60-day** subscription for shopping multiple used cars: up to **10 full scans per calendar day** (resets each day) and you can scan **different vehicles**—not limited to one car like the free tier. **$14.99** via secure checkout in the app. When your pass activates, your daily scan count typically starts fresh for that day.

**What is a one-time scan?**
If you've used your **free scans** and only need **one more** engine health check without a pass, you can buy a **single scan** for **$3.99** (In-App Purchase) from the dashboard. The credit applies the next time you start a scan.

**What is Deep Check?**
Deep Check is an **add-on** (separate from the OBD scan): you enter a **VIN** and get a **vehicle history–style report** in the browser—things like title signals, accident history, and recalls where data is available. **$9.99.** It complements your MintCheck scan; it doesn't replace a hands-on mechanical inspection.`,
  },
];

function buildSupportFromApp(): Article[] {
  const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);
  return APP_SUPPORT_ARTICLES.map((a) => ({
    id: a.id,
    type: 'support' as const,
    title: a.title,
    slug: a.id,
    cardDescription: firstSummary(a.content, 80),
    summary: firstSummary(a.content),
    heroImage: a.heroImage ?? SUPPORT_HERO_IMAGE,
    body: markdownToHtml(a.content),
    category: a.category,
    published: true,
    createdAt: fourteenDaysAgo.toISOString(),
    updatedAt: fourteenDaysAgo.toISOString(),
  }));
}

const DEFAULT_SUPPORT_ARTICLES = buildSupportFromApp();
const APP_SUPPORT_SLUGS = new Set(APP_SUPPORT_ARTICLES.map((a) => a.id));

const getInitialArticles = (): Article[] => {
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000);
  const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const blogArticles: Article[] = [
    {
      id: '3',
      type: 'blog',
      title: 'Understanding Your Car\'s Check Engine Light',
      slug: 'check-engine-light',
      cardDescription: 'What that warning light really means',
      summary: 'Learn what causes the check engine light to turn on and when you should be concerned.',
      heroImage: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=1200&h=400&fit=crop',
      body: '<h2>What Does It Mean?</h2><p>The check engine light is your car\'s way of telling you something needs attention.</p><h3>Common Causes</h3><ul><li>Loose gas cap</li><li>Oxygen sensor issues</li><li>Catalytic converter problems</li></ul>',
      published: true,
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    },
    {
      id: '4',
      type: 'blog',
      title: '5 Signs You Should Walk Away from a Used Car',
      slug: 'used-car-warning-signs',
      cardDescription: 'Red flags every buyer should know before purchasing',
      summary: 'Before you buy that used car, watch out for these warning signs that could save you thousands in repairs.',
      heroImage: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=1200&h=400&fit=crop',
      body: '<h2>Red Flags to Watch For</h2><p>When shopping for a used car, certain warning signs can indicate major problems ahead.</p><h3>1. Check Engine Light Is On</h3><p>If the check engine light is illuminated during your test drive, ask why. It could be something minor or a sign of serious issues.</p><h3>2. Excessive Engine Smoke</h3><p>Blue or white smoke from the exhaust often indicates engine problems that can be expensive to fix.</p><h3>3. Strange Noises</h3><p>Knocking, grinding, or squealing sounds shouldn\'t be ignored.</p><h3>4. Fluid Leaks</h3><p>Check under the car for oil, coolant, or transmission fluid leaks.</p><h3>5. Mismatched Service Records</h3><p>Incomplete or suspicious maintenance history is a major red flag.</p>',
      published: true,
      createdAt: oneDayAgo.toISOString(),
      updatedAt: oneDayAgo.toISOString(),
    },
    {
      id: '5',
      type: 'blog',
      title: 'How Often Should You Check Your Car\'s Diagnostics?',
      slug: 'diagnostic-check-frequency',
      cardDescription: 'A maintenance schedule for staying ahead of problems',
      summary: 'Regular diagnostic checks can help you catch problems early and save money on repairs.',
      heroImage: 'https://images.unsplash.com/photo-1625047509248-ec889cbff17f?w=1200&h=400&fit=crop',
      body: '<h2>The Smart Maintenance Schedule</h2><p>Staying on top of your vehicle\'s health doesn\'t have to be complicated.</p><h3>Monthly Quick Checks</h3><p>Do a quick diagnostic scan once a month to catch any new codes or issues.</p><h3>Before Long Trips</h3><p>Always run a diagnostic check before road trips to avoid breakdowns far from home.</p><h3>After Warning Lights</h3><p>Any time a warning light appears, scan immediately to understand what\'s wrong.</p><h3>During Oil Changes</h3><p>Make it a habit to check diagnostics when you change your oil every 3-6 months.</p>',
      published: true,
      createdAt: threeDaysAgo.toISOString(),
      updatedAt: threeDaysAgo.toISOString(),
    },
    {
      id: '6',
      type: 'blog',
      title: 'The Real Cost of Ignoring Car Problems',
      slug: 'cost-of-ignoring-problems',
      cardDescription: 'Why small issues become expensive repairs',
      summary: 'That small issue you\'re ignoring could turn into a major repair bill. Here\'s why catching problems early saves money.',
      heroImage: 'https://images.unsplash.com/photo-1523365237953-703b97e20c8f?w=1200&h=400&fit=crop',
      body: '<h2>Small Problems, Big Bills</h2><p>Ignoring minor car issues might seem like saving money, but it usually costs more in the long run.</p><h3>Example 1: The $20 vs $2,000 Problem</h3><p>A loose gas cap (free to fix) can trigger a check engine light. Ignoring it while an oxygen sensor fails could lead to catalytic converter damage costing $2,000+.</p><h3>Example 2: Oil Leaks</h3><p>A small oil leak might cost $100 to fix. Ignoring it until your engine runs dry? That\'s a $4,000+ engine replacement.</p><h3>The MintCheck Advantage</h3><p>With regular diagnostic checks, you can catch these issues early and fix them before they become expensive problems.</p>',
      published: true,
      createdAt: sevenDaysAgo.toISOString(),
      updatedAt: sevenDaysAgo.toISOString(),
    },
  ];

  const stored = localStorage.getItem(STORAGE_KEY);
  if (!stored) {
    return [...DEFAULT_SUPPORT_ARTICLES, ...blogArticles];
  }
  try {
    const parsed: Article[] = JSON.parse(stored);
    const rest = parsed.filter((a) => a.type !== 'support' || !APP_SUPPORT_SLUGS.has(a.slug));
    return [...DEFAULT_SUPPORT_ARTICLES, ...rest];
  } catch {
    return [...DEFAULT_SUPPORT_ARTICLES, ...blogArticles];
  }
};

export function AdminProvider({ children }: { children: ReactNode }) {
  const [articles, setArticles] = useState<Article[]>(getInitialArticles);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(articles));
  }, [articles]);

  const addArticle = (article: Omit<Article, 'id' | 'createdAt' | 'updatedAt'>) => {
    const newArticle: Article = {
      ...article,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    setArticles((prev) => [...prev, newArticle]);
  };

  const updateArticle = (id: string, updates: Partial<Article>) => {
    setArticles((prev) =>
      prev.map((article) =>
        article.id === id
          ? { ...article, ...updates, updatedAt: new Date().toISOString() }
          : article
      )
    );
  };

  const deleteArticle = (id: string) => {
    setArticles((prev) => prev.filter((article) => article.id !== id));
  };

  const getArticle = (slug: string) => {
    return articles.find((article) => article.slug === slug && article.published);
  };

  const getSupportArticles = () => {
    return articles.filter((article) => article.type === 'support' && article.published);
  };

  const getBlogArticles = () => {
    return articles
      .filter((article) => article.type === 'blog' && article.published)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  };

  const getArticlesByCategory = (category: string) => {
    return articles.filter(
      (article) => article.type === 'support' && article.category === category && article.published
    );
  };

  return (
    <AdminContext.Provider
      value={{
        articles,
        addArticle,
        updateArticle,
        deleteArticle,
        getArticle,
        getSupportArticles,
        getBlogArticles,
        getArticlesByCategory,
      }}
    >
      {children}
    </AdminContext.Provider>
  );
}

export function useAdmin() {
  const context = useContext(AdminContext);
  if (context === undefined) {
    throw new Error('useAdmin must be used within an AdminProvider');
  }
  return context;
}
export { AUTH_KEY };
