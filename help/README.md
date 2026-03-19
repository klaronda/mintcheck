# Help / support copy (reference)

Bundled support articles for the **website** live in **`src/app/contexts/AdminContext.tsx`** (`APP_SUPPORT_ARTICLES`).

Keep them aligned with the **iOS** app:

- `MintCheck/MintCheck/MintCheck/Views/SupportView.swift` — article list + markdown-style `content`
- `MintCheck/MintCheck/MintCheck/Views/DeviceConnectionView.swift` — `OBDHelpSheet` (Finding your OBD-II port)

When you add or change help in the app, update `APP_SUPPORT_ARTICLES` (same `id` / slug as `SupportArticle.id` where applicable) and bump `STORAGE_KEY` in `AdminContext.tsx` if needed.
