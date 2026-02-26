-- Allow server/admin to force show onboarding again for a user (e.g. support reset).
-- App reads this on session load; if true, clears local onboarding state and sets this to false.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS reset_onboarding boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.reset_onboarding IS 'When true, app resets local onboarding (UserDefaults) and then sets this back to false. One-time reset per open.';
