import { useState } from 'react';
import { Mail, Send } from 'lucide-react';
import { Helmet } from 'react-helmet-async';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { contactApi } from '@/lib/supabase';
import { getOrganizationSchema, getContactPageSchema } from '@/app/utils/structuredData';

export default function Contact() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: '',
  });
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [statusMessage, setStatusMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('loading');
    setStatusMessage('');

    try {
      await contactApi.submit(formData.name, formData.email, formData.message);
      setStatus('success');
      setStatusMessage('Thanks for reaching out! We’ll get back to you soon.');
      setFormData({ name: '', email: '', message: '' });
    } catch (error) {
      setStatus('error');
      setStatusMessage(error instanceof Error ? error.message : 'Something went wrong. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Contact Us | MintCheck</title>
        <meta name="description" content="Get in touch with the MintCheck team. We’re here to help with questions, feedback, or support." />
        <meta name="robots" content="index, follow" />
        <link rel="canonical" href="https://mintcheckapp.com/contact" />
        
        {/* Open Graph */}
        <meta property="og:title" content="Contact Us | MintCheck" />
        <meta property="og:description" content="Get in touch with the MintCheck team. We’re here to help with questions, feedback, or support." />
        <meta property="og:type" content="website" />
        <meta property="og:url" content="https://mintcheckapp.com/contact" />
        <meta property="og:image" content="https://mintcheckapp.com/og-image.jpg" />
        <meta property="og:site_name" content="MintCheck" />
        
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary" />
        <meta name="twitter:title" content="Contact Us | MintCheck" />
        <meta name="twitter:description" content="Get in touch with the MintCheck team." />
        
        {/* Structured Data */}
        <script type="application/ld+json">
          {JSON.stringify(getOrganizationSchema())}
        </script>
        <script type="application/ld+json">
          {JSON.stringify(getContactPageSchema())}
        </script>
      </Helmet>

      <Navbar />

      {/* Hero */}
      <div className="bg-[#3EB489] text-white py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h1 className="text-4xl md:text-5xl mb-4" style={{ fontWeight: 600 }}>
            Contact Us
          </h1>
          <p className="text-xl text-white/90">
            Have a question? We’re here to help.
          </p>
        </div>
      </div>

      {/* Contact Form */}
      <section className="max-w-2xl mx-auto px-6 py-24">
        <div className="bg-white border border-border rounded-lg p-8">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-12 h-12 bg-accent rounded-lg flex items-center justify-center">
              <Mail className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h2 className="text-2xl" style={{ fontWeight: 600 }}>
                Send us a message
              </h2>
              <p className="text-sm text-muted-foreground">
                We typically respond within 24 hours
              </p>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="name" className="block text-sm font-medium mb-2">
                Name
              </label>
              <input
                type="text"
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
                className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="Your name"
              />
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium mb-2">
                Email
              </label>
              <input
                type="email"
                id="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                required
                className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="your@email.com"
              />
            </div>

            <div>
              <label htmlFor="message" className="block text-sm font-medium mb-2">
                Message
              </label>
              <textarea
                id="message"
                value={formData.message}
                onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                required
                rows={6}
                className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary resize-none"
                placeholder="Tell us what’s on your mind..."
              />
            </div>

            {statusMessage && (
              <div className={`p-4 rounded-lg ${
                status === 'success' 
                  ? 'bg-[#E6F4EE] text-[#3EB489]' 
                  : 'bg-red-50 text-red-600'
              }`}>
                {statusMessage}
              </div>
            )}

            <button
              type="submit"
              disabled={status === 'loading'}
              className="w-full inline-flex items-center justify-center gap-2 bg-primary text-primary-foreground px-8 py-4 rounded-lg transition-opacity hover:opacity-90 disabled:opacity-50"
              style={{ fontWeight: 600 }}
            >
              {status === 'loading' ? (
                <>Sending...</>
              ) : (
                <>
                  <Send className="w-5 h-5" />
                  Send Message
                </>
              )}
            </button>
          </form>
        </div>

        {/* Alternative Contact */}
        <div className="mt-12 text-center">
          <p className="text-muted-foreground mb-2">
            Prefer email? Reach us directly at
          </p>
          <a 
            href="mailto:support@mintcheckapp.com" 
            className="text-[#3EB489] hover:underline font-medium"
          >
            support@mintcheckapp.com
          </a>
        </div>
      </section>

      <Footer />
    </div>
  );
}
