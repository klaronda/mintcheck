# MintCheck – Internal TestFlight Process

Use this when you’re ready to put a build in the hands of internal testers (your team / Apple Developer account members). Internal testing does **not** require Beta App Review.

---

## Prerequisites

- **Apple Developer account** (paid) – required for TestFlight and real-device OBD/entitlements
- **App Store Connect** access for the MintCheck app (Account Holder, Admin, App Manager, Developer, or Marketing)
- **Xcode** with the MintCheck project open
- Optional: run through [QA_CHECKLIST.md](./QA_CHECKLIST.md) (sections 1–7 at least) before uploading

---

## Step 1: Prepare the build in Xcode

1. Open **MintCheck.xcodeproj** in Xcode.
2. Select the **MintCheck** scheme and choose **Any iOS Device (arm64)** as the run destination (not a simulator).
3. Confirm **Signing & Capabilities** for the MintCheck target:
   - Team set to your Apple Developer team
   - Capabilities you use (e.g. **Associated Domains** for universal links, **Access WiFi Information** if needed) are enabled and configured.
4. Bump the **build number** (and optionally version) so this build is distinct:
   - In the project navigator, select the **MintCheck** target → **General** tab.
   - Increase **Build** (e.g. `1` → `2`). Keep **Version** as-is unless you’re doing a version release.
5. **Product → Archive**.
   - Wait for the archive to finish. If it fails, fix signing or build errors and try again.

---

## Step 2: Upload to App Store Connect

1. When the archive completes, the **Organizer** window should open (or open it via **Window → Organizer**).
2. Select the **Archives** tab and the archive you just created.
3. Click **Distribute App**.
4. Choose **App Store Connect** → **Next**.
5. Choose **Upload** → **Next**.
6. Leave defaults (e.g. upload symbols, manage version and build number) and continue through the options.
7. Select the correct **destination** (team / distribution certificate / provisioning) and click **Upload**.
8. Wait for the upload to complete. You’ll see a success message when it’s done.

---

## Step 3: Wait for processing

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → your app **MintCheck** → **TestFlight** tab.
2. The new build will appear under **iOS** with a yellow “Processing” state. This usually takes **5–30 minutes** (sometimes longer).
3. When processing finishes, the build will show a green checkmark and become available for testing. You may get an email when it’s ready.

---

## Step 4: Add internal testers (if not already added)

1. In App Store Connect → **TestFlight** → **Internal Testing**.
2. **Internal testers** are people with one of these roles on your App Store Connect team: Account Holder, Admin, App Manager, Developer, Marketing (up to 100).
3. If needed, add testers:
   - **Users and Access** (in the main App Store Connect menu) → invite users and assign a role that includes TestFlight internal testing, **or**
   - Under **Internal Testing**, create or use a group and add testers by email (they must already be in your team).
4. Assign the **new build** to the internal testing group:
   - Under **Internal Testing**, select the group.
   - Click **+** or **Add Build** and choose the build you just uploaded.
   - Internal testers in that group will get the build automatically (no Beta App Review).

---

## Step 5: Install and test

1. **Testers** install the **TestFlight** app from the App Store on their iPhone.
2. They sign in with their **Apple ID** that’s tied to your App Store Connect team (the one you invited).
3. They open TestFlight and accept the invite or see **MintCheck** under Internal Testing; they tap **Install** for the build you assigned.
4. Run through the flows that matter for this build (e.g. auth, scan flow, OBD on a real device, results, share, settings). Use [QA_CHECKLIST.md](./QA_CHECKLIST.md) as needed.

---

## Step 6: Iterate

- Fix issues, then repeat from **Step 1** (bump build number, Archive, Upload, wait for processing, assign new build to internal testers).
- Internal testers can switch to the latest build from the TestFlight app.

---

## Quick reference

| Step | Where | Action |
|------|--------|--------|
| 1 | Xcode | Any iOS Device → bump Build → Product → Archive |
| 2 | Xcode Organizer | Distribute App → App Store Connect → Upload |
| 3 | App Store Connect → TestFlight | Wait for build “Processing” to finish |
| 4 | App Store Connect → Internal Testing | Assign build to internal group |
| 5 | Testers’ iPhones | TestFlight app → Install MintCheck build |

---

## Notes

- **Internal** testers do **not** go through Beta App Review; they get builds as soon as processing is done.
- **Password reset emails:** The `send-password-reset` Edge Function requires Supabase secrets to be set: `RESEND_API_KEY` (required) and optionally `RESEND_FROM_EMAIL`. Without `RESEND_API_KEY`, forgot-password requests succeed but no email is sent. See `supabase/functions/README.md` for details.
- **External** testers (if you add them later) require Beta App Review for the first build per group.
- TestFlight builds typically **expire** after 90 days; plan new builds before expiry.
- For OBD, deep links, and real device behavior, test on a **physical device**; see [QA_CHECKLIST.md](./QA_CHECKLIST.md) and [DEVELOPER_HANDOFF.md](./DEVELOPER_HANDOFF.md).
- If upload or signing fails, check Xcode’s **Report navigator** and App Store Connect **Activity** for the app for details.
