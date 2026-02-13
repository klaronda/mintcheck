# Push MintCheck to TestFlight (Internal)

## Option A: Use the archive we just built (fastest)

1. **Open the archive in Xcode**
   - Open **Xcode**
   - Menu: **Window → Organizer** (or `Cmd+Shift+Option+O`)
   - In the left sidebar, select **Archives**
   - If you see **MintCheck** with today’s date, select it and go to step 3  
   - If you don’t see it: in Finder go to  
     `Cursor/mintcheck/MintCheck/build/MintCheck.xcarchive`  
     and **double‑click** the `.xcarchive` file to open it in Organizer

2. **Upload to App Store Connect**
   - With the archive selected, click **Distribute App**
   - Choose **App Store Connect** → **Next**
   - Choose **Upload** → **Next**
   - Leave options as default (e.g. upload symbols, manage version/build) → **Next**
   - Select your **team** and **distribution certificate** (Xcode may create/fetch profiles) → **Next**
   - Click **Upload**
   - When it finishes, the build will appear in [App Store Connect](https://appstoreconnect.apple.com) under your app → **TestFlight** (processing can take a few minutes).

3. **Enable for internal testing**
   - In App Store Connect: **My Apps → MintCheck → TestFlight**
   - Under **Internal Testing**, add or select your internal group
   - Click **+** (or the build) and select the build you just uploaded
   - Internal testers get the build automatically (they may need to accept the email invite).

---

## Option B: Archive again from Xcode (if you prefer)

1. Open **MintCheck.xcodeproj** in Xcode (from `Cursor/mintcheck/MintCheck/`).
2. In the toolbar, set the run destination to **Any iOS Device (arm64)**.
3. Menu: **Product → Archive**.
4. When Organizer opens, select the new **MintCheck** archive.
5. Click **Distribute App** and follow the same steps as in Option A (App Store Connect → Upload, then enable the build in TestFlight for Internal Testing).

---

## If you see “No profiles for com.mintcheckapp.MintCheck”

- In Xcode: **Settings → Accounts** → select your Apple ID → **Download Manual Profiles**.
- Or: **Xcode → Settings → Accounts → [Your Apple ID] → Manage Certificates** and ensure you have an **Apple Distribution** certificate.
- In [developer.apple.com](https://developer.apple.com): ensure the app **MintCheck** (bundle ID `com.mintcheckapp.MintCheck`) exists in your account and that you have an App Store distribution provisioning profile for it. Then in Xcode run **Product → Clean Build Folder** and try archiving again.

---

## Build location

- Archive we built: **`mintcheck/MintCheck/build/MintCheck.xcarchive`**
