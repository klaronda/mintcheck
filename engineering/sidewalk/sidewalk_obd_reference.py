#!/usr/bin/env python3
"""
MintCheck – Sidewalk + OBD reference tool (for future use).

There is no direct "Sidewalk to OBD" connection. This script:
  1. Loads an existing MintCheck scan JSON (from engineering/scans/ or current dir).
  2. Builds a minimal "Sidewalk-sized" payload (VIN, DTC count, key PIDs).
  3. Optionally checks payload size vs Sidewalk limits.

When you have a Sidewalk PDF/spec, extend this (e.g. topic format, encoding).

Usage:
  python3 sidewalk_obd_reference.py [path/to/scan_YYYYMMDD_HHMMSS.json]
  python3 sidewalk_obd_reference.py   # uses latest scan_*.json in ../scans/
"""

import json
import os
import sys
from pathlib import Path

# Sidewalk reference limits (from public docs)
SIDEWALK_MAX_PAYLOAD_BYTES = 217  # typical LoRa message size; adjust per PHY
SIDEWALK_MONTHLY_CAP_MB = 500

# Keys we'd send over Sidewalk (minimal health-check summary)
SIDEWALK_PAYLOAD_KEYS = [
    "vin",
    "dtc_count",
    "mil_on",
    "engine_rpm",
    "coolant_temp_c",
    "throttle_pct",
    "engine_load_pct",
    "battery_voltage",
    "fuel_level_pct",
]

# Map hex PID (from scan "data") -> Sidewalk payload key (scanner JSONs use hex keys)
DATA_PID_TO_PAYLOAD_KEY = {
    "010C": "engine_rpm",
    "0104": "engine_load_pct",
    "0105": "coolant_temp_c",
    "0111": "throttle_pct",
    "0142": "battery_voltage",
    "012F": "fuel_level_pct",
}


def find_latest_scan(scans_dir: Path) -> Path | None:
    """Return path to most recent scan_*.json in scans_dir."""
    if not scans_dir.is_dir():
        return None
    candidates = list(scans_dir.glob("scan_*.json"))
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


def load_scan(path: Path) -> dict | None:
    """Load and return scan JSON."""
    try:
        with open(path, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"Failed to load {path}: {e}", file=sys.stderr)
        return None


def build_sidewalk_payload(scan: dict) -> dict:
    """Build minimal payload suitable for Sidewalk (small size)."""
    out = {}
    # Prefer top-level keys from our scanner JSON
    for key in SIDEWALK_PAYLOAD_KEYS:
        if key in scan:
            out[key] = scan[key]
    # Fallback: pull from nested structures if present
    if "vin" not in out and "vin_decoded" in scan:
        out["vin"] = scan.get("vin_decoded") or scan.get("vin")
    if "vin" not in out and "vin" in scan:
        out["vin"] = scan["vin"]
    if "dtc_count" not in out:
        dtcs = scan.get("dtcs") or scan.get("trouble_codes") or []
        if isinstance(dtcs, list):
            out["dtc_count"] = len(dtcs)
        elif dtcs in (None, "None", ""):
            out["dtc_count"] = 0
        else:
            out["dtc_count"] = 1  # at least one DTC string
    if "mil_on" not in out and "mil" in scan:
        out["mil_on"] = scan["mil"]
    # Common PID names from WIFI_SCAN_FULL / app
    pids = scan.get("pids") or scan.get("readings") or {}
    for pid_key in ["engine_rpm", "coolant_temp_c", "throttle_pct", "engine_load_pct", "battery_voltage", "fuel_level_pct"]:
        if pid_key not in out and pid_key in pids:
            out[pid_key] = pids[pid_key]
    # Scanner JSONs sometimes put computed values under "data" with hex PID keys
    data = scan.get("data") or {}
    for hex_pid, payload_key in DATA_PID_TO_PAYLOAD_KEY.items():
        if payload_key not in out and hex_pid in data:
            out[payload_key] = data[hex_pid]
    return out


def main():
    script_dir = Path(__file__).resolve().parent
    scans_dir = script_dir / ".." / "scans"
    scans_dir = scans_dir.resolve()

    if len(sys.argv) >= 2:
        path = Path(sys.argv[1])
        if not path.is_absolute():
            path = (script_dir / path).resolve()
    else:
        path = find_latest_scan(scans_dir)
        if path is None:
            # Try current dir
            path = find_latest_scan(Path.cwd())
        if path is None:
            print("No scan_*.json found in ../scans or current dir. Pass a path: python3 sidewalk_obd_reference.py <path>", file=sys.stderr)
            sys.exit(1)

    scan = load_scan(path)
    if not scan:
        sys.exit(2)

    payload = build_sidewalk_payload(scan)
    payload_bytes = json.dumps(payload).encode("utf-8")
    n = len(payload_bytes)

    print("Source scan:", path)
    print("Sidewalk payload (minimal):")
    print(json.dumps(payload, indent=2))
    print()
    print(f"Payload size: {n} bytes")
    if n <= SIDEWALK_MAX_PAYLOAD_BYTES:
        print(f"  OK for typical Sidewalk message (limit ~{SIDEWALK_MAX_PAYLOAD_BYTES} bytes)")
    else:
        print(f"  Over typical limit ({SIDEWALK_MAX_PAYLOAD_BYTES} bytes). Consider fewer PIDs or compression.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
