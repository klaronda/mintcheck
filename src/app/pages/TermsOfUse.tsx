import { Link } from 'react-router';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { Helmet } from 'react-helmet-async';
import { getOrganizationSchema } from '@/app/utils/structuredData';

export default function TermsOfUse() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Terms of Use | MintCheck</title>
        <meta name="description" content="MintCheck Terms of Use. Read our terms and conditions for using the MintCheck app." />
        <meta name="robots" content="index, follow" />
        <link rel="canonical" href="https://mintcheckapp.com/terms" />
        
        {/* Open Graph */}
        <meta property="og:title" content="Terms of Use | MintCheck" />
        <meta property="og:description" content="MintCheck Terms of Use - Read our terms and conditions for using the MintCheck app." />
        <meta property="og:type" content="website" />
        <meta property="og:url" content="https://mintcheckapp.com/terms" />
        <meta property="og:image" content="https://mintcheckapp.com/og-image.jpg" />
        <meta property="og:site_name" content="MintCheck" />
        
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary" />
        <meta name="twitter:title" content="Terms of Use | MintCheck" />
        <meta name="twitter:description" content="MintCheck Terms of Use - Read our terms and conditions." />
        
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
          MintCheck Terms of Service
        </h1>
        
        <div className="space-y-8 text-muted-foreground leading-relaxed">
          <p className="text-sm text-muted-foreground italic">
            Last updated: January 23, 2026
          </p>

          <p>
            These Terms of Service ("<strong>Terms</strong>") govern your access to and use of the MintCheck mobile application and related services (the "<strong>Service</strong>"), operated by MintCheck ("<strong>MintCheck</strong>," "<strong>we</strong>," "<strong>us</strong>," or "<strong>our</strong>").
          </p>

          <p>
            By accessing or using the Service, you agree to be bound by these Terms. If you do not agree, do not use the Service.
          </p>

          <hr className="border-border" />

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              1. Purpose of the Service
            </h2>
            <p>
              MintCheck provides vehicle health insights by reading data from a vehicle’s onboard systems and presenting that information in an easy-to-understand format.
            </p>
            <p>
              The Service is intended for <strong>informational and educational purposes only</strong>.
            </p>
            <p>
              MintCheck does <strong>not</strong>:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Perform mechanical repairs or inspections</li>
              <li>Guarantee vehicle condition or reliability</li>
              <li>Replace a licensed mechanic or professional inspection</li>
              <li>Provide warranties, certifications, or guarantees</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              2. Eligibility
            </h2>
            <p>
              You must be at least 13 years old to use the Service.
            </p>
            <p>
              By using MintCheck, you represent that you meet this requirement.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              3. No Professional Advice
            </h2>
            <p>
              MintCheck does <strong>not</strong> provide mechanical, automotive, legal, or financial advice.
            </p>
            <p>
              All insights, summaries, or indicators (including phrases such as "Car is Healthy" or similar language) are <strong>non-binding informational signals</strong>, not statements of fact or guarantees.
            </p>
            <p>
              Vehicle systems can fail without warning, and many issues cannot be detected through the car’s onboard systems.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              4. User Responsibility
            </h2>
            <p>
              You acknowledge and agree that:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>You are solely responsible for evaluating a vehicle before purchase</li>
              <li>You should obtain a professional, in-person mechanical inspection when appropriate</li>
              <li>You assume all risk related to vehicle purchases, ownership, and operation</li>
              <li>MintCheck is one of many tools you may choose to consult, not a definitive authority</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              5. Free Use; No Subscription
            </h2>
            <p>
              At this time:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>The Service is provided <strong>free of charge</strong></li>
              <li>No subscription, payment, or billing is required</li>
              <li>MintCheck may introduce paid features or subscriptions in the future</li>
            </ul>
            <p>
              If pricing or subscriptions are introduced, updated terms will be provided before any charges apply.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              6. Acceptable Use
            </h2>
            <p>
              You agree not to:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Use the Service for unlawful purposes</li>
              <li>Attempt to reverse engineer, modify, or interfere with the Service</li>
              <li>Use the Service to misrepresent vehicle condition to others</li>
              <li>Scrape, extract, or misuse data from the Service at scale</li>
            </ul>
            <p>
              MintCheck reserves the right to suspend or terminate access for misuse.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              7. Data & Privacy
            </h2>
            <p>
              Your use of the Service is also governed by the <strong>MintCheck Privacy Policy</strong>, which explains how data is collected and used.
            </p>
            <p>
              By using the Service, you consent to the practices described in that policy.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              8. No Warranties
            </h2>
            <p>
              The Service is provided <strong>"as is"</strong> and <strong>"as available."</strong>
            </p>
            <p>
              To the fullest extent permitted by law, MintCheck disclaims all warranties, express or implied, including but not limited to:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Merchantability</li>
              <li>Fitness for a particular purpose</li>
              <li>Accuracy, completeness, or reliability of data</li>
              <li>Uninterrupted or error-free operation</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              9. Limitation of Liability
            </h2>
            <p>
              To the fullest extent permitted by law:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>MintCheck shall <strong>not be liable</strong> for any indirect, incidental, consequential, or special damages</li>
              <li>MintCheck shall <strong>not be responsible</strong> for vehicle failures, breakdowns, repair costs, or financial losses</li>
              <li>MintCheck shall <strong>not be liable</strong> for purchase decisions made based on the Service</li>
            </ul>
            <p>
              Your sole remedy for dissatisfaction with the Service is to stop using it.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              10. Assumption of Risk
            </h2>
            <p>
              You understand and agree that vehicle scans have limits and are not certain.
            </p>
            <p>
              By using the Service, you knowingly assume all risks associated with:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Vehicle condition</li>
              <li>Vehicle purchases</li>
              <li>Vehicle operation and maintenance</li>
            </ul>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              11. Changes to the Service
            </h2>
            <p>
              MintCheck may:
            </p>
            <ul className="list-disc pl-8 space-y-2">
              <li>Modify or discontinue features at any time</li>
              <li>Update the Service without notice</li>
              <li>Improve, limit, or remove functionality</li>
            </ul>
            <p>
              We are not obligated to maintain any specific feature or data availability.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              12. Changes to These Terms
            </h2>
            <p>
              We may update these Terms from time to time. If changes are material, we will update the "Last updated" date above.
            </p>
            <p>
              Continued use of the Service after changes means you accept the updated Terms.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              13. Governing Law
            </h2>
            <p>
              These Terms are governed by and construed in accordance with the laws of the United States, without regard to conflict-of-law principles.
            </p>
          </section>

          <section className="space-y-4">
            <h2 className="text-2xl text-foreground" style={{ fontWeight: 600 }}>
              14. Contact Information
            </h2>
            <p>
              If you have questions about these Terms, contact us at:
            </p>
            <p>
              <strong>MintCheck</strong><br />
              Email: <a href="mailto:terms@mintcheckapp.com" className="text-primary hover:underline">terms@mintcheckapp.com</a><br />
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