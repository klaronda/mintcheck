# App Encryption & export compliance (App Store)

This document explains what Apple means by **“encryption”** on the App Store, what you usually answer when submitting **MintCheck**, and when you must **upload extra documentation**. It is **not legal advice**—if your situation is unusual (custom crypto, VPN, classified markets), consult a lawyer or compliance specialist.

---

## 1. Why Apple asks

The U.S. **Export Administration Regulations (EAR)** treat certain **encryption software** as controlled. Apple collects your answers so your app can be distributed in compliance with applicable rules. Most consumer apps that only use **standard HTTPS** fall under **exemptions** and need **no** separate CCATS filing—but you must still answer the questions **accurately** each time you submit a build.

---

## 2. What counts as “encryption” in your app

For MintCheck, encryption usually includes:

| Mechanism | Typical use in MintCheck | Notes |
|-----------|---------------------------|--------|
| **HTTPS / TLS** | Calls to Supabase, Stripe Checkout, Resend, NHTSA, etc. | **Standard** encryption provided by iOS (`URLSession`, etc.). |
| **StoreKit 2** | Apple’s purchase APIs | Handled by **Apple**; you still declare at app level per questionnaire. |
| **Keychain** | Storing tokens or credentials (if you use it) | Platform API; still “encryption” in a broad sense. |

If you **only** use Apple’s APIs and **industry-standard** TLS for network traffic, you are in the **most common** bucket for indie apps.

---

## 3. Where you answer in the workflow

- **App Store Connect:** When uploading a build or at **submit for review**, you’ll see prompts about **encryption / export compliance**.
- **Xcode:** Older flows sometimes asked during **archive**; today much of this is in **App Store Connect** when you submit.

Exact UI labels change; look for **“Export Compliance”**, **“App uses encryption”**, or **ITSAppUsesNonExemptEncryption** (Info.plist key).

---

## 4. Info.plist key (optional technical note)

Apple may set or ask about:

- **`ITSAppUsesNonExemptEncryption`** — If your app **does not** use **non-exempt** encryption (or only uses exempt categories), this is often **`NO`** in many setups—but **only** if that matches your actual implementation.

**Do not** copy a value from the internet without matching it to **your** app. If unsure, use App Store Connect’s questionnaire; it often drives the correct plist behavior.

---

## 5. Typical answers for a standard HTTPS-only app

When the questionnaire asks whether the app uses encryption:

1. **Yes** — the app uses encryption (HTTPS is encryption).

Then Apple often asks **what kind**:

- You use encryption **only** for:
  - Authentication over HTTPS, or
  - Standard TLS to your backend, or
  - Features covered by **exemption** (e.g. **mass market** consumer app using only **standard** TLS).

Many flows then offer:

- **“Your app qualifies for an exemption”** or  
- **“Uses only standard encryption”** (wording varies)

**Upload documentation** if and only if:

- The flow says your answers **require** a **CCATS** / **encryption registration**, or  
- You use **non-standard** or **custom** cryptography, **proprietary** algorithms, or **VPN**-style tunneling beyond normal HTTPS.

For **MintCheck** as described in this repo (Supabase + Stripe + standard APIs), **uploading documents** is **usually not** required.

---

## 6. When you must be more careful (not typical MintCheck)

You may need **legal/engineering review** if:

- You ship **custom** crypto libraries (not just HTTPS).
- You implement **end-to-end encryption** for user content in a **non-standard** way.
- You distribute in **specific countries** with extra registration rules (Apple’s UI will ask).
- You use **hardware** or **SDKs** marketed for **secure communications** beyond normal TLS.

---

## 7. What to tell Apple Review (if asked)

Short, honest examples:

- *“The app uses HTTPS for API calls to our backend and third-party services (Stripe, Supabase, etc.) using iOS standard networking APIs.”*
- *“No custom encryption algorithms; we use TLS as provided by the operating system.”*

---

## 8. Official Apple references (bookmark these)

- **Export compliance overview:** [Apple Developer — Complying with Encryption Export Regulations](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations) (URL may change; search Apple Developer for “encryption export compliance”).

- **App Store Connect Help:** Search for **“export compliance”** or **“encryption”** in [App Store Connect Help](https://support.apple.com/apps).

- **EAR / classification:** U.S. **BIS** (Bureau of Industry and Security) publishes EAR; Apple’s questionnaire is designed to route you to the right declaration.

---

## 9. Checklist before you submit

- [ ] You answered the **latest** encryption questions for **this** build (not an old copy-paste from another app).
- [ ] Your answers match **HTTPS + standard APIs** only (if that’s true).
- [ ] You uploaded **extra documents** only if the portal **required** them after your answers.
- [ ] If you added **new** networking (custom SDK, VPN, new crypto), **re-review** the questionnaire.

---

## 10. Relation to MintCheck code

- **Supabase Swift client**, **Stripe Checkout in Safari**, **Edge Functions** over HTTPS: all **TLS**.
- **StoreKit 2** IAP: Apple’s stack; follow the questionnaire’s guidance for **in-app purchase** apps.
- **No** custom cipher implementations are required for normal operation of this app as documented in the repo.

---

*Last updated for MintCheck internal use. Revise when Apple updates export compliance flows or when you change how data is encrypted in transit or at rest.*
