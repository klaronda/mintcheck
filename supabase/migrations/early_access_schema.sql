-- Early Access User: profiles role, app config, vehicles.vin_locked, scans flags
-- Run after create_profiles_if_missing and add_summary_columns

-- 1.1 Profiles: role and early_access_granted_at
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS early_access_granted_at timestamptz;

COMMENT ON COLUMN public.profiles.role IS 'User type: tester | early_access | free | subscriber';
COMMENT ON COLUMN public.profiles.early_access_granted_at IS 'When user was granted early_access (for display/migration)';

-- Backfill existing profiles (existing users default to free)
UPDATE public.profiles SET role = 'free' WHERE role IS NULL OR role = '';
UPDATE public.profiles SET role = 'free' WHERE role NOT IN ('tester', 'early_access', 'free', 'subscriber');

-- 1.2 App config / feature flags (for signup trigger and client)
CREATE TABLE IF NOT EXISTS public.app_config (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT 'null',
  updated_at timestamptz DEFAULT now() NOT NULL
);

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Only service role / backend should write; allow read for authenticated (for app fetch)
DROP POLICY IF EXISTS "Allow read app_config for authenticated" ON public.app_config;
CREATE POLICY "Allow read app_config for authenticated"
  ON public.app_config FOR SELECT
  TO authenticated
  USING (true);

-- Seed defaults: new signups get tester until you flip; early_access window off
INSERT INTO public.app_config (key, value) VALUES
  ('early_access_enabled', 'false'),
  ('new_user_default_role', '"tester"')
ON CONFLICT (key) DO NOTHING;

-- 1.3 Vehicles: vin_locked
ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS vin_locked boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.vehicles.vin_locked IS 'For early_access: true once single VIN is saved; prevents adding another vehicle';

-- 1.4 Scans: vin_verified, vin_mismatch, analysis_enabled
ALTER TABLE public.scans
  ADD COLUMN IF NOT EXISTS vin_verified boolean,
  ADD COLUMN IF NOT EXISTS vin_mismatch boolean,
  ADD COLUMN IF NOT EXISTS analysis_enabled boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.scans.vin_verified IS 'True if VIN was confirmed (decode or ECU match)';
COMMENT ON COLUMN public.scans.vin_mismatch IS 'True if ECU VIN != user-entered VIN';
COMMENT ON COLUMN public.scans.analysis_enabled IS 'False for early_access (snapshot-only; no prediction/history)';

-- 1.5 Update handle_new_user to set role from app_config
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  early_access_on boolean;
  default_role text;
  assign_role text;
  assign_early_at timestamptz;
BEGIN
  SELECT (value = true) INTO early_access_on
  FROM public.app_config WHERE key = 'early_access_enabled' LIMIT 1;
  IF early_access_on IS NULL THEN
    early_access_on := false;
  END IF;

  SELECT COALESCE(value #>> '{}', 'free') INTO default_role
  FROM public.app_config WHERE key = 'new_user_default_role' LIMIT 1;
  IF default_role IS NULL OR default_role = '' THEN
    default_role := 'free';
  END IF;
  -- Strip quotes if stored as JSON string
  default_role := trim(both '"' from default_role);

  IF early_access_on THEN
    assign_role := 'early_access';
    assign_early_at := now();
  ELSE
    assign_role := default_role;
    assign_early_at := NULL;
  END IF;

  INSERT INTO public.profiles (id, first_name, last_name, role, early_access_granted_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', NEW.raw_user_meta_data->>'firstName'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', NEW.raw_user_meta_data->>'lastName'),
    assign_role,
    assign_early_at
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
