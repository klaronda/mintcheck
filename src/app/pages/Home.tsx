import { Plug, Scan, FileText, Check, X, Mail, ExternalLink } from 'lucide-react';
import { Link, useLocation } from 'react-router';
import { useEffect } from 'react';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { Helmet } from 'react-helmet-async';
import { getOrganizationSchema, getSoftwareApplicationSchema } from '@/app/utils/structuredData';

export default function Home() {
  const location = useLocation();

  useEffect(() => {
    // Handle hash scrolling when page loads with a hash
    if (location.hash) {
      const targetId = location.hash.replace('#', '');
      setTimeout(() => {
        const element = document.getElementById(targetId);
        if (element) {
          const offset = 80; // Account for sticky navbar
          const elementPosition = element.getBoundingClientRect().top;
          const offsetPosition = elementPosition + window.pageYOffset - offset;
          
          window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
          });
        }
      }, 100);
    }
  }, [location.hash]);
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>MintCheck - OBD-II Car Health Made Simple | iOS App</title>
        <meta name="description" content="MintCheck helps you make smarter decisions when buying or owning used cars with OBD-II scans. Get clear, easy-to-understand car health information." />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="canonical" href="https://mintcheckapp.com" />
        
        {/* Open Graph */}
        <meta property="og:title" content="MintCheck - OBD-II Car Health Made Simple" />
        <meta property="og:description" content="Make smarter decisions about used cars with clear, easy-to-understand car health information." />
        <meta property="og:type" content="website" />
        <meta property="og:url" content="https://mintcheckapp.com" />
        <meta property="og:image" content="https://mintcheckapp.com/og-image.jpg" />
        
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content="MintCheck - OBD-II Car Health Made Simple" />
        <meta name="twitter:description" content="Make smarter decisions about used cars with clear, easy-to-understand car health information." />
        <meta name="twitter:image" content="https://mintcheckapp.com/og-image.jpg" />
        
        {/* Structured Data */}
        <script type="application/ld+json">
          {JSON.stringify(getSoftwareApplicationSchema())}
        </script>
        <script type="application/ld+json">
          {JSON.stringify(getOrganizationSchema())}
        </script>
      </Helmet>

      {/* Navbar */}
      <Navbar />

      {/* Hero Section */}
      <section id="hero" className="border-b border-border">
        <div className="max-w-6xl mx-auto px-6 py-12 md:py-16">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div className="space-y-8">
              <h1 className="text-4xl md:text-5xl tracking-tight" style={{ fontWeight: 600 }}>
                Know the real health of any car
              </h1>
              <p className="text-xl text-muted-foreground leading-relaxed">
                MintCheck connects to a car’s OBD port and reads what the vehicle knows about itself.
                Get a clear health check, understand trouble codes in simple terms, and see if problems were recently hidden.
              </p>
              <div className="pt-2">
                <a 
                  href="/download" 
                  className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90"
                  style={{ fontWeight: 600 }}
                >
                  <img 
                    src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/3P-content/logos/Apple_logo_black.svg" 
                    alt="Apple" 
                    className="w-5 h-5"
                    style={{ filter: 'brightness(0) invert(1)' }}
                  />
                  Get the iOS App
                </a>
                <p className="text-sm text-muted-foreground mt-6">
                  Real-time scans. Clear results. No car knowledge needed.
                </p>
              </div>
            </div>
            <div className="flex justify-center md:justify-end items-end">
              <img 
                src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/hero.webp" 
                alt="MintCheck iOS App" 
                className="max-w-lg md:max-w-xl w-full rounded-lg shadow-lg"
                style={{ objectPosition: 'center bottom', objectFit: 'cover' }}
                fetchPriority="high"
                width="800"
                height="600"
                decoding="async"
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
                  src="https://images.unsplash.com/photo-1699204886256-37e17d892074?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx1c2VkJTIwY2FyJTIwYnV5aW5nJTIwaW5zcGVjdGlvbnxlbnwxfHx8fDE3NjkxOTM1ODF8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                  alt="Buying a Used Car" 
                  className="w-full h-full object-cover"
                  loading="lazy"
                  width="800"
                  height="450"
                  decoding="async"
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
                  src="https://images.unsplash.com/photo-1617043954482-647e38794271?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXIlMjBkYXNoYm9hcmQlMjB3YXJuaW5nJTIwbGlnaHR8ZW58MXx8fHwxNzY5MTkzNTgyfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                  alt="Owning a Car" 
                  className="w-full h-full object-cover"
                  loading="lazy"
                  width="800"
                  height="450"
                  decoding="async"
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
          
          <div className="max-w-sm mx-auto">
            <div className="bg-white border border-border rounded-lg overflow-hidden">
              <div className="aspect-square bg-secondary/50 flex items-center justify-center p-6">
                <img 
                  src="https://images.unsplash.com/photo-1713470599399-aa0d2b068eae?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxlbGVjdHJvbmljJTIwZGV2aWNlJTIwZ2FkZ2V0fGVufDF8fHx8MTc2OTE2MTk4Nnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                  alt="VEEPEAK Mini WiFi Scanner" 
                  className="w-full h-full object-cover rounded"
                  loading="lazy"
                  width="400"
                  height="400"
                  decoding="async"
                />
              </div>
              <div className="p-5 space-y-3">
                <div>
                  <h3 className="text-lg mb-1" style={{ fontWeight: 600 }}>VEEPEAK Mini WiFi</h3>
                  <p className="text-sm text-muted-foreground">
                    Compact and reliable WiFi scanner
                  </p>
                </div>
                <div className="text-xl" style={{ fontWeight: 600 }}>$19.99</div>
                <a 
                  href="https://www.amazon.com/s?k=veepeak+obd2+scanner" 
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
          <div className="grid md:grid-cols-5 gap-12 items-center">
            <div className="md:col-span-2 flex justify-center md:justify-start">
              <img 
                src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/about.webp"
                alt="Founder and family"
                className="w-full aspect-square object-cover rounded-lg"
                loading="lazy"
                width="600"
                height="600"
                decoding="async"
              />
            </div>
            <div className="md:col-span-3 space-y-6">
              <h2 className="text-3xl" style={{ fontWeight: 600 }}>
                About MintCheck
              </h2>
              <div className="space-y-4 text-muted-foreground leading-relaxed">
                <p>
                  I was living far from my mom when she needed to buy a used car. She found one she liked, but had no way to know if it was in good shape.
                </p>
                <p>
                  With my young daughter, traveling is hard. I wanted to build something she could use without needing my help or a mechanic.
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