import { supabase } from '@/lib/supabase';
import type { Article } from '@/app/contexts/AdminContext';

export const SITE_ARTICLES_TABLE = 'site_articles';

export interface SiteArticleRow {
  id: string;
  type: string;
  slug: string;
  title: string;
  card_description: string;
  summary: string;
  hero_image: string;
  body: string;
  category: string | null;
  published: boolean;
  created_at: string;
  updated_at: string;
}

function looksLikeUuid(s: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(s);
}

export function mapSiteRowToArticle(row: SiteArticleRow): Article {
  const cat = row.category?.trim() || null;
  const category =
    cat === 'Device Help' || cat === 'Using the App' || cat === 'Vehicle Support' ? cat : undefined;
  return {
    id: row.id,
    type: row.type as Article['type'],
    slug: row.slug,
    title: row.title,
    cardDescription: row.card_description,
    summary: row.summary,
    heroImage: row.hero_image,
    body: row.body,
    category,
    published: row.published,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

/** Payload for insert/upsert (omit id unless real UUID). */
export function articleToDbRow(a: Article): Record<string, unknown> {
  const row: Record<string, unknown> = {
    type: a.type,
    slug: a.slug,
    title: a.title,
    card_description: a.cardDescription,
    summary: a.summary,
    hero_image: a.heroImage,
    body: a.body,
    category: a.category ?? null,
    published: a.published,
  };
  if (looksLikeUuid(a.id)) row.id = a.id;
  return row;
}

export async function fetchSiteArticlesFromDb(): Promise<{
  rows: SiteArticleRow[] | null;
  error: string | null;
}> {
  const { data, error } = await supabase
    .from(SITE_ARTICLES_TABLE)
    .select('*')
    .order('created_at', { ascending: true });

  if (error) return { rows: null, error: error.message };
  return { rows: (data ?? []) as SiteArticleRow[], error: null };
}

export async function bootstrapSiteArticles(defaults: Article[]): Promise<{ ok: boolean; error: string | null }> {
  const payload = defaults.map((a) => articleToDbRow(a));
  const { error } = await supabase.from(SITE_ARTICLES_TABLE).upsert(payload, { onConflict: 'slug' });
  if (error) return { ok: false, error: error.message };
  return { ok: true, error: null };
}

export async function insertSiteArticle(a: Article): Promise<{ row: SiteArticleRow | null; error: string | null }> {
  const { data, error } = await supabase
    .from(SITE_ARTICLES_TABLE)
    .insert(articleToDbRow(a))
    .select()
    .single();

  if (error) return { row: null, error: error.message };
  return { row: data as SiteArticleRow, error: null };
}

export async function updateSiteArticleDb(
  id: string,
  patch: Partial<Article>,
): Promise<{ error: string | null }> {
  const row: Record<string, unknown> = {};
  if (patch.type !== undefined) row.type = patch.type;
  if (patch.slug !== undefined) row.slug = patch.slug;
  if (patch.title !== undefined) row.title = patch.title;
  if (patch.cardDescription !== undefined) row.card_description = patch.cardDescription;
  if (patch.summary !== undefined) row.summary = patch.summary;
  if (patch.heroImage !== undefined) row.hero_image = patch.heroImage;
  if (patch.body !== undefined) row.body = patch.body;
  if (patch.category !== undefined) row.category = patch.category ?? null;
  if (patch.published !== undefined) row.published = patch.published;

  const { error } = await supabase.from(SITE_ARTICLES_TABLE).update(row).eq('id', id);
  return { error: error?.message ?? null };
}

export async function deleteSiteArticleDb(id: string): Promise<{ error: string | null }> {
  const { error } = await supabase.from(SITE_ARTICLES_TABLE).delete().eq('id', id);
  return { error: error?.message ?? null };
}
