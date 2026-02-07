-- Add recommendation_status to deep_check_purchases (problems_reported | history_available)
-- Set by generate-deep-check-report after extracting vhr from CARFAX HTML.
ALTER TABLE public.deep_check_purchases
  ADD COLUMN IF NOT EXISTS recommendation_status text;
COMMENT ON COLUMN public.deep_check_purchases.recommendation_status IS 'problems_reported or history_available; derived from report vhr (branded title / accident damage)';
