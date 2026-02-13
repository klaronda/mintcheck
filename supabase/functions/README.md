# Supabase Edge Functions

## send-password-reset

Sends a password reset email when the app calls it (e.g. from Forgot Password). Uses Resend to deliver a MintCheck-branded email; the link opens in the app via Universal Link.

**Required secrets (set in Supabase Dashboard → Project Settings → Edge Functions → Secrets):**

- **`RESEND_API_KEY`** – Required. Without it, the function returns success but does not send any email (and logs a warning).
- **`RESEND_FROM_EMAIL`** – Optional. Defaults to `MintCheck <noreply@mintcheckapp.com>` if unset.

After setting secrets, (re)deploy the function for changes to take effect.

---

## send-confirmation-email

Sends the email confirmation link when **creating an account** (first signup) and when the user taps **Resend confirmation email**. Uses Resend with the guidelines template (Security Notice, footer). The link opens in the app via Universal Link (`https://mintcheckapp.com/auth/confirm?token=...&type=signup|email_change`).

**Required Supabase Auth setting:** In Dashboard go to **Authentication → Providers → Email** and turn **ON** "Confirm email". If this is off, Supabase returns a session on signup, so the app never calls this function and users can use the app without confirming (and no Resend email is sent).

**Secrets:** Same as `send-password-reset` – `RESEND_API_KEY` (required), `RESEND_FROM_EMAIL` (optional). Without `RESEND_API_KEY`, the function returns 500 and logs a warning.

**Avoiding duplicate emails:** The app calls this function on first signup so new users get the Resend email. If Supabase Auth is also set to send a confirmation email, users may receive two emails. To have only one (Resend), configure Supabase: use Resend as **Custom SMTP** and set Auth → Email templates → **Confirm signup** to minimal content, or disable the built-in confirmation email if your project supports it.
