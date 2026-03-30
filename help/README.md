# Help / support copy (reference)

## Website (live CMS)

Public **Support** and **Blog** pages load from Supabase table **`site_articles`** (see migration `supabase/migrations/site_articles.sql`). Edits in **Admin** are saved there and are visible to all visitors after refresh.

**One-time setup**

1. Apply the migration in the Supabase SQL editor (or `supabase db push`).
2. Set your CMS user’s profile role:  
   `UPDATE public.profiles SET role = 'admin' WHERE id = (SELECT id FROM auth.users WHERE email = 'your-admin@email');`  
   (Must match the account you use on `/admin/login`.)
3. Deploy the site. The first time an **admin** loads the app with an empty `site_articles` table, bundled defaults from `AdminContext.tsx` are **upserted** automatically.

If the table is empty and nobody has seeded yet, visitors still see **bundled fallback** copy from `APP_SUPPORT_ARTICLES` + default blog HTML in code.

## Bundled defaults (source of truth for seed + iOS)

Default support markdown still lives in **`src/app/contexts/AdminContext.tsx`** (`APP_SUPPORT_ARTICLES`). Keep aligned with the **iOS** app:

- `MintCheck/MintCheck/MintCheck/Views/SupportView.swift` — article list + markdown-style `content`
- `MintCheck/MintCheck/MintCheck/Views/DeviceConnectionView.swift` — `OBDHelpSheet` (Finding your OBD-II port)

When you add a new help slug in the app, add it to `APP_SUPPORT_ARTICLES` and redeploy so bootstrap / fallbacks stay correct; you can also add the row in Admin or Supabase.
