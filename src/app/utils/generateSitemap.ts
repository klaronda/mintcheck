import { articlesApi } from '@/lib/supabase';
import type { Article } from '@/lib/supabase';

const BASE_URL = 'https://mintcheckapp.com';

// Static routes configuration
const staticRoutes = [
  { path: '/', priority: '1.0', changefreq: 'weekly' },
  { path: '/download', priority: '0.9', changefreq: 'monthly' },
  { path: '/contact', priority: '0.7', changefreq: 'monthly' },
  { path: '/blog', priority: '0.8', changefreq: 'weekly' },
  { path: '/support', priority: '0.8', changefreq: 'weekly' },
  { path: '/privacy', priority: '0.3', changefreq: 'yearly' },
  { path: '/terms', priority: '0.3', changefreq: 'yearly' },
];

// Format date for sitemap (YYYY-MM-DD)
function formatDate(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toISOString().split('T')[0];
}

// Generate XML sitemap entry
function generateUrlEntry(path: string, lastmod: string, changefreq: string, priority: string): string {
  return `  <url>
    <loc>${BASE_URL}${path}</loc>
    <lastmod>${lastmod}</lastmod>
    <changefreq>${changefreq}</changefreq>
    <priority>${priority}</priority>
  </url>`;
}

// Generate complete sitemap XML
export async function generateSitemap(): Promise<string> {
  const today = formatDate(new Date());
  const urls: string[] = [];

  // Add static routes
  for (const route of staticRoutes) {
    urls.push(generateUrlEntry(route.path, today, route.changefreq, route.priority));
  }

  try {
    // Fetch published articles from Supabase
    const articles = await articlesApi.getPublished();
    
    // Add blog articles
    const blogArticles = articles.filter((article: Article) => article.type === 'blog');
    for (const article of blogArticles) {
      const lastmod = formatDate(article.updated_at || article.created_at);
      urls.push(generateUrlEntry(`/blog/${article.slug}`, lastmod, 'monthly', '0.7'));
    }

    // Add support articles
    const supportArticles = articles.filter((article: Article) => article.type === 'support');
    for (const article of supportArticles) {
      const lastmod = formatDate(article.updated_at || article.created_at);
      urls.push(generateUrlEntry(`/support/${article.slug}`, lastmod, 'monthly', '0.7'));
    }
  } catch (error) {
    console.error('Error fetching articles for sitemap:', error);
    // Continue with static routes even if articles fail
  }

  // Combine into XML
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.join('\n')}
</urlset>`;
}

// Generate sitemap synchronously (for build-time generation without async)
export function generateSitemapSync(articles: Article[] = []): string {
  const today = formatDate(new Date());
  const urls: string[] = [];

  // Add static routes
  for (const route of staticRoutes) {
    urls.push(generateUrlEntry(route.path, today, route.changefreq, route.priority));
  }

  // Add blog articles
  const blogArticles = articles.filter((article: Article) => article.type === 'blog');
  for (const article of blogArticles) {
    const lastmod = formatDate(article.updated_at || article.created_at);
    urls.push(generateUrlEntry(`/blog/${article.slug}`, lastmod, 'monthly', '0.7'));
  }

  // Add support articles
  const supportArticles = articles.filter((article: Article) => article.type === 'support');
  for (const article of supportArticles) {
    const lastmod = formatDate(article.updated_at || article.created_at);
    urls.push(generateUrlEntry(`/support/${article.slug}`, lastmod, 'monthly', '0.7'));
  }

  // Combine into XML
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.join('\n')}
</urlset>`;
}
