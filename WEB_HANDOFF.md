# MintCheck Website – Web Handoff Doc

Handoff document for the MintCheck marketing/website project. Use this to run, deploy, and extend the site.

---

## 1. Project overview

- **Purpose:** Marketing site for MintCheck (iOS OBD-II vehicle scan app). Includes public pages, shared report viewing, auth deep-link fallbacks, admin area, and Deep Check success landing.
- **Domain:** `mintcheckapp.com` (production).
- **Deployment:** Vercel (SPA with rewrites; see below).

---

## 2. Tech stack

| Layer | Choice |
|-------|--------|
| **Runtime** | Node 18+ |
| **Framework** | React 18 |
| **Build** | Vite 6 |
| **Router** | React Router 7 (`react-router`) |
| **Styling** | Tailwind CSS 4 |
| **UI primitives** | Radix UI (via `src/app/components/ui/`) |
| **Backend / data** | Supabase (anon client only on the site) |
| **SEO / head** | `react-helmet-async` |
| **Package manager** | npm (lockfile: `package-lock.json`) |

---

## 3. Repo structure (website)

```
website/
├── .env                    # Local env (see §5; do not commit secrets)
├── index.html              # Entry HTML
├── package.json
├── vite.config.ts
├── postcss.config.mjs
├── vercel.json             # Vercel rewrites + AASA headers
├── public/
│   ├── .well-known/
│   │   └── apple-app-site-association   # Universal Links for iOS app
│   └── favicon.svg
├── src/
│   ├── main.tsx            # Renders <App /> + global styles
│   ├── lib/
│   │   └── supabase.ts     # Supabase client + shared report API
│   ├── styles/
│   │   ├── index.css       # Imports fonts, tailwind, theme
│   │   ├── fonts.css
│   │   ├── tailwind.css
│   │   └── theme.css
│   └── app/
│       ├── App.tsx         # RouterProvider + HelmetProvider + AdminProvider
│       ├── routes.tsx      # All routes (createBrowserRouter)
│       ├── components/    # Layout, Navbar, Footer, ScrollToTop, ui/*
│       ├── contexts/
│       │   └── AdminContext.tsx   # Admin article state (localStorage)
│       ├── pages/         # One component per route
│       └── utils/
│           └── reportUtils.ts    # Report page helpers
```

---

## 4. How to run

- **Install:**  
  `npm install`

- **Dev (with hot reload):**  
  `npm run dev`  
  Default: `http://localhost:5173`

- **Production build:**  
  `npm run build`  
  Output: `dist/`

- **Preview build locally:**  
  After `npm run build`, serve `dist/` with any static server (e.g. `npx serve dist`).

---

## 5. Environment variables

Create a `.env` in `website/` (and set the same in Vercel):

| Variable | Required | Description |
|----------|----------|-------------|
| `VITE_SUPABASE_URL` | Yes | Supabase project URL (e.g. `https://xxx.supabase.co`) |
| `VITE_SUPABASE_ANON_KEY` | Yes | Supabase anon (public) key |
| `VITE_ADMIN_FEEDBACK_SECRET` | Yes for /admin/feedback | Must match `ADMIN_FEEDBACK_SECRET` in Supabase Edge Functions. Used to call `list-feedback`. |

All client-side vars must be prefixed with `VITE_` so Vite exposes them as `import.meta.env.VITE_*`.

---

## 6. Deployment (Vercel)

- **Build command:** `npm run build`
- **Output directory:** `dist`
- **Node version:** 18.x (or set in Vercel project settings).

`vercel.json` config:

- **Rewrites:** All non-`.well-known` requests go to `/index.html` (SPA).
- **Headers:** `/.well-known/apple-app-site-association` is served with `Content-Type: application/json`.

Ensure the AASA file is actually at `public/.well-known/apple-app-site-association` so it’s in `dist` after build.

---

## 7. Routes reference

Defined in `src/app/routes.tsx` with `createBrowserRouter`.

### Standalone (no Layout)

No navbar/footer; used for app deep links and Stripe redirect.

| Path | Page | Purpose |
|------|------|--------|
| `/auth/confirm` | `AuthConfirm` | Email confirmation link from app (Universal Link) |
| `/auth/reset` | `AuthReset` | Password reset link from app |
| `/deep-check/success` | `DeepCheckSuccess` | Post–Stripe Deep Check payment; “Open in app” / Universal Link (§11) |

### With Layout

Layout wraps children with `ScrollToTop` and `<Outlet />` (no nav in Layout; nav is in individual pages as needed).

| Path | Page | Purpose |
|------|------|--------|
| `/` | `Home` | Homepage |
| `/download` | `Download` | App download |
| `/support` | `Support` | Support hub |
| `/support/:slug` | `SupportArticle` | Support article |
| `/blog` | `Blog` | Blog list |
| `/blog/:slug` | `BlogArticle` | Blog article |
| `/privacy` | `PrivacyPolicy` | Privacy policy |
| `/terms` | `TermsOfUse` | Terms of use |
| `/admin/login` | `AdminLogin` | Admin login (secret-based) |
| `/admin/dashboard` | `AdminDashboard` | Admin dashboard |
| `/admin/feedback` | `AdminFeedback` | Feedback inbox (uses `VITE_ADMIN_FEEDBACK_SECRET`) |
| `/report/:shareCode` | `ReportPage` | Public shared scan report |
| `/deep-check/report/:code` | `DeepCheckReportPage` | Deep Check Carfax report (post-purchase); “Open Report” from app (§11) |

---

## 8. Conventions

- **New route:** Add in `routes.tsx`. Use `Layout` for normal pages; use a top-level route with no `Layout` for deep-link/redirect pages.
- **Supabase:** Use `src/lib/supabase.ts`. Only anon key is used on the website; no service role.
- **Admin:** `AdminContext` holds article state (localStorage). Admin Feedback calls the Supabase Edge Function `list-feedback` with `x-admin-secret` (or JWT for admin users); secret must match `VITE_ADMIN_FEEDBACK_SECRET` / `ADMIN_FEEDBACK_SECRET`.
- **Shared reports:** Fetched via `sharedReportsApi.getByShareCode(shareCode)` from `shared_reports` (public read). Report structure is in `ReportData` / `SharedReport` in `supabase.ts`.
- **Head/SEO:** Use `react-helmet-async` (e.g. `<Helmet>` in each page as needed).

---

## 9. Styling

- **Tailwind:** Entry is `src/styles/index.css` → `tailwind.css` + `theme.css` + `fonts.css`. Use Tailwind utility classes; custom design tokens in `theme.css` if needed.
- **Components:** Reusable UI in `src/app/components/ui/` (Radix-based). Use these for consistency.
- **References:** See `TAILWIND_REFERENCE.md` and `COMPONENT_LIBRARY.md` in the repo if present.

---

## 10. Universal Links (iOS app)

- **File:** `public/.well-known/apple-app-site-association` (no file extension).
- **Content:** JSON with `applinks.details[].paths`. Current paths: `/auth/confirm*`, `/auth/reset*`, `/deep-check/success*`.
- **Serving:** Must be HTTPS, `Content-Type: application/json`. Vercel headers are set in `vercel.json`.
- **Domain:** Same as production (e.g. `mintcheckapp.com`). Do not change AASA paths without updating the iOS app’s associated domains.

---

## 11. Stripe integration (Deep Check)

One-time purchase for **Deep Vehicle Check**. Stripe Checkout is used; the website hosts the **success redirect** page and the **“Open in app”** link.

### Flow

1. User starts Deep Check in the **iOS app** (VIN required, signed in).
2. App calls **`create-deep-check-session`** Edge Function (POST, JWT). Function inserts a `deep_check_purchases` row (`status: pending`), creates a Stripe Checkout session, stores `stripe_session_id`, returns checkout URL.
3. User pays on **Stripe Checkout** (hosted by Stripe).
4. Stripe redirects to **`https://mintcheckapp.com/deep-check/success`** (or cancel → `https://mintcheckapp.com`).
5. **`/deep-check/success`** page shows “Payment successful”, “Opening MintCheck…”, and an **“Open in app”** button linking to `mintcheck://deep-check/success`. The path is in AASA (`/deep-check/success*`) for Universal Links.
6. **`stripe-webhook`** receives `checkout.session.completed`, updates `deep_check_purchases` to `status: paid`, then invokes **`generate-deep-check-report`** with `purchase_id` from metadata (fire-and-forget).
7. **`generate-deep-check-report`** (JWT off) fetches Carfax HTML from CheapCARFAX API, stores it in `deep_check_reports`, sets `report_url` and `status = report_ready` (or `report_failed` on error).
8. App uses **`get-my-deep-check`** to poll `vin`, `status`, `report_url`, `report_error`. When `report_ready`, **`report_url`** points to the website: `https://mintcheckapp.com/deep-check/report/{code}`.
9. User taps “Open Report” in app → opens that URL in browser → **website** fetches report HTML from **`get-deep-check-report`** (GET `?code=...`, JWT off) and renders it in an iframe.

### Website scope

- **Route:** `/deep-check/success` → `DeepCheckSuccess` (no Layout). Stripe success URL points here.
- **Page:** “Payment successful”, “Open in app” (`mintcheck://deep-check/success`). No Stripe SDK or env vars on the site.
- **Route:** `/deep-check/report/:code` → `DeepCheckReportPage`. Public (no auth). Fetches report by `code` from Edge Function `get-deep-check-report`, shows MintCheck header + Carfax HTML in sandboxed iframe. Used when user opens “Open Report” from the app after purchase.
- **AASA:** `/deep-check/success*` must stay in `apple-app-site-association` for Universal Links back into the app.

### Backend (Supabase)

| Component | Role |
|-----------|------|
| **`create-deep-check-session`** | Auth via JWT, insert `deep_check_purchases`, create Stripe Checkout session, return `{ url }`. VIN must be 17 chars. Success/cancel URLs hardcoded to `mintcheckapp.com`. |
| **`stripe-webhook`** | Verify `Stripe-Signature`, set `status = 'paid'`, then invoke **`generate-deep-check-report`** with `metadata.purchase_id` (JWT off). |
| **`generate-deep-check-report`** | JWT off. POST body `{ purchase_id }`. Calls CheapCARFAX Carfax API, stores HTML in `deep_check_reports`, sets `report_url` + `status = report_ready` or `report_failed`. |
| **`get-deep-check-report`** | JWT off. GET `?code=...`. Returns `{ html, yearMakeModel }` for that report code. Used by `/deep-check/report/:code`. |
| **`get-my-deep-check`** | GET, JWT. Returns latest `deep_check_purchases` row: `vin`, `status`, `report_url`, `report_error`. |
| **`deep_check_purchases`** | `status` can be `pending` \| `paid` \| `report_ready` \| `report_failed`; optional `report_error`. |
| **`deep_check_reports`** | Stores Carfax HTML by `report_code`; served via `get-deep-check-report`. |

### Edge Function secrets (Supabase)

Set for `create-deep-check-session`, `stripe-webhook`, and **`generate-deep-check-report`**:

| Secret | Required | Description |
|--------|----------|-------------|
| `STRIPE_SECRET_KEY` | Yes | Stripe secret key (e.g. `sk_live_...` or `sk_test_...`). |
| `STRIPE_DEEP_CHECK_PRICE_ID` | Yes (create-deep-check-session) | Stripe Price ID for the Deep Check one-time product. |
| `STRIPE_WEBHOOK_SECRET` | Yes (stripe-webhook) | Webhook signing secret (`whsec_...`) from Stripe Dashboard → Developers → Webhooks. |
| `CHEAPCARFAX_API_KEY` | Yes (generate-deep-check-report) | API key for CheapCARFAX Carfax HTML endpoint. |

### Stripe Dashboard (webhook)

1. **Developers → Webhooks → Add endpoint.**
2. **Endpoint URL:** `https://<project-ref>.supabase.co/functions/v1/stripe-webhook` (replace with your Supabase project URL).
3. **Events:** `checkout.session.completed`.
4. Copy the **Signing secret** → set as `STRIPE_WEBHOOK_SECRET` in Supabase.

Use **test** keys and a **test** webhook endpoint for local/staging; **live** keys and **live** webhook for production.

### iOS (out of scope for web)

- **`DeepCheckService`** calls `create-deep-check-session` and `get-my-deep-check`.
- **`DeepCheckSuccessView`** is shown when returning via `mintcheck://deep-check/success` or Universal Link.

---

## 12. Related docs (in repo)

- `SHARED_REPORTS_HANDOFF.md` – Shared report page and API.
- `REPORT_ROUTING_FIX_HANDOFF.md` – Report routing notes (if present).
- `README.md` – Repo-level setup (if present).

---

## 13. Quick checklist for new devs

1. Clone repo, `cd website`, `npm install`, copy `.env.example` to `.env` (or create `.env` from §5) and fill in values.
2. Run `npm run dev`, open `http://localhost:5173`.
3. Confirm Supabase and (if used) admin feedback secret in Vercel env match §5.
4. After deploy, test `/report/:shareCode`, `/auth/confirm`, `/deep-check/success`, **`/deep-check/report/:code`** (use a valid report code from a completed Deep Check), and that AASA is reachable at `https://<domain>/.well-known/apple-app-site-association`. For Stripe/Deep Check, ensure webhook, `CHEAPCARFAX_API_KEY`, and Edge Function secrets are set (§11).
