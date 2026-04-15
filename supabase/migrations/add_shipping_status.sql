ALTER TABLE public.starter_kit_orders
  ADD COLUMN IF NOT EXISTS shipping_status text
    CHECK (shipping_status IN ('in_transit', 'out_for_delivery', 'delivered', 'failed')),
  ADD COLUMN IF NOT EXISTS delivery_email_sent_at timestamptz;
