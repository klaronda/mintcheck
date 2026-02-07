import { Apple, Plug, Scan, FileText, Check, X, Mail, ExternalLink } from 'lucide-react';
import { Link } from 'react-router';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { Helmet } from 'react-helmet-async';

export default function Home() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>MintCheck - OBD-II Car Diagnostics Made Simple | iOS App</title>
        <meta name="description" content="MintCheck helps you make smarter decisions when buying or owning used cars through OBD-II scanner diagnostics. Get clear, easy-to-understand car health information." />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="canonical" href="https://mintcheckapp.com" />
        
        {/* Open Graph */}
        <meta property="og:title" content="MintCheck - OBD-II Car Diagnostics Made Simple" />
        <meta property="og:description" content="Make smarter decisions about used cars with easy-to-understand diagnostic information." />
        <meta property="og:type" content="website" />
        <meta property="og:url" content="https://mintcheckapp.com" />
        
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content="MintCheck - OBD-II Car Diagnostics Made Simple" />
        <meta name="twitter:description" content="Make smarter decisions about used cars with easy-to-understand diagnostic information." />
      </Helmet>

      {/* Navbar */}
      <Navbar />

      {/* Hero Section */}
      <section id="hero" className="border-b border-border">
        <div className="max-w-6xl mx-auto px-6 py-20 md:py-28">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div className="space-y-8">
              <h1 className="text-4xl md:text-5xl tracking-tight" style={{ fontWeight: 600 }}>
                Make smarter decisions about used cars
              </h1>
              <p className="text-xl text-muted-foreground leading-relaxed">
                MintCheck turns confusing car data into simple advice you can understand. 
                Know what you're buying — or what your car needs — in plain English.
              </p>
              <div className="pt-2">
                <a 
                  href="#" 
                  className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90"
                  style={{ fontWeight: 600 }}
                >
                  <Apple className="w-5 h-5" />
                  Get the iOS App
                </a>
                <p className="text-sm text-muted-foreground mt-6">
                  Like having a mechanic in your pocket
                </p>
              </div>
            </div>
            <div className="flex justify-center md:justify-end">
              <img 
                src="https://images.unsplash.com/photo-1585060282215-39a72f82385c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpcGhvbmUlMjBhcHAlMjBzY3JlZW4lMjBtb2NrdXB8ZW58MXx8fHwxNzY5MTkzMjU0fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                alt="MintCheck iOS App" 
                className="max-w-sm w-full rounded-lg shadow-lg"
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
              <h3 style={{ fontWeight: 600 }}>Plug in an OBD-II scanner</h3>
              <p className="text-muted-foreground leading-relaxed">
                Connect a standard OBD-II scanner to the car. Any basic model works — they're available online for around $20.
              </p>
            </div>
            <div className="space-y-4">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
                <Scan className="w-6 h-6 text-primary" />
              </div>
              <h3 style={{ fontWeight: 600 }}>Run a scan in the app</h3>
              <p className="text-muted-foreground leading-relaxed">
                Open MintCheck and start a scan. The app reads the car's diagnostic codes and system status in seconds.
              </p>
            </div>
            <div className="space-y-4">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
                <FileText className="w-6 h-6 text-primary" />
              </div>
              <h3 style={{ fontWeight: 600 }}>Get clear guidance</h3>
              <p className="text-muted-foreground leading-relaxed">
                Receive a plain-English summary of what's happening with the car and what you should consider next.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases Section */}
      <section id="use-cases" className="border-b border-border">
        <div className="max-w-6xl mx-auto px-6 py-24">
          <h2 className="text-3xl text-center mb-16" style={{ fontWeight: 600 }}>
            Always know the health of your car
          </h2>
          <div className="grid md:grid-cols-2 gap-16">
            <div className="space-y-6">
              <div className="aspect-video bg-secondary/50 rounded-lg overflow-hidden mb-6">
                <img 
                  src="https://images.unsplash.com/photo-1699204886256-37e17d892074?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx1c2VkJTIwY2FyJTIwYnV5aW5nJTIwaW5zcGVjdGlvbnxlbnwxfHx8fDE3NjkxOTM1ODF8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                  alt="Buying a Used Car" 
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="space-y-3">
                <h3 className="text-2xl" style={{ fontWeight: 600 }}>
                  Buying a Used Car
                </h3>
                <p className="text-lg text-muted-foreground leading-relaxed">
                  Make the right choice before you buy.
                </p>
              </div>
              <div className="space-y-4 text-muted-foreground leading-relaxed">
                <p>
                  When you're looking at a used car, you can't tell what's wrong just by looking at it.
                </p>
                <p>
                  MintCheck helps you understand the risks before you spend your money. Run a quick scan and see what you're getting into.
                </p>
                <p>
                  No car knowledge needed. Just plug in, scan, and read.
                </p>
              </div>
            </div>
            <div className="space-y-6">
              <div className="aspect-video bg-secondary/50 rounded-lg overflow-hidden mb-6">
                <img 
                  src="https://images.unsplash.com/photo-1617043954482-647e38794271?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXIlMjBkYXNoYm9hcmQlMjB3YXJuaW5nJTIwbGlnaHR8ZW58MXx8fHwxNzY5MTkzNTgyfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                  alt="Owning a Car" 
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="space-y-3">
                <h3 className="text-2xl" style={{ fontWeight: 600 }}>
                  Owning a Car
                </h3>
                <p className="text-lg text-muted-foreground leading-relaxed">
                  Know what your car is trying to tell you.
                </p>
              </div>
              <div className="space-y-4 text-muted-foreground leading-relaxed">
                <p>
                  Warning lights can be scary. Is it serious? Can it wait? Do you need to stop right now?
                </p>
                <p>
                  MintCheck explains what's happening in simple words. Track issues over time and know when something really needs fixing.
                </p>
                <p>
                  No more guessing.
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
              These affordable scanners have been tested and approved to work with MintCheck. All are recommended — choose based on your budget.
            </p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-6">
            {/* Scanner 1 */}
            <div className="bg-white border border-border rounded-lg overflow-hidden">
              <div className="aspect-square bg-secondary/50 flex items-center justify-center p-6">
                <img 
                  src="https://images.unsplash.com/photo-1713470599399-aa0d2b068eae?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxlbGVjdHJvbmljJTIwZGV2aWNlJTIwZ2FkZ2V0fGVufDF8fHx8MTc2OTE2MTk4Nnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                  alt="VEEPEAK Mini WiFi Scanner" 
                  className="w-full h-full object-cover rounded"
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

            {/* Scanner 2 */}
            <div className="bg-white border border-border rounded-lg overflow-hidden">
              <div className="aspect-square bg-secondary/50 flex items-center justify-center p-6">
                <img 
                  src="https://images.unsplash.com/photo-1645575205773-6514860cd97d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxibHVldG9vdGglMjBjYXIlMjBkaWFnbm9zdGljJTIwdG9vbHxlbnwxfHx8fDE3NjkxOTM0Nzl8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                  alt="BlueDriver Bluetooth Pro Scanner" 
                  className="w-full h-full object-cover rounded"
                />
              </div>
              <div className="p-5 space-y-3">
                <div>
                  <h3 className="text-lg mb-1" style={{ fontWeight: 600 }}>BlueDriver Bluetooth Pro</h3>
                  <p className="text-sm text-muted-foreground">
                    Professional-grade with enhanced diagnostics
                  </p>
                </div>
                <div className="text-xl" style={{ fontWeight: 600 }}>$119.95</div>
                <a 
                  href="https://www.amazon.com/s?k=bluedriver+bluetooth+obd2" 
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

            {/* Scanner 3 */}
            <div className="bg-white border border-border rounded-lg overflow-hidden">
              <div className="aspect-square bg-secondary/50 flex items-center justify-center p-6">
                <img 
                  src="https://images.unsplash.com/photo-1729216205883-71b58c21f913?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXIlMjBkaWFnbm9zdGljJTIwc2Nhbm5lcnxlbnwxfHx8fDE3NjkxNjM2NTN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                  alt="OBDLink MX+ Scanner" 
                  className="w-full h-full object-cover rounded"
                />
              </div>
              <div className="p-5 space-y-3">
                <div>
                  <h3 className="text-lg mb-1" style={{ fontWeight: 600 }}>OBDLink MX+</h3>
                  <p className="text-sm text-muted-foreground">
                    Premium with fastest processor
                  </p>
                </div>
                <div className="text-xl" style={{ fontWeight: 600 }}>$99.95</div>
                <a 
                  href="https://www.amazon.com/s?k=obdlink+mx+bluetooth" 
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
                MintCheck gives you helpful information about your car. It helps you make better choices.
              </p>
            </div>
            
            <div className="grid md:grid-cols-2 gap-8">
              <div className="bg-white border border-border rounded-lg p-8 space-y-4">
                <div className="w-12 h-12 bg-[#3EB489] rounded-full flex items-center justify-center">
                  <Check className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-xl" style={{ fontWeight: 600 }}>
                  Clear, honest information
                </h3>
                <p className="text-muted-foreground leading-relaxed">
                  MintCheck explains car problems in simple words. No tricks, no selling stuff — just easy-to-understand information.
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
                  MintCheck helps you understand, but it can't fix your car. For big decisions, always have a real mechanic look at the car in person.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* About / Founder Story Section */}
      <section id="about" className="border-b border-border" style={{ backgroundColor: '#FCFCFB' }}>
        <div className="max-w-4xl mx-auto px-6 py-24">
          <div className="grid md:grid-cols-3 gap-12 items-start">
            <div className="md:col-span-1 flex justify-center md:justify-start">
              <img 
                src="https://images.unsplash.com/photo-1579255565889-2ac16e9b2950?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb3RoZXIlMjBzb24lMjBzbWlsaW5nJTIwZnJpZW5kbHl8ZW58MXx8fHwxNzY5MTg4MjIwfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
                alt="Founder and family"
                className="w-full max-w-[480px] aspect-square object-cover rounded-lg"
              />
            </div>
            <div className="md:col-span-2 space-y-6">
              <h2 className="text-3xl" style={{ fontWeight: 600 }}>
                About MintCheck
              </h2>
              <div className="space-y-4 text-muted-foreground leading-relaxed">
                <p>
                  MintCheck started when my mom needed to buy a used car from far away. She found one she liked, but had no way to know if it was in good shape.
                </p>
                <p>
                  I knew the information was there — modern cars track everything. But scanners just show codes and numbers that don't make sense to most people.
                </p>
                <p>
                  So I built MintCheck to turn that data into something clear and helpful. Now anyone can understand what's really going on with a car, whether they're buying one or already own it.
                </p>
                <p>
                  It's the tool I wish we had when my mom was shopping.
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