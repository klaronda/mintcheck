import { Link } from 'react-router';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { Helmet } from 'react-helmet-async';
import { getOrganizationSchema } from '@/app/utils/structuredData';

export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Privacy Policy | MintCheck</title>
        <meta name="description" content="MintCheck Privacy Policy. Learn how we collect, use, and protect your vehicle and scan data." />
        <meta name="robots" content="index, follow" />
        <link rel="canonical" href="https://mintcheckapp.com/privacy" />
        
        {/* Open Graph */}
        <meta property="og:title" content="Privacy Policy | MintCheck" />
        <meta property="og:description" content="MintCheck Privacy Policy. Learn how we collect, use, and protect your vehicle and scan data." />
        <meta property="og:type" content="website" />
        <meta property="og:url" content="https://mintcheckapp.com/privacy" />
        <meta property="og:image" content="https://mintcheckapp.com/og-image.jpg" />
        <meta property="og:site_name" content="MintCheck" />
        
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary" />
        <meta name="twitter:title" content="Privacy Policy | MintCheck" />
        <meta name="twitter:description" content="MintCheck Privacy Policy - Learn how we protect your data." />
        
        {/* Structured Data */}
        <script type="application/ld+json">
          {JSON.stringify(getOrganizationSchema())}
        </script>
      </Helmet>

      {/* Navbar */}
      <Navbar />

      {/* Content */}
      <main className="max-w-4xl mx-auto px-6 py-16">
        <h1 className="text-4xl mb-8" style={{ fontWeight: 600 }}>
          MintCheck Privacy Policy
        </h1>
        
        <div className="space-y-8 text-muted-foreground leading-relaxed">
          <p className="text-sm text-muted-foreground italic">
            Last updated: January 23, 2026
          </p>

          <p>
            MintCheck ("<strong>MintCheck</strong>," "<strong>we</strong>," "<strong>us</strong>," or "<strong>our</strong>") respects your privacy and is committed to being transparent about how we collect, use, and protect information. This Privacy Policy explains what data we collect when you use the MintCheck mobile application and related services (the "<strong>Service</strong>").
          </p>

          <p>
            By using MintCheck, you agree to the practices described in this Privacy Policy.
          </p>

          <hr className="border-border" />

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              1. Overview
            </h2>
            <p>
              MintCheck helps users better understand a vehicle’s condition by reading data from a vehicle’s onboard systems and presenting it in a clear, useful way.
            </p>
            <p>
              MintCheck:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Does <strong>not</strong> require you to create an account</li>
              <li>Does <strong>not</strong> require your name, email address, or phone number</li>
              <li>Does <strong>not</strong> sell personal data</li>
              <li>Is <strong>free to use</strong> at this time</li>
            </ul>
            <p>
              MintCheck is <strong>not a replacement for a professional mechanic or vehicle inspection</strong>. See Section 8 for important disclaimers.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              2. Information We Collect
            </h2>
            
            <div className="space-y-4">
              <div>
                <h3 className="text-xl text-foreground mb-2" style={{ fontWeight: 600 }}>
                  A. Vehicle & Scan Data
                </h3>
                <p>
                  When you connect MintCheck to a vehicle, we may collect technical data including:
                </p>
                <ul className="list-disc pl-8 space-y-2 mt-2">
                  <li>Vehicle Identification Number (VIN)</li>
                  <li>Vehicle make, model, year, and engine type</li>
                  <li>Trouble codes (DTCs)</li>
                  <li>Emissions and system status indicators</li>
                  <li>Sensor readings and system health signals</li>
                  <li>Scan timestamps and basic scan metadata</li>
                </ul>
                <p className="mt-2">
                  This data is <strong>about the vehicle</strong>, not about you as a person.
                </p>
              </div>

              <div>
                <h3 className="text-xl text-foreground mb-2" style={{ fontWeight: 600 }}>
                  B. App Usage Data
                </h3>
                <p>
                  We may collect limited, non-identifying usage data to improve the app, such as:
                </p>
                <ul className="list-disc pl-8 space-y-2 mt-2">
                  <li>App version and device type</li>
                  <li>Feature usage patterns</li>
                  <li>Crash logs and performance metrics</li>
                </ul>
                <p className="mt-2">
                  This data is aggregated and does <strong>not</strong> identify you personally.
                </p>
              </div>

              <div>
                <h3 className="text-xl text-foreground mb-2" style={{ fontWeight: 600 }}>
                  C. What We Do NOT Collect
                </h3>
                <p>
                  We do <strong>not</strong> collect:
                </p>
                <ul className="list-disc pl-8 space-y-2 mt-2">
                  <li>Names</li>
                  <li>Email addresses</li>
                  <li>Phone numbers</li>
                  <li>Precise location data</li>
                  <li>Government IDs</li>
                  <li>Payment information (no purchases or subscriptions at this time)</li>
                </ul>
              </div>
            </div>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              3. How We Use Information
            </h2>
            <p>
              We use collected data to:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Generate vehicle health insights and summaries</li>
              <li>Improve accuracy, reliability, and performance</li>
              <li>Debug issues and improve user experience</li>
              <li>Conduct internal research and product development</li>
            </ul>
            <p>
              We do <strong>not</strong> use vehicle data to make guarantees, warranties, or predictions about future vehicle performance.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              4. Data Sharing
            </h2>
            
            <div className="space-y-4">
              <div>
                <h3 className="text-xl text-foreground mb-2" style={{ fontWeight: 600 }}>
                  A. No Sale of Personal Data
                </h3>
                <p>
                  MintCheck does <strong>not sell personal data</strong>.
                </p>
                <p>
                  Because we do not collect personal identifying information, there is no personal data to sell.
                </p>
              </div>

              <div>
                <h3 className="text-xl text-foreground mb-2" style={{ fontWeight: 600 }}>
                  B. Service Providers
                </h3>
                <p>
                  We may share limited data with trusted service providers (such as cloud infrastructure or analytics tools) strictly to operate and improve the Service. These providers are contractually obligated to protect the data and use it only for permitted purposes.
                </p>
              </div>

              <div>
                <h3 className="text-xl text-foreground mb-2" style={{ fontWeight: 600 }}>
                  C. Aggregated & Anonymized Data
                </h3>
                <p>
                  In the future, MintCheck may use or share <strong>aggregated, anonymized vehicle data</strong> (for example, trends across makes or model years). This data:
                </p>
                <ul className="list-disc pl-8 space-y-2 mt-2">
                  <li>Cannot be traced back to an individual or specific user</li>
                  <li>Does not include personal identifying information</li>
                  <li>Is used for research, insights, or industry analysis</li>
                </ul>
              </div>
            </div>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              5. Data Retention
            </h2>
            <p>
              We retain vehicle and usage data only as long as reasonably necessary to:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Provide the Service</li>
              <li>Improve product quality</li>
              <li>Comply with legal obligations</li>
            </ul>
            <p>
              We may delete or anonymize data at any time.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              6. Data Security
            </h2>
            <p>
              We use reasonable administrative, technical, and organizational safeguards to protect data. However, no system is 100% secure, and we cannot guarantee absolute security.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              7. Children’s Privacy
            </h2>
            <p>
              MintCheck is not intended for use by children under 13. We do not knowingly collect data from children.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              8. Important Disclaimers
            </h2>
            <p>
              MintCheck provides <strong>informational insights only</strong>.
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>MintCheck does <strong>not</strong> perform physical inspections</li>
              <li>MintCheck does <strong>not</strong> detect all mechanical issues</li>
              <li>MintCheck does <strong>not</strong> replace a licensed mechanic</li>
              <li>MintCheck does <strong>not</strong> guarantee vehicle reliability or future performance</li>
            </ul>
            <p>
              Vehicle conditions can change quickly, and some issues may not show up in the car’s onboard systems.
            </p>
            <p>
              <strong>You remain solely responsible for purchase decisions, inspections, and repairs.</strong>
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              9. Changes to This Policy
            </h2>
            <p>
              We may update this Privacy Policy from time to time. If we make material changes, we will update the "Last updated" date above. Continued use of the Service means you accept the updated policy.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              10. Contact Us
            </h2>
            <p>
              If you have questions about this Privacy Policy, contact us at:
            </p>
            <p>
              <strong>MintCheck</strong><br />
              Email: <a href="mailto:privacy@mintcheckapp.com" className="text-primary hover:underline">privacy@mintcheckapp.com</a><br />
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

      {/* Footer */}
      <Footer />
    </div>
  );
}