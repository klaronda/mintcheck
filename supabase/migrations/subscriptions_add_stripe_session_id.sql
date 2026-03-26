-- Referenced by create-buyer-pass-session, stripe-webhook (buyer_pass), fulfill-starter-kit-order
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS stripe_session_id text;

COMMENT ON COLUMN public.subscriptions.stripe_session_id IS 'Stripe Checkout session id, or starter_kit_order:<uuid> for kit fulfillment';

CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_stripe_session_id_unique
  ON public.subscriptions (stripe_session_id)
  WHERE stripe_session_id IS NOT NULL;
