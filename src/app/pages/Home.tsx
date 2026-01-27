import { Plug, Scan, FileText, Check, X, ExternalLink } from 'lucide-react';
import { Link } from 'react-router';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { Helmet } from 'react-helmet-async';

export default function Home() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>MintCheck - Car Health Made Simple | iOS App</title>
        <meta name="description" content="MintCheck helps you make smarter decisions about used cars. Get clear, easy-to-understand car health information." />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="canonical" href="https://mintcheckapp.com/" />
        {/* Open Graph */}
        <meta property="og:url" content="https://mintcheckapp.com/" />
        <meta property="og:type" content="website" />
        <meta property="og:title" content="Get the MintCheck app for iOS. Car Health Made Simple." />
        <meta property="og:description" content="MintCheck helps you make smarter decisions about used cars. Get clear, easy-to-understand car health information." />
        <meta property="og:image" content="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/OG_mintcheck.png" />
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary_large_image" />
        <meta property="twitter:domain" content="mintcheckapp.com" />
        <meta property="twitter:url" content="https://mintcheckapp.com/" />
        <meta name="twitter:title" content="Get the MintCheck app for iOS. Car Health Made Simple." />
        <meta name="twitter:description" content="MintCheck helps you make smarter decisions about used cars. Get clear, easy-to-understand car health information." />
        <meta name="twitter:image" content="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/OG_mintcheck.png" />
      </Helmet>

      {/* Navbar */}
      <Navbar />

      {/* Hero Section */}
      <section id="hero" className="border-b border-border">
        <div className="max-w-6xl mx-auto px-6 py-20 md:py-28">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div className="space-y-8">
              <h1 className="text-4xl md:text-5xl tracking-tight" style={{ fontWeight: 600 }}>
                Know the real health of any car
              </h1>
              <p className="text-xl text-muted-foreground leading-relaxed">
                MintCheck connects to a car’s OBD port and reads what the vehicle knows about itself. Get a clear health check, understand trouble codes in simple terms, and see if problems were recently hidden.
              </p>
              <div className="pt-2">
                <Link 
                  to="/download" 
                  className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90"
                  style={{ fontWeight: 600 }}
                >
                  <img 
                    src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/3P-content/logos/Apple_logo_black.svg" 
                    alt="" 
                    className="w-5 h-5 brightness-0 invert" 
                    aria-hidden 
                  />
                  Get the iOS App
                </Link>
                <p className="text-sm text-muted-foreground mt-6">
                  Real-time scans. Clear results. No car knowledge needed.
                </p>
              </div>
            </div>
            <div className="flex justify-center md:justify-end">
              <img 
                src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/hero.avif" 
                alt="MintCheck iOS App" 
                className="max-w-[605px] w-full rounded-lg shadow-lg"
              />
            </div>
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section id="how-it-works" className="border-b border-border" style={{ backgroundColor: '#FCFCFB' }}>
        <div className="max-w-5xl mx-auto px-6 py-24">
          <h2 className="text-3xl text-center mb-16" style={{ fontWeight: 600 }}>
            How It Works
          </h2>
          <div className="grid md:grid-cols-3 gap-12">
            <div className="space-y-4">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
                <Plug className="w-6 h-6 text-primary" />
              </div>
              <h3 style={{ fontWeight: 600 }}>Connect your scanner</h3>
              <p className="text-muted-foreground leading-relaxed">
                Plug a WiFi OBD-II scanner into the car’s OBD port. Turn the ignition on, connect your phone, and you’re ready.
              </p>
            </div>
            <div className="space-y-4">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
                <Scan className="w-6 h-6 text-primary" />
              </div>
              <h3 style={{ fontWeight: 600 }}>Scan the vehicle</h3>
              <p className="text-muted-foreground leading-relaxed">
                Tap to start. MintCheck reads trouble codes, engine data, battery health, fuel system status, and more, all in about 30 seconds.
              </p>
            </div>
            <div className="space-y-4">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
                <FileText className="w-6 h-6 text-primary" />
              </div>
              <h3 style={{ fontWeight: 600 }}>Get your health report</h3>
              <p className="text-muted-foreground leading-relaxed">
                See a health score, understand any trouble codes in simple terms, and get recommendations. Track scans over time to spot changes.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases Section */}
      <section id="use-cases" className="border-b border-border">
        <div className="max-w-6xl mx-auto px-6 py-24">
          <h2 className="text-3xl text-center mb-16" style={{ fontWeight: 600 }}>
            For buyers, sellers, and owners
          </h2>
          <div className="grid md:grid-cols-2 gap-16">
            <div className="space-y-6">
              <div className="aspect-video bg-secondary/50 rounded-lg overflow-hidden mb-6">
                <img 
                  src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/buy-car.png" 
                  alt="Buying a Used Car" 
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="space-y-3">
                <h3 className="text-2xl" style={{ fontWeight: 600 }}>
                  Buying a Used Car
                </h3>
                <p className="text-lg text-muted-foreground leading-relaxed">
                  Know what you’re buying before you pay.
                </p>
              </div>
              <div className="space-y-4 text-muted-foreground leading-relaxed">
                <p>
                  A car can look perfect but hide serious problems. Trouble codes tell the real story, but most people can’t read them.
                </p>
                <p>
                  MintCheck scans the car’s computer and explains everything clearly. See trouble codes, check if problems were recently cleared, and get a health score that helps you decide.
                </p>
                <p>
                  Bring a scanner to any test drive. Know the truth in 30 seconds.
                </p>
              </div>
            </div>
            <div className="space-y-6">
              <div className="aspect-video bg-secondary/50 rounded-lg overflow-hidden mb-6">
                <img 
                  src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/own-car.png" 
                  alt="Owning a Car" 
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="space-y-3">
                <h3 className="text-2xl" style={{ fontWeight: 600 }}>
                  Owning a Car
                </h3>
                <p className="text-lg text-muted-foreground leading-relaxed">
                  Monitor your car’s health over time.
                </p>
              </div>
              <div className="space-y-4 text-muted-foreground leading-relaxed">
                <p>
                  When a warning light appears, you need to know what it means. MintCheck reads the trouble codes and explains them in simple terms, no mechanic jargon.
                </p>
                <p>
                  Track your car’s health with regular scans. See how systems are doing, catch issues early, and know what needs attention before it gets expensive.
                </p>
                <p>
                  Your scan history stays in the app, so you can see changes over time.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* OBD-II Scanners Section */}
      <section id="scanners" className="border-b border-border" style={{ backgroundColor: '#F8F8F7' }}>
        <div className="max-w-5xl mx-auto px-6 py-16">
          <div className="text-center space-y-3 mb-12">
            <h2 className="text-3xl" style={{ fontWeight: 600 }}>
              Get an OBD-II Scanner
            </h2>
            <p className="text-muted-foreground leading-relaxed max-w-2xl mx-auto">
              MintCheck works with WiFi OBD-II scanners only. Bluetooth is not supported. This one has been tested and works great.
            </p>
          </div>
          
          <div className="flex justify-center">
            <div className="bg-white border border-border rounded-lg overflow-hidden w-full max-w-sm">
              <div className="aspect-square bg-secondary/50 flex items-center justify-center p-6">
                <img 
                  src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/generic-wifi.png" 
                  alt="WiFi ELM327 OBD-II Scanner (Generic)" 
                  className="w-full h-full object-cover rounded"
                />
              </div>
              <div className="p-5 space-y-3">
                <div>
                  <h3 className="text-lg mb-1" style={{ fontWeight: 600 }}>WiFi ELM327 OBD-II Scanner (Generic)</h3>
                  <p className="text-sm text-muted-foreground">
                    Plain-brand Wi-Fi scanner that works well with MintCheck.
                  </p>
                </div>
                <div className="text-xl" style={{ fontWeight: 600 }}>$15.99</div>
                <a 
                  href="https://www.amazon.com/dp/B0BRKJ38ZQ?ref=ppx_yo2ov_dt_b_fed_asin_title" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="w-full inline-flex items-center justify-center gap-2 bg-primary text-primary-foreground px-4 py-2.5 rounded-lg transition-opacity hover:opacity-90 text-sm"
                  style={{ fontWeight: 600 }}
                >
                  Buy on Amazon
                  <ExternalLink className="w-3.5 h-3.5" />
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Trust & Boundaries Section */}
      <section className="border-b border-border">
        <div className="max-w-4xl mx-auto px-6 py-24">
          <div className="space-y-12">
            <div className="text-center space-y-4">
              <h2 className="text-3xl" style={{ fontWeight: 600 }}>
                What MintCheck Does
              </h2>
              <p className="text-lg text-muted-foreground leading-relaxed max-w-2xl mx-auto">
                MintCheck reads data from the car’s computer and turns it into clear, useful information.
              </p>
            </div>
            
            <div className="grid md:grid-cols-2 gap-8">
              <div className="bg-white border border-border rounded-lg p-8 space-y-4">
                <div className="w-12 h-12 bg-[#3EB489] rounded-full flex items-center justify-center">
                  <Check className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-xl" style={{ fontWeight: 600 }}>
                  Clear, simple explanations
                </h3>
                <p className="text-muted-foreground leading-relaxed">
                  MintCheck reads trouble codes and explains them in simple terms. See what’s wrong, why it matters, and what to do about it. No mechanic jargon.
                </p>
              </div>
              
              <div className="bg-white border border-border rounded-lg p-8 space-y-4">
                <div className="w-12 h-12 bg-[#E85D5D] rounded-full flex items-center justify-center">
                  <X className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-xl" style={{ fontWeight: 600 }}>
                  Not a replacement for a mechanic
                </h3>
                <p className="text-muted-foreground leading-relaxed">
                  MintCheck helps you understand what the car’s computer is reporting, but it can’t perform physical inspections or fix problems. For major decisions, always consult a qualified mechanic.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* About / Founder Story Section */}
      <section id="about" className="border-b border-border" style={{ backgroundColor: '#FCFCFB' }}>
        <div className="max-w-6xl mx-auto px-6 py-24">
          <div className="grid md:grid-cols-[1fr_1fr] gap-12 items-center">
            <div className="flex justify-center md:justify-start w-full max-w-[704px]">
              <img 
                src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/about.webp"
                alt="Founder and family"
                className="w-full aspect-square object-cover rounded-lg"
              />
            </div>
            <div className="space-y-4 text-left">
              <h2 className="text-3xl" style={{ fontWeight: 600 }}>
                About MintCheck
              </h2>
              <div className="space-y-4 text-muted-foreground leading-relaxed">
                <p>
                  I was living far from my mom when she needed to buy a used car. She found one she liked, but had no way to know if it was in good shape.
                </p>
                <p>
                  So I built MintCheck to turn the car’s data into something clear and helpful. Now she can understand what’s really going on with a car, and so can anyone else—whether they’re buying one or already own it.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <Footer />
    </div>
  );
}