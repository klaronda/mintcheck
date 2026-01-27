import { Link } from 'react-router';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { Helmet } from 'react-helmet-async';

export default function TermsOfUse() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Terms of Use | MintCheck</title>
        <meta name="description" content="MintCheck Terms of Use - Read our terms and conditions for using the MintCheck OBD-II car diagnostics app." />
        <meta name="robots" content="index, follow" />
      </Helmet>

      {/* Navbar */}
      <Navbar />

      {/* Content */}
      <main className="max-w-4xl mx-auto px-6 py-16">
        <h1 className="text-4xl mb-8" style={{ fontWeight: 600 }}>
          Terms of Use
        </h1>
        
        <div className="space-y-8 text-muted-foreground leading-relaxed">
          <p className="text-sm text-muted-foreground">
            Last Updated: January 23, 2026
          </p>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Agreement to Terms
            </h2>
            <p>
              By using MintCheck, you agree to these Terms of Use. If you don't agree, please don't use the app.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              What MintCheck Does
            </h2>
            <p>
              MintCheck helps you understand your vehicle's diagnostic data by reading OBD-II information and explaining it in simple terms. The app provides educational information to help you make better decisions about your vehicle.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Important Limitations
            </h2>
            <p>
              <strong>MintCheck is not a replacement for professional automotive service.</strong> The app provides information and guidance, but:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>It cannot diagnose all vehicle problems</li>
              <li>It cannot repair your vehicle</li>
              <li>It should not replace professional inspections, especially when buying a used car</li>
              <li>Always consult a qualified mechanic for major repairs or safety concerns</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Your Responsibilities
            </h2>
            <p>
              When using MintCheck, you agree to:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Provide accurate information</li>
              <li>Use the app only for lawful purposes</li>
              <li>Not attempt to reverse engineer or hack the app</li>
              <li>Not share your account with others</li>
              <li>Use proper OBD-II scanners that are compatible with MintCheck</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              No Warranties
            </h2>
            <p>
              MintCheck is provided "as is" without any warranties. We don't guarantee that:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>The app will always be available or error-free</li>
              <li>Information provided will be completely accurate for all vehicles</li>
              <li>The app will meet all your needs</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Limitation of Liability
            </h2>
            <p>
              To the maximum extent permitted by law, MintCheck and its creators are not responsible for:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Any decisions you make based on information from the app</li>
              <li>Vehicle damage or mechanical failures</li>
              <li>Losses from purchasing or not purchasing a vehicle</li>
              <li>Any indirect, incidental, or consequential damages</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Third-Party Scanners
            </h2>
            <p>
              MintCheck recommends certain OBD-II scanners, but we don't manufacture or sell them. We're not responsible for scanner quality, compatibility, or performance. The links to purchase scanners are provided for your convenience.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Account Termination
            </h2>
            <p>
              We may suspend or terminate your account if you violate these Terms or use the app in ways that could harm MintCheck or other users.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Changes to Terms
            </h2>
            <p>
              We may update these Terms from time to time. Continued use of the app after changes means you accept the new Terms.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Governing Law
            </h2>
            <p>
              These Terms are governed by the laws of the United States. Any disputes will be resolved in the appropriate courts.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Contact Us
            </h2>
            <p>
              If you have questions about these Terms, please contact us at:
            </p>
            <p>
              Email: <a href="mailto:support@mintcheckapp.com" className="text-primary hover:underline">support@mintcheckapp.com</a>
            </p>
          </section>
        </div>

        <div className="mt-12 pt-8 border-t border-border">
          <Link to="/" className="text-primary hover:underline" style={{ fontWeight: 600 }}>
            ← Back to Home
          </Link>
        </div>
      </main>

      {/* Footer */}
      <Footer />
    </div>
  );
}