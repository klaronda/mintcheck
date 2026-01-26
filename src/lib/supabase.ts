import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://iawkgqbrxoctatfrjpli.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_JiTpE3pqlh5Lpi_RP_NGiw_HDfgPfly';

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Database types
export interface Article {
  id: string;
  type: 'support' | 'blog';
  title: string;
  slug: string;
  card_description: string;
  summary: string;
  hero_image: string;
  body: string;
  category?: 'Device Help' | 'Using the App' | 'Vehicle Support';
  published: boolean;
  user_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface ContactSubmission {
  id: string;
  name: string;
  email: string;
  message: string;
  created_at: string;
  status: 'new' | 'read' | 'replied';
}

// Shared report types (see SHARED_REPORTS_HANDOFF.md)
export interface ReportData {
  vehicleYear: string;
  vehicleMake: string;
  vehicleModel: string;
  vin?: string;
  recommendation: 'safe' | 'caution' | 'not-recommended';
  scanDate: string;
  summary?: string;
  findings?: string[];
  valuationLow?: number;
  valuationHigh?: number;
  odometerReading?: number;
  askingPrice?: number;
}

export interface SharedReport {
  id: string;
  user_id: string;
  scan_id: string;
  share_code: string;
  vin: string | null;
  report_data: ReportData;
  created_at: string;
}

// Helper functions
export const articlesApi = {
  // Get all published articles
  async getPublished(type?: 'support' | 'blog') {
    let query = supabase
      .from('articles')
      .select('*')
      .eq('published', true)
      .order('created_at', { ascending: false });

    if (type) {
      query = query.eq('type', type);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data as Article[];
  },

  // Get article by slug
  async getBySlug(slug: string) {
    const { data, error } = await supabase
      .from('articles')
      .select('*')
      .eq('slug', slug)
      .eq('published', true)
      .single();

    if (error) throw error;
    return data as Article;
  },

  // Get all articles (for admin)
  async getAll() {
    const { data, error } = await supabase
      .from('articles')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as Article[];
  },

  // Create article
  async create(article: Omit<Article, 'id' | 'created_at' | 'updated_at' | 'user_id'>) {
    const { data: { user } } = await supabase.auth.getUser();
    
    const { data, error } = await supabase
      .from('articles')
      .insert({
        ...article,
        user_id: user?.id || null,
      })
      .select()
      .single();

    if (error) throw error;
    return data as Article;
  },

  // Update article
  async update(id: string, updates: Partial<Article>) {
    const { data, error } = await supabase
      .from('articles')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data as Article;
  },

  // Delete article
  async delete(id: string) {
    const { error } = await supabase
      .from('articles')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },
};

export const contactApi = {
  async submit(name: string, email: string, message: string) {
    const { data, error } = await supabase
      .from('contact_submissions')
      .insert({ name, email, message })
      .select()
      .single();

    if (error) throw error;
    return data as ContactSubmission;
  },

  async getAll() {
    const { data, error } = await supabase
      .from('contact_submissions')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as ContactSubmission[];
  },
};

export const sharedReportsApi = {
  async getByShareCode(shareCode: string) {
    const { data, error } = await supabase
      .from('shared_reports')
      .select('*')
      .eq('share_code', shareCode)
      .single();

    if (error) throw error;
    return data as SharedReport;
  },
};

// Admin auth: distinguish CMS admins from app users via app_metadata.role
export function isAdminUser(user: { app_metadata?: { role?: string } } | null): boolean {
  return user?.app_metadata?.role === 'admin';
}

export const adminAuthApi = {
  async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return { success: false as const, error: error.message, user: null };
    if (!isAdminUser(data.user)) {
      await supabase.auth.signOut();
      return { success: false as const, error: 'This account is not an admin.', user: null };
    }
    return { success: true as const, error: null, user: data.user };
  },

  async signOut() {
    await supabase.auth.signOut();
  },

  async getSession() {
    const { data: { session } } = await supabase.auth.getSession();
    return session;
  },
};
