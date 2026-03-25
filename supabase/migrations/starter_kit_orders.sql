-- Starter Kit: paid hardware orders; Buyer Pass is activated later (e.g. on ship) via fulfill-starter-kit-order.
CREATE TABLE IF NOT EXISTS public.starter_kit_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  stripe_session_id text NOT NULL,
  status text NOT NULL DEFAULT 'paid_pending_fulfillment'
    CHECK (status IN ('paid_pending_fulfillment', 'pass_activated', 'canceled')),
  customer_email text,
  customer_name text,
  confirmation_email_sent_at timestamptz,
  pass_activated_at timestamptz,
  buyer_pass_subscription_id uuid REFERENCES public.subscriptions (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT starter_kit_orders_stripe_session_id_key UNIQUE (stripe_session_id)
);

CREATE INDEX IF NOT EXISTS idx_starter_kit_orders_user_id ON public.starter_kit_orders (user_id);
CREATE INDEX IF NOT EXISTS idx_starter_kit_orders_status ON public.starter_kit_orders (status);

COMMENT ON TABLE public.starter_kit_orders IS 'MintCheck Starter Kit Stripe Checkout orders; 60-day Buyer Pass is granted on fulfillment, not at payment.';

ALTER TABLE public.starter_kit_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own starter kit orders" ON public.starter_kit_orders;
CREATE POLICY "Users can view own starter kit orders"
  ON public.starter_kit_orders FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Buyer Pass rows created for Starter Kit fulfillment may not be tied to a vehicle.
ALTER TABLE public.subscriptions
  ALTER COLUMN vehicle_id DROP NOT NULL;
