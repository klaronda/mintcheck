-- Idempotency for shipping confirmation email (Resend) when admin saves tracking
ALTER TABLE public.starter_kit_orders
  ADD COLUMN IF NOT EXISTS shipping_confirmation_sent_at timestamptz;

COMMENT ON COLUMN public.starter_kit_orders.shipping_confirmation_sent_at IS 'When the shipped / tracking email was sent via send-starter-kit-shipping';
