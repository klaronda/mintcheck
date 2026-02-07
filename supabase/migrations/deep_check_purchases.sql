-- Deep Check purchases: one row per Stripe Checkout (user + VIN); webhook marks paid

CREATE TABLE IF NOT EXISTS public.deep_check_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vin text NOT NULL,
  stripe_session_id text UNIQUE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'report_ready')),
  report_url text,
  created_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_deep_check_purchases_user_id ON public.deep_check_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_deep_check_purchases_stripe_session_id ON public.deep_check_purchases(stripe_session_id);

ALTER TABLE public.deep_check_purchases ENABLE ROW LEVEL SECURITY;

-- Users can only read/insert their own rows
DROP POLICY IF EXISTS "Users can read own deep_check_purchases" ON public.deep_check_purchases;
CREATE POLICY "Users can read own deep_check_purchases"
  ON public.deep_check_purchases FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own deep_check_purchases" ON public.deep_check_purchases;
CREATE POLICY "Users can insert own deep_check_purchases"
  ON public.deep_check_purchases FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- No UPDATE/DELETE for users; webhook uses service role to update status

COMMENT ON TABLE public.deep_check_purchases IS 'Deep Vehicle Check one-time purchases; Stripe webhook sets status = paid';
