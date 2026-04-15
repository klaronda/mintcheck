-- Schedule check-shipping-status to run every 2 hours.
-- Replace <DEEP_CHECK_INVOKE_SECRET> with the actual value from your Edge Function secrets,
-- then run this once in the Supabase SQL Editor.
--
-- To find the secret: Supabase Dashboard → Edge Functions → any function that uses it
-- (e.g. generate-deep-check-report) → Environment Variables → DEEP_CHECK_INVOKE_SECRET.

SELECT cron.schedule(
  'check-shipping-status',
  '0 */2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://iawkgqbrxoctatfrjpli.supabase.co/functions/v1/check-shipping-status',
    headers := '{"Content-Type": "application/json", "X-Internal-Secret": "<DEEP_CHECK_INVOKE_SECRET>"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
