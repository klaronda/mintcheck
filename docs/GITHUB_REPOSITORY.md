# GitHub repository (canonical)

This monorepo (iOS app, Supabase, marketing site, docs) lives in **one** Git repository.

| Item | Value |
|------|--------|
| **Correct remote** | `https://github.com/klaronda/mintcheck.git` |
| **GitHub repo name** | `klaronda/mintcheck` |
| **Local root** | The folder that contains this file’s parent `docs/` and the root `.git` directory |

## Do not use

- **`mintcheck-app`** — a separate repo; pushes there are wrong for this project unless you intentionally work in that clone.

## Agents & contributors

- Run `git remote -v` from the repo root before pushing. **`origin` must end with `mintcheck.git`**, not `mintcheck-app`.
- If your editor workspace is a **parent** folder (e.g. `Cursor/`) that is not a git root, `cd` into the **`mintcheck`** project directory before `git push`.

## Quick check

```bash
cd /path/to/mintcheck
git rev-parse --show-toplevel   # should be the mintcheck repo root
git remote get-url origin       # should be .../mintcheck.git
```
