# Switch Stripe to test mode

Deep Check uses three Supabase Edge Function secrets. To use **Stripe test mode** (no real charges, test card `4242 4242 4242 4242`), set those secrets to your **test** values.

---

## 1. Stripe Dashboard → Test mode

1. Go to [Stripe Dashboard](https://dashboard.stripe.com).
2. Turn **Test mode** on (toggle in the top-right, or **Developers** → **Test mode**).
3. Keep the dashboard in test mode for all steps below.

---

## 2. Get test API key and Price ID

1. **Developers** → **API keys**
   - Copy **Secret key** (starts with `sk_test_`).  
   - This goes in Supabase as **`STRIPE_SECRET_KEY`**.

2. **Products** → open your Deep Check product (or create one in test mode)
   - Use the **Price** you want for testing (e.g. $9.99).
   - Copy the **Price ID** (starts with `price_`).  
   - This goes in Supabase as **`STRIPE_DEEP_CHECK_PRICE_ID`**.  
   - Test and live products/prices are separate; use the price from the test product.

---

## 3. Create test webhook endpoint

1. **Developers** → **Webhooks** → **Add endpoint**
2. **Endpoint URL:**  
   `https://<your-project-ref>.supabase.co/functions/v1/stripe-webhook`  
   (same URL you use in live; Stripe test/live is distinguished by the signing secret.)
3. **Events to send:**  
   Select **checkout.session.completed** (or “Select events” and choose it).
4. Click **Add endpoint**.
5. On the new endpoint, click **Reveal** under **Signing secret** and copy it (`whsec_...`).  
   This goes in Supabase as **`STRIPE_WEBHOOK_SECRET`**.  
   **Important:** Use the signing secret for this **test** endpoint. If you already have a live webhook, test mode needs its own endpoint (or its own secret) so the secret matches the key you’re using.

---

## 4. Set Supabase secrets (test values)

1. **Supabase Dashboard** → your project → **Project Settings** → **Edge Functions** (or **Settings** → **Secrets**).
2. Under **Edge Function secrets**, set:

   | Name                         | Value                    |
   |------------------------------|--------------------------|
   | `STRIPE_SECRET_KEY`          | `sk_test_...`            |
   | `STRIPE_WEBHOOK_SECRET`       | `whsec_...` (test endpoint) |
   | `STRIPE_DEEP_CHECK_PRICE_ID`  | `price_...` (test price) |

3. Save. Redeploy if your platform requires it:  
   **Edge Functions** → **stripe-webhook** and **create-deep-check-session** → **Redeploy** (or `supabase functions deploy stripe-webhook create-deep-check-session`).

---

## 5. Test a payment

1. In the app, start a Deep Check (enter a VIN, tap **Add Now**).
2. On Stripe Checkout, use test card **4242 4242 4242 4242**, any future expiry, any CVC, any postal code.
3. Complete payment; the webhook should run and the purchase should move to `paid` and trigger report generation.

---

## Switching back to live

1. In Stripe Dashboard, turn **Test mode** off.
2. Get your **live** Secret key, **live** Price ID, and **live** webhook signing secret.
3. Update the same three secrets in Supabase with the live values.
4. Redeploy the Edge Functions that use them.
