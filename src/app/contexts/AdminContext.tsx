import { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';
import { articlesApi, supabase, type Article as SupabaseArticle } from '@/lib/supabase';

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
  loading: boolean;
  error: string | null;
  addArticle: (article: Omit<Article, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  updateArticle: (id: string, article: Partial<Article>) => Promise<void>;
  deleteArticle: (id: string) => Promise<void>;
  getArticle: (slug: string) => Article | undefined;
  getSupportArticles: () => Article[];
  getBlogArticles: () => Article[];
  getArticlesByCategory: (category: string) => Article[];
  refreshArticles: () => Promise<void>;
}

const AdminContext = createContext<AdminContextType | undefined>(undefined);

// Helper to convert Supabase article to component article
const mapSupabaseToArticle = (dbArticle: SupabaseArticle): Article => ({
  id: dbArticle.id,
  type: dbArticle.type,
  title: dbArticle.title,
  slug: dbArticle.slug,
  cardDescription: dbArticle.card_description,
  summary: dbArticle.summary,
  heroImage: dbArticle.hero_image,
  body: dbArticle.body,
  category: dbArticle.category || undefined,
  published: dbArticle.published,
  createdAt: dbArticle.created_at,
  updatedAt: dbArticle.updated_at,
});

// Helper to convert component article to Supabase article
const mapArticleToSupabase = (article: Omit<Article, 'id' | 'createdAt' | 'updatedAt'>) => ({
  type: article.type,
  title: article.title,
  slug: article.slug,
  card_description: article.cardDescription,
  summary: article.summary,
  hero_image: article.heroImage,
  body: article.body,
  category: article.category || null,
  published: article.published,
});

export function AdminProvider({ children }: { children: ReactNode }) {
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadArticles = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await articlesApi.getAll();
      setArticles(data.map(mapSupabaseToArticle));
    } catch (err) {
      console.error('Error loading articles:', err);
      setError(err instanceof Error ? err.message : 'Failed to load articles');
      setArticles([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadArticles();

    // Set up real-time subscription
    const channel = supabase
      .channel('articles_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'articles',
        },
        () => {
          // Reload articles on any change
          loadArticles();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [loadArticles]);

  const addArticle = async (article: Omit<Article, 'id' | 'createdAt' | 'updatedAt'>) => {
    try {
      setError(null);
      const supabaseArticle = mapArticleToSupabase(article);
      const newArticle = await articlesApi.create(supabaseArticle);
      setArticles(prev => [mapSupabaseToArticle(newArticle), ...prev]);
    } catch (err) {
      console.error('Error adding article:', err);
      setError(err instanceof Error ? err.message : 'Failed to add article');
      throw err;
    }
  };

  const updateArticle = async (id: string, updates: Partial<Article>) => {
    try {
      setError(null);
      const supabaseUpdates: Partial<SupabaseArticle> = {};
      
      if (updates.title !== undefined) supabaseUpdates.title = updates.title;
      if (updates.slug !== undefined) supabaseUpdates.slug = updates.slug;
      if (updates.cardDescription !== undefined) supabaseUpdates.card_description = updates.cardDescription;
      if (updates.summary !== undefined) supabaseUpdates.summary = updates.summary;
      if (updates.heroImage !== undefined) supabaseUpdates.hero_image = updates.heroImage;
      if (updates.body !== undefined) supabaseUpdates.body = updates.body;
      if (updates.category !== undefined) supabaseUpdates.category = updates.category || null;
      if (updates.published !== undefined) supabaseUpdates.published = updates.published;
      if (updates.type !== undefined) supabaseUpdates.type = updates.type;

      const updatedArticle = await articlesApi.update(id, supabaseUpdates);
      setArticles(prev =>
        prev.map(article =>
          article.id === id ? mapSupabaseToArticle(updatedArticle) : article
        )
      );
    } catch (err) {
      console.error('Error updating article:', err);
      setError(err instanceof Error ? err.message : 'Failed to update article');
      throw err;
    }
  };

  const deleteArticle = async (id: string) => {
    try {
      setError(null);
      await articlesApi.delete(id);
      setArticles(prev => prev.filter(article => article.id !== id));
    } catch (err) {
      console.error('Error deleting article:', err);
      setError(err instanceof Error ? err.message : 'Failed to delete article');
      throw err;
    }
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
        loading,
        error,
        addArticle,
        updateArticle,
        deleteArticle,
        getArticle,
        getSupportArticles,
        getBlogArticles,
        getArticlesByCategory,
        refreshArticles: loadArticles,
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