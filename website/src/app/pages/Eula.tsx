import { Link } from 'react-router';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { Helmet } from 'react-helmet-async';

export default function Eula() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>End User License Agreement (EULA) | MintCheck</title>
        <meta name="description" content="MintCheck End User License Agreement - Terms governing your use of the MintCheck mobile app." />
        <meta name="robots" content="index, follow" />
      </Helmet>

      <Navbar />

      <main className="max-w-4xl mx-auto px-6 py-16">
        <h1 className="text-4xl mb-8" style={{ fontWeight: 600 }}>
          End User License Agreement (EULA)
        </h1>

        <div className="space-y-8 text-muted-foreground leading-relaxed">
          <p className="text-sm text-muted-foreground">
            Last updated: March 19, 2026
          </p>

          <p>
            This End User License Agreement (“<strong>EULA</strong>”) is a legal agreement between you (“<strong>User</strong>,” “<strong>you</strong>”) and MintCheck (“<strong>MintCheck</strong>,” “<strong>we</strong>,” “<strong>us</strong>,” or “<strong>our</strong>”) governing your use of the MintCheck mobile application (the “<strong>App</strong>”).
          </p>
          <p>
            By downloading, installing, or using the App, you agree to this EULA.
          </p>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              1. License Grant
            </h2>
            <p>
              MintCheck grants you a limited, non-exclusive, non-transferable, revocable license to download and use the App for personal, non-commercial purposes on devices you own or control.
            </p>
            <p>
              This license does not transfer ownership of the App.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              2. Restrictions
            </h2>
            <p>You agree not to:</p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Copy, modify, or distribute the App</li>
              <li>Reverse engineer, decompile, or attempt to extract source code</li>
              <li>Use the App for unlawful or misleading purposes</li>
              <li>Interfere with or disrupt the App’s functionality</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              3. Ownership
            </h2>
            <p>
              The App, including all content, design, code, and intellectual property, is owned by MintCheck and protected by applicable laws.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              4. Third-Party Platform (Apple)
            </h2>
            <p>
              This EULA is between you and MintCheck, not Apple.
            </p>
            <p>However:</p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Apple is not responsible for the App or its content</li>
              <li>Apple has no obligation to provide maintenance or support</li>
              <li>Apple is not responsible for addressing claims related to the App</li>
            </ul>
            <p>
              You agree to comply with applicable App Store terms.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              5. No Warranty
            </h2>
            <p>
              The App is provided <strong>“as is”</strong> and <strong>“as available.”</strong>
            </p>
            <p>MintCheck makes no guarantees regarding:</p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Accuracy of vehicle data or insights</li>
              <li>Availability or reliability of the App</li>
              <li>Fitness for a particular purpose</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              6. Limitation of Liability
            </h2>
            <p>To the fullest extent permitted by law:</p>
            <p>MintCheck is not liable for:</p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Vehicle issues, breakdowns, or repair costs</li>
              <li>Purchase decisions made using the App</li>
              <li>Any indirect, incidental, or consequential damages</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              7. Informational Use Only
            </h2>
            <p>
              The App provides <strong>informational insights only</strong> and does not replace a professional mechanic or inspection.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              8. Termination
            </h2>
            <p>
              This license is effective until terminated.
            </p>
            <p>
              MintCheck may terminate or suspend your access at any time if you violate this EULA.
            </p>
            <p>
              Upon termination, you must stop using and delete the App.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              9. Updates
            </h2>
            <p>
              MintCheck may update or modify the App at any time without notice.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              10. Governing Law
            </h2>
            <p>
              This EULA is governed by the laws of the United States, without regard to conflict-of-law principles.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              11. Contact
            </h2>
            <p>
              <strong>MintCheck</strong>
            </p>
            <p>
              Email: <a href="mailto:support@mintcheckapp.com" className="text-primary hover:underline">support@mintcheckapp.com</a>
            </p>
            <p>
              Website: <a href="https://mintcheckapp.com" className="text-primary hover:underline">mintcheckapp.com</a>
            </p>
          </section>
        </div>

        <div className="mt-12 pt-8 border-t border-border">
          <Link to="/" className="text-primary hover:underline" style={{ fontWeight: 600 }}>
            ← Back to Home
          </Link>
        </div>
      </main>

      <Footer />
    </div>
  );
}
