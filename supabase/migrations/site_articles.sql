-- Site CMS: support + blog articles (public read published; admin full access)
-- After deploy: grant CMS access with
--   UPDATE public.profiles SET role = 'admin' WHERE id = (SELECT id FROM auth.users WHERE email = 'your-admin@email');

CREATE TABLE IF NOT EXISTS public.site_articles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('support', 'blog')),
  slug text NOT NULL UNIQUE,
  title text NOT NULL,
  card_description text NOT NULL DEFAULT '',
  summary text NOT NULL DEFAULT '',
  hero_image text NOT NULL DEFAULT '',
  body text NOT NULL DEFAULT '',
  category text,
  published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS site_articles_type_published_idx
  ON public.site_articles (type, published);

DROP TRIGGER IF EXISTS site_articles_updated_at ON public.site_articles;
CREATE TRIGGER site_articles_updated_at
  BEFORE UPDATE ON public.site_articles
  FOR EACH ROW
  EXECUTE PROCEDURE public.set_updated_at();

ALTER TABLE public.site_articles ENABLE ROW LEVEL SECURITY;

-- Admins (profiles.role = 'admin') can do everything
CREATE OR REPLACE FUNCTION public.is_profile_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
$$;

DROP POLICY IF EXISTS "site_articles_public_read_published" ON public.site_articles;
CREATE POLICY "site_articles_public_read_published"
  ON public.site_articles
  FOR SELECT
  TO anon, authenticated
  USING (published = true);

DROP POLICY IF EXISTS "site_articles_admin_select_all" ON public.site_articles;
CREATE POLICY "site_articles_admin_select_all"
  ON public.site_articles
  FOR SELECT
  TO authenticated
  USING (public.is_profile_admin());

DROP POLICY IF EXISTS "site_articles_admin_insert" ON public.site_articles;
CREATE POLICY "site_articles_admin_insert"
  ON public.site_articles
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_profile_admin());

DROP POLICY IF EXISTS "site_articles_admin_update" ON public.site_articles;
CREATE POLICY "site_articles_admin_update"
  ON public.site_articles
  FOR UPDATE
  TO authenticated
  USING (public.is_profile_admin())
  WITH CHECK (public.is_profile_admin());

DROP POLICY IF EXISTS "site_articles_admin_delete" ON public.site_articles;
CREATE POLICY "site_articles_admin_delete"
  ON public.site_articles
  FOR DELETE
  TO authenticated
  USING (public.is_profile_admin());

COMMENT ON TABLE public.site_articles IS 'Marketing/support and blog HTML for mintcheckapp.com; edited via Admin after RLS grants.';
