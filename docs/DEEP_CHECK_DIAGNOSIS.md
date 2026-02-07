# Deep Check "No recent Deep Check found" – Diagnosis & Checklist

When you see **"No recent Deep Check found"** in the app, it usually means either:
- **404**: no row in `deep_check_purchases` for the currently logged-in user, or
- **401**: `get-my-deep-check` rejected the request (missing/invalid/expired token — often because **Verify JWT** is ON at the gateway and the `Authorization` header is stripped).

This doc walks you through the full flow, then a step-by-step checklist to find where it breaks.

---

## Live diagnosis (Supabase MCP)

**Tables:** `deep_check_purchases` exists, **5 rows**. `deep_check_reports` exists, **0 rows**.

**Recent purchases:**

| user_id (email) | vin | status | created_at |
|-----------------|-----|--------|------------|
| e0ad9432... (contact@donewellco.com) | 4S4BTGKD4L3219535 | **report_failed** | 2026-01-30 22:09 |
| e0ad9432... (contact@donewellco.com) | 4S4BTGKD4L3219535 | pending | 2026-01-30 21:50 |
| e0ad9432... (contact@donewellco.com) | 4S4BTGKD4L3219535 | pending | 2026-01-30 19:41 |
| 4ac52369... (klaronda@gmail.com) | JH4DC4360SS001610 | **report_failed** | 2026-01-30 16:59 |
| 4ac52369... (klaronda@gmail.com) | JH4DC4360SS001610 | pending | 2026-01-30 16:35 |

**Edge function logs (recent):**
- **get-my-deep-check**: **GET 401** — request rejected (token missing/invalid or gateway stripping `Authorization` when Verify JWT is ON).
- **stripe-webhook**: POST 200 — webhook is succeeding; purchases are being marked and report generation is triggered.
- **generate-deep-check-report**: **POST 403** — invoked by webhook but gateway is rejecting the call (likely **Verify JWT** ON; service-role bearer is not a user JWT).

**Root cause of "No recent Deep Check found":**  
The app is calling `get-my-deep-check` and receiving **401 Unauthorized**, so it never gets the latest purchase. That happens when the Edge Function doesn’t receive a valid Bearer token — often because **Verify JWT** is enabled for `get-my-deep-check` and the Supabase gateway strips or rejects the header before forwarding.

**Fixes:**
1. **get-my-deep-check**: In Supabase Dashboard → Edge Functions → `get-my-deep-check` → set **Verify JWT** to **OFF** (the function validates the token itself).
2. **generate-deep-check-report**: In Supabase Dashboard → Edge Functions → `generate-deep-check-report` → set **Verify JWT** to **OFF** (the webhook calls it with the service role key; the function does not use user JWT).
3. In the app: ensure the session is valid when opening the Deep Check success screen (e.g. refresh session if needed before calling `get-my-deep-check`).

After (1) and (2), the app should receive the latest purchase (e.g. `report_failed` with `report_error`) and show the correct state instead of "No recent Deep Check found." Reports are currently failing (report_failed) — likely CheapCARFAX API; that’s separate from the 401/403 fixes above.

---

## 1. End-to-end flow (what *should* happen)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  APP: User taps "Add Now" (Deep Vehicle Check)                               │
│  → Calls create-deep-check-session with Bearer <token> + { vin }            │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  create-deep-check-session (Edge Function)                                   │
│  • Validates JWT → gets user.id                                              │
│  • INSERT into deep_check_purchases (user_id, vin, status: 'pending')         │
│  • Creates Stripe Checkout session (metadata: { vin, purchase_id: row.id }) │
│  • UPDATE deep_check_purchases SET stripe_session_id = session.id            │
│  • Returns { url } → app opens Stripe Checkout in browser                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  USER: Completes payment on Stripe → redirect to mintcheckapp.com/.../success│
│  STRIPE: Sends webhook POST to your Supabase stripe-webhook URL              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  stripe-webhook (Edge Function)                                             │
│  • Verifies signature (constructEventAsync)                                  │
│  • On checkout.session.completed:                                            │
│    - UPDATE deep_check_purchases SET status = 'paid'                         │
│      WHERE stripe_session_id = session.id                                    │
│    - POST to generate-deep-check-report with { purchase_id }                  │
│  • Returns 200                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  generate-deep-check-report (Edge Function)                                  │
│  • Loads purchase row, fetches report, saves to deep_check_reports            │
│  • UPDATE deep_check_purchases SET report_url, status = 'report_ready'       │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  APP: User taps "Open MintCheck" → app opens, shows DeepCheckSuccessView     │
│  → Calls get-my-deep-check (Bearer <token>)                                  │
│  → Returns latest deep_check_purchases row for user_id from token            │
│  → App shows status (paid / report_ready / report_failed) or "No recent…"   │
└─────────────────────────────────────────────────────────────────────────────┘
```

**"No recent Deep Check found"** = `get-my-deep-check` returned **404** = **no row in `deep_check_purchases` for this user's `user_id`**.

So the break is either:

- **A)** No row was ever created for this user (create-deep-check-session failed or wasn’t called with this account), or  
- **B)** The row was created with a *different* user (e.g. different session/account when they tapped "Add Now" vs when they opened the app after payment).

---

## 2. Step-by-step diagnosis (hold-my-hand)

### Step 1: Check Supabase – do *any* Deep Check rows exist?

1. Open **Supabase Dashboard** → your project.
2. Go to **Table Editor** → **`deep_check_purchases`**.
3. Look at the table:
   - **If it’s empty** → no purchase was ever recorded. Go to **Step 2** (create-deep-check-session / app).
   - **If there are rows** → note the **`user_id`** values. Then go to **Step 3** to see if the webhook ran and **Step 4** to match the app user.

### Step 2: Confirm the app is calling create-deep-check-session with this account

- When you tapped **"Add Now"**, you must have been **logged in** in the app. The Edge Function uses the **Bearer token** to get `user.id` and inserts a row with that **`user_id`**.
- If you were logged out, or on another account, the row would be tied to a different user — so when you open the app *after* payment with your normal account, `get-my-deep-check` looks up *your* `user_id` and finds nothing → "No recent Deep Check found."

**Check:**

- In the app, go to **Settings** (or wherever you see account/email). Note which email you’re logged in as **now**.
- In Supabase: **Authentication** → **Users**. Find that email and copy the **User UID**.
- In **Table Editor** → **`deep_check_purchases`**: does any row have **`user_id`** = that same UID?
  - **No** → The purchase was created under a different user (different login when you hit "Add Now"). Fix: use the same account when starting a Deep Check and when opening the app after payment; or re-run a Deep Check while logged in as this user.
  - **Yes** → Row exists for this user; the problem is likely downstream (webhook or report). Go to **Step 3**.

### Step 3: Check Stripe – webhook endpoint and events

If a row *exists* for your user but status is still **`pending`** (and never became **`paid`**), Stripe’s webhook either didn’t run or failed (e.g. 400 from our side).

1. **Stripe Dashboard** → **Developers** → **Webhooks**.
2. Find the endpoint that points to your **Supabase** `stripe-webhook` URL, e.g.  
   `https://<project-ref>.supabase.co/functions/v1/stripe-webhook`
3. Click it and check:
   - **Endpoint URL** – must be exactly the Supabase function URL above (no typo, correct project).
   - **Listen to** – ensure **checkout.session.completed** is selected (or “All events” for testing).
   - **Status** – should be “Enabled”.
4. Open **Recent deliveries** (or **Logs**):
   - Find a delivery for **checkout.session.completed** around the time you paid.
   - **Response code**:
     - **200** → Webhook succeeded; our function updated the row. If the app still shows "No recent…", the row might be for a different user (Step 2).
     - **400** → Often "Invalid signature" → **Step 3b**.
     - **500** → Check Supabase Edge Function logs for `stripe-webhook` (see Step 5).

#### Step 3b: Fix "Invalid signature" (400)

- **Stripe Dashboard** → **Developers** → **Webhooks** → your endpoint → **Signing secret** (e.g. `whsec_...`).
- **Supabase Dashboard** → **Project Settings** → **Edge Functions** → **Secrets** (or **Settings** → **Secrets**).
- Set **`STRIPE_WEBHOOK_SECRET`** to that **exact** signing secret (copy-paste, no spaces).
- Redeploy the **stripe-webhook** function if needed, then trigger a test payment and check the webhook delivery again.

Also ensure **`STRIPE_SECRET_KEY`** in Supabase matches the Stripe mode (Test vs Live) you’re using for checkout.

### Step 4: Match user in app vs DB (optional but useful)

- **Option A – Supabase SQL:**  
  In **SQL Editor** run:
  ```sql
  SELECT id, user_id, vin, status, stripe_session_id, created_at
  FROM deep_check_purchases
  ORDER BY created_at DESC
  LIMIT 10;
  ```
  Compare `user_id` with the **User UID** of the account you’re logged in with in the app (Step 2).

- **Option B – App-side:**  
  Temporarily log or display the current user’s ID (e.g. from Supabase Auth) and compare to the `user_id` of the row you see in `deep_check_purchases`.

### Step 5: Check Edge Function logs (Supabase)

1. **Supabase Dashboard** → **Edge Functions** (or **Logs** → filter by function).
2. Check logs for:
   - **create-deep-check-session** – errors when you tap "Add Now" (e.g. 401, 500).
   - **stripe-webhook** – "signature verification failed" or "update deep_check_purchases error".
   - **get-my-deep-check** – 404 is expected when there’s no row for that user; 401 means bad/expired token.

Use the timestamps of your "Add Now" and payment to correlate with log lines.

---

## 3. Quick checklist (copy and tick off)

- [ ] **Supabase → Table Editor → `deep_check_purchases`**  
  Any rows? Note `user_id` and `status`.

- [ ] **Supabase → Authentication → Users**  
  Current app account’s **User UID** matches one of the `user_id` in `deep_check_purchases`?

- [ ] **Stripe → Webhooks**  
  Endpoint URL = `https://<project>.supabase.co/functions/v1/stripe-webhook`  
  Event **checkout.session.completed** (or “All”)  
  Status **Enabled**.

- [ ] **Stripe → Webhooks → Your endpoint → Signing secret**  
  Same value as **Supabase Edge Function secret** **`STRIPE_WEBHOOK_SECRET`**.

- [ ] **Supabase Edge Function secrets**  
  **`STRIPE_SECRET_KEY`** and **`STRIPE_WEBHOOK_SECRET`** set and match Stripe (Test/Live).

- [ ] **Stripe → Recent webhook deliveries**  
  For the payment you care about: response **200** (not 400/500).

- [ ] **Same account**  
  You were logged into the app as the *same* user when you tapped "Add Now" and when you opened the app after payment.

---

## 4. Most likely causes of "No recent Deep Check found"

1. **Different user when starting checkout vs in app now**  
   Row exists under another `user_id`. Fix: use same account for "Add Now" and when opening the app after payment; or run a new Deep Check while logged in as the account you use now.

2. **Webhook never succeeded (400 Invalid signature)**  
   `STRIPE_WEBHOOK_SECRET` in Supabase doesn’t match Stripe’s signing secret for that endpoint. Fix: copy signing secret from Stripe → Supabase secret, redeploy stripe-webhook.

3. **No row at all**  
   create-deep-check-session wasn’t called or failed (e.g. 401 if token missing/expired, or 500). Fix: check Edge Function logs and app flow; ensure "Add Now" sends the correct Bearer token and that the function can insert into `deep_check_purchases`.

Once the correct user has a row and the webhook returns 200, **get-my-deep-check** will return that row and the app will show status (e.g. "Payment received" or "Your Deep Vehicle Check is ready") instead of "No recent Deep Check found."

---

## 5. Fixie (static IP for CheapCARFAX)

If CheapCARFAX requires IP whitelisting, use [Fixie](https://usefixie.com/) so report requests go out from a static IP. The **generate-deep-check-report** Edge Function uses Fixie when the secret **`FIXIE_URL`** is set.

### Supabase setup

1. **Supabase Dashboard** → **Project Settings** → **Edge Functions** (or **Settings** → **Secrets**).
2. Under **Edge Function secrets**, add:
   - **Name:** `FIXIE_URL`
   - **Value:** the **Proxy URL** from your Fixie app (e.g. `http://user:pass@us-east-1.fixie.com:port` — copy from Fixie dashboard).
3. Give CheapCARFAX the **static outbound IP(s)** shown in Fixie for that app so they can whitelist you.
4. **Redeploy** the **generate-deep-check-report** function so it picks up the new secret (Dashboard → Edge Functions → generate-deep-check-report → Redeploy, or `supabase functions deploy generate-deep-check-report`).

If **`FIXIE_URL`** is not set, the function calls CheapCARFAX directly (no proxy). If CheapCARFAX later allows API-key-only (no IP whitelist), you can remove **`FIXIE_URL`** and redeploy to stop using the proxy.
