import { Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { Calendar } from 'lucide-react';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';
import { useAdmin } from '@/app/contexts/AdminContext';

export default function Blog() {
  const { getBlogArticles } = useAdmin();
  const articles = getBlogArticles();

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  };

  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Blog | MintCheck</title>
        <meta name="description" content="Read the latest articles about car diagnostics, vehicle maintenance, and getting the most out of your OBD-II scanner." />
      </Helmet>

      <Navbar />

      {/* Hero */}
      <div className="bg-[#3EB489] text-white py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h1 className="text-4xl md:text-5xl mb-4" style={{ fontWeight: 600 }}>
            MintCheck Blog
          </h1>
          <p className="text-xl text-white/90">
            Tips, insights, and news about car diagnostics and vehicle health
          </p>
        </div>
      </div>

      {/* Articles */}
      <div className="max-w-4xl mx-auto px-6 py-16">
        {articles.length > 0 ? (
          <div className="space-y-16">
            {/* Hero - Latest Post */}
            {articles[0] && (
              <article className="pb-12 border-b border-border">
                <Link to={`/blog/${articles[0].slug}`} className="block group">
                  <img
                    src={articles[0].heroImage}
                    alt={articles[0].title}
                    className="w-full h-96 object-cover rounded-lg mb-6 group-hover:opacity-90 transition-opacity"
                  />
                  
                  <div className="flex items-center gap-2 text-sm text-muted-foreground mb-3">
                    <Calendar className="w-4 h-4" />
                    <time>{formatDate(articles[0].createdAt)}</time>
                  </div>

                  <h2 className="text-3xl md:text-4xl mb-4 group-hover:text-[#3EB489] transition-colors" style={{ fontWeight: 600 }}>
                    {articles[0].title}
                  </h2>

                  <p className="text-lg text-muted-foreground mb-4">
                    {articles[0].cardDescription}
                  </p>

                  <span className="text-[#3EB489] group-hover:underline" style={{ fontWeight: 600 }}>
                    Read more →
                  </span>
                </Link>
              </article>
            )}

            {/* Older Posts - Card Grid */}
            {articles.length > 1 && (
              <div>
                <h3 className="text-xl mb-6" style={{ fontWeight: 600 }}>
                  More Articles
                </h3>
                <div className="grid md:grid-cols-3 gap-6">
                  {articles.slice(1).map((article) => (
                    <Link
                      key={article.id}
                      to={`/blog/${article.slug}`}
                      className="block group border border-border rounded-lg overflow-hidden hover:shadow-lg transition-shadow"
                    >
                      <img
                        src={article.heroImage}
                        alt={article.title}
                        className="w-full h-48 object-cover group-hover:opacity-90 transition-opacity"
                      />
                      <div className="p-4">
                        <div className="flex items-center gap-2 text-xs text-muted-foreground mb-2">
                          <Calendar className="w-3 h-3" />
                          <time>{formatDate(article.createdAt)}</time>
                        </div>
                        <h3 className="text-lg mb-2 group-hover:text-[#3EB489] transition-colors" style={{ fontWeight: 600 }}>
                          {article.title}
                        </h3>
                        <p className="text-sm text-muted-foreground line-clamp-2">
                          {article.cardDescription}
                        </p>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            )}
          </div>
        ) : (
          <div className="text-center py-12 text-muted-foreground">
            <p className="text-xl mb-4">No blog posts yet</p>
            <p>Check back soon for new articles!</p>
          </div>
        )}
      </div>

      {/* Footer */}
      <Footer />
    </div>
  );
}