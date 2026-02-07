-- Monitor Add Car: extend vehicles (cars) and create subscriptions (entitlements)
-- Single concept: vehicles table holds all user cars; Monitor subscription per car

-- 1. Extend vehicles with Monitor/car fields
ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS odometer_baseline int,
  ADD COLUMN IF NOT EXISTS vin_hash text;

COMMENT ON COLUMN public.vehicles.name IS 'Friendly car name (e.g. Daily Driver)';
COMMENT ON COLUMN public.vehicles.odometer_baseline IS 'Odometer when car was added (optional)';
COMMENT ON COLUMN public.vehicles.vin_hash IS 'Normalized VIN (uppercase, no spaces) for uniqueness';

-- One car per VIN per user when VIN is provided
DROP INDEX IF EXISTS vehicles_user_id_vin_hash_unique;
CREATE UNIQUE INDEX vehicles_user_id_vin_hash_unique
  ON public.vehicles (user_id, vin_hash)
  WHERE vin_hash IS NOT NULL AND vin_hash != '';

-- 2. Subscriptions (entitlements) for Monitor / Buyer Pass
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  plan text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  provider text,
  provider_subscription_id text,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  CONSTRAINT subscriptions_plan_check CHECK (plan IN ('monitor', 'buyer_pass')),
  CONSTRAINT subscriptions_status_check CHECK (status IN ('active', 'inactive', 'canceled')),
  CONSTRAINT subscriptions_user_vehicle_plan_unique UNIQUE (user_id, vehicle_id, plan)
);

COMMENT ON TABLE public.subscriptions IS 'Per-car subscription entitlements (Monitor, Buyer Pass)';
COMMENT ON COLUMN public.subscriptions.plan IS 'monitor | buyer_pass';
COMMENT ON COLUMN public.subscriptions.status IS 'active | inactive | canceled';

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON public.subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can insert own subscriptions"
  ON public.subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can update own subscriptions"
  ON public.subscriptions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
