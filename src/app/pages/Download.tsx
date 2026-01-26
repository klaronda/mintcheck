import { Apple, QrCode, Check, Download as DownloadIcon } from 'lucide-react';
import { Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { getOrganizationSchema, getSoftwareApplicationSchema } from '@/app/utils/structuredData';

export default function Download() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Download MintCheck | iOS App</title>
        <meta name="description" content="Download MintCheck for iOS. Get the app that helps you make smarter decisions about used cars with OBD-II scans." />
        <meta name="robots" content="index, follow" />
        <link rel="canonical" href="https://mintcheckapp.com/download" />
        
        {/* Open Graph */}
        <meta property="og:title" content="Download MintCheck | iOS App" />
        <meta property="og:description" content="Get the app that helps you make smarter decisions about used cars with OBD-II scans." />
        <meta property="og:type" content="website" />
        <meta property="og:url" content="https://mintcheckapp.com/download" />
        <meta property="og:image" content="https://mintcheckapp.com/og-download.jpg" />
        <meta property="og:site_name" content="MintCheck" />
        
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content="Download MintCheck | iOS App" />
        <meta name="twitter:description" content="Get the app that helps you make smarter decisions about used cars." />
        <meta name="twitter:image" content="https://mintcheckapp.com/og-download.jpg" />
        
        {/* Structured Data */}
        <script type="application/ld+json">
          {JSON.stringify(getOrganizationSchema())}
        </script>
        <script type="application/ld+json">
          {JSON.stringify(getSoftwareApplicationSchema())}
        </script>
      </Helmet>

      <Navbar />

      {/* Hero Section */}
      <section className="border-b border-border" style={{ backgroundColor: '#FCFCFB' }}>
        <div className="max-w-6xl mx-auto px-6 py-20 md:py-28">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div className="space-y-8">
              <h1 className="text-4xl md:text-5xl tracking-tight" style={{ fontWeight: 600 }}>
                Get MintCheck for iOS
              </h1>
              <p className="text-xl text-muted-foreground leading-relaxed">
                Download the app that turns confusing car data into simple advice you can understand.
              </p>
              
              {/* App Store Button */}
              <div className="pt-4">
                <a 
                  href="https://apps.apple.com/app/mintcheck" 
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-3 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90"
                  style={{ fontWeight: 600 }}
                >
                  <Apple className="w-6 h-6" />
                  Download on the App Store
                </a>
                <p className="text-sm text-muted-foreground mt-4">
                  Available now on iOS
                </p>
              </div>

              {/* QR Code Section */}
              <div className="pt-6 border-t border-border">
                <div className="flex items-center gap-4">
                  <div className="w-24 h-24 bg-white border border-border rounded-lg flex items-center justify-center">
                    <QrCode className="w-12 h-12 text-muted-foreground" />
                  </div>
                  <div>
                    <p className="text-sm font-medium mb-1">Scan to download</p>
                    <p className="text-xs text-muted-foreground">
                      Open this page on your iPhone and scan the QR code
                    </p>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="flex justify-center md:justify-end">
              <img 
                src="https://images.unsplash.com/photo-1585060282215-39a72f82385c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpcGhvbmUlMjBhcHAlMjBzY3JlZW4lMjBtb2NrdXB8ZW58MXx8fHwxNzY5MTkzMjU0fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                alt="MintCheck iOS App" 
                className="max-w-sm w-full rounded-lg shadow-lg"
                loading="lazy"
                width="400"
                height="800"
                decoding="async"
              />
            </div>
          </div>
        </div>
      </section>

      {/* System Requirements */}
      <section className="border-b border-border">
        <div className="max-w-4xl mx-auto px-6 py-24">
          <h2 className="text-3xl text-center mb-12" style={{ fontWeight: 600 }}>
            System Requirements
          </h2>
          <div className="grid md:grid-cols-2 gap-8">
            <div className="bg-white border border-border rounded-lg p-6">
              <h3 className="text-xl mb-4" style={{ fontWeight: 600 }}>
                iOS Requirements
              </h3>
              <ul className="space-y-3 text-muted-foreground">
                <li className="flex items-start gap-2">
                  <Check className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                  <span>iOS 15.0 or later</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                  <span>iPhone 8 or later</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                  <span>WiFi OBD-II scanner (Bluetooth not supported)</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                  <span>Internet connection for vehicle data</span>
                </li>
              </ul>
            </div>
            
            <div className="bg-white border border-border rounded-lg p-6">
              <h3 className="text-xl mb-4" style={{ fontWeight: 600 }}>
                What You’ll Need
              </h3>
              <ul className="space-y-3 text-muted-foreground">
                <li className="flex items-start gap-2">
                  <Check className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                  <span>OBD-II compatible vehicle (1996 or later)</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                  <span>WiFi OBD-II scanner (Bluetooth not supported)</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                  <span>MintCheck account (free to create)</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                  <span>Vehicle’s OBD-II port accessible</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="border-b border-border" style={{ backgroundColor: '#F8F8F7' }}>
        <div className="max-w-4xl mx-auto px-6 py-24">
          <h2 className="text-3xl text-center mb-16" style={{ fontWeight: 600 }}>
            What You Get
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-white border border-border rounded-lg p-6">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center mb-4">
                <DownloadIcon className="w-6 h-6 text-primary" />
              </div>
              <h3 className="text-lg mb-2" style={{ fontWeight: 600 }}>
                Simple scans
              </h3>
              <p className="text-muted-foreground text-sm leading-relaxed">
                Connect your OBD-II scanner and get instant, easy-to-understand car health information.
              </p>
            </div>
            
            <div className="bg-white border border-border rounded-lg p-6">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center mb-4">
                <Check className="w-6 h-6 text-primary" />
              </div>
              <h3 className="text-lg mb-2" style={{ fontWeight: 600 }}>
                Clear guidance
              </h3>
              <p className="text-muted-foreground text-sm leading-relaxed">
                Get clear explanations of what’s going on with your car, not just codes and numbers.
              </p>
            </div>
            
            <div className="bg-white border border-border rounded-lg p-6">
              <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center mb-4">
                <Apple className="w-6 h-6 text-primary" />
              </div>
              <h3 className="text-lg mb-2" style={{ fontWeight: 600 }}>
                Free to Use
              </h3>
              <p className="text-muted-foreground text-sm leading-relaxed">
                Download and use MintCheck for free. No subscriptions, no hidden fees.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section>
        <div className="max-w-4xl mx-auto px-6 py-24 text-center">
          <h2 className="text-3xl mb-6" style={{ fontWeight: 600 }}>
            Ready to get started?
          </h2>
          <p className="text-xl text-muted-foreground mb-8">
            Download MintCheck today and make smarter decisions about your car.
          </p>
          <a 
            href="https://apps.apple.com/app/mintcheck" 
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-3 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90"
            style={{ fontWeight: 600 }}
          >
            <Apple className="w-6 h-6" />
            Download on the App Store
          </a>
          <div className="mt-8">
            <Link 
              to="/" 
              className="text-[#3EB489] hover:underline"
            >
              ← Back to home
            </Link>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
