# MintCheck iOS App - Developer Handoff

## Project Overview
- **SwiftUI** iOS app for used car buyers
- **Supabase** backend (auth, database, edge functions)
- **OpenAI** (via Supabase Edge Function `analyze-dtcs`) for AI-powered DTC analysis
- **NHTSA API** for free vehicle history (recalls, safety ratings)

---

## Critical Files & Architecture

| File | Purpose |
|------|---------|
| `ContentView.swift` | Main navigation hub, `ScanData` struct, all screen routing |
| `Colors.swift` | Brand colors - `#3EB489` is mint green |
| `LaunchScreen.storyboard` | Native launch screen (uses inline RGB, not named colors) |
| `DTCAnalysisService.swift` | Calls `analyze-dtcs` Edge Function (OpenAI) for DTC explanations |
| `Services/` folder | VIN decoder, valuation, mock OBD, auth |

---

## Things NOT to Change

### 1. No Transitions
All `.transition()` modifiers were removed from `ContentView.swift` due to visual glitches (split-screen flashing). Screen changes are instant. **Do not add transitions back.**

### 2. Launch Screen Colors
Uses inline RGB values directly in storyboard, NOT named color references:
```
Red: 0.24313725490196078
Green: 0.70588235294117652
Blue: 0.53725490196078429
```
This equals `#3EB489`. Do not use named colors or color assets for the launch screen.

### 3. Navigation Pattern
Uses `NavigationState` observable with `currentScreen` enum. Does NOT use NavigationStack. The home screen sits at the bottom of the Z-stack and other screens appear over it.

### 4. Bottom Navigation
Fixed position at bottom of screen, not floating. Icons have no strokes.

### 5. Brand Color
`#3EB489` is the mint green used everywhere. Defined in `Colors.swift` as `Color.mintGreen`.

---

## Supabase Configuration

### Edge Function Secrets (`analyze-dtcs`)
- `OPENAI_API_KEY` - OpenAI API key (required)
- `OPENAI_MODEL` - Optional; defaults to `gpt-4o-mini`

Remove legacy Bedrock secrets (`AWS_*`, `BEDROCK_*`) from Supabase if still present.

### `analyze-dtcs` request (iOS → Edge Function)
The app sends **`appRecommendation`** on each analysis request: the current `RecommendationType.rawValue` (`safe`, `low-data`, `caution`, `not-recommended`). The model uses it so narrative tone matches the on-screen badge tier without changing Swift recommendation logic.

**AI `summary` (under the tier title):** Edge Function caps at **180 characters** and instructs the model to explain **what is wrong** (issue-first), not to repeat the Healthy/Caution/Not Recommended headline. Tier tone is secondary.

**Repair cost line on results:** When the Edge Function returns **`totalRepairCostLow` / `totalRepairCostHigh`** (non-zero), the results screen shows that range for “all codes.” Prompts ask for **code-specific** shop ranges (not generic $2,500–$5,000). If the AI call fails or omits totals, the UI uses softer tier-based fallback copy (still not a fixed dollar band).

### Database Tables
- `profiles` - User profiles
- `scans` - Saved vehicle scans
- `vehicles` - Vehicle information

---

## Current State

### Working Features
- User authentication (sign up, sign in, sign out)
- Mock OBD-II scan flow
- VIN decoding (NHTSA API)
- Vehicle history (recalls, safety ratings - NHTSA)
- AI-powered DTC analysis (OpenAI via Edge Function)
- Vehicle valuation estimates
- Scan history
- Help/Support pages
- Settings with account deletion

### Using Mock Data
- `MockOBDService.swift` - Simulates OBD-II device communication
- Real device integration pending (devices arriving soon)

---

## Next Steps for Launch

### Must-Have (Before Launch)
1. **Real OBD-II Integration** - Replace `MockOBDService` with actual Bluetooth/WiFi ELM327 communication
2. **TestFlight Beta** - Test with real vehicles and real users
3. **App Store Assets** - Screenshots, app description, keywords
4. **Privacy Policy & Terms** - Required for App Store submission
5. **Website** - Landing page for the app

### Should-Have (Launch or Shortly After)
1. **VinAudit Integration** - Vehicle history reports at $8.99
   - Dealer pricing available: $20/mo + $1/report
   - Plan exists in conversation history, not yet implemented
2. **Error Handling** - More robust error states for network failures, Bluetooth issues
3. **Offline Mode** - Cache previous scans for offline viewing

### Nice-to-Have (Post-Launch)
1. **Push Notifications** - Recall alerts for saved vehicles
2. **Car Marketplace Map** - Let free users see scanned cars on a map
3. **AI Value Reconciliation** - Factor repair costs into vehicle valuation

---

## App Store Submission Checklist

- [ ] App icon (all sizes in Assets.xcassets)
- [ ] Screenshots for different device sizes
- [ ] App description & keywords
- [ ] Privacy policy URL
- [ ] Support URL (support@mintcheckapp.com)
- [ ] Age rating questionnaire
- [ ] Export compliance (uses encryption via Supabase)

---

## Key Decisions Made

1. **Free vehicle history** via NHTSA instead of paid services initially
2. **VinAudit** planned for premium reports ($8.99 to user)
3. **OpenAI** (`gpt-4o-mini` by default) for DTC/valuation JSON via `analyze-dtcs`
4. **No birthday field** in user profiles (was removed)
5. **Year is optional** for manual vehicle entry - displays as "(Year N/A)" if unknown
6. **Make and Model are required** - never show "Unknown"

---

## Support

- Email: support@mintcheckapp.com
- The Help section has articles on:
  - Finding your OBD-II port
  - Understanding scan results
  - What are trouble codes
  - Why codes were recently cleared
  - FAQs
