# MintCheck Admin Auth Setup

The website CMS uses **Supabase Auth** for admin login. Admin users are separate from app users: only accounts with `app_metadata.role === 'admin'` can access `/admin/login` and the dashboard.

## Admin user: contact@mintcheckapp.com

### 1. Create the user in Supabase

1. Open your Supabase project: [Dashboard](https://supabase.com/dashboard) → your MintCheck project.
2. Go to **Authentication** → **Users**.
3. Click **Add user** → **Create new user**.
4. Use:
   - **Email:** `contact@mintcheckapp.com`
   - **Password:** Set a strong password (you’ll use this to sign in on the site).

### 2. Set admin role (required)

1. After the user exists, open that user in the Users list.
2. Find **User Metadata** or **Edit user**.
3. Set **Raw User Meta Data** or **App Metadata** to:

   ```json
   {
     "role": "admin"
   }
   ```

   If your UI has separate **App metadata** (recommended): use that and set `"role": "admin"` there. The app checks `user.app_metadata.role === 'admin'`.

4. Save.

### 3. Sign in on the website

1. Go to `https://mintcheckapp.com/admin/login` (or `http://localhost:5173/admin/login` in dev).
2. Sign in with `contact@mintcheckapp.com` and the password you set.
3. You’ll be redirected to the admin dashboard.

## App users vs admin users

- **App users:** Sign up/sign in via the iOS app. They use the same Supabase Auth but do **not** have `role: 'admin'`. They cannot access the admin panel.
- **Admin users:** Created in the Supabase Dashboard with `app_metadata.role = 'admin'`. Only they can access the CMS.

Both use the same Supabase project; the role metadata is what enforces access.

## Adding more admins

1. Create a new user under **Authentication** → **Users**.
2. Set **App metadata** to `{ "role": "admin" }`.
3. They can then sign in at `/admin/login`.

## Troubleshooting

- **“This account is not an admin”**  
  The user exists but doesn’t have `app_metadata.role === 'admin'`. Edit the user in Supabase and add that.

- **“Invalid login credentials”**  
  Check email and password. Ensure the user was created under the same Supabase project the site uses.

- **Redirect loop or immediate logout**  
  Confirm `app_metadata.role` is exactly `"admin"` (no typos, correct field).
