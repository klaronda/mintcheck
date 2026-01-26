# Vercel Deployment Setup

The MintCheck marketing site is ready to deploy on [Vercel](https://vercel.com). The repo lives at **https://github.com/klaronda/mintcheck**.

## 1. Connect the repo

1. Go to [vercel.com](https://vercel.com) and sign in (or create an account).
2. Click **Add New…** → **Project**.
3. **Import** your Git repository. Connect GitHub if prompted, then select **klaronda/mintcheck**.
4. Vercel will detect **Vite** as the framework. Use these settings:
   - **Framework Preset:** Vite
   - **Root Directory:** leave empty (repo root is the website)
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
   - **Install Command:** `npm install`

## 2. Environment variables

Add these in **Project Settings → Environment Variables** (or during import):

| Name | Description | Required |
|------|-------------|----------|
| `VITE_SUPABASE_URL` | Your Supabase project URL (e.g. `https://xxxx.supabase.co`) | Recommended |
| `VITE_SUPABASE_ANON_KEY` | Supabase anonymous (public) key | Recommended |

The app has fallbacks for local development, but you should set these in Vercel for production so the site uses your Supabase project (CMS, contact form, shared reports).

## 3. Deploy

1. Click **Deploy**. Vercel will build and publish the site.
2. You’ll get a URL like `mintcheck-xxx.vercel.app`. Use it for testing.

## 4. Custom domain (optional)

To use **mintcheckapp.com**:

1. **Project Settings → Domains** → Add `mintcheckapp.com` (and `www.mintcheckapp.com` if you use it).
2. Follow Vercel’s DNS instructions (either Vercel nameservers or CNAME to `cname.vercel-dns.com`).

## 5. After setup

- Every push to `main` triggers a new production deployment.
- Preview deployments are created for other branches and pull requests.
- `vercel.json` in the repo configures SPA rewrites, security headers, and caching for assets, `sitemap.xml`, and `robots.txt`.

## Local development

```bash
npm install
npm run dev
```

Copy `.env.example` to `.env` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. Never commit `.env`.
