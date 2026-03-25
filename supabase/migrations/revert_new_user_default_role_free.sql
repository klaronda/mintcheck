-- New signups: role from app_config (default free). Replaces force_new_user_role_tester.sql behavior.
-- Flip new_user_default_role or early_access_enabled in app_config when you want different signup roles.

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

INSERT INTO public.app_config (key, value) VALUES
  ('new_user_default_role', '"free"')
ON CONFLICT (key) DO UPDATE
  SET value = EXCLUDED.value, updated_at = now();
