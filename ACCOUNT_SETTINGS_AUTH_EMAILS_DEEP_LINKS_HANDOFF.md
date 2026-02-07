# Account Settings + Auth Emails + Deep Links - Deployment Handoff

## Overview

This handoff covers the **web fallback pages** and **AASA file** that were implemented as part of the Account Settings + Auth Emails + Deep Links MVP. The iOS app changes are complete and ready for deployment separately.

## ⚠️ Important: Apple Developer Account Requirement

**The iOS app requires a PAID Apple Developer account ($99/year) for the following features:**
- **Associated Domains** - Required for Universal Links (auth email deep links)
- **Hotspot Configuration** - Required for OBD-II WiFi scanner connections
- **Wi-Fi Information** - Required for OBD-II WiFi scanner connections

**Current Status**: These capabilities are **commented out** in `MintCheck.entitlements` to allow builds with a personal/free developer account. **You must uncomment them and upgrade to a paid account before:**
- Testing Universal Links (auth email deep links)
- Using WiFi OBD-II scanner connections
- Submitting to App Store

See `MintCheck/MintCheck.entitlements` for details.

## What Was Implemented

### 1. Web Fallback Pages (Auth Deep Links)

**Purpose**: When users click email confirmation or password reset links, if the app isn't installed or Universal Links fail, they land on these web pages that attempt to open the app via custom scheme fallback.

**Files Created**:
- `website/src/app/pages/AuthConfirm.tsx` - Handles `/auth/confirm?token=...&type=...`
- `website/src/app/pages/AuthReset.tsx` - Handles `/auth/reset?token=...`

**Files Modified**:
- `website/src/app/routes.tsx` - Added routes for `/auth/confirm` and `/auth/reset` (outside Layout for minimal pages)

**Behavior**:
- Shows "Opening MintCheck…" message
- Attempts to open app via `mintcheck://auth/confirm?...` or `mintcheck://auth/reset?...`
- Provides "Download the app" button (links to `/download`)
- Provides "Copy link" button for manual sharing
- Handles missing/invalid token gracefully

### 2. Apple App Site Association (AASA) File

**Purpose**: Enables iOS Universal Links so `https://mintcheckapp.com/auth/confirm` and `/auth/reset` URLs automatically open the MintCheck app when installed.

**File Created**:
- `website/public/.well-known/apple-app-site-association`

**File Modified**:
- `website/vercel.json` - Added headers config to serve AASA with correct `Content-Type: application/json` and updated rewrite to exclude `.well-known` paths

**AASA Configuration**:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "H4XTMGZ8C6.com.mintcheckapp.MintCheck",
        "paths": [
          "/auth/confirm*",
          "/auth/reset*"
        ]
      }
    ]
  }
}
```

## Deployment Checklist

### Pre-Deployment

- [x] AASA file created at `public/.well-known/apple-app-site-association`
- [x] Vercel config updated with headers for AASA
- [x] Auth fallback pages created (`AuthConfirm.tsx`, `AuthReset.tsx`)
- [x] Routes added to `routes.tsx` (outside Layout)

### Deployment Steps

1. **Commit changes to GitHub**:
   ```bash
   git add website/src/app/pages/AuthConfirm.tsx
   git add website/src/app/pages/AuthReset.tsx
   git add website/src/app/routes.tsx
   git add website/public/.well-known/apple-app-site-association
   git add website/vercel.json
   git commit -m "Add auth deep link fallback pages and AASA file for Universal Links"
   git push origin main
   ```

2. **Vercel will auto-deploy** (if connected to GitHub)

3. **Verify AASA file is accessible**:
   ```bash
   curl -I https://mintcheckapp.com/.well-known/apple-app-site-association
   ```
   - Should return `Content-Type: application/json`
   - Should NOT return `Content-Type: text/html` (if it does, the rewrite is catching it)

4. **Verify AASA file content**:
   ```bash
   curl https://mintcheckapp.com/.well-known/apple-app-site-association
   ```
   - Should return valid JSON matching the file in `public/.well-known/`

5. **Test fallback pages**:
   - Visit `https://mintcheckapp.com/auth/confirm?token=test&type=signup`
   - Should show "Opening MintCheck…" page (not 404)
   - Visit `https://mintcheckapp.com/auth/reset?token=test`
   - Should show "Opening MintCheck…" page (not 404)

## Important Notes

### AASA File Requirements

- **Must be served at**: `https://mintcheckapp.com/.well-known/apple-app-site-association`
- **Must have Content-Type**: `application/json` (NOT `text/html`)
- **Must NOT redirect** (301/302 will break Universal Links)
- **Must be accessible without authentication**
- **File must have NO file extension** (not `.json`)

### Universal Links Testing

After deployment, Universal Links will work when:
1. App is installed on iOS device
2. User clicks link in Safari (not other browsers)
3. AASA file is valid and accessible
4. Domain matches exactly: `mintcheckapp.com` (no `www.`)

### Custom Scheme Fallback

If Universal Links fail, the web pages attempt `mintcheck://auth/confirm?...` as fallback. This requires:
- URL scheme `mintcheck://` configured in iOS app (already done in entitlements/Info.plist)
- App installed on device

### Edge Function Integration

The web pages receive tokens from these Edge Functions:
- `supabase/functions/send-confirmation-email/index.ts` - Sends confirmation emails with `https://mintcheckapp.com/auth/confirm?token=...&type=signup|email_change`
- `supabase/functions/send-password-reset/index.ts` - Sends reset emails with `https://mintcheckapp.com/auth/reset?token=...`

These Edge Functions are already implemented and working.

## Troubleshooting

### AASA returns 404
- Check file exists at `public/.well-known/apple-app-site-association`
- Check Vercel rewrites aren't catching `.well-known` paths
- Verify file was committed and deployed

### AASA returns HTML instead of JSON
- Check `vercel.json` headers config is correct
- Verify rewrite pattern excludes `.well-known`
- May need to clear Vercel cache

### Universal Links not working
- Verify AASA file is accessible and valid JSON
- Check app's Associated Domains capability includes `applinks:mintcheckapp.com`
- Test in Safari (not Chrome/Firefox)
- Universal Links only work on installed apps
- iOS caches AASA file - may take a few minutes after deployment

### Fallback pages show 404
- Check routes are added to `routes.tsx` outside the Layout wrapper
- Verify pages exist at correct paths
- Check Vercel deployment logs

## Related Files (iOS App - Already Complete)

These were implemented in the iOS app and are ready for deployment separately:

- `MintCheck/MintCheck.entitlements` - Associated Domains configured
- `MintCheck/MintCheck.xcodeproj/project.pbxproj` - CODE_SIGN_ENTITLEMENTS set
- Deep link handling in `DeepLinkService.swift`
- `.onOpenURL` handler in `ContentView.swift`
- `ResetPasswordView.swift`, `EmailConfirmationView.swift`
- `AccountInfoView.swift`, `ChangeEmailView.swift`, `ChangePasswordView.swift`
- `SettingsView.swift`, `DashboardView.swift` - Email confirmation banners

## Summary

**Ready to Deploy**:
- ✅ Web fallback pages (`AuthConfirm.tsx`, `AuthReset.tsx`)
- ✅ Routes configuration
- ✅ AASA file for Universal Links
- ✅ Vercel config for proper AASA serving

**Action Required**:
1. Commit and push to GitHub
2. Verify AASA file is accessible after deployment
3. Test fallback pages work
4. Test Universal Links on iOS device (after app is deployed)

All code is complete and ready for production deployment.
