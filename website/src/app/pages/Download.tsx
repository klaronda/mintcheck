import { Helmet } from 'react-helmet-async';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { APP_STORE_URL, APPLE_LOGO_SVG_URL } from '@/app/constants/appStore';

const STARTER_KIT_CHECKOUT_URL = 'https://buy.stripe.com/aFaaEXcHC0Ih7tX215dby03';
const STARTER_KIT_IMG =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Images/Product/MC-01a.png';

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
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90"
            style={{ fontWeight: 600 }}
          >
            <img
              src={APPLE_LOGO_SVG_URL}
              alt=""
              className="w-5 h-5 shrink-0 brightness-0 invert"
              aria-hidden
            />
            Get the iOS App
          </a>
        </div>
      </section>

      <section className="border-b border-border bg-muted/30">
        <div className="max-w-6xl mx-auto px-6 py-16 md:py-20">
          <div className="grid md:grid-cols-2 gap-10 md:gap-12 items-center">
            <div className="flex justify-center md:justify-start order-2 md:order-1">
              <img
                src={STARTER_KIT_IMG}
                alt="MintCheck Wi-Fi OBD-II scanner"
                className="w-full max-w-sm rounded-lg border border-border shadow-sm"
              />
            </div>
            <div className="space-y-4 text-center md:text-left order-1 md:order-2">
              <h2 className="text-3xl md:text-4xl tracking-tight" style={{ fontWeight: 600 }}>
                MintCheck Starter Kit
              </h2>
              <p className="text-lg text-muted-foreground leading-relaxed">
                Wi-Fi scanner + 60-day pass – scan unlimited vehicles. Know the real health of any car in about 30 seconds.
              </p>
              <div className="text-2xl md:text-3xl" style={{ fontWeight: 700 }}>
                $34.99
              </div>
              <div className="space-y-2 pt-1">
                <a
                  href={STARTER_KIT_CHECKOUT_URL}
                  className="inline-flex items-center justify-center gap-2 bg-white border-2 border-[#3EB489] text-[#3EB489] px-8 py-4 rounded-lg transition-colors hover:bg-[#3EB489]/10"
                  style={{ fontWeight: 600 }}
                >
                  Buy Starter Kit – $34.99
                </a>
                <p className="text-sm text-muted-foreground">
                  Ships to the US. One price covers the kit and standard shipping.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
