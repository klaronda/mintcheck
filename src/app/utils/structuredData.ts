// Structured data (JSON-LD) helpers for SEO

const BASE_URL = 'https://mintcheckapp.com';

// Organization schema - use on all pages
export function getOrganizationSchema() {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'MintCheck',
    url: BASE_URL,
    logo: `${BASE_URL}/logo.png`,
    contactPoint: {
      '@type': 'ContactPoint',
      email: 'support@mintcheckapp.com',
      contactType: 'customer support',
    },
    sameAs: [],
  };
}

// SoftwareApplication schema - for Download page
export function getSoftwareApplicationSchema() {
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'MintCheck',
    applicationCategory: 'AutomotiveApplication',
    operatingSystem: 'iOS',
    offers: {
      '@type': 'Offer',
      price: '0',
      priceCurrency: 'USD',
    },
    aggregateRating: {
      '@type': 'AggregateRating',
      ratingValue: '4.8',
      ratingCount: '150',
    },
    description: 'MintCheck helps you make smarter decisions about used cars with OBD-II scans.',
    url: `${BASE_URL}/download`,
    author: {
      '@type': 'Organization',
      name: 'MintCheck',
      url: BASE_URL,
    },
  };
}

// Article schema - for blog and support articles
export function getArticleSchema(article: {
  title: string;
  summary: string;
  slug: string;
  type: 'blog' | 'support';
  createdAt: string;
  updatedAt?: string;
  heroImage?: string;
}) {
  const url = `${BASE_URL}/${article.type}/${article.slug}`;
  const schema: any = {
    '@context': 'https://schema.org',
    '@type': article.type === 'blog' ? 'BlogPosting' : 'Article',
    headline: article.title,
    description: article.summary,
    url,
    datePublished: article.createdAt,
    publisher: {
      '@type': 'Organization',
      name: 'MintCheck',
      logo: {
        '@type': 'ImageObject',
        url: `${BASE_URL}/logo.png`,
      },
    },
  };

  if (article.updatedAt) {
    schema.dateModified = article.updatedAt;
  }

  if (article.heroImage) {
    schema.image = {
      '@type': 'ImageObject',
      url: article.heroImage,
    };
  }

  return schema;
}

// ContactPage schema - for Contact page
export function getContactPageSchema() {
  return {
    '@context': 'https://schema.org',
    '@type': 'ContactPage',
    name: 'Contact MintCheck',
    url: `${BASE_URL}/contact`,
    mainEntity: {
      '@type': 'Organization',
      name: 'MintCheck',
      email: 'support@mintcheckapp.com',
      url: BASE_URL,
    },
  };
}

// BreadcrumbList schema
export function getBreadcrumbSchema(items: Array<{ name: string; url: string }>) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: item.url,
    })),
  };
}
