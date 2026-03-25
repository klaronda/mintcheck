-- Shipping / tracking for Starter Kit admin fulfillment workflow
ALTER TABLE public.starter_kit_orders
  ADD COLUMN IF NOT EXISTS tracking_carrier text,
  ADD COLUMN IF NOT EXISTS tracking_number text,
  ADD COLUMN IF NOT EXISTS shipped_at timestamptz;

COMMENT ON COLUMN public.starter_kit_orders.tracking_carrier IS 'e.g. USPS, UPS, FedEx';
COMMENT ON COLUMN public.starter_kit_orders.tracking_number IS 'Carrier tracking number (set from MintCheck Admin)';
COMMENT ON COLUMN public.starter_kit_orders.shipped_at IS 'When tracking was first saved (optional operational timestamp)';
