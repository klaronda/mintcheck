# MintCheck — App Store Connect copy

Use these strings in **App Store Connect** (App Information + version **1.0 Prepare for Submission**). Adjust wording to match your final legal/compliance review.

**Character limits (iOS, typical):** Subtitle 30 · Promotional 170 · Keywords 100 · Description 4000.

---

## Subtitle (max 30 characters)

Pick one:

| Option | Chars |
|--------|------:|
| `OBD health checks for used cars` | 30 ✓ |
| `Know the car before you buy` | 28 |
| `Engine health for used car buyers` | 30 ✓ |
| `Used car scans with OBD Wi‑Fi` | 28 |

**Recommended:** `OBD health checks for used cars`

---

## Promotional text (max 170 characters)

> Scan before you buy. MintCheck reads your car’s computer with a compatible Wi‑Fi OBD2 scanner and turns it into a clear health readout—plus recalls and vehicle context. Find scanners at mintcheckapp.com.

*(169 characters — trim one word if your paste adds a character.)*

**Shorter fallback (under 170):**

> Scan a used car’s engine health in minutes with a Wi‑Fi OBD2 scanner. Free scans, optional Buyer Pass, and one-time scans. Compatible devices: mintcheckapp.com.

---

## Keywords (max 100 characters, comma-separated, no spaces)

```
OBD2,used car,car scanner,ELM327,vehicle,VIN,diagnostic,engine,Carfax,buy used
```

**Alternate (if you need to drop “Carfax” for trademark caution):**

```
OBD2,used car,car scanner,ELM327,vehicle,VIN,diagnostic,engine,recall,buy car
```

---

## Description

You can paste this into the **Description** field (under 4000 characters).

```
MintCheck helps used car buyers decide with confidence. Plug in a compatible Wi‑Fi ELM327 OBD2 scanner, run a quick scan, and get a plain-English read on engine health—right on your phone.

REQUIRES A COMPATIBLE DEVICE
MintCheck is built for Wi‑Fi OBD2 scanners (not Bluetooth-only adapters). See compatible options at mintcheckapp.com.

WHAT YOU GET
• Free tier: up to three scans to get started on your first vehicle
• Clear results with diagnostic context, recalls, and vehicle details
• Built for real-world shopping—use it on the lot or in the driveway

ONE-TIME SCAN — $3.99 (In-App Purchase)
Need just one more scan? Buy a single scan credit when you’re blocked after free scans—fast checkout with Apple.

BUYER PASS — $14.99
Shopping a lot of cars? Get 60 days of scanning with up to ten full scans per day (paid via secure checkout in your browser—see app for details).

DEEP CHECK — $9.99
Full vehicle history–style report: accidents, damage, title and more—delivered as a detailed report (see app for availability and flow).

SUPPORT
Help & contact: mintcheckapp.com · support@mintcheckapp.com

MintCheck does not replace a professional mechanical inspection. Results depend on vehicle, adapter, and data available from the car’s computer.
```

---

## “What’s New in This Version” (release notes template)

```
• One-Time Scan: buy a single scan ($3.99) when you’ve used your free scans
• Buyer Pass flow and dashboard improvements
• Light, consistent UI for night use in driveways and lots
• Bug fixes and performance improvements
```

---

## URLs & metadata (version page)

| Field | Suggested value |
|--------|------------------|
| **Support URL** | `https://mintcheckapp.com` (or your `/support` path if you add one) |
| **Marketing URL** | `https://mintcheckapp.com` |
| **Copyright** | `© 2026 MintCheck LLC` (adjust year/entity as needed) |

---

## App Review notes (paste into “Notes” for reviewer)

Short template you can extend:

```
TEST ACCOUNT (if sign-in required):
Email: [your test account]
Password: [your test account]

ONE-TIME SCAN PURCHASE (IAP):
Product ID: com.mintcheck.onetimescan
After free scans are used, the “One-Time Scan” card appears on the home screen, or “Start Check” offers “Buy One Scan — $3.99”. Purchase is consumable sandbox credit.

HARDWARE:
Requires a compatible Wi‑Fi ELM327 OBD2 adapter. Purchase flow and credits can be verified without a vehicle; full scan requires adapter + vehicle. See mintcheckapp.com for compatible devices.

OTHER PAYMENTS:
Buyer Pass and Deep Check use Stripe in Safari; not part of IAP testing.
```

---

## App Information & compliance (what to do for each field)

Below is **MintCheck-specific** guidance. Apple’s exact wording changes; always read each question literally.

### 1. Category (Primary + optional Secondary)

| Field | Suggestion for MintCheck | Why |
|--------|---------------------------|-----|
| **Primary** | **Utilities** | Tool that reads car data and shows diagnostics—not a game or social app. |
| **Secondary (optional)** | **Shopping** or **Lifestyle** | **Shopping** if you want “buying a used car” discovery; **Lifestyle** if you prefer a softer fit. Pick **one** secondary or leave blank. |

**Avoid** picking **Navigation** unless you truly position the app as GPS/maps (you don’t).

---

### 2. Content rights (“Set Up Content Rights Information”)

Apple wants to know if the app **contains or streams third-party content** you must have rights to.

**Typical path for MintCheck:**

- You **own** your app name, UI, and marketing copy (or your **LLC** does).
- You use **data/APIs** (Supabase, Stripe, NHTSA, vehicle history provider, etc.) under **their terms**—that’s not the same as “uploading someone else’s movies.” Answer the questions **honestly**:
  - If the app **does not** primarily offer third-party music, video, or user-uploaded marketplace of others’ copyrighted works, you usually select **no** where asked about that kind of content.
  - If you **embed** third-party trademarks (e.g. car brand logos), say so only if Apple’s questionnaire asks about **branded assets**—many diagnostic apps use **generic** car imagery and **avoid** OEM logos.

**Rule of thumb:** If you’re unsure, open **Set Up Content Rights** and answer **yes/no** per screen; use **short, factual** explanations where there’s a free-text box (“We use licensed APIs and our own UI; no third-party entertainment content”).

---

### 3. Age ratings (Edit → questionnaire) — clears **“Unrated”**

1. Open **App Information → Age Ratings → Edit** (or the dedicated **Age Rating** flow).
2. Work through **every** section (violence, gambling, medical, unrestricted web, user-generated content, etc.).
3. For MintCheck as shipped today, answers are usually **minimal**:
   - **No** in-app chat / **no** unmoderated UGC → say **no** to user-generated content unless you ship forums.
   - **No** gambling, drugs, profanity features → **no** in those categories.
   - **Web content:** if the app only opens **your** support/marketing URLs in Safari/WebKit, answer per Apple’s definitions (often “none” or “infrequent” depending on wording).
4. **Save**. It can take **hours to a day** for “Unrated” to disappear on device purchase sheets after metadata propagates.

*If Apple adds new questions later, re-open **Edit** and complete any new required items.*

---

### 4. App encryption / export compliance

When you submit a build, Apple asks whether your app uses encryption.

**Typical MintCheck answers:**

- The app uses **HTTPS/TLS** (API calls, Stripe, Supabase) like almost every app → this is **standard encryption**.
- You are usually **exempt** from filing a separate CCATS document under **EAR** if you only use **Apple’s** APIs and **standard** HTTPS—Apple’s flow will offer something like **“App uses standard encryption only”** or **exemption**—choose what matches your implementation.
- **Upload encryption docs** only if Apple’s questions say your scenario **requires** it (uncommon for a normal consumer app using HTTPS).

*If you add custom crypto, VPN tunnels, or non-standard TLS, re-read the questions with your engineer.*

**Longer guide:** See **[APP_STORE_ENCRYPTION.md](./APP_STORE_ENCRYPTION.md)** (what counts as encryption, exemptions, when to upload docs, official links).

---

### 5. Digital Services Act (DSA) — Trader status (EU)

If you distribute in the **EU** and Apple prompts for **trader** details:

- **Legal entity:** **MintCheck LLC** (or your registered name).
- **Address / contact:** match what’s on your **business registration** and **support** page.
- Complete **Edit** on any **DSA** / **trader** card until there are **no** warnings.

This is **not** optional for many EU storefronts once Apple requires it.

---

### 6. App Store version **1.0** (left sidebar — separate from App Information)

On **1.0 Prepare for Submission**, complete **all** of these before **Submit for Review**:

| Item | Notes |
|------|--------|
| **Screenshots** | Required sizes for your devices; use real UI. |
| **App preview** (optional) | Short video if you have one. |
| **Description / keywords / promo** | Use sections above in this doc. |
| **Support URL** | Must work (e.g. mintcheckapp.com). |
| **Privacy Policy URL** | Must work; linked in app Settings too. |
| **Build** | Select the uploaded build. |
| **Sign-in** | If app requires login, provide a **demo account** + password in **App Review Information**. |
| **Notes** | Paste/adapt the **App Review notes** template from this doc. |
| **In-App Purchases** | Attach **One-Time Scan** (and any other IAP) to **this version** (required for first IAP). |

---

### 7. Optional — only if they apply

| Item | When to bother |
|------|----------------|
| **Age Suitability URL** | Only if **Apple or a specific country** asks for a URL in a message or rejection. |
| **Vietnam game license** | Only if the app is a **game** in Vietnam (MintCheck is **not** a game—skip). |
| **App Store Server Notifications** (Production / Sandbox URLs) | Useful if **your server** must receive Apple’s **subscription** / IAP lifecycle events. For **Stripe** products you use **Stripe webhooks**; for **Apple consumable IAP** you already verify via **Supabase Edge Function**—you don’t need Apple’s server notification URLs **unless** you’re building server-side handling for **App Store Server Notifications v2**. Safe to **skip** until you implement that. |
| **App-specific shared secret** | Legacy **receipt verification** for **auto-renewable subscriptions**. For **StoreKit 2** + **consumable** one-time scan, you typically **don’t** need this. **Skip** unless Apple or your backend doc says otherwise. |

---

### 8. Subtitle / category (short recap)

- **Subtitle:** use the table at the top of this doc.
- **Primary category:** **Utilities** (recommended).
- **Secondary:** **Shopping** or **Lifestyle** if you want one.

---

*Generated for MintCheck — edit before submission. Not legal advice.*
