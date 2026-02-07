-- Add 'admin' to allowed profiles.role; do not overwrite existing admin rows

COMMENT ON COLUMN public.profiles.role IS 'User type: tester | early_access | free | subscriber | admin';

-- Backfill: only set role = free for invalid/unknown values; leave admin untouched
UPDATE public.profiles
SET role = 'free'
WHERE role IS NULL OR role = ''
   OR role NOT IN ('tester', 'early_access', 'free', 'subscriber', 'admin');
