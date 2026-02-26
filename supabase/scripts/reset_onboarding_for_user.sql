-- 1) Ensure column exists (same as migration add_reset_onboarding_to_profiles.sql)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS reset_onboarding boolean NOT NULL DEFAULT false;

-- 2) Set reset_onboarding = true for hollaronda@gmail.com (run this in Supabase SQL Editor)
UPDATE public.profiles
SET reset_onboarding = true
WHERE id = (SELECT id FROM auth.users WHERE email = 'hollaronda@gmail.com' LIMIT 1);
