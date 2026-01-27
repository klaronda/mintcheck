import { Link } from 'react-router';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { Helmet } from 'react-helmet-async';

export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Privacy Policy | MintCheck</title>
        <meta name="description" content="MintCheck Privacy Policy - Learn how we collect, use, and protect your vehicle diagnostic data and personal information." />
        <meta name="robots" content="index, follow" />
      </Helmet>

      {/* Navbar */}
      <Navbar />

      {/* Content */}
      <main className="max-w-4xl mx-auto px-6 py-16">
        <h1 className="text-4xl mb-8" style={{ fontWeight: 600 }}>
          Privacy Policy
        </h1>
        
        <div className="space-y-8 text-muted-foreground leading-relaxed">
          <p className="text-sm text-muted-foreground">
            Last Updated: January 23, 2026
          </p>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Introduction
            </h2>
            <p>
              MintCheck ("we," "our," or "us") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and share information when you use our mobile app.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Information We Collect
            </h2>
            <p>
              <strong>Account Information:</strong> When you create an account, we collect your email address and any other information you choose to provide.
            </p>
            <p>
              <strong>Vehicle Data:</strong> We collect diagnostic data from your vehicle through OBD-II scanners, including error codes, sensor readings, and vehicle status information.
            </p>
            <p>
              <strong>Usage Data:</strong> We collect information about how you use the app, including features accessed and scan history.
            </p>
            <p>
              <strong>Device Information:</strong> We collect information about your mobile device, including device type, operating system, and unique device identifiers.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              How We Use Your Information
            </h2>
            <p>
              We use the information we collect to:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Provide and improve the MintCheck service</li>
              <li>Analyze vehicle diagnostic data and provide you with clear explanations</li>
              <li>Track your vehicle's history over time</li>
              <li>Send you important updates about the app</li>
              <li>Respond to your questions and support requests</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              How We Share Your Information
            </h2>
            <p>
              We do not sell your personal information. We may share your information only in the following circumstances:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li><strong>With Your Consent:</strong> When you explicitly agree to share information</li>
              <li><strong>Service Providers:</strong> With trusted third parties who help us operate the app</li>
              <li><strong>Legal Requirements:</strong> When required by law or to protect our rights</li>
              <li><strong>Business Transfers:</strong> In connection with a merger, sale, or acquisition</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Data Security
            </h2>
            <p>
              We use industry-standard security measures to protect your information. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Your Rights
            </h2>
            <p>
              You have the right to:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Access and download your data</li>
              <li>Request correction of inaccurate data</li>
              <li>Request deletion of your account and data</li>
              <li>Opt out of marketing communications</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Children's Privacy
            </h2>
            <p>
              MintCheck is not intended for use by children under 13 years of age. We do not knowingly collect information from children under 13.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Changes to This Policy
            </h2>
            <p>
              We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new policy in the app and updating the "Last Updated" date.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              Contact Us
            </h2>
            <p>
              If you have questions about this Privacy Policy, please contact us at:
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