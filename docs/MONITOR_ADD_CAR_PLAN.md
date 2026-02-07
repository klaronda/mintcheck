# Monitor “Add Car” Flow — Implementation Plan

Based on the brief and your choices: **1B** (single concept: extend vehicles → cars), **2A** (entitlement only, no payment), **3C** (picker before scan + match/prompt after).

---

## 1. Data model (Supabase)

### 1.1 Extend `vehicles` → “cars” (single table)

Keep the existing `vehicles` table as the single place for all user vehicles/cars. Add Monitor-specific columns via a new migration (e.g. `supabase/migrations/monitor_cars_and_entitlements.sql`):

- **`name`** `text` nullable — friendly name (e.g. “Daily Driver”).
- **`odometer_baseline`** `int` nullable — current mileage when added.
- **`vin_hash`** `text` nullable — normalized VIN for uniqueness: uppercase, no spaces, length 17; store a hash or the normalized string per your preference (brief suggests storing for comparisons).

**Constraints:**

- Partial unique index so one VIN per user when VIN is provided:  
  `CREATE UNIQUE INDEX ... ON vehicles (user_id, vin_hash) WHERE vin_hash IS NOT NULL;`
- On insert/update: if `vin` is present, set `vin_hash = upper(trim(vin))` (and enforce length 17 in app or DB).

Existing columns (`vin`, `year`, `make`, `model`, `user_id`, `vin_locked`, etc.) stay; no need to rename the table unless you want the app to call it “cars” in code only.

### 1.2 Create `subscriptions` (entitlements)

New table: **`subscriptions`** (or `entitlements`):

- `id` uuid PK default `gen_random_uuid()`
- `user_id` uuid NOT NULL references `auth.users(id)`
- `vehicle_id` uuid NOT NULL references `vehicles(id)` — the “car” for Monitor
- `plan` text NOT NULL — e.g. `'monitor'` (and later `'buyer_pass'`)
- `status` text NOT NULL default `'active'` — e.g. `active | inactive | canceled`
- `provider` text nullable — e.g. `'iap' | 'stripe'` (for later; leave null for 2A)
- `provider_subscription_id` text nullable
- `started_at` timestamptz default `now()`
- `ended_at` timestamptz nullable

**Rule:** one Monitor subscription per car per user:  
`UNIQUE (user_id, vehicle_id, plan)` or unique partial index where `plan = 'monitor'`.

RLS: users can only read/insert/update their own rows.

### 1.3 Scans

Keep existing **`scans`** table and **`vehicle_id`** (no new `car_id`). Scans already attach to a vehicle; that vehicle is the “car” once we’ve extended `vehicles`. No schema change needed for scans in this phase.

---

## 2. iOS app — “Add Car” flow

### 2.1 Entry points

- **Settings → Plan Details → Monitor card**  
  Change the Monitor card from a single “Learn more” link to: primary CTA **“Add Car”** (starts Add Car flow). Optionally keep a secondary “Learn more” link to the website.
- **My Cars screen**  
  New screen (see below) with list of cars and an **“Add Car”** button that starts the same flow.

### 2.2 Step 1: Vehicle identification (VIN-first)

- **Screen:** e.g. `AddCarStep1View` or first step in an `AddCarFlowView`.
- **Fields:**  
  - VIN (primary): placeholder “Enter 17-character VIN (recommended)”.  
  - Inline helper: “VIN helps confirm year/make/model.”  
  - Secondary link: “Can’t find or decode VIN?” → go to Step 1a (fallback).
- **Behavior:**  
  - On 17-character VIN: call existing VIN decode (e.g. `VINDecoderService`).  
  - If decode succeeds: auto-fill Year/Make/Model; show them locked with an “Edit” to override.  
  - If decode fails: show inline message “We couldn’t decode this VIN. You can still add your car using year/make/model.” and link to Step 1a.
- **Validation:** Before Step 2: either valid decoded VIN (17 chars) or user has completed Step 1a (Year/Make/Model).

### 2.3 Step 1a: Fallback (no VIN decode)

- **Screen:** “Add your car without a VIN”.
- **Copy:** “Monitoring works even when VIN data isn’t available.”
- **Fields:** Year*, Make*, Model* (required); VIN optional.
- Reuse or mirror existing year/make/model pickers (e.g. from `VehicleDetailsStepView` / `VehicleBasicsView`).

### 2.4 Step 2: Vehicle details

- **Fields:**  
  - Odometer (optional): placeholder “Current mileage (optional)”; optional “I’m not sure” that saves null.  
  - Car name (optional): placeholder “e.g. Daily Driver, Family SUV”.

### 2.5 Step 3: Confirm and “Start Monitoring”

- **Summary card:** Car name (or default “My Car”), Year Make Model, VIN masked if provided.
- **Copy:** “MintCheck Monitor — $4.99 / month for this car” (no payment in 2A; just copy).
- **CTA:** “Start Monitoring”.
- **On tap (2A — entitlement only):**  
  1. Normalize VIN if present (uppercase, trim, length 17); set `vin_hash` (or equivalent) for DB.  
  2. Create or get `vehicles` row (user_id, vin, vin_hash, year, make, model, name, odometer_baseline).  
  3. Insert `subscriptions` row: user_id, vehicle_id, plan = `'monitor'`, status = `'active'`, started_at = now.  
  4. On success: show car in My Cars; navigate to car detail (minimal) with “Monitoring active” and “Next recommended scan: every 10–14 days”.

### 2.6 Copy and UX

- Use brief’s default text for Add Car header, VIN helper, odometer helper where specified.
- No registration photos; no blocking if VIN can’t be read from OBD later.

---

## 3. My Cars screen (minimal)

- **Navigation:** New screen, e.g. `Screen.myCars`. Reachable from:  
  - Menu (hamburger): add “My Cars” item that sets `nav.currentScreen = .myCars`.  
  - Optionally a Dashboard card “My Cars” for users who have or are eligible for Monitor.
- **Content:**  
  - List of cars (from `vehicles` for current user; optionally only those with an active Monitor subscription if you want to show “monitored” cars only).  
  - Each card: Car name (or default “My Car”), Year Make Model, monitoring status badge (Active / Not active), last scan timestamp if any.  
  - CTA: “Add Car” (starts Add Car flow).
- **Car detail (minimal):**  
  - On tap: navigate to car detail screen.  
  - Show: Car name, Year Make Model, VIN masked; status “Monitoring active”; “Next recommended scan: Scan every 10–14 days”; placeholder for “Latest status” (Healthy / Watch / Attention); list of scan timestamps (no charts in v1).

---

## 4. Scan flow — attach scan to car (3C)

### 4.1 Optional “Which car?” before scan

- When user starts a scan (e.g. from Dashboard “Start a Mint Check”), if they have at least one car in My Cars (or at least one vehicle with an active Monitor subscription), show an optional step or modal: “Which car are you scanning?” with a picker of their cars.
- If they pick a car: store selected `vehicle_id` in scan context (e.g. `nav.currentScanData.vehicleId` or dedicated `selectedCarId`) and use it when saving the scan.
- If they skip or have no cars: proceed as today (create vehicle from current flow if needed); after scan, use 4.2.

### 4.2 After scan: match or prompt

- When saving the scan:  
  - If a car was selected before scan: save scan with that `vehicle_id`.  
  - Else if OBD reported VIN: try to match to a vehicle/car for this user (e.g. by normalized VIN). If one match: attach scan to that vehicle.  
  - Else (no selection, no VIN match): prompt “Assign this scan to a car?” with list of cars; user can pick one or “Skip” (save scan with vehicle created from current flow, not linked to a Monitor car).
- VIN verification remains soft: set `vin_verified` / `vin_mismatch` when OBD VIN is present; never block monitoring or saving.

---

## 5. Implementation order

1. **Migration**  
   - Extend `vehicles` (name, odometer_baseline, vin_hash; unique on (user_id, vin_hash) where vin_hash not null).  
   - Create `subscriptions` table and RLS.

2. **App: models and API**  
   - Extend `VehicleInfo` (or add a “Car” type) with name, odometerBaseline, vinHash.  
   - Add ScanService (or CarService) methods: createCar, listCars, getCarsWithMonitorSubscription; createSubscription(vehicleId, plan: "monitor").

3. **App: Add Car flow**  
   - Add Car flow (Steps 1, 1a, 2, 3) with VIN decode + fallback, odometer + name, confirm + “Start Monitoring” (create car + subscription only).

4. **App: My Cars**  
   - My Cars screen and minimal car detail; “Add Car” from Settings (Monitor card) and from My Cars.

5. **App: Scan attachment**  
   - Optional car picker before scan; after scan, match by VIN or prompt to assign; save scan with chosen vehicle_id.

---

## 6. Files to touch (summary)

- **Supabase:** New migration in [mintcheck/supabase/migrations/](mintcheck/supabase/migrations/) for vehicles columns and `subscriptions` table.
- **iOS:**  
  - [MintCheck/.../Models/Vehicle.swift](mintcheck/MintCheck/MintCheck/MintCheck/Models/Vehicle.swift) — extend vehicle (name, odometerBaseline, vinHash).  
  - [MintCheck/.../Services/ScanService.swift](mintcheck/MintCheck/MintCheck/MintCheck/Services/ScanService.swift) — car CRUD + subscription create/list.  
  - New views: Add Car flow (step 1, 1a, 2, 3), My Cars list, Car detail (minimal).  
  - [MintCheck/.../ContentView.swift](mintcheck/MintCheck/MintCheck/MintCheck/ContentView.swift) — add Screen.myCars, navigation from menu and from Add Car success.  
  - [MintCheck/.../Views/SettingsView.swift](mintcheck/MintCheck/MintCheck/MintCheck/Views/SettingsView.swift) — Monitor card “Add Car” CTA.  
  - Scan flow (e.g. [MintCheck/.../Views/ScanFlowView.swift](mintcheck/MintCheck/MintCheck/MintCheck/Views/ScanFlowView.swift) or ContentView): optional car picker before scan; after scan, match by VIN or prompt and set vehicle_id when saving.

---

## 7. Out of scope for this plan

- Real payment (Stripe / Apple IAP) for $4.99/month.
- Charts or advanced analytics; only store scans and show list/timestamps.
- Prediction logic; comparison/insights in a later phase.
