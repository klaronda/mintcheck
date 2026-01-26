import { useParams, Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { ArrowLeft } from 'lucide-react';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { useAdmin } from '@/app/contexts/AdminContext';
import { getOrganizationSchema, getArticleSchema, getBreadcrumbSchema } from '@/app/utils/structuredData';

export default function SupportArticle() {
  const { slug } = useParams<{ slug: string }>();
  const { getArticle } = useAdmin();
  
  const article = slug ? getArticle(slug) : null;

  if (!article || article.type !== 'support') {
    return (
      <div className="min-h-screen bg-white">
        <Navbar />
        <div className="max-w-4xl mx-auto px-6 py-16 text-center">
          <h1 className="text-3xl mb-4" style={{ fontWeight: 600 }}>Article Not Found</h1>
          <Link to="/support" className="text-[#3EB489] hover:underline">
            Back to Support
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>{article.title} | Support | MintCheck</title>
        <meta name="description" content={article.summary || article.cardDescription} />
        <meta name="robots" content="index, follow" />
        <link rel="canonical" href={`https://mintcheckapp.com/support/${article.slug}`} />
        
        {/* Open Graph */}
        <meta property="og:title" content={`${article.title} | MintCheck Support`} />
        <meta property="og:description" content={article.summary || article.cardDescription} />
        <meta property="og:type" content="article" />
        <meta property="og:url" content={`https://mintcheckapp.com/support/${article.slug}`} />
        <meta property="og:image" content={article.heroImage} />
        <meta property="og:site_name" content="MintCheck" />
        
        {/* Twitter Card */}
        <meta name="twitter:card" content="summary" />
        <meta name="twitter:title" content={article.title} />
        <meta name="twitter:description" content={article.summary || article.cardDescription} />
        
        {/* Structured Data */}
        <script type="application/ld+json">
          {JSON.stringify(getOrganizationSchema())}
        </script>
        <script type="application/ld+json">
          {JSON.stringify(getArticleSchema({
            title: article.title,
            summary: article.summary || article.cardDescription,
            slug: article.slug,
            type: article.type,
            createdAt: article.createdAt,
            updatedAt: article.updatedAt,
            heroImage: article.heroImage,
          }))}
        </script>
        <script type="application/ld+json">
          {JSON.stringify(getBreadcrumbSchema([
            { name: 'Home', url: 'https://mintcheckapp.com' },
            { name: 'Support', url: 'https://mintcheckapp.com/support' },
            { name: article.title, url: `https://mintcheckapp.com/support/${article.slug}` },
          ]))}
        </script>
      </Helmet>

      <Navbar />

      {/* Hero Image */}
      <div className="h-[400px] relative overflow-hidden">
        <img
          src={article.heroImage}
          alt={article.title}
          className="w-full h-full object-cover"
          fetchPriority="high"
          width="1200"
          height="400"
          decoding="async"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-6 py-12">
        <Link
          to="/support"
          className="inline-flex items-center gap-2 text-[#3EB489] hover:underline mb-8"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Support
        </Link>

        {article.category && (
          <div className="mb-4">
            <span className="inline-block px-3 py-1 bg-[#3EB489]/10 text-[#3EB489] rounded text-sm">
              {article.category}
            </span>
          </div>
        )}

        <h1 className="text-4xl md:text-5xl mb-6" style={{ fontWeight: 600 }}>
          {article.title}
        </h1>

        <p className="text-xl text-muted-foreground mb-12">
          {article.summary}
        </p>

        <div 
          className="prose prose-lg max-w-none"
          dangerouslySetInnerHTML={{ __html: article.body }}
        />

        <div className="mt-12 pt-8 border-t border-border">
          <p className="text-sm text-muted-foreground mb-4">
            Was this article helpful?
          </p>
          <div className="flex gap-4" role="group" aria-label="Article feedback">
            <button 
              className="px-6 py-2 border border-border rounded-lg hover:bg-gray-50 transition-colors"
              aria-label="Mark article as helpful"
            >
              Yes
            </button>
            <button 
              className="px-6 py-2 border border-border rounded-lg hover:bg-gray-50 transition-colors"
              aria-label="Mark article as not helpful"
            >
              No
            </button>
          </div>
        </div>
      </div>

      {/* Footer */}
      <Footer />

      <style>{`
        .prose h1, .prose h2, .prose h3 {
          font-weight: 600;
          color: #000;
        }
        .prose h2 {
          font-size: 1.875rem;
          margin-top: 2em;
          margin-bottom: 1em;
        }
        .prose h3 {
          font-size: 1.5rem;
          margin-top: 1.6em;
          margin-bottom: 0.6em;
        }
        .prose p {
          margin-bottom: 1.25em;
          line-height: 1.75;
        }
        .prose ul, .prose ol {
          margin: 1.25em 0;
          padding-left: 1.625em;
        }
        .prose li {
          margin-bottom: 0.5em;
        }
        .prose a {
          color: #3EB489;
          text-decoration: underline;
        }
        .prose img {
          border-radius: 8px;
          margin: 2em 0;
        }
      `}</style>
    </div>
  );
}