# Supabase Edge Functions

## send-password-reset

Sends a password reset email when the app calls it (e.g. from Forgot Password). Uses Resend to deliver a MintCheck-branded email; the link opens in the app via Universal Link.

**Required secrets (set in Supabase Dashboard → Project Settings → Edge Functions → Secrets):**

- **`RESEND_API_KEY`** – Required. Without it, the function returns success but does not send any email (and logs a warning).
- **`RESEND_FROM_EMAIL`** – Optional. Defaults to `MintCheck <noreply@mintcheckapp.com>` if unset.

After setting secrets, (re)deploy the function for changes to take effect.
