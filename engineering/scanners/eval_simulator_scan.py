#!/usr/bin/env python3
"""
MintCheck Simulator Scan Evaluator

Compares simulator ground truth (what we sent) to the scan result in Supabase
(or a local scan JSON). Reports accuracy, missing fields, confidence %, and
connection stability.

Usage:
  # With ground-truth file and Supabase (set SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  python3 eval_simulator_scan.py --ground-truth ../scans/simulator_ground_truth_<id>.json
  python3 eval_simulator_scan.py --session-id <uuid> --scans-dir ../scans

  # With a local scan JSON (no Supabase)
  python3 eval_simulator_scan.py --ground-truth ../scans/simulator_ground_truth_<id>.json --scan-json /path/to/scan.json

  # Resolve simulator user by email (default)
  python3 eval_simulator_scan.py --ground-truth <path> --simulator-email simulator@mintcheckapp.com
"""

import argparse
import json
import os
import sys
from pathlib import Path
from datetime import datetime, timezone, timedelta

# Default simulator account
DEFAULT_SIMULATOR_EMAIL = "simulator@mintcheckapp.com"
SCANS_DIR = Path(__file__).resolve().parent.parent / "scans"

# Map OBD command -> obd_data field name (OBDDataJSON)
COMMAND_TO_OBD_FIELD = {
    "0902": "vin",
    "03": "dtcs",
    "010C": "rpm",
    "0104": "engineLoad",
    "0105": "coolantTemp",
    "010F": "intakeTemp",
    "010D": "vehicleSpeed",
    "0111": "throttlePosition",
    "012F": "fuelLevel",
    "0142": "batteryVoltage",
    "0131": "distanceSinceCleared",
    "0130": "warmupCycles",  # int in OBDDataJSON
    "0151": "fuelType",
    "011C": "obdStandard",
    "0133": "barometricPressure",
}

# Numeric tolerance: relative (for %) or absolute
NUMERIC_TOLERANCE_PCT = 1.0
NUMERIC_TOLERANCE_ABS = 0.5


def load_ground_truth(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def expected_from_ground_truth(gt: dict) -> dict:
    """Build expected { obd_field: value } from ground truth command log."""
    expected = {}
    for entry in gt.get("commands", []):
        cmd = entry.get("command", "").strip().upper().replace(" ", "")
        resp = entry.get("response") or {}
        if cmd in COMMAND_TO_OBD_FIELD:
            field = COMMAND_TO_OBD_FIELD[cmd]
            if cmd == "0902":
                expected[field] = resp.get("vin")
            elif cmd == "03":
                expected[field] = resp.get("dtcs") or []
            elif cmd == "0130":
                v = resp.get("value")
                expected[field] = int(v) if v is not None else None
            elif cmd in ("0151", "011C"):
                # App stores string; we have int. Map 1 -> "Gasoline", 7 -> "EOBD + OBD-II" etc.
                v = resp.get("value")
                if v is not None and cmd == "0151":
                    fuel = {0: "Not Available", 1: "Gasoline", 2: "Methanol", 3: "Ethanol", 4: "Diesel", 5: "LPG", 6: "CNG", 8: "Electric", 17: "Hybrid Gasoline", 18: "Hybrid Ethanol", 19: "Hybrid Diesel", 20: "Hybrid Electric"}
                    expected[field] = fuel.get(int(v), str(v))
                elif v is not None and cmd == "011C":
                    obd = {1: "OBD-II CARB", 2: "OBD EPA", 3: "OBD + OBD-II", 6: "EOBD", 7: "EOBD + OBD-II"}
                    expected[field] = obd.get(int(v), str(v))
                else:
                    expected[field] = resp.get("value")
            else:
                expected[field] = resp.get("value")
    return expected


def compare_value(expected, received, field: str) -> tuple[bool, str]:
    """Return (match, message)."""
    if expected is None and received is None:
        return True, "both null"
    if expected is None:
        return True, "no expected"
    if received is None:
        return False, f"missing (sent {expected})"
    if field == "vin":
        return (expected == received), f"sent '{expected}' got '{received}'" if expected != received else "match"
    if field == "dtcs":
        exp_set = set(d.strip().upper() for d in expected) if isinstance(expected, list) else set()
        rec_set = set(d.strip().upper() for d in received) if isinstance(received, list) else set()
        match = exp_set == rec_set
        msg = f"sent {sorted(exp_set)} got {sorted(rec_set)}" if not match else "match"
        return match, msg
    if isinstance(expected, (int, float)) and isinstance(received, (int, float)):
        if isinstance(received, int) and field == "warmupCycles":
            rec = received
        else:
            rec = float(received)
        exp = float(expected)
        if exp == 0:
            ok = abs(rec - exp) <= NUMERIC_TOLERANCE_ABS
        else:
            ok = abs(rec - exp) <= max(NUMERIC_TOLERANCE_ABS, abs(exp) * NUMERIC_TOLERANCE_PCT / 100)
        msg = f"sent {exp} got {rec}" if not ok else "match"
        return ok, msg
    match = expected == received
    return match, f"sent {expected} got {received}" if not match else "match"


def stability_from_ground_truth(gt: dict) -> dict:
    """Derive connection stability from connection_events and commands."""
    events = gt.get("connection_events") or []
    started = gt.get("started_at")
    ended = gt.get("ended_at")
    duration_sec = None
    if started and ended:
        try:
            a = datetime.fromisoformat(started.replace("Z", "+00:00"))
            b = datetime.fromisoformat(ended.replace("Z", "+00:00"))
            duration_sec = (b - a).total_seconds()
        except Exception:
            pass
    disconnects = sum(1 for e in events if e.get("event") == "disconnect")
    connects = sum(1 for e in events if e.get("event") == "connect")
    commands = [e.get("command", "").strip().upper() for e in gt.get("commands", [])]
    has_vin = "0902" in commands
    has_dtcs = "03" in commands
    has_rpm = "010C" in commands
    completed = has_vin and has_dtcs and has_rpm
    return {
        "session_duration_sec": duration_sec,
        "connect_count": connects,
        "disconnect_count": disconnects,
        "completed": completed,
        "commands_seen": len(commands),
    }


def fetch_simulator_scans_from_supabase(simulator_user_id: str, within_minutes: int = 10) -> list:
    """Return list of scans for simulator user (recent). Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY."""
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        return []
    try:
        import urllib.request
        since = (datetime.now(timezone.utc) - timedelta(minutes=within_minutes)).isoformat().replace("+00:00", "Z")
        # Supabase REST: GET /rest/v1/scans?user_id=eq.<uuid>&order=created_at.desc&limit=20
        req = urllib.request.Request(
            f"{url.rstrip('/')}/rest/v1/scans?user_id=eq.{simulator_user_id}&order=created_at.desc&limit=20",
            headers={"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        print(f"Supabase fetch error: {e}", file=sys.stderr)
        return []


def match_scan_to_session(gt: dict, scans: list, time_window_minutes: int = 5) -> dict | None:
    """Return the scan whose created_at falls within time_window of session start/end."""
    started = gt.get("started_at") or gt.get("ended_at")
    ended = gt.get("ended_at") or gt.get("started_at")
    if not started or not scans:
        return scans[0] if scans else None
    try:
        start_dt = datetime.fromisoformat(started.replace("Z", "+00:00"))
        end_dt = datetime.fromisoformat(ended.replace("Z", "+00:00"))
    except Exception:
        return scans[0] if scans else None
    window = timedelta(minutes=time_window_minutes)
    best = None
    best_diff = None
    for s in scans:
        ct = s.get("created_at")
        if not ct:
            continue
        try:
            scan_dt = datetime.fromisoformat(ct.replace("Z", "+00:00"))
        except Exception:
            continue
        if start_dt - window <= scan_dt <= end_dt + window:
            diff = min(abs((scan_dt - start_dt).total_seconds()), abs((scan_dt - end_dt).total_seconds()))
            if best_diff is None or diff < best_diff:
                best = s
                best_diff = diff
    return best


def run_eval(gt_path: Path, scan: dict | None, expected: dict) -> dict:
    """Compare expected to scan['obd_data'], return report dict."""
    obd = (scan or {}).get("obd_data") or {}
    report = {
        "session_id": None,
        "scan_id": None,
        "comparisons": [],
        "missing": [],
        "correct": 0,
        "total": 0,
        "confidence_pct": None,
        "stability": {},
    }
    for field, exp_val in expected.items():
        rec_val = obd.get(field)
        match, msg = compare_value(exp_val, rec_val, field)
        report["comparisons"].append({"field": field, "sent": exp_val, "received": rec_val, "match": match, "note": msg})
        report["total"] += 1
        if match:
            report["correct"] += 1
        else:
            report["missing"].append({"field": field, "sent": exp_val, "received": rec_val})
    if report["total"] > 0:
        report["confidence_pct"] = round(100.0 * report["correct"] / report["total"], 1)
    return report


def main():
    ap = argparse.ArgumentParser(description="Compare simulator ground truth to scan result")
    ap.add_argument("--ground-truth", type=Path, help="Path to simulator_ground_truth_<id>.json")
    ap.add_argument("--session-id", help="Session UUID (then --scans-dir to find ground truth file)")
    ap.add_argument("--scans-dir", type=Path, default=SCANS_DIR)
    ap.add_argument("--scan-json", type=Path, help="Path to a single scan JSON (obd_data, created_at)")
    ap.add_argument("--supabase-user-id", help="Simulator user UUID (default: resolve via env or email)")
    ap.add_argument("--simulator-email", default=DEFAULT_SIMULATOR_EMAIL)
    ap.add_argument("--time-window-minutes", type=int, default=5)
    ap.add_argument("--output-json", type=Path, help="Write report to JSON file")
    args = ap.parse_args()

    gt_path = args.ground_truth
    if not gt_path and args.session_id:
        gt_path = args.scans_dir / f"simulator_ground_truth_{args.session_id}.json"
    if not gt_path or not gt_path.exists():
        print(f"Ground truth file not found: {gt_path}", file=sys.stderr)
        sys.exit(1)

    gt = load_ground_truth(gt_path)
    report = {"session_id": gt.get("session_id"), "ground_truth_path": str(gt_path)}

    expected = expected_from_ground_truth(gt)
    if not expected:
        print("No comparable commands in ground truth.", file=sys.stderr)
        sys.exit(1)

    scan = None
    if args.scan_json and args.scan_json.exists():
        with open(args.scan_json) as f:
            scan = json.load(f)
        report["scan_source"] = "file"
        report["scan_id"] = scan.get("id")
    else:
        simulator_user_id = (
            args.supabase_user_id
            or os.environ.get("SIMULATOR_USER_ID")
            or "5838ed15-5acf-4d09-a027-3a8a64e9267c"  # simulator@mintcheckapp.com
        )
        scans = fetch_simulator_scans_from_supabase(simulator_user_id, within_minutes=args.time_window_minutes + 5)
        scan = match_scan_to_session(gt, scans, args.time_window_minutes)
        report["scan_source"] = "supabase" if scan else "none"
        report["scan_id"] = scan.get("id") if scan else None

    eval_report = run_eval(gt_path, scan, expected)
    eval_report["session_id"] = gt.get("session_id")
    eval_report["scan_id"] = report.get("scan_id")
    eval_report["stability"] = stability_from_ground_truth(gt)

    # Stdout report
    print("=" * 60)
    print("Simulator scan evaluation")
    print("=" * 60)
    print(f"Session:    {gt.get('session_id', '')}")
    print(f"Scan:       {report.get('scan_id') or 'none (use --scan-json or Supabase)'}")
    print(f"Confidence: {eval_report.get('confidence_pct')}% ({eval_report.get('correct')}/{eval_report.get('total')} fields)")
    print()
    print("Stability:")
    for k, v in eval_report["stability"].items():
        print(f"  {k}: {v}")
    print()
    print("Per-field comparison:")
    for c in eval_report["comparisons"]:
        status = "OK" if c["match"] else "MISMATCH"
        print(f"  {c['field']:22} {status:10} {c['note']}")
    if eval_report["missing"]:
        print()
        print("Missing/wrong:")
        for m in eval_report["missing"]:
            print(f"  {m['field']}: sent {m['sent']} -> received {m['received']}")
    print("=" * 60)

    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        with open(args.output_json, "w") as f:
            json.dump(eval_report, f, indent=2)
        print(f"Report written to {args.output_json}")

    sys.exit(0 if (eval_report.get("confidence_pct", 0) >= 0 and scan) else 1)


if __name__ == "__main__":
    main()
