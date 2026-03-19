import { Apple } from 'lucide-react';
import { Helmet } from 'react-helmet-async';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';

export default function Download() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Download MintCheck | iOS App</title>
        <meta name="description" content="Download MintCheck for iOS. Get the app that helps you make smarter decisions about used cars with OBD-II scans." />
        <link rel="canonical" href="https://mintcheckapp.com/download" />
      </Helmet>

      <Navbar />

      <section className="border-b border-border">
        <div className="max-w-2xl mx-auto px-6 py-24 text-center">
          <h1 className="text-4xl md:text-5xl tracking-tight mb-6" style={{ fontWeight: 600 }}>
            Get the iOS App
          </h1>
          <p className="text-xl text-muted-foreground leading-relaxed mb-10">
            Download MintCheck from the App Store. Know the real health of any car in about 30 seconds.
          </p>
          <a
            href="https://apps.apple.com/app/mintcheck"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90"
            style={{ fontWeight: 600 }}
          >
            <Apple className="w-5 h-5" />
            Get the iOS App
          </a>
        </div>
      </section>

      <Footer />
    </div>
  );
}
