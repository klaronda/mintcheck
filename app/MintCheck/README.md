# MintCheck iOS App

A SwiftUI iOS app for checking used vehicle health via OBD-II diagnostics.

## Requirements

- **macOS** 13.5 or later
- **Xcode** 15.0 or later
- **iOS** 16.0+ deployment target
- An OBD-II WiFi adapter (for actual vehicle scanning)

## Setup Instructions

### 1. Install Xcode

1. Open the **Mac App Store**
2. Search for "Xcode"
3. Click "Get" and wait for the download (~12GB)
4. Open Xcode and accept the license agreement
5. Wait for additional components to install

### 2. Create the Xcode Project

Since we've created all the source files, you need to create a new Xcode project and add these files:

1. Open Xcode
2. Select **Create New Project**
3. Choose **iOS > App**
4. Configure:
   - Product Name: `MintCheck`
   - Team: Your Apple Developer account (or "None" for simulator only)
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck "Include Tests" for now
5. Click **Next** and save in `/Users/kevoo/Cursor/mintcheck/app/`

### 3. Add Swift Package Dependencies

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter: `https://github.com/supabase-community/supabase-swift.git`
3. Select version: `2.0.0` or later
4. Click **Add Package**
5. Select the `Supabase` library and add to your target

### 4. Add Source Files

1. In Xcode's Project Navigator, right-click on the `MintCheck` folder
2. Select **Add Files to "MintCheck"**
3. Navigate to `/Users/kevoo/Cursor/mintcheck/app/MintCheck/MintCheck/`
4. Select all folders and files:
   - `Config/`
   - `Models/`
   - `Services/`
   - `DesignSystem/`
   - `Views/`
   - `MintCheckApp.swift`
   - `ContentView.swift`
5. Make sure **"Copy items if needed"** is unchecked (files are already in place)
6. Make sure **"Create groups"** is selected
7. Click **Add**

### 5. Add Image Assets

You'll need to add these images to your asset catalog:

1. Open `Assets.xcassets` in Xcode
2. Add the following images:
   - `hero-car` - Hero image for home screen (use a car dashboard photo)
   - `logo-white` - MintCheck logo (white version for dark backgrounds)
   - `logo-mint` - MintCheck logo (mint/green version for light backgrounds)
   - `obd-port` - OBD-II port diagram image

For now, you can use placeholder images or the ones from the React UI assets:
`/Users/kevoo/Cursor/mintcheck/app/MintCheck_UX-UI/src/assets/`

### 6. Configure Info.plist

Add these entries for WiFi/Bluetooth permissions:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>MintCheck needs local network access to communicate with your OBD-II scanner.</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>MintCheck needs Bluetooth access to connect to your OBD-II scanner.</string>

<key>UIRequiresPersistentWiFi</key>
<true/>
```

### 7. Build and Run

1. Select a simulator (e.g., iPhone 15 Pro)
2. Press **Cmd + R** or click the Play button
3. The app should build and launch in the simulator

## Project Structure

```
MintCheck/
├── MintCheckApp.swift          # App entry point
├── ContentView.swift           # Navigation controller
├── Config/
│   └── SupabaseConfig.swift    # Supabase client setup
├── Models/
│   ├── User.swift              # User profile model
│   ├── Vehicle.swift           # Vehicle info model
│   ├── ScanResult.swift        # Scan results model
│   ├── QuickCheck.swift        # Visual inspection model
│   └── OBDScanResults.swift    # OBD data model
├── Services/
│   ├── AuthService.swift       # Supabase authentication
│   ├── ScanService.swift       # Scan history CRUD
│   ├── OBDService.swift        # WiFi OBD communication
│   └── VINDecoderService.swift # NHTSA VIN API
├── DesignSystem/
│   ├── Colors.swift            # Brand colors
│   ├── Typography.swift        # Font styles
│   └── Components/             # Reusable UI components
└── Views/
    ├── HomeView.swift
    ├── SignInView.swift
    ├── OnboardingView.swift
    ├── DashboardView.swift
    ├── VehicleBasicsView.swift
    ├── DeviceConnectionView.swift
    ├── ScanningView.swift
    ├── DisconnectReconnectView.swift
    ├── QuickHumanCheckView.swift
    ├── ResultsView.swift
    └── SystemDetailView.swift
```

## App Flow

1. **Home** → Welcome screen with "Start Vehicle Check" CTA
2. **Sign In** → Create account or sign in with email/password
3. **Onboarding** → 3-slide carousel (first time only)
4. **Dashboard** → Main hub with scan history
5. **Vehicle Basics** → Enter year/make/model/VIN
6. **Device Connection** → Select WiFi or Bluetooth scanner
7. **Scanning** → Live scan progress
8. **Disconnect** → Prompt to unplug scanner
9. **Quick Check** → Visual inspection questions
10. **Results** → Comprehensive report with recommendation

## Testing on Real Device

To test with an actual OBD-II scanner:

1. You need an Apple Developer account ($99/year) to run on a physical device
2. Connect your iPhone via USB
3. Select your device in Xcode
4. Build and run

### OBD-II Scanner Setup

1. Plug the OBD-II adapter into the vehicle's port (under dashboard)
2. Turn the vehicle's ignition to "ON" (don't need to start engine)
3. Connect your phone to the scanner's WiFi network (usually "OBD" or similar)
4. Return to the MintCheck app and start the scan

## Supabase Configuration

The app is configured to use your Supabase project:
- URL: `https://iawkgqbrxoctatfrjpli.supabase.co`
- Anon Key: Already configured in `SupabaseConfig.swift`

### Database Tables

The following tables have been created:
- `profiles` - User profiles (linked to auth.users)
- `vehicles` - Vehicle information
- `scans` - Scan results and history

## Troubleshooting

### Build Errors

1. **Missing Package**: Go to File > Packages > Reset Package Caches
2. **Signing Issues**: Go to project settings and select your team
3. **iOS Version**: Make sure deployment target is iOS 16.0+

### Runtime Issues

1. **Can't connect to scanner**: 
   - Check you're connected to the scanner's WiFi
   - Verify the scanner is powered on
   - Try the default IP: 192.168.0.10:35000

2. **Auth not working**:
   - Check Supabase project is active
   - Verify the anon key is correct

## Next Steps

- Add app icons (1024x1024 for App Store)
- Add launch screen
- Test on multiple devices
- Submit to App Store (requires Apple Developer account)
