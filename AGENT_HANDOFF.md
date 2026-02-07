# 🚨 AGENT HANDOFF - READ THIS FIRST 🚨

**Last Updated:** Jan 22, 2026  
**Status:** MVP COMPLETE - App is working, DO NOT refactor

---

## ⚠️ CRITICAL RULES

1. **DO NOT refactor or "improve" working code** - The app works. Leave it alone.
2. **DO NOT reorganize folder structure** - It's already organized.
3. **DO NOT update dependencies** unless specifically asked.
4. **DO NOT change the OBD-II scanner logic** - It's been tested on 3 real cars.

---

## ✅ WHAT'S WORKING

| Component | Status | Location |
|-----------|--------|----------|
| iOS App (SwiftUI) | ✅ MVP Complete | `app/MintCheck/` |
| WiFi OBD Scanner | ✅ Tested on 3 cars | `engineering/scanners/` |
| Supabase Auth | ✅ Working | Configured in app |
| VIN Decoder | ✅ Working | NHTSA API |

### Tested Vehicles
- 2020 Subaru CrossTrek ✅
- 2025 Suzuki Swift ✅  
- 2012 Jeep Grand Cherokee ✅

### Tested OBD-II Adapters
- Bluetooth ELM327 (unstable - not recommended)
- WiFi OBD-II #1 ✅
- WiFi OBD-II #2 ✅

---

## 🧪 TESTING NEW OBD-II DEVICES

When new devices arrive, test them with the **Python scanner first** (not the app):

```bash
# 1. Plug device into car's OBD port
# 2. Turn car ignition ON
# 3. Connect Mac/PC to device's WiFi network (usually "wifi obdii" or similar)
# 4. Run the scanner:

cd /Users/kevoo/Cursor/mintcheck/engineering/scanners
python3 WIFI_SCAN_FULL.py
```

### Expected Output
- Should connect to `192.168.0.10:35000`
- Should show VIN, RPM, coolant temp, etc.
- Results auto-save to `engineering/scans/scan_YYYYMMDD_HHMMSS.json`

### If Device Uses Different IP/Port
Edit `WIFI_SCAN_FULL.py` line ~185:
```python
for host, port in [('192.168.0.10', 35000), ('192.168.0.10', 23)]:
```
Add the new IP/port to this list.

---

## 📱 TESTING THE iOS APP

1. Open Xcode
2. Open `app/MintCheck/` project
3. Build and run on simulator or device
4. Connect to OBD-II WiFi from iPhone settings first
5. Start scan in app

---

## 🚫 DO NOT TOUCH

| File/Folder | Reason |
|-------------|--------|
| `app/MintCheck/Services/OBDScanner.swift` | Core scanner logic - tested and working |
| `app/MintCheck/Services/SupabaseManager.swift` | Auth config - working |
| `engineering/scanners/*.py` | Reference scanners - working |
| `engineering/scans/` | Historical data - preserve for comparison |

---

## 📝 IF USER ASKS TO...

| Request | Action |
|---------|--------|
| "Test new device" | Use Python scanner first, then app |
| "Fix a bug" | Get specific repro steps, make minimal change |
| "Add a feature" | Ask user to confirm scope first |
| "Refactor" | DECLINE unless user insists |
| "Update dependencies" | DECLINE unless security issue |

---

## 🔧 COMMON ISSUES

### "Can't connect to OBD device"
1. Is car ignition ON? (not just accessory)
2. Is phone/Mac connected to OBD WiFi network?
3. Is another app using the connection?
4. Try unplugging and replugging the OBD device

### "NO DATA responses"
- Normal for some PIDs - not all cars support all data
- Engine might need to be running (not just ignition on)

### "Wrong IP address"
- Most devices use `192.168.0.10:35000`
- Some use `192.168.1.10` or port `23`
- Check device manual

---

## 📊 DATA REFERENCE

All scan data is in `engineering/scans/scan_data.csv`  
14 scans across 3 vehicles with 2 WiFi devices

---

## 💬 HANDOFF NOTES

The owner (Kevin) is doing UX/UI work in Figma. The app MVP is complete and ready for real-world testing. New OBD devices arriving in ~4 days.

**Priority:** Don't break what's working. Only make changes if explicitly asked and keep them minimal.
