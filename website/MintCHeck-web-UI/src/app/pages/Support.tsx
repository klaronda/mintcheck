import { Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { HelpCircle, Smartphone, Car } from 'lucide-react';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { useAdmin } from '@/app/contexts/AdminContext';

export default function Support() {
  const { getArticlesByCategory } = useAdmin();

  const categories = [
    {
      name: 'Device Help',
      icon: Smartphone,
      description: 'Scanner setup, connection issues, and device troubleshooting',
      articles: getArticlesByCategory('Device Help'),
    },
    {
      name: 'Using the App',
      icon: HelpCircle,
      description: 'Learn how to use MintCheck features and understand your results',
      articles: getArticlesByCategory('Using the App'),
    },
    {
      name: 'Vehicle Support',
      icon: Car,
      description: 'Vehicle compatibility, diagnostic codes, and car-specific help',
      articles: getArticlesByCategory('Vehicle Support'),
    },
  ];

  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Support | MintCheck</title>
        <meta name="description" content="Get help with MintCheck. Find answers about device setup, using the app, and understanding your vehicle's diagnostics." />
      </Helmet>

      <Navbar />

      {/* Hero */}
      <div className="bg-[#3EB489] text-white py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h1 className="text-4xl md:text-5xl mb-4" style={{ fontWeight: 600 }}>
            How can we help?
          </h1>
          <p className="text-xl text-white/90">
            Find answers and learn how to get the most out of MintCheck
          </p>
        </div>
      </div>

      {/* Categories */}
      <div className="max-w-6xl mx-auto px-6 py-16">
        <div className="grid md:grid-cols-3 gap-8">
          {categories.map((category) => {
            const Icon = category.icon;
            return (
              <div key={category.name} className="border border-border rounded-lg p-6">
                <div className="w-12 h-12 bg-[#3EB489]/10 rounded-lg flex items-center justify-center mb-4">
                  <Icon className="w-6 h-6 text-[#3EB489]" />
                </div>
                <h2 className="text-xl mb-2" style={{ fontWeight: 600 }}>
                  {category.name}
                </h2>
                <p className="text-muted-foreground text-sm mb-6">
                  {category.description}
                </p>

                <div className="space-y-3">
                  {category.articles.length > 0 ? (
                    category.articles.map((article) => (
                      <Link
                        key={article.id}
                        to={`/support/${article.slug}`}
                        className="block text-sm text-[#3EB489] hover:underline"
                      >
                        {article.title}
                      </Link>
                    ))
                  ) : (
                    <p className="text-sm text-muted-foreground">No articles yet</p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Contact */}
      <div className="bg-gray-50 py-16">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h2 className="text-2xl mb-4" style={{ fontWeight: 600 }}>
            Still need help?
          </h2>
          <p className="text-muted-foreground mb-6">
            Can't find what you're looking for? Get in touch with our support team.
          </p>
          <a
            href="mailto:support@mintcheckapp.com"
            className="inline-block bg-[#3EB489] text-white px-6 py-3 rounded-lg hover:bg-[#359e7a] transition-colors"
            style={{ fontWeight: 600 }}
          >
            Contact Support
          </a>
        </div>
      </div>

      {/* Footer */}
      <Footer />
    </div>
  );
}