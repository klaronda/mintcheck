-- When the report-ready email was sent to the purchaser (for "Emailed to you on ..." on report page)
ALTER TABLE public.deep_check_reports
  ADD COLUMN IF NOT EXISTS report_emailed_at timestamptz;
COMMENT ON COLUMN public.deep_check_reports.report_emailed_at IS 'When the report link was emailed to the purchaser (Resend)';
