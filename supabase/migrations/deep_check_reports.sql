-- Deep Check reports: store Carfax HTML by report_code; allow report_failed on purchases

-- Extend deep_check_purchases status and add optional error message
ALTER TABLE public.deep_check_purchases
  DROP CONSTRAINT IF EXISTS deep_check_purchases_status_check;
ALTER TABLE public.deep_check_purchases
  ADD CONSTRAINT deep_check_purchases_status_check
  CHECK (status IN ('pending', 'paid', 'report_ready', 'report_failed'));

ALTER TABLE public.deep_check_purchases
  ADD COLUMN IF NOT EXISTS report_error text;
COMMENT ON COLUMN public.deep_check_purchases.report_error IS 'Error message when status = report_failed (e.g. from CheapCARFAX API)';

-- Table to store Carfax HTML keyed by secret report_code (for /deep-check/report/:code)
CREATE TABLE IF NOT EXISTS public.deep_check_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id uuid NOT NULL REFERENCES public.deep_check_purchases(id) ON DELETE CASCADE,
  report_code text NOT NULL UNIQUE,
  html_content text NOT NULL,
  year_make_model text,
  created_at timestamptz DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_deep_check_reports_report_code ON public.deep_check_reports(report_code);
CREATE INDEX IF NOT EXISTS idx_deep_check_reports_purchase_id ON public.deep_check_reports(purchase_id);

ALTER TABLE public.deep_check_reports ENABLE ROW LEVEL SECURITY;

-- No direct user policies; only service role (Edge Functions) read/write
-- Public report view is served via Edge Function that looks up by report_code

COMMENT ON TABLE public.deep_check_reports IS 'Stored Carfax HTML for Deep Check; served by report_code at /deep-check/report/:code';
