# MintCheck - SwiftUI Conversion Guide

## App Overview
MintCheck is a mobile app that helps users check vehicle health using OBD-II diagnostics. The app guides users through a comprehensive vehicle inspection process with a premium, consumer-tech feel.

---

## Design System

### Colors
```swift
// Primary Brand Color
let mintGreen = Color(hex: "#3EB489")
let mintGreenHover = Color(hex: "#2D9970")

// Backgrounds
let deepBackground = Color(hex: "#F8F8F7")      // Main screen background
let softBackground = Color(hex: "#FCFCFB")      // Tips/info cards
let cardBackground = Color.white                // Main content cards

// Text Colors
let textPrimary = Color(hex: "#1A1A1A")        // Near-black for main text
let textSecondary = Color(hex: "#666666")       // Gray for secondary text
let textMuted = Color(hex: "#999999")           // Muted for disabled states

// Borders
let borderColor = Color(hex: "#E5E5E5")         // Light gray borders

// Status Colors
let statusSafe = Color(hex: "#3EB489")          // Green - Safe to buy
let statusSafeBg = Color(hex: "#E6F4EE")        // Light green background
let statusCaution = Color(hex: "#E3B341")       // Yellow - Caution
let statusCautionBg = Color(hex: "#FFF9E6")     // Light yellow background
let statusDanger = Color(hex: "#C94A4A")        // Red - Not recommended
let statusDangerBg = Color(hex: "#FFE6E6")      // Light red background
let statusWarning = Color(hex: "#F59E0B")       // Orange - Repair estimates
```

### Typography
```swift
// Font Weights: 400 (regular), 600 (semibold)
// The app uses system fonts with specific weights

// Headings
let h1Size: CGFloat = 26              // Screen titles
let h2Size: CGFloat = 22              // Section titles (like "Safe to Buy")
let h3Size: CGFloat = 18              // Card headers
let h4Size: CGFloat = 17              // Subsection headers
let h5Size: CGFloat = 16              // Smaller section headers

// Body Text
let bodyLarge: CGFloat = 15           // Main body text, buttons
let bodyRegular: CGFloat = 14         // Secondary text, labels
let bodySmall: CGFloat = 13           // Fine print, disclaimers

// Note: Never override font sizes, weights, or line heights with custom values
// unless user specifically requests it. Use system defaults.
```

### Spacing & Layout
```swift
let borderRadius: CGFloat = 4         // Reduced border radius for premium feel
let buttonHeight: CGFloat = 48        // Standard button height (h-12)
let maxWidth: CGFloat = 448           // max-w-md for mobile forms (28rem = 448px)
let maxWidthWide: CGFloat = 672       // max-w-2xl for content (42rem = 672px)

// Padding
let padding2: CGFloat = 8             // p-2
let padding3: CGFloat = 12            // p-3
let padding4: CGFloat = 16            // p-4
let padding5: CGFloat = 20            // p-5
let padding6: CGFloat = 24            // p-6
let padding8: CGFloat = 32            // p-8
```

### Logo Assets
- **White Logo**: Used on dark backgrounds (mint green buttons, headers)
- **Mint/Green Logo**: Used on white/light backgrounds
- Both logos should be SVG or high-resolution PNG with transparency

---

## App Flow & Navigation

### Navigation Structure
```
1. Home Screen (first launch)
2. Onboarding Screen (3 slides, first-time only)
3. Dashboard (main hub after onboarding)
4. Vehicle Basics Screen (enter Make/Model/Year/VIN)
5. Quick Human Check Screen (visual inspection questions)
6. Device Connection Screen (OBD-II device pairing)
7. Scanning Screen (active scan with progress)
8. Results Screen (comprehensive report)
```

### Screen Transition Flow
```
HomeScreen → OnboardingScreen → DashboardScreen
                                      ↓
                              VehicleBasicsScreen
                                      ↓
                            QuickHumanCheckScreen
                                      ↓
                          DeviceConnectionScreen
                                      ↓
                              ScanningScreen
                                      ↓
                              ResultsScreen → Dashboard
```

---

## Screen Details

### 1. Home Screen (`home-screen.tsx`)
**Purpose**: Welcome screen with app branding and main CTA

**Layout**:
- Full screen with `deepBackground` (#F8F8F7)
- Centered logo (mint/green version)
- Large "MintCheck" heading (26px, weight 600)
- Tagline: "Know before you buy" (15px, #666666)
- Primary button: "Get Started" (mint green, full width, 48px height)

**Key Features**:
- Simple, clean single-screen layout
- One primary action button
- Logo centered vertically and horizontally

---

### 2. Onboarding Screen (`onboarding-screen.tsx`)
**Purpose**: 3-slide carousel explaining app features

**Slides**:
1. **Scan Vehicle Systems**
   - Icon: Activity monitor icon
   - Description: "Connect to your car's computer to check engine health, emissions, and more"

2. **Get Instant Analysis**
   - Icon: Checkmark badge icon
   - Description: "Receive a detailed report on the vehicle's condition in minutes"

3. **Make Smart Decisions**
   - Icon: Light bulb icon
   - Description: "Know what you're buying with confidence and transparency"

**Layout**:
- White background
- Icon container: 64px × 64px, soft green background (#E6F4EE), mint green icon
- Heading: 22px, weight 600
- Body text: 15px, #666666, centered
- Progress dots at bottom (mint green when active, light gray when inactive)
- "Next" button or "Get Started" on final slide
- "Skip" button (text only, #666666) on first two slides

**Navigation**:
- Swipe gesture to move between slides
- Auto-advance option (not required)
- Skip button available on slides 1-2
- Final slide shows "Get Started" instead of "Next"

---

### 3. Dashboard Screen (`dashboard-screen.tsx`)
**Purpose**: Main hub after onboarding, shows scan history and starts new scans

**Layout**:
- Sticky header with white background, logo (mint version), border-bottom
- Main content area: deepBackground (#F8F8F7)
- Welcome message with user name (if available)
- "Start New Scan" button (mint green, full width)
- Recent scans section (if any exist)

**Recent Scan Card** (if scans exist):
- White background, border
- Vehicle info: "2018 Honda Accord"
- Status badge: "Safe to Buy" (green), "Caution" (yellow), or "Not Recommended" (red)
- Date scanned
- Tap to view full report

**Empty State** (no scans):
- Icon illustration
- "No scans yet" heading
- "Start your first vehicle scan" description

**Key Features**:
- Persistent header across app
- Clear primary action
- Scan history with status indicators

---

### 4. Vehicle Basics Screen (`vehicle-basics-screen.tsx`)
**Purpose**: Collect vehicle information (Make, Model, Year, VIN)

**Layout**:
- Sticky header: "Vehicle Details"
- Progress indicator: "Step 1 of 3"
- Form fields (vertically stacked):
  1. **Year** - Picker or text input (1990-2026)
  2. **Make** - Text input (e.g., "Honda", "Toyota")
  3. **Model** - Text input (e.g., "Accord", "Camry")
  4. **VIN** - Text input with info icon
     - Optional field
     - Format: 17 characters alphanumeric
     - Info tooltip: "The VIN helps us identify exact vehicle specs. Found on dashboard or driver's door."

**VIN Info Section** (soft background card):
- Light bulb icon
- Heading: "Why enter a VIN?"
- Description: "The VIN helps us decode exact trim, engine, and specs. You can skip this and enter details manually."

**Sticky Bottom**:
- White background
- "Continue" button (mint green, disabled until Year/Make/Model filled)
- "Back" text button (#666666)

**Validation**:
- Year: 1990-2026
- Make: Required, min 2 characters
- Model: Required, min 2 characters
- VIN: Optional, but if entered must be 17 characters

---

### 5. Quick Human Check Screen (`quick-human-check-screen.tsx`)
**Purpose**: Visual inspection questions before OBD scan

**Layout**:
- Sticky header: "Quick Visual Check"
- Progress indicator: "Step 2 of 3"
- Scrollable form with 7 questions
- Sticky bottom: Continue button + Skip option

**Questions** (all use button selection):

1. **Dashboard warning lights on?**
   - Options: Yes / No
   - If "Yes" → Show warning light grid (see below)

2. **Warning Light Selection** (conditional, only if answered "Yes" above):
   - 3×3 grid layout (9 warning lights)
   - Types: Oil, Check Engine, Tire Pressure, Washer Fluid, ABS, Radiator, Battery, AirBag, Other
   - Multi-select allowed
   - Each has icon + label
   - Selected state: mint green background, white text
   - Unselected: white background, border

3. **Any fluid leaks under the car?**
   - Options: Yes / No / Not Sure

4. **How would you rate the interior condition?**
   - Options: Good / Worn / Poor
   - 3-column grid

5. **What is the tire tread condition?**
   - Options: Good / Worn / Bare
   - 3-column grid

6. **Any unusual engine sounds or vibrations?**
   - Options: Yes / No / Not Sure
   - 2-column grid

7. **Any visible body damage?**
   - Options: Yes / No
   - 2-column grid

**Warning Light Icons** (Lucide React icons used):
- Oil: Droplet
- Check Engine: AlertTriangle
- Tire Pressure: Wind
- Washer Fluid: Droplets
- ABS: Disc
- Radiator: Thermometer
- Battery: Battery
- AirBag: Shield
- Other: MoreHorizontal

**Button States**:
- Selected: mint green background (#3EB489), white text
- Unselected: white background, border (#E5E5E5), dark text
- All buttons: 44px height minimum, border-radius 4px

**Bottom Actions**:
- White background (not deepBackground)
- "Continue" button (enabled only when all questions answered)
- "Skip this step" text button

---

### 6. Device Connection Screen (`device-connection-screen.tsx`)
**Purpose**: Connect to OBD-II device via Bluetooth

**Layout**:
- Sticky header: "Connect Device"
- Progress indicator: "Step 3 of 3"
- Main content: centered vertically

**Connection States**:

**State 1: Searching**
- Bluetooth icon (pulsing animation)
- "Searching for devices..." heading
- "Make sure your OBD-II adapter is plugged in and ignition is on"
- Spinner/loading indicator

**State 2: Device Found**
- List of available devices
- Each device card:
  - Device name (e.g., "OBD-II Scanner ABC123")
  - Signal strength indicator
  - "Connect" button

**State 3: Connecting**
- "Connecting to [Device Name]..."
- Progress indicator
- "Cancel" option

**State 4: Connected**
- Checkmark icon (mint green)
- "Connected to [Device Name]"
- "Continue to Scan" button (mint green)

**Info Card** (soft background):
- Icon: Info icon
- "Device Not Found?"
- Troubleshooting tips:
  - Check device is plugged into OBD port
  - Turn ignition to ON position
  - Ensure Bluetooth is enabled

**Bottom Actions**:
- "Continue" button (enabled when connected)
- "Back" text button

---

### 7. Scanning Screen (`scanning-screen.tsx`)
**Purpose**: Active scan with real-time progress

**Layout**:
- Full screen with centered content
- No back button (prevent interruption)

**Scan Stages** (show sequentially):

1. **Connecting to Vehicle** (0-15%)
   - Icon: Bluetooth/connection icon
   - "Establishing connection..."

2. **Reading Engine Data** (15-40%)
   - Icon: CPU/processor icon
   - "Analyzing engine systems..."

3. **Checking Emissions** (40-65%)
   - Icon: Wind/air icon
   - "Scanning emissions controls..."

4. **Analyzing Results** (65-100%)
   - Icon: Checkmark in circle
   - "Generating report..."

**Visual Elements**:
- Large circular progress indicator (mint green)
- Percentage: 72% (inside circle, 32px, weight 600)
- Current stage heading (18px, weight 600)
- Status message below (15px, #666666)

**Progress Bar** (linear, below circle):
- Track: light gray background
- Fill: mint green, animated
- 4px height, full width

**Info Card** (bottom, soft background):
- "This may take 2-3 minutes"
- "Keep the ignition on during the scan"

**Completion**:
- When 100%, auto-navigate to Results Screen
- Brief success message: "Scan complete!"

---

### 8. Results Screen (`results-screen.tsx`)
**Purpose**: Comprehensive vehicle scan report with recommendation

**Layout**:
- Sticky header with share button
- Scrollable content area
- Fixed bottom action button

**Header**:
- Title: "Vehicle Scan Report" (18px, weight 600)
- Subtitle: "2018 Honda Accord" (14px, #666666)
- Share button (top-right, icon only)

**Recommendation Badge** (first card):
- 2px border, colored background (light green/yellow/red)
- Large icon in colored square (48px × 48px)
- Status heading: "Safe to Buy" / "Proceed with Caution" / "Not Recommended"
- Summary paragraph explaining the recommendation

**Recommendation Types**:

1. **Safe to Buy** (Green)
   - Color: #3EB489
   - Background: #E6F4EE
   - Icon: CheckCircle2
   - Summary: "Based on the scan, this vehicle's engine and core systems appear to be in good condition. No major concerns were found."

2. **Proceed with Caution** (Yellow)
   - Color: #E3B341
   - Background: #FFF9E6
   - Icon: AlertCircle
   - Summary: "The scan found some items that need attention. Review the details below and consider having a mechanic inspect the vehicle before buying."

3. **Not Recommended** (Red)
   - Color: #C94A4A
   - Background: #FFE6E6
   - Icon: XCircle
   - Summary: "The scan found significant concerns with this vehicle's systems. We recommend looking at other options or getting a professional inspection before proceeding."

**Vehicle Details Card** (NEW):
- Heading: "Vehicle Details"
- Key-value pairs (left-aligned labels, right-aligned values):
  - VIN (if available, monospace font)
  - Year
  - Make
  - Model
  - Trim (if decoded from VIN)
  - Fuel Type (if decoded from VIN)
  - Engine (if decoded from VIN)
  - Transmission (if decoded from VIN)
  - Drivetrain (if decoded from VIN)

**VIN Disclaimer** (if VIN not decoded):
- Border-top divider
- Small gray text (13px, #666666)
- Message: "VIN could not be decoded. Details shown are based on user input."
  OR "VIN was not provided. Details shown are based on user input."

**What We Found Card**:
- Heading: "What We Found"
- Bulleted list with colored dots (matches recommendation color)
- 3-5 key findings based on scan results

**Examples**:
- Safe: "No trouble codes found", "Engine temperature normal", etc.
- Caution: "Some systems haven't completed self-checks yet", etc.
- Not Recommended: "Multiple engine trouble codes detected", etc.

**Price Context** (subsection in same card):
- Border-top divider
- Heading: "Price Context"
- Price range: "$15,000 - $17,000" (bold)
- Context note based on recommendation
- Repair estimate (if applicable, orange warning color)

**System Details Card** (Expandable Accordion):
- Heading: "System Details"
- 4 expandable sections:

1. **Engine**
   - Status dot (green or yellow)
   - Status text: "Good" or "Needs Attention"
   - Expand icon (chevron)
   - When expanded:
     - Explanation paragraph
     - Bulleted details list

2. **Fuel System**
   - Same structure as Engine

3. **Emissions**
   - Same structure as Engine

4. **Electrical**
   - Same structure as Engine

**Expandable Interaction**:
- Collapsed: Show name, status, chevron-down
- Expanded: Show name, status, chevron-up, plus details area with light background
- Tap header to toggle
- Details background: #F8F8F7 (deepBackground)

**Important Note Card** (soft background):
- Background: #FCFCFB
- Text: "This check reviews the car's systems. Other inspections may be needed."
- 14px, #666666

**Bottom Action**:
- Fixed to bottom
- White background, border-top
- "Return to Dashboard" button (mint green)

---

## State Management

### Key Data Models

```swift
// Vehicle Information
struct VehicleInfo {
    var make: String
    var model: String
    var year: String
    var vin: String?
    var trim: String?
    var fuelType: String?
    var engine: String?
    var transmission: String?
    var drivetrain: String?
}

// Quick Check Data
struct QuickCheckData {
    var warningLights: Bool?
    var selectedWarningLights: [WarningLightType]
    var fluidLeaks: String?
    var interiorCondition: String?
    var tireCondition: String?
    var engineSounds: Bool?
    var bodyDamage: Bool?
}

enum WarningLightType: String, CaseIterable {
    case oil = "Oil"
    case checkEngine = "Check Engine"
    case tirePressure = "Tire Pressure"
    case washerFluid = "Washer Fluid"
    case abs = "ABS"
    case radiator = "Radiator"
    case battery = "Battery"
    case airbag = "AirBag"
    case other = "Other"
}

// Scan Results
struct ScanResults {
    var recommendation: RecommendationType
    var vinDecoded: Bool
    var keyFindings: [String]
    var priceRange: String
    var priceNote: String
    var repairEstimate: String?
    var systemDetails: [SystemDetail]
}

enum RecommendationType {
    case safe
    case caution
    case notRecommended
}

struct SystemDetail {
    var name: String
    var status: String
    var color: String
    var details: [String]
    var explanation: String
}
```

### User Preferences
```swift
// Store in UserDefaults
var hasCompletedOnboarding: Bool = false
var savedScans: [ScanResults] = []
```

---

## Component Patterns

### Button Styles

**Primary Button** (Mint Green):
```swift
// Background: #3EB489
// Hover/Active: #2D9970
// Text: White
// Height: 48px
// Border radius: 4px
// Font: 15px, weight 600
```

**Secondary Button** (White/Outlined):
```swift
// Background: White
// Border: #E5E5E5
// Text: #1A1A1A
// Height: 44px minimum
// Border radius: 4px
// Font: 15px, weight 600
```

**Selected Button** (Multi-select):
```swift
// Background: #3EB489
// Border: #3EB489
// Text: White
// Height: 44px minimum
```

**Disabled Button**:
```swift
// Background: #E5E5E5
// Text: #999999
// No hover state
```

**Text Button**:
```swift
// No background
// Text: #666666
// Font: 15px, weight 600
// No border
```

### Card Styles

**White Card**:
```swift
// Background: White
// Border: 1px solid #E5E5E5
// Border radius: 4px
// Padding: 24px
```

**Info Card** (Soft Background):
```swift
// Background: #FCFCFB
// Border: 1px solid #E5E5E5
// Border radius: 4px
// Padding: 16px
```

**Status Card** (Colored):
```swift
// Background: Status-specific light color
// Border: 2px solid status color
// Border radius: 4px
// Padding: 24px
```

### Input Fields
```swift
// Background: White
// Border: 1px solid #E5E5E5
// Border radius: 4px
// Padding: 12px
// Font: 15px
// Focus border: #3EB489
// Error border: #C94A4A
```

---

## Accessibility

### Color Contrast
All text meets WCAG AAA standards:
- Dark text (#1A1A1A) on white: 16.5:1
- Secondary text (#666666) on white: 5.74:1
- White text on mint green (#3EB489): 4.6:1 (AA Large)

### Touch Targets
- Minimum tap target: 44px × 44px
- Buttons: 48px height (exceeds minimum)
- Interactive elements have adequate spacing

### Screen Reader Support
- All images have descriptive alt text
- Buttons have clear labels
- Form fields have associated labels
- Status indicators have text equivalents

---

## Animations & Transitions

### Screen Transitions
- Standard push/pop navigation (slide from right)
- Modal presentations for dialogs (slide up from bottom)
- Duration: 300ms ease-in-out

### Button Interactions
- Tap: Scale down to 0.95, duration 100ms
- Color transitions: 200ms ease

### Progress Indicators
- Circular progress: Smooth arc animation
- Linear progress bar: Animated width change, duration matches scan stage
- Percentage updates: Number increments smoothly

### Loading States
- Spinner: Continuous rotation
- Pulse animation for connection state
- Skeleton screens for loading content

### Expandable Sections
- Chevron rotation: 200ms ease
- Content expand: Height animation, 300ms ease-out
- Background color fade: 200ms

---

## Special Considerations

### OBD-II Integration
The app needs to connect to Bluetooth OBD-II devices. Consider:
- CoreBluetooth framework for device discovery
- OBD-II protocol commands (Mode 01, Mode 03 for DTCs)
- Handle connection timeouts gracefully
- Parse OBD-II response data

### VIN Decoding
- Optional feature (can work without VIN)
- If VIN entered, attempt to decode vehicle specs
- Use VIN decoding API (NHTSA API or third-party)
- Fallback to manual entry if decode fails
- Show disclaimer when VIN not decoded

### Error Handling
- Device connection failures: Clear messaging with retry option
- Scan interruptions: Save partial progress if possible
- Invalid VIN: Non-blocking, allow continuation
- Network errors: Graceful degradation

### Data Persistence
- Save scan results locally (Core Data or UserDefaults)
- Cache vehicle information for quick re-scans
- Sync scan history across devices (optional, iCloud)

### Offline Capability
- Core scanning functionality should work offline
- VIN decoding may require network (show indicator)
- Price context may be cached or generic when offline

---

## Assets Required

### Logos
1. **MintCheck Logo (Mint/Green)** - For light backgrounds
   - SVG or PDF vector format
   - Transparent background
   - High resolution (3x scale for retina)

2. **MintCheck Logo (White)** - For dark backgrounds
   - SVG or PDF vector format
   - Transparent background
   - High resolution (3x scale for retina)

### Icons
Using SF Symbols (iOS native) for most icons. Map Lucide React icons to SF Symbols:

```swift
// Lucide → SF Symbol mapping
Activity → waveform.path.ecg
CheckCircle2 → checkmark.circle.fill
AlertCircle → exclamationmark.circle.fill
XCircle → xmark.circle.fill
Share2 → square.and.arrow.up
Home → house.fill
ChevronDown → chevron.down
ChevronUp → chevron.up
Droplet → drop.fill
AlertTriangle → exclamationmark.triangle.fill
Wind → wind
Droplets → drop.triangle.fill
Disc → circlebadge.fill
Thermometer → thermometer
Battery → battery.100
Shield → shield.fill
MoreHorizontal → ellipsis
Bluetooth → antenna.radiowaves.left.and.right
Info → info.circle
Lightbulb → lightbulb.fill
```

### Illustrations
Consider adding illustrations for:
- Empty state on Dashboard
- Onboarding slides (simple iconography works too)
- Connection troubleshooting

---

## Testing Checklist

### User Flow Testing
- [ ] Complete onboarding → Dashboard
- [ ] Start scan with valid vehicle info
- [ ] Start scan with VIN entry
- [ ] Start scan without VIN
- [ ] Complete quick check with all questions
- [ ] Skip quick check
- [ ] Connect to OBD-II device
- [ ] Handle device connection failure
- [ ] Complete full scan
- [ ] View results for each recommendation type
- [ ] Share results
- [ ] Return to dashboard
- [ ] View saved scans

### UI Testing
- [ ] All screens render correctly on iPhone SE (small)
- [ ] All screens render correctly on iPhone 15 Pro Max (large)
- [ ] Dark mode support (if implementing)
- [ ] Landscape orientation (optional, may lock to portrait)
- [ ] Dynamic type support
- [ ] VoiceOver navigation works

### Edge Cases
- [ ] VIN decode fails (show disclaimer)
- [ ] No VIN entered (skip VIN fields in results)
- [ ] Warning lights "No" selected (grid hidden)
- [ ] Warning lights "Yes" but none selected
- [ ] Device connection timeout
- [ ] Scan interruption (app backgrounded)
- [ ] No saved scans yet (empty state)

---

## Build Notes

### Minimum iOS Version
Recommend iOS 15.0+ for:
- SwiftUI maturity
- CoreBluetooth enhancements
- Native async/await support

### Third-Party Dependencies
Consider these for SwiftUI:
- **Charts**: Native Swift Charts (iOS 16+) or third-party like SwiftUICharts
- **Bluetooth**: CoreBluetooth (native)
- **Network**: URLSession (native) for VIN decoding API
- **Local Storage**: UserDefaults for simple data, Core Data for complex

### Performance
- Lazy loading for scan history list
- Efficient VIN API calls (debounce if real-time)
- Bluetooth scanning optimization (limit search time)
- Image optimization for logos

---

## API Integration (Future)

### VIN Decoding API
```
Endpoint: https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/{vin}?format=json
Method: GET
Response includes: Make, Model, Year, Trim, Engine, Transmission, etc.
```

### Price Data API (Optional)
Consider integrating Kelley Blue Book, Edmunds, or CarGurus API for:
- Real-time price ranges
- Market condition data
- Similar vehicle listings

---

## Summary

MintCheck is a well-structured app with clear navigation flow, consistent design system, and thoughtful UX. The conversion to SwiftUI should be straightforward with:

1. **8 main screens** following a linear flow
2. **Simple state management** (no complex Redux-like patterns)
3. **Standard iOS patterns** (navigation, lists, forms, buttons)
4. **Bluetooth integration** for OBD-II devices
5. **Optional VIN decoding** with graceful fallback
6. **Clean, premium design** with mint green accent

Key areas to focus on:
- Bluetooth device discovery and connection
- Smooth screen transitions and progress animations
- Proper error handling and user feedback
- Accessibility and dynamic type support
- Local data persistence for scan history

Good luck with the build! 🚀
