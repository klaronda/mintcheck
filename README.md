# MintCheck (monorepo)

This repository contains the **MintCheck iOS app**, the **marketing website** (Vite + React), **Supabase** (Edge Functions & migrations), engineering notes, and internal handoff docs.

## GitHub (correct remote)

**Canonical remote:** [`klaronda/mintcheck`](https://github.com/klaronda/mintcheck) — `origin` should be `https://github.com/klaronda/mintcheck.git`.

Do **not** push this codebase to a separate **`mintcheck-app`** repo unless you explicitly mean to. See [`docs/GITHUB_REPOSITORY.md`](./docs/GITHUB_REPOSITORY.md).

## What lives where

| Area | Path | Notes |
|------|------|--------|
| **iOS app** | `MintCheck/` | Xcode project |
| **Marketing site** | `src/`, `public/`, `package.json`, `vite.config.ts` | Vite + React (typical Vercel deploy root) |
| **Legacy / extra web** | `website/` | Older or parallel site tree—confirm with your deploy setup |
| **Backend** | `supabase/` | Edge functions, SQL migrations |
| **Docs** | `docs/`, `*.md` at repo root | Handoffs, runbooks |

## Marketing website (quick start)

```bash
npm install
npm run dev
npm run build
```

Detailed UI and Cursor-oriented docs: **CURSOR_QUICKSTART.md**, **CURSOR_SETUP.md**, **COMPONENT_LIBRARY.md**, **TAILWIND_REFERENCE.md**.

## iOS

Open `MintCheck/MintCheck.xcodeproj` in Xcode.

## Environment (web)

Create a `.env` in the repo root for local Vite (see existing handoff docs for variable names, e.g. `VITE_SUPABASE_*`).

## License / contact

Proprietary — **MintCheck**. Support: **support@mintcheckapp.com**.
