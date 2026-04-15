ALTER TABLE public.starter_kit_orders
  ADD COLUMN IF NOT EXISTS archived_at timestamptz;
