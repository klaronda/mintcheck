-- Add scan_credits column to profiles (tracks purchased one-time scan credits)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS scan_credits integer NOT NULL DEFAULT 0;

-- Table to record verified Apple IAP transactions (prevents replay)
CREATE TABLE IF NOT EXISTS scan_purchases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_id text NOT NULL UNIQUE,
    product_id text NOT NULL DEFAULT 'com.mintcheck.onetimescan',
    original_transaction_id text,
    price_cents integer NOT NULL DEFAULT 399,
    currency text NOT NULL DEFAULT 'USD',
    environment text NOT NULL DEFAULT 'Production',
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_scan_purchases_user_id ON scan_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_scan_purchases_transaction_id ON scan_purchases(transaction_id);

ALTER TABLE scan_purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own purchases"
    ON scan_purchases FOR SELECT
    USING (auth.uid() = user_id);

-- Atomic increment/decrement RPCs for scan_credits
CREATE OR REPLACE FUNCTION increment_scan_credits(p_user_id uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE new_credits integer;
BEGIN
    UPDATE profiles SET scan_credits = scan_credits + 1
    WHERE id = p_user_id
    RETURNING scan_credits INTO new_credits;
    RETURN new_credits;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_scan_credits(p_user_id uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE new_credits integer;
BEGIN
    UPDATE profiles SET scan_credits = GREATEST(scan_credits - 1, 0)
    WHERE id = p_user_id
    RETURNING scan_credits INTO new_credits;
    RETURN new_credits;
END;
$$;
