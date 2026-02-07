# MintCheck QA Checklist

Use this checklist to run through the product before TestFlight, launch, or after major changes. Test on a **real device** for OBD and deep links; simulator is fine for auth, settings, and navigation.

---

## 1. iOS App – Launch and Auth

| #    | Check                                                                                                                                                                                       | Pass |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| 1.1  | App launches to splash (mint green), then resolves to Home (logged out) or Dashboard (logged in).                                                                                           |      |
| 1.2  | **Home (logged out):** "Get Started" / "Sign In" navigates to Sign In.                                                                                                                      |      |
| 1.3  | **Sign In:** Valid email + password signs in and lands on Dashboard.                                                                                                                        |      |
| 1.4  | **Sign In:** Wrong password shows error and "Report this issue" is available.                                                                                                               |      |
| 1.5  | **Create account:** All fields (name, email, password, birthdate) validate; signup succeeds and shows email confirmation message or lands in app.                                         |      |
| 1.6  | **Create account:** Validation errors (e.g. passwords don't match, short password) show; "Report this issue" appears when error is shown.                                                    |      |
| 1.7  | **Forgot password (from Sign In):** Opens sheet; submitting email shows success or error; "Report this issue" on error.                                                                     |      |
| 1.8  | **Reset password (deep link):** Open `https://mintcheckapp.com/auth/reset?token=...` in Safari on device with app installed – app opens to Set New Password (or "Link Expired" if invalid). |      |
| 1.9  | **Reset password:** New password + confirm updates password; success state and "Sign In" work.                                                                                              |      |
| 1.10 | **Email confirmation (deep link):** Open `https://mintcheckapp.com/auth/confirm?token=...&type=signup` – app opens to confirmation success or appropriate screen.                           |      |
| 1.11 | **Sign out:** From Settings or menu, sign out returns to Home; session is cleared.                                                                                                          |      |

---

## 2. iOS App – Navigation and Tabs

| #   | Check                                                                                                   | Pass |
| --- | ------------------------------------------------------------------------------------------------------- | ---- |
| 2.1 | Bottom tabs: Home, Scan, Support, Settings – each switches to correct root screen.                      |      |
| 2.2 | From Dashboard: "Start a check" enters scan flow; "View all scans" opens All Scans; scan history loads. |      |
| 2.3 | Menu (if used) opens and tab selection works.                                                           |      |
| 2.4 | Navigating away from Results (e.g. to another tab) triggers save/upload when applicable; no crash.      |      |

---

## 3. iOS App – Scan Flow (full path)

| #    | Check                                                                                                                                                                                        | Pass |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| 3.1  | **Engine on** – Continue advances.                                                                                                                                                           |      |
| 3.2  | **Enter VIN:** Manual entry accepts 17-char VIN; camera/scanner opens if available; invalid VIN shows error and "Report this issue."                                                         |      |
| 3.3  | **VIN decode:** Valid VIN shows "Vehicle Found!" and decoded make/model/year; manual fallback works.                                                                                         |      |
| 3.4  | **Vehicle details:** Year/make/model (and any optional fields) – Next continues.                                                                                                             |      |
| 3.5  | **Locate port / OBD help:** Help sheet opens and closes.                                                                                                                                     |      |
| 3.6  | **Connect WiFi:** "Connect to Scanner" starts connection; if phone is already on OBD WiFi with no internet, "Scanner connected too soon" alert appears with "Report this issue."             |      |
| 3.7  | **Connect WiFi – failure:** After connection fails, "Couldn't find your scanner automatically" with Open Settings, Try Again, Troubleshoot; "Report this issue" opens feedback with context. |      |
| 3.8  | **Connect WiFi – success:** Connected state shows; "Start Scan" appears.                                                                                                                     |      |
| 3.9  | **Scanning:** Progress and status text update; scan completes or shows error.                                                                                                                |      |
| 3.10 | **Scan error:** "Scan Error" alert with Try Again, Cancel, and "Report this issue" – Report opens feedback with error message.                                                              |      |
| 3.11 | **Connection lost mid-scan:** Recovery overlay (Retry / Start Over / Troubleshoot) appears and works.                                                                                        |      |
| 3.12 | **Unplug device:** "I've Unplugged It" continues.                                                                                                                                              |      |
| 3.13 | **Disconnect WiFi:** Step completes; flow continues to analyzing/results.                                                                                                                    |      |
| 3.14 | **No scanner dialog:** If shown ("only compatible with select Wi‑Fi scanners"), dismiss works.                                                                                              |      |

---

## 4. iOS App – Results and Share

| #    | Check                                                                                                                 | Pass |
| ---- | --------------------------------------------------------------------------------------------------------------------- | ---- |
| 4.1  | Results screen shows: recommendation badge, findings, price context, system details, vehicle details, disclaimer.     |      |
| 4.2  | **AI/valuation:** If network failed, "Estimated value not available" and "Report this issue" appear.                  |      |
| 4.3  | **Share:** Share button opens share sheet; recipients field, message, "Send Report" work.                             |      |
| 4.4  | **Share – success:** Report sent; success state and shareable link (if any) show.                                     |      |
| 4.5  | **Share – failure:** Error message, "Try Again," "Copy Share Link" (if applicable), and "Report this issue" work.     |      |
| 4.6  | **Share – offline:** Offline message and disabled send (or clear error) as designed.                                  |      |
| 4.7  | **View system detail:** Tapping a system opens system detail; back returns to results.                                |      |
| 4.8  | **Delete scan:** "Delete this car scan" → confirmation alert → scan removed and navigated away.                       |      |
| 4.9  | **Delete scan – failure:** Toast "Couldn't delete…" and "Report this issue" appear.                                   |      |
| 4.10 | **Upload pending:** If save/upload failed, "Not uploaded yet" / "Upload now" and "Report this issue" (in toast) work.   |      |
| 4.11 | **Close/Done:** Returns to Dashboard; scan saved when applicable.                                                     |      |

---

## 5. iOS App – Settings and Account

| #    | Check                                                                                                                                   | Pass |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| 5.1  | **Account info:** Name, email displayed; Edit expands; save updates profile and shows confirmation.                                     |      |
| 5.2  | **Change email:** Sheet opens; new email + password; confirmation email or error; "Report this issue" on error.                         |      |
| 5.3  | **Change password:** Current + new + confirm; update works; "Report this issue" on error; Forgot password link opens sheet.             |      |
| 5.4  | **Send feedback:** Opens feedback modal (category, message, optional email); submit shows success or offline message.                   |      |
| 5.5  | **Privacy Policy:** Opens [https://mintcheckapp.com/privacy](https://mintcheckapp.com/privacy) in browser.                              |      |
| 5.6  | **Terms of Service:** Opens [https://mintcheckapp.com/terms](https://mintcheckapp.com/terms) in browser.                                |      |
| 5.7  | **Shared Links:** List loads; copy link works; delete link works.                                                                       |      |
| 5.8  | **Shared Links – load error:** Error state and "Report this issue" appear.                                                              |      |
| 5.9  | **Delete shared link – failure:** Alert "Couldn't delete link" with "Report this issue."                                                |      |
| 5.10 | **Sign out:** Confirmation alert; sign out completes.                                                                                   |      |
| 5.11 | **Delete account:** First alert → Confirm → second confirmation; account deletes and success message or error with "Report this issue." |      |

---

## 6. iOS App – Support and Help

| #   | Check                                                                   | Pass |
| --- | ----------------------------------------------------------------------- | ---- |
| 6.1 | Support tab lists help articles; tapping opens article.                 |      |
| 6.2 | OBD / scanner help opens from scan flow or support where implemented.   |      |
| 6.3 | Troubleshoot sheet opens and closes from scan error or connect failure. |      |

---

## 7. iOS App – Feedback (all entry points)

| #    | Check                                                                                                               | Pass |
| ---- | ------------------------------------------------------------------------------------------------------------------- | ---- |
| 7.1  | Settings → "Send feedback" → submit: success toast or offline message.                                              |      |
| 7.2  | Scanner connected too soon → "Report this issue" → modal pre-filled (bug), submit works.                            |      |
| 7.3  | Connect failed → "Report this issue" → modal with connect failure context.                                          |      |
| 7.4  | Scan Error alert → "Report this issue" → modal with scan error.                                                     |      |
| 7.5  | Save/upload failure toast → "Report this issue" → modal.                                                            |      |
| 7.6  | Delete scan failure toast → "Report this issue" → modal.                                                            |      |
| 7.7  | AI/valuation error on results → "Report this issue" → modal.                                                        |      |
| 7.8  | Share send failed → "Report this issue" → modal.                                                                    |      |
| 7.9  | Delete account failed → "Report this issue" → modal.                                                                |      |
| 7.10 | Delete shared link failed → "Report this issue" → modal.                                                            |      |
| 7.11 | Shared Links load failed → "Report this issue" → modal.                                                             |      |
| 7.12 | Sign in / Create account error → "Report this issue" → modal.                                                       |      |
| 7.13 | Change password / email / Forgot / Reset password error → "Report this issue" → modal.                              |      |
| 7.14 | VIN decode error (vehicle basics) → "Report this issue" → modal.                                                    |      |
| 7.15 | Submit feedback while offline: queued message; after back online, open app and confirm queue flushes (if testable). |      |

---

## 8. iOS App – Deep Links and Universal Links (requires paid Apple Developer)

| #   | Check                                                                                                                                     | Pass |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| 8.1 | **Universal Links:** From Safari on device, open `https://mintcheckapp.com/auth/confirm?token=...&type=signup` – app opens (not browser). |      |
| 8.2 | **Universal Links:** Same for `https://mintcheckapp.com/auth/reset?token=...` – app opens to reset flow.                                  |      |
| 8.3 | **Fallback (no app / UL fail):** Same URLs in browser show "Opening MintCheck…" and "Download the app" / copy link.                       |      |

---

## 9. Website – Public Pages

| #   | Check                                                                                                                                                                              | Pass |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| 9.1 | **Home:** [https://mintcheckapp.com](https://mintcheckapp.com) loads; CTAs, copy, and "Download" link work.                                                                        |      |
| 9.2 | **Download:** [https://mintcheckapp.com/download](https://mintcheckapp.com/download) – content and App Store link (or placeholder) correct.                                        |      |
| 9.3 | **Privacy:** [https://mintcheckapp.com/privacy](https://mintcheckapp.com/privacy) – policy loads and is readable.                                                                  |      |
| 9.4 | **Terms:** [https://mintcheckapp.com/terms](https://mintcheckapp.com/terms) – terms load and are readable.                                                                         |      |
| 9.5 | **Support:** Support index and article routes (e.g. /support, /support/:slug) work.                                                                                                |      |
| 9.6 | **Report page:** [https://mintcheckapp.com/report/:shareCode](https://mintcheckapp.com/report/:shareCode) – valid share code shows report; invalid shows appropriate error or 404. |      |

---

## 10. Website – Auth Fallbacks and AASA

| #    | Check                                                                                                                                                                                         | Pass |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| 10.1 | **Auth confirm:** [https://mintcheckapp.com/auth/confirm?token=test&type=signup](https://mintcheckapp.com/auth/confirm?token=test&type=signup) – "Opening MintCheck…" and Download/Copy link. |      |
| 10.2 | **Auth reset:** [https://mintcheckapp.com/auth/reset?token=test](https://mintcheckapp.com/auth/reset?token=test) – same.                                                                      |      |
| 10.3 | **AASA:** `curl -I https://mintcheckapp.com/.well-known/apple-app-site-association` returns 200 and `Content-Type: application/json`.                                                         |      |
| 10.4 | **AASA body:** `curl https://mintcheckapp.com/.well-known/apple-app-site-association` returns valid JSON with applinks paths.                                                                 |      |

---

## 11. Website – Admin

| #    | Check                                                                                                                                     | Pass |
| ---- | ----------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| 11.1 | **Admin login:** /admin/login – credentials work; redirect to dashboard.                                                                  |      |
| 11.2 | **Admin dashboard:** /admin/dashboard – loads; "Feedback" link present.                                                                   |      |
| 11.3 | **Admin feedback:** /admin/feedback – list loads (with `VITE_ADMIN_FEEDBACK_SECRET` set); expand row shows full message and context JSON. |      |
| 11.4 | **Admin feedback – no secret:** With secret unset, 401 or error message as designed.                                                      |      |

---

## 12. Backend and Integration

| #    | Check                                                                                                          | Pass |
| ---- | -------------------------------------------------------------------------------------------------------------- | ---- |
| 12.1 | **Supabase Auth:** Sign up, sign in, sign out, reset password, and email confirmation complete without errors. |      |
| 12.2 | **Supabase DB:** Scans and vehicles save/load; profiles update.                                                |      |
| 12.3 | **Edge Functions:** Auth emails (confirm, reset) send and links work.                                          |      |
| 12.4 | **Edge Functions:** delete-account succeeds when called with valid token.                                      |      |
| 12.5 | **Feedback:** Submit from app → row in `feedback` table; notify-feedback sends team email (Resend).            |      |
| 12.6 | **Share:** Share report API creates link and/or sends email; report page fetches by share code.                |      |
| 12.7 | **list-feedback:** Returns data when called with correct `x-admin-secret`.                                     |      |

---

## 13. Device and Network

| #    | Check                                                                                                                | Pass |
| ---- | -------------------------------------------------------------------------------------------------------------------- | ---- |
| 13.1 | **WiFi OBD (real device):** Phone on OBD WiFi, scan flow connects and completes scan (tested on known-good vehicle). |      |
| 13.2 | **Airplane / no network:** App doesn't crash; offline messaging and queued feedback behave as designed.              |      |
| 13.3 | **Poor network:** Scan save/upload retry or "Upload now" and toasts work.                                            |      |
| 13.4 | **Simulator:** Auth, navigation, settings, support, feedback (no OBD) all work.                                       |      |

---

## 14. App Store Readiness (pre-submission)

| #    | Check                                                                                                                                                                                                               | Pass |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| 14.1 | App icon set for all required sizes in Assets.                                                                                                                                                                      |      |
| 14.2 | Screenshots prepared for required device sizes (e.g. 6.7", 5.5").                                                                                                                                                     |      |
| 14.3 | Privacy policy URL: [https://mintcheckapp.com/privacy](https://mintcheckapp.com/privacy).                                                                                                                             |      |
| 14.4 | Terms (or EULA) URL: [https://mintcheckapp.com/terms](https://mintcheckapp.com/terms).                                                                                                                               |      |
| 14.5 | Support URL/email (e.g. [support@mintcheckapp.com](mailto:support@mintcheckapp.com)) set.                                                                                                                           |      |
| 14.6 | Age rating and export compliance (encryption) completed in App Store Connect.                                                                                                                                        |      |
| 14.7 | Entitlements: If using OBD WiFi and Universal Links, Associated Domains and Hotspot/Wi-Fi Info enabled in MintCheck/MintCheck.entitlements and in Xcode Signing & Capabilities. |      |

---

## Notes

- **OBD:** Full scan flow and "Report this issue" from connect/scan errors require a **real device** and (for WiFi OBD) a **paid Apple Developer account** with entitlements enabled.
- **Feedback queue:** To verify offline queue, submit feedback with device offline then bring it online and reopen app; check admin inbox or DB for the delayed submission.
- **Deep links:** Use real tokens from your auth emails for reset/confirm; replace `...` in the checklist URLs when testing.
