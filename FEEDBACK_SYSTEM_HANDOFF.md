# MintCheck Customer Feedback System — Handoff

## What Was Built

### Backend (Supabase)
- **Migration**: `supabase/migrations/create_feedback_table.sql` — `feedback` table with RLS (insert only for anon/authenticated; no select for clients).
- **Edge Functions**:
  - `notify-feedback` — Sends a Resend email to your team when feedback is submitted (call with `{ "feedbackId": "<uuid>" }` after insert). Uses`SUPPORT_EMAIL` and `RESEND_API_KEY`, `RESEND_FROM_EMAIL`.
  - `list-feedback` — Returns recent feedback rows for the admin inbox. Protected by header `x-admin-secret`; must match env `ADMIN_FEEDBACK_SECRET`.

### iOS App
- **FeedbackContextService** — Builds context (device, app version, connectivity, scan state, breadcrumbs).
- **BreadcrumbLogger** — In-memory ring buffer of last ~20 events; snapshot included in context.
- **FeedbackService** — Submits feedback via Supabase REST; on failure queues in UserDefaults and exposes `flushQueueIfOnline(connectionManager:)` (call on app launch / when back online).
- **FeedbackModalView** — Reusable modal: category, message, email; submit/cancel; success toast or “We'll try again when you're back online.”
- **Entry points**:
  - Settings → “Send feedback” (opens modal, source `in_app`).
  - Connect WiFi step → “Scanner connected too soon” alert includes “Report this issue” (opens modal with bug + error prefill, source `error_cta`).
  - Connect WiFi step → When “Couldn't find your scanner automatically” (connection failed) → “Report this issue” (source `error_cta`, `ERR_OBD_CONNECT_FAIL`).
  - Scan Error alert (ScanningView) → “Report this issue” (source `error_cta`, `ERR_OBD_DROP`).
  - Results → Save/upload failure toast → “Report this issue” (source `error_cta`, `ERR_SAVE_UPLOAD_FAIL`).
  - Results → Delete scan failure toast → “Report this issue” (source `error_cta`, `ERR_DELETE_FAIL`).
  - Results → AI/valuation network error (FindingsWithPricingCard) → “Report this issue” (source `error_cta`, `ERR_AI_ANALYSIS_FAIL`).
  - Share report sheet → Send failed → “Report this issue” (source `error_cta`, `ERR_EMAIL_SEND_FAIL`).
  - Settings → Delete account failed alert → “Report this issue” (source `error_cta`, `ERR_DELETE_ACCOUNT_FAIL`).
  - Settings → Delete shared link failed alert → “Report this issue” (source `error_cta`, `ERR_DELETE_SHARED_LINK_FAIL`).
  - Settings → Shared Links load failed → “Report this issue” (source `error_cta`, `ERR_LOAD_SHARED_REPORTS_FAIL`).
  - Sign In / Create account → Error shown → “Report this issue” (source `error_cta`, `ERR_AUTH_FAIL`).
  - Change password / Change email / Forgot password / Reset password → Error shown → “Report this issue” (source `error_cta`, `ERR_AUTH_FAIL`).
  - Vehicle basics (VIN entry) → VIN decode error → “Report this issue” (source `error_cta`, `ERR_VIN_DECODE_FAIL`).
- **ContentView** — Presents feedback sheet from `nav.showFeedbackModal`; on appear calls `FeedbackService.shared.flushQueueIfOnline(connectionManager:)`.

### Website (Admin)
- **Route**: `/admin/feedback` — Feedback inbox (same auth as `/admin/login`).
- **AdminFeedback.tsx** — Fetches from `list-feedback` with `x-admin-secret` (from `VITE_ADMIN_FEEDBACK_SECRET`). Table: date, category, source, email, message (truncated), status; row expand shows full message and context JSON.
- **Admin Dashboard** — Header link “Feedback” → `/admin/feedback`.

## Env / Config

### Supabase Edge Functions (Secrets)
- `FEEDBACK_TEAM_EMAIL` or `SUPPORT_EMAIL` — Where to send notify-feedback emails.
- `ADMIN_FEEDBACK_SECRET` — Secret string; same value as `VITE_ADMIN_FEEDBACK_SECRET` (used by list-feedback to allow admin inbox to fetch).

### Website (Vite)
- `VITE_SUPABASE_URL` — Already used for report page; needed for `list-feedback` URL.
- `VITE_ADMIN_FEEDBACK_SECRET` — Same value as Supabase `ADMIN_FEEDBACK_SECRET`; sent as `x-admin-secret` when loading feedback. If unset, inbox will get 401 and show an error.

## How to Use

1. **Run migration**: `supabase db push` or apply `create_feedback_table.sql` in the Supabase SQL editor.
2. **Set Edge Function secrets**: In Supabase Dashboard → Edge Functions → notify-feedback and list-feedback, set `FEEDBACK_TEAM_EMAIL`, `ADMIN_FEEDBACK_SECRET`, and Resend keys as above.
3. **Set website env**: In Vercel (or local `.env`), set `VITE_ADMIN_FEEDBACK_SECRET` to the same value as `ADMIN_FEEDBACK_SECRET`.
4. **iOS**: Build and run; submit feedback from Settings or from the “Scanner connected too soon” error; go offline and submit again to confirm queue + flush when back online.
5. **Admin inbox**: Log in at `/admin/login`, then open “Feedback” or go to `/admin/feedback` to see submissions.

## Optional: More “Report this issue” Surfaces

Additional “Report this issue” touch points are already wired. To add more, set `nav.feedbackSource = .error_cta`, `nav.feedbackPrefillMessage`, `nav.feedbackErrorCode`, `nav.feedbackErrorMessage`, `nav.feedbackScanStep`, and `nav.showFeedbackModal = true` when the user taps the link (or pass an `onReportIssue` / `onReportConnectFailed` callback from the parent when the view doesn’t have `nav`).

## Optional: Breadcrumbs

Call `BreadcrumbLogger.shared.log("event_name")` (or with metadata) at key points (e.g. `entered_scan_flow`, `wifi_selected`, `obd_connected`, `scan_started`) so context includes a short event history.
