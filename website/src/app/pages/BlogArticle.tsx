import { useParams, Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { ArrowLeft, Calendar } from 'lucide-react';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { useAdmin } from '@/app/contexts/AdminContext';

export default function BlogArticle() {
  const { slug } = useParams<{ slug: string }>();
  const { getArticle } = useAdmin();
  
  const article = slug ? getArticle(slug) : null;

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  };

  if (!article || article.type !== 'blog') {
    return (
      <div className="min-h-screen bg-white">
        <Navbar />
        <div className="max-w-4xl mx-auto px-6 py-16 text-center">
          <h1 className="text-3xl mb-4" style={{ fontWeight: 600 }}>Article Not Found</h1>
          <Link to="/blog" className="text-[#3EB489] hover:underline">
            Back to Blog
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>{article.title} | Blog | MintCheck</title>
        <meta name="description" content={article.summary} />
      </Helmet>

      <Navbar />

      {/* Hero Image */}
      <div className="h-[400px] relative overflow-hidden">
        <img
          src={article.heroImage}
          alt={article.title}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-6 py-12">
        <Link
          to="/blog"
          className="inline-flex items-center gap-2 text-[#3EB489] hover:underline mb-8"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Blog
        </Link>

        <div className="flex items-center gap-2 text-sm text-muted-foreground mb-4">
          <Calendar className="w-4 h-4" />
          <time>{formatDate(article.createdAt)}</time>
        </div>

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

        <div className="mt-12 pt-8 border-t border-border flex justify-between items-center">
          <p className="text-sm text-muted-foreground">
            Published on {formatDate(article.createdAt)}
          </p>
          <Link
            to="/blog"
            className="text-[#3EB489] hover:underline"
            style={{ fontWeight: 600 }}
          >
            ← Back to all posts
          </Link>
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