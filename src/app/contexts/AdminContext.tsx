import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

export interface Article {
  id: string;
  type: 'support' | 'blog';
  title: string;
  slug: string;
  cardDescription: string;
  summary: string;
  heroImage: string;
  body: string;
  category?: 'Device Help' | 'Using the App' | 'Vehicle Support';
  published: boolean;
  createdAt: string;
  updatedAt: string;
}

interface AdminContextType {
  articles: Article[];
  addArticle: (article: Omit<Article, 'id' | 'createdAt' | 'updatedAt'>) => void;
  updateArticle: (id: string, article: Partial<Article>) => void;
  deleteArticle: (id: string) => void;
  getArticle: (slug: string) => Article | undefined;
  getSupportArticles: () => Article[];
  getBlogArticles: () => Article[];
  getArticlesByCategory: (category: string) => Article[];
}

const AdminContext = createContext<AdminContextType | undefined>(undefined);

const STORAGE_KEY = 'mintcheck_articles';
const AUTH_KEY = 'mintcheck_admin_auth';

// Initialize with some default articles
const getInitialArticles = (): Article[] => {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored) {
    return JSON.parse(stored);
  }
  
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000);
  const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const fourteenDaysAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);
  
  return [
    {
      id: '1',
      type: 'support',
      title: 'Getting Started with MintCheck',
      slug: 'getting-started',
      cardDescription: 'Learn how to set up and use MintCheck for the first time',
      summary: 'A comprehensive guide to help you get started with MintCheck and connect your OBD-II scanner.',
      heroImage: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=1200&h=400&fit=crop',
      body: '<h2>Welcome to MintCheck</h2><p>This guide will help you get started with MintCheck and connect your OBD-II scanner.</p><h3>Step 1: Download the App</h3><p>Download MintCheck from the iOS App Store.</p><h3>Step 2: Connect Your Scanner</h3><p>Turn on your Bluetooth OBD-II scanner and pair it with your iPhone.</p>',
      category: 'Using the App',
      published: true,
      createdAt: sevenDaysAgo.toISOString(),
      updatedAt: sevenDaysAgo.toISOString(),
    },
    {
      id: '2',
      type: 'support',
      title: 'Choosing the Right OBD-II Scanner',
      slug: 'choosing-scanner',
      cardDescription: 'Find the perfect scanner for your needs',
      summary: 'Learn about the different types of OBD-II scanners and which one is right for you.',
      heroImage: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=1200&h=400&fit=crop',
      body: '<h2>Scanner Types</h2><p>There are three main types of OBD-II scanners compatible with MintCheck:</p><ul><li>Basic Bluetooth scanners</li><li>Advanced diagnostic scanners</li><li>Professional-grade scanners</li></ul>',
      category: 'Device Help',
      published: true,
      createdAt: fourteenDaysAgo.toISOString(),
      updatedAt: fourteenDaysAgo.toISOString(),
    },
    {
      id: '3',
      type: 'blog',
      title: 'Understanding Your Car\'s Check Engine Light',
      slug: 'check-engine-light',
      cardDescription: 'What that warning light really means',
      summary: 'Learn what causes the check engine light to turn on and when you should be concerned.',
      heroImage: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=1200&h=400&fit=crop',
      body: '<h2>What Does It Mean?</h2><p>The check engine light is your car\'s way of telling you something needs attention.</p><h3>Common Causes</h3><ul><li>Loose gas cap</li><li>Oxygen sensor issues</li><li>Catalytic converter problems</li></ul>',
      published: true,
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    },
    {
      id: '4',
      type: 'blog',
      title: '5 Signs You Should Walk Away from a Used Car',
      slug: 'used-car-warning-signs',
      cardDescription: 'Red flags every buyer should know before purchasing',
      summary: 'Before you buy that used car, watch out for these warning signs that could save you thousands in repairs.',
      heroImage: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=1200&h=400&fit=crop',
      body: '<h2>Red Flags to Watch For</h2><p>When shopping for a used car, certain warning signs can indicate major problems ahead.</p><h3>1. Check Engine Light Is On</h3><p>If the check engine light is illuminated during your test drive, ask why. It could be something minor or a sign of serious issues.</p><h3>2. Excessive Engine Smoke</h3><p>Blue or white smoke from the exhaust often indicates engine problems that can be expensive to fix.</p><h3>3. Strange Noises</h3><p>Knocking, grinding, or squealing sounds shouldn\'t be ignored.</p><h3>4. Fluid Leaks</h3><p>Check under the car for oil, coolant, or transmission fluid leaks.</p><h3>5. Mismatched Service Records</h3><p>Incomplete or suspicious maintenance history is a major red flag.</p>',
      published: true,
      createdAt: oneDayAgo.toISOString(),
      updatedAt: oneDayAgo.toISOString(),
    },
    {
      id: '5',
      type: 'blog',
      title: 'How Often Should You Check Your Car\'s Diagnostics?',
      slug: 'diagnostic-check-frequency',
      cardDescription: 'A maintenance schedule for staying ahead of problems',
      summary: 'Regular diagnostic checks can help you catch problems early and save money on repairs.',
      heroImage: 'https://images.unsplash.com/photo-1625047509248-ec889cbff17f?w=1200&h=400&fit=crop',
      body: '<h2>The Smart Maintenance Schedule</h2><p>Staying on top of your vehicle\'s health doesn\'t have to be complicated.</p><h3>Monthly Quick Checks</h3><p>Do a quick diagnostic scan once a month to catch any new codes or issues.</p><h3>Before Long Trips</h3><p>Always run a diagnostic check before road trips to avoid breakdowns far from home.</p><h3>After Warning Lights</h3><p>Any time a warning light appears, scan immediately to understand what\'s wrong.</p><h3>During Oil Changes</h3><p>Make it a habit to check diagnostics when you change your oil every 3-6 months.</p>',
      published: true,
      createdAt: threeDaysAgo.toISOString(),
      updatedAt: threeDaysAgo.toISOString(),
    },
    {
      id: '6',
      type: 'blog',
      title: 'The Real Cost of Ignoring Car Problems',
      slug: 'cost-of-ignoring-problems',
      cardDescription: 'Why small issues become expensive repairs',
      summary: 'That small issue you\'re ignoring could turn into a major repair bill. Here\'s why catching problems early saves money.',
      heroImage: 'https://images.unsplash.com/photo-1523365237953-703b97e20c8f?w=1200&h=400&fit=crop',
      body: '<h2>Small Problems, Big Bills</h2><p>Ignoring minor car issues might seem like saving money, but it usually costs more in the long run.</p><h3>Example 1: The $20 vs $2,000 Problem</h3><p>A loose gas cap (free to fix) can trigger a check engine light. Ignoring it while an oxygen sensor fails could lead to catalytic converter damage costing $2,000+.</p><h3>Example 2: Oil Leaks</h3><p>A small oil leak might cost $100 to fix. Ignoring it until your engine runs dry? That\'s a $4,000+ engine replacement.</p><h3>The MintCheck Advantage</h3><p>With regular diagnostic checks, you can catch these issues early and fix them before they become expensive problems.</p>',
      published: true,
      createdAt: sevenDaysAgo.toISOString(),
      updatedAt: sevenDaysAgo.toISOString(),
    },
  ];
};

export function AdminProvider({ children }: { children: ReactNode }) {
  const [articles, setArticles] = useState<Article[]>(getInitialArticles);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(articles));
  }, [articles]);

  const addArticle = (article: Omit<Article, 'id' | 'createdAt' | 'updatedAt'>) => {
    const newArticle: Article = {
      ...article,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    setArticles(prev => [...prev, newArticle]);
  };

  const updateArticle = (id: string, updates: Partial<Article>) => {
    setArticles(prev =>
      prev.map(article =>
        article.id === id
          ? { ...article, ...updates, updatedAt: new Date().toISOString() }
          : article
      )
    );
  };

  const deleteArticle = (id: string) => {
    setArticles(prev => prev.filter(article => article.id !== id));
  };

  const getArticle = (slug: string) => {
    return articles.find(article => article.slug === slug && article.published);
  };

  const getSupportArticles = () => {
    return articles.filter(article => article.type === 'support' && article.published);
  };

  const getBlogArticles = () => {
    return articles
      .filter(article => article.type === 'blog' && article.published)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  };

  const getArticlesByCategory = (category: string) => {
    return articles.filter(
      article => article.type === 'support' && article.category === category && article.published
    );
  };

  return (
    <AdminContext.Provider
      value={{
        articles,
        addArticle,
        updateArticle,
        deleteArticle,
        getArticle,
        getSupportArticles,
        getBlogArticles,
        getArticlesByCategory,
      }}
    >
      {children}
    </AdminContext.Provider>
  );
}

export function useAdmin() {
  const context = useContext(AdminContext);
  if (context === undefined) {
    throw new Error('useAdmin must be used within AdminProvider');
  }
  return context;
}
export { AUTH_KEY };
