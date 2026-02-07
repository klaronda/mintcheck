# MintCheck Engineering

OBD-II communication layer and scanner tools.

## Structure

```
engineering/
├── swift/          # Swift CLI for Bluetooth OBD2 (macOS)
├── scanners/       # Python WiFi scanners (recommended)
├── scans/          # Raw scan data (JSON + CSV)
└── docs/           # Technical documentation
```

## Quick Start (WiFi - Recommended)

```bash
# Connect to OBD2 WiFi network first
cd scanners
python3 WIFI_SCAN_FULL.py
```

## Files

| File | Purpose |
|------|---------|
| `scanners/WIFI_SCAN_FULL.py` | Full comprehensive scanner |
| `scanners/WIFI_SCAN.py` | Quick basic scan |
| `scanners/MOCK_DATA.py` | Mock data for development |
| `scans/scan_data.csv` | All 14 scans collected |
