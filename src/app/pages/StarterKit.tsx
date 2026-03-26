import { useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { ShieldCheck, Zap, Plug, Scan, FileText, ChevronDown, Apple, Wifi } from 'lucide-react';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';

const SCANNER_IMG =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/Product/MC-01a.png';

const FAQ_ITEMS = [
  {
    q: 'What exactly is included?',
    a: 'The MintCheck Starter Kit includes one Wi-Fi ELM327 OBD-II scanner and a 60-day pass that lets you scan unlimited vehicles with the MintCheck iOS app.',
  },
  {
    q: 'How long does shipping take?',
    a: 'Orders typically ship within 2–3 business days. Standard delivery within the US is 5–7 business days after shipment. Shipping is included in the price ($34.99).',
  },
  {
    q: 'Can I return it?',
      a: "Yes. If you’re not satisfied, you can return the unopened scanner within 30 days for a full refund. The 60-day pass is non-refundable once activated.",
  },
  {
    q: 'Why Wi-Fi and not Bluetooth?',
    a: 'MintCheck communicates with the scanner over a local Wi-Fi connection for fast, reliable data transfer. Bluetooth OBD-II scanners are not compatible.',
  },
  {
    q: 'What happens after the 60-day pass expires?',
    a: 'You keep the scanner. You can purchase individual scans or renew with another pass directly in the MintCheck app.',
  },
  {
    q: 'Which cars are compatible?',
    a: 'MintCheck works with any car or light truck sold in the US from 1996 onward (OBD-II compliant). Most vehicles worldwide from 2005+ are also supported.',
  },
  {
    q: 'Do I need to create an account?',
    a: "You can purchase the Starter Kit without an account. You’ll need a free MintCheck account to use the app and activate your 60-day pass.",
  },
];

function FaqItem({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="border-b border-border">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between py-5 text-left gap-4"
      >
        <span className="text-lg" style={{ fontWeight: 600 }}>{q}</span>
        <ChevronDown
          className={`w-5 h-5 shrink-0 text-muted-foreground transition-transform duration-200 ${open ? 'rotate-180' : ''}`}
        />
      </button>
      {open && (
        <p className="pb-5 text-muted-foreground leading-relaxed pr-8">{a}</p>
      )}
    </div>
  );
}

const CHECKOUT_URL = 'https://buy.stripe.com/aFaaEXcHC0Ih7tX215dby03';

export default function StarterKit() {
  const buyButton = (extraClass = '') => (
    <a
      href={CHECKOUT_URL}
      className={`inline-flex items-center justify-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90 ${extraClass}`}
      style={{ fontWeight: 600 }}
    >
      Buy Starter Kit – $34.99
    </a>
  );

  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>MintCheck Starter Kit – Scanner + 60-Day Pass | $34.99</title>
        <meta
          name="description"
          content="Get a Wi-Fi OBD-II scanner and 60-day unlimited scanning pass. Know the real health of any car in about 30 seconds. $34.99 with US shipping included."
        />
        <link rel="canonical" href="https://mintcheckapp.com/starter-kit" />
        <meta property="og:url" content="https://mintcheckapp.com/starter-kit" />
        <meta property="og:type" content="product" />
        <meta property="og:title" content="MintCheck Starter Kit – $34.99" />
        <meta
          property="og:description"
          content="Wi-Fi scanner + 60-day unlimited scanning pass. Know the real health of any car."
        />
        <meta
          property="og:image"
          content="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/Product/MC-01a.png"
        />
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content="MintCheck Starter Kit – $34.99" />
        <meta name="twitter:description" content="Wi-Fi scanner + 60-day unlimited scanning pass. Know the real health of any car." />
        <meta name="twitter:image" content="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/Product/MC-01a.png" />
      </Helmet>

      <Navbar />

      {/* ───── Hero ───── */}
      <section className="border-b border-border">
        <div className="max-w-6xl mx-auto px-6 py-20 md:py-28">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div className="space-y-6">
              <h1 className="text-4xl md:text-5xl tracking-tight" style={{ fontWeight: 600 }}>
                MintCheck Starter Kit
              </h1>
              <p className="text-xl text-muted-foreground leading-relaxed">
                Wi-Fi scanner + 60-day pass – scan unlimited vehicles. Know the real health of any car in about 30 seconds.
              </p>
              <div className="text-3xl" style={{ fontWeight: 700 }}>$34.99</div>
              <div className="space-y-3">
                {buyButton()}
                <p className="text-sm text-muted-foreground">
                  Ships to the US. One price covers the kit and standard shipping.
                </p>
              </div>
              <div className="flex flex-wrap gap-x-6 gap-y-2 text-sm text-muted-foreground pt-2">
                <span className="flex items-center gap-1.5">
                  <Wifi className="w-4 h-4 text-primary" /> Wi-Fi OBD-II
                </span>
                <span className="flex items-center gap-1.5">
                  <Apple className="w-4 h-4 text-primary" /> Works with MintCheck on iPhone
                </span>
              </div>
            </div>
            <div className="flex justify-center md:justify-end">
              <div className="bg-secondary/50 rounded-2xl p-8 max-w-sm w-full">
                <img
                  src={SCANNER_IMG}
                  alt="MintCheck Wi-Fi OBD-II Scanner"
                  className="w-full h-auto object-contain rounded-lg"
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ───── What’s in the Box ───── */}
      <section className="border-b border-border" style={{ backgroundColor: '#FCFCFB' }}>
        <div className="max-w-5xl mx-auto px-6 py-20">
          <h2 className="text-3xl text-center mb-14" style={{ fontWeight: 600 }}>
            What’s in the Box
          </h2>
          <div className="grid md:grid-cols-2 gap-10 max-w-2xl mx-auto">
            <div className="text-center space-y-4">
              <div className="w-14 h-14 bg-accent rounded-xl flex items-center justify-center mx-auto">
                <Wifi className="w-7 h-7 text-primary" />
              </div>
              <h3 className="text-lg" style={{ fontWeight: 600 }}>Wi-Fi OBD-II Scanner</h3>
              <p className="text-muted-foreground leading-relaxed">
                A compact plug-and-play adapter that reads your car’s engine data over Wi-Fi.
              </p>
            </div>
            <div className="text-center space-y-4">
              <div className="w-14 h-14 bg-accent rounded-xl flex items-center justify-center mx-auto">
                <ShieldCheck className="w-7 h-7 text-primary" />
              </div>
              <h3 className="text-lg" style={{ fontWeight: 600 }}>60-Day Unlimited Pass</h3>
              <p className="text-muted-foreground leading-relaxed">
                Scan as many vehicles as you want for 60 days with the MintCheck iOS app.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ───── Why MintCheck ───── */}
      <section className="border-b border-border">
        <div className="max-w-5xl mx-auto px-6 py-20">
          <h2 className="text-3xl text-center mb-14" style={{ fontWeight: 600 }}>
            Why MintCheck
          </h2>
          <div className="grid md:grid-cols-3 gap-10">
            <div className="space-y-3">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
                <Zap className="w-6 h-6 text-primary" />
              </div>
              <h3 style={{ fontWeight: 600 }}>Engine health in minutes</h3>
              <p className="text-muted-foreground leading-relaxed">
                Plug in the scanner, open the app, and get a complete health report in about 30 seconds. No tools, no appointments.
              </p>
            </div>
            <div className="space-y-3">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
                <FileText className="w-6 h-6 text-primary" />
              </div>
              <h3 style={{ fontWeight: 600 }}>Clear readout, not raw codes</h3>
              <p className="text-muted-foreground leading-relaxed">
                MintCheck translates trouble codes into plain English. You’ll know what’s wrong, why it matters, and what to do next.
              </p>
            </div>
            <div className="space-y-3">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
                <ShieldCheck className="w-6 h-6 text-primary" />
              </div>
              <h3 style={{ fontWeight: 600 }}>Built for used-car buyers</h3>
              <p className="text-muted-foreground leading-relaxed">
                Bring it to any test drive. See if trouble codes were recently cleared, catch hidden problems, and negotiate with confidence.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ───── How It Works ───── */}
      <section className="border-b border-border" style={{ backgroundColor: '#FCFCFB' }}>
        <div className="max-w-5xl mx-auto px-6 py-20">
          <h2 className="text-3xl text-center mb-14" style={{ fontWeight: 600 }}>
            How It Works
          </h2>
          <div className="grid md:grid-cols-3 gap-12">
            {[
              {
                num: '1',
                icon: <Plug className="w-6 h-6 text-primary" />,
                title: 'Turn on the car',
                desc: "Start the engine or turn the ignition to the ON position. The car’s computer needs to be powered up.",
              },
              {
                num: '2',
                icon: <Wifi className="w-6 h-6 text-primary" />,
                title: 'Plug in the scanner',
                desc: "Insert the Wi-Fi scanner into the OBD-II port (usually under the dashboard, near the steering column). Connect your phone to the scanner’s Wi-Fi network.",
              },
              {
                num: '3',
                icon: <Scan className="w-6 h-6 text-primary" />,
                title: 'Open MintCheck and scan',
                desc: "Tap scan in the app. In about 30 seconds you’ll have a full health report with trouble codes explained in plain English.",
              },
            ].map((step) => (
              <div key={step.num} className="space-y-4">
                <div className="flex items-center gap-3">
                  <span
                    className="w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-sm"
                    style={{ fontWeight: 700 }}
                  >
                    {step.num}
                  </span>
                  <div className="w-10 h-10 bg-accent rounded-lg flex items-center justify-center">
                    {step.icon}
                  </div>
                </div>
                <h3 style={{ fontWeight: 600 }}>{step.title}</h3>
                <p className="text-muted-foreground leading-relaxed">{step.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ───── Compatibility ───── */}
      <section className="border-b border-border">
        <div className="max-w-3xl mx-auto px-6 py-20">
          <h2 className="text-3xl text-center mb-10" style={{ fontWeight: 600 }}>
            Compatibility
          </h2>
          <div className="bg-secondary/30 rounded-xl p-8 space-y-4">
            <h3 className="text-lg" style={{ fontWeight: 600 }}>You’ll need</h3>
            <ul className="space-y-2 text-muted-foreground">
              <li className="flex items-start gap-2">
                <span className="text-primary mt-0.5">•</span>
                <span>An <strong>iPhone</strong> with the MintCheck app installed</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-0.5">•</span>
                <span>A <strong>Wi-Fi</strong> ELM327 OBD-II scanner (included in this kit)</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-0.5">•</span>
                <span>A car or light truck with an <strong>OBD-II port</strong> (US vehicles 1996+, most international 2005+)</span>
              </li>
            </ul>
            <p className="text-sm text-muted-foreground/70 pt-2">
              Bluetooth scanners are not compatible. MintCheck requires a Wi-Fi connection to the OBD-II adapter.
            </p>
          </div>
        </div>
      </section>

      {/* ───── FAQ ───── */}
      <section className="border-b border-border" style={{ backgroundColor: '#FCFCFB' }}>
        <div className="max-w-3xl mx-auto px-6 py-20">
          <h2 className="text-3xl text-center mb-10" style={{ fontWeight: 600 }}>
            Frequently Asked Questions
          </h2>
          <div className="border-t border-border">
            {FAQ_ITEMS.map((item) => (
              <FaqItem key={item.q} q={item.q} a={item.a} />
            ))}
          </div>
        </div>
      </section>

      {/* ───── Closing CTA ───── */}
      <section className="border-b border-border">
        <div className="max-w-3xl mx-auto px-6 py-20 text-center space-y-6">
          <h2 className="text-3xl md:text-4xl tracking-tight" style={{ fontWeight: 600 }}>
            Know before you buy
          </h2>
          <p className="text-xl text-muted-foreground leading-relaxed">
            Everything you need to scan any car – $34.99 with US shipping included.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            {buyButton()}
            <a
              href="https://apps.apple.com/app/mintcheck"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 border border-border px-6 py-3.5 rounded-lg transition-colors hover:bg-muted/50"
              style={{ fontWeight: 600 }}
            >
              <Apple className="w-5 h-5" />
              Get the iOS App
            </a>
          </div>
        </div>
      </section>

      <Footer />

      {/* ───── Sticky mobile bottom bar ───── */}
      <div className="fixed bottom-0 inset-x-0 md:hidden bg-white/95 backdrop-blur border-t border-border px-4 py-3 z-50">
        <a
          href={CHECKOUT_URL}
          className="block w-full bg-primary text-primary-foreground py-3.5 rounded-lg transition-opacity hover:opacity-90 text-center"
          style={{ fontWeight: 600 }}
        >
          Buy Starter Kit – $34.99
        </a>
      </div>
    </div>
  );
}
