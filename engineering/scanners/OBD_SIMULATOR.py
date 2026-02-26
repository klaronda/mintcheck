#!/usr/bin/env python3
"""
MintCheck OBD-II Simulator

Emulates a car ECU over TCP (fake scanner) or serial (female OBD2 adapter).
Feeds configurable car data (VIN, PIDs, DTCs) so you can test scanners and the app
without a real vehicle. Logs ground truth and connection events for evaluation.

Usage:
  TCP (default; app or WIFI_SCAN_FULL connect to this host:35000):
    python3 OBD_SIMULATOR.py
    python3 OBD_SIMULATOR.py --mode tcp --port 35000 --scenario healthy

  Serial (scanner in female OBD2; ELM327-style line protocol):
    python3 OBD_SIMULATOR.py --mode serial --serial-port /dev/cu.usbserial-XXXX

  python3 OBD_SIMULATOR.py --vin 1HGBH41JXMN109186 --scenario minor
"""

import argparse
import json
import socket
import sys
import threading
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

# Default ground-truth output dir (same as scan output)
SCANS_DIR = Path(__file__).resolve().parent.parent / "scans"

# --- Scenarios: value sets for healthy, minor issues, serious issues ---
SCENARIOS = {
    "healthy": {
        "vin": "1HGBH41JXMN109186",
        "rpm": 750,
        "engine_load_pct": 22.0,
        "coolant_temp_c": 90,
        "intake_temp_c": 38,
        "timing_advance": 8.0,
        "maf_gps": 12.5,
        "intake_pressure_kpa": 43,
        "fuel_level_pct": 65.0,
        "fuel_system_status": 2,  # Closed loop
        "st_trim_pct": 0.0,
        "lt_trim_pct": -1.5,
        "fuel_pressure_kpa": 45,
        "baro_kpa": 101,
        "battery_v": 14.1,
        "throttle_pct": 15.0,
        "rel_throttle_pct": 14.0,
        "ambient_temp_c": 25,
        "speed_kmh": 0,
        "distance_mil_km": 0,
        "warmups": 120,
        "distance_cleared_km": 8500,
        "time_mil_min": 0,
        "time_cleared_min": 420,
        "engine_run_time_s": 340,
        "fuel_type": 1,  # Gasoline
        "obd_standard": 7,  # EOBD + OBD-II
        "odometer_km": 125000.0,
        "dtcs": [],
    },
    "minor": {
        "vin": "2HGFG2B54CH501234",
        "rpm": 720,
        "engine_load_pct": 28.0,
        "coolant_temp_c": 94,
        "intake_temp_c": 45,
        "timing_advance": 6.0,
        "maf_gps": 14.2,
        "intake_pressure_kpa": 48,
        "fuel_level_pct": 42.0,
        "fuel_system_status": 2,
        "st_trim_pct": 3.0,
        "lt_trim_pct": 2.0,
        "fuel_pressure_kpa": 48,
        "baro_kpa": 100,
        "battery_v": 13.7,
        "throttle_pct": 14.5,
        "rel_throttle_pct": 14.0,
        "ambient_temp_c": 28,
        "speed_kmh": 0,
        "distance_mil_km": 0,
        "warmups": 85,
        "distance_cleared_km": 5200,
        "time_mil_min": 0,
        "time_cleared_min": 280,
        "engine_run_time_s": 180,
        "fuel_type": 1,
        "obd_standard": 7,
        "odometer_km": 98000.0,
        "dtcs": ["P0133"],
    },
    "serious": {
        "vin": "WVWZZZ3CZWE123456",
        "rpm": 650,
        "engine_load_pct": 35.0,
        "coolant_temp_c": 108,
        "intake_temp_c": 52,
        "timing_advance": 4.0,
        "maf_gps": 18.0,
        "intake_pressure_kpa": 55,
        "fuel_level_pct": 25.0,
        "fuel_system_status": 2,
        "st_trim_pct": 8.0,
        "lt_trim_pct": 6.0,
        "fuel_pressure_kpa": 42,
        "baro_kpa": 99,
        "battery_v": 12.2,
        "throttle_pct": 22.0,
        "rel_throttle_pct": 20.0,
        "ambient_temp_c": 35,
        "speed_kmh": 0,
        "distance_mil_km": 120,
        "warmups": 12,
        "distance_cleared_km": 800,
        "time_mil_min": 45,
        "time_cleared_min": 90,
        "engine_run_time_s": 60,
        "fuel_type": 1,
        "obd_standard": 7,
        "odometer_km": 185000.0,
        "dtcs": ["P0300", "P0128", "P0219"],
    },
}


def _vin_to_0902_hex(vin: str) -> str:
    """Encode 17-char VIN as Mode 09 PID 02 response: 49 02 01 xx xx xx 49 02 02 ..."""
    if len(vin) < 17:
        vin = vin.ljust(17, " ")
    parts = []
    for i in range(0, 17, 3):
        chunk = vin[i : i + 3]
        seq = (i // 3) + 1
        hex_bytes = " ".join(f"{ord(c):02X}" for c in chunk)
        parts.append(f"49 02 {seq:02X} {hex_bytes}")
    return " ".join(parts)


def _dtcs_to_03_hex(dtcs: list) -> str:
    """Encode DTC list as Mode 03 response: 43 [b1][b2][b3][b4]...
    DTC P0133 = digits 0,1,3,3 -> byte1=0x01, byte2=0x33."""
    if not dtcs:
        return "43 00"
    out = ["43"]
    for code in dtcs:
        code = code.strip().upper()
        if len(code) >= 5 and code[0] in "PBCU" and code[1:5].isdigit():
            d1, d2, d3, d4 = int(code[1]), int(code[2]), int(code[3]), int(code[4])
            b1 = d1 * 16 + d2
            b2 = d3 * 16 + d4
            out.append(f"{b1:02X}")
            out.append(f"{b2:02X}")
    return " ".join(out)


class PayloadEngine:
    """Build ELM327-format responses from scenario values."""

    def __init__(self, scenario: str, vin_override: str | None = None):
        self.v = SCENARIOS.get(scenario, SCENARIOS["healthy"]).copy()
        if vin_override:
            self.v["vin"] = vin_override

    def response(self, cmd: str) -> tuple[str, dict]:
        """Return (response_line, ground_truth_dict). response_line is what we send (no >)."""
        cmd = cmd.strip().upper().replace(" ", "")
        if not cmd:
            return ("", {})

        # AT commands
        if cmd == "ATZ":
            return ("ELM327 v1.5", {"raw": "ELM327 v1.5", "command": "ATZ"})
        if cmd in ("ATE0", "ATL0", "ATS1", "ATH0", "ATSP0"):
            return ("OK", {"raw": "OK", "command": cmd})
        if cmd == "ATDPN":
            return ("A0", {"raw": "A0", "command": "ATDPN"})
        if cmd == "ATI":
            return ("ELM327 v1.5", {"raw": "ELM327 v1.5", "command": "ATI"})

        # Supported PIDs 01-20: bitmap so 0100 returns 41 00 xx xx xx xx (support 01-20)
        if cmd == "0100":
            # Support 0103, 0104, 0105, 010C, 010D, 010F, 0111, etc.
            b2 = 0xBE  # support many PIDs
            b3 = 0x3E
            b4 = 0xB8
            b5 = 0x31
            return (
                f"41 00 {b2:02X} {b3:02X} {b4:02X} {b5:02X}",
                {"raw": f"41 00 {b2:02X} {b3:02X} {b4:02X} {b5:02X}", "command": "0100"},
            )

        # VIN Mode 09 PID 02
        if cmd == "0902":
            hex_resp = _vin_to_0902_hex(self.v["vin"])
            return (hex_resp, {"command": "0902", "vin": self.v["vin"], "raw": hex_resp})

        # DTCs Mode 03
        if cmd == "03":
            hex_resp = _dtcs_to_03_hex(self.v["dtcs"])
            return (hex_resp, {"command": "03", "dtcs": list(self.v["dtcs"]), "raw": hex_resp})

        # Mode 01 PIDs: value -> hex bytes (inverse of WIFI_SCAN_FULL formulas)
        v = self.v

        def one_byte(pid: str, val: float) -> str:
            a = max(0, min(255, int(round(val))))
            return f"41 {pid[-2:].upper()} {a:02X}"

        def two_byte(pid: str, val: float) -> str:
            x = max(0, min(65535, int(round(val))))
            a, b = (x >> 8) & 0xFF, x & 0xFF
            return f"41 {pid[-2:].upper()} {a:02X} {b:02X}"

        pid_map = {
            "0103": (one_byte, v["fuel_system_status"]),
            "0104": (lambda p, x: one_byte(p, x * 255 / 100), v["engine_load_pct"]),
            "0105": (lambda p, x: one_byte(p, x + 40), v["coolant_temp_c"]),
            "0106": (lambda p, x: one_byte(p, 128 + x * 128 / 100), v["st_trim_pct"]),
            "0107": (lambda p, x: one_byte(p, 128 + x * 128 / 100), v["lt_trim_pct"]),
            "010A": (lambda p, x: one_byte(p, x / 3), v["fuel_pressure_kpa"]),
            "010B": (one_byte, v["intake_pressure_kpa"]),
            "010C": (lambda p, x: two_byte(p, x * 4), v["rpm"]),
            "010D": (one_byte, v["speed_kmh"]),
            "010E": (lambda p, x: one_byte(p, (x + 64) * 2), v["timing_advance"]),
            "010F": (lambda p, x: one_byte(p, x + 40), v["intake_temp_c"]),
            "0110": (lambda p, x: two_byte(p, x * 100), v["maf_gps"]),
            "0111": (lambda p, x: one_byte(p, x * 255 / 100), v["throttle_pct"]),
            "011C": (one_byte, v["obd_standard"]),
            "011F": (two_byte, v["engine_run_time_s"]),
            "0121": (two_byte, v["distance_mil_km"]),
            "012F": (lambda p, x: one_byte(p, x * 255 / 100), v["fuel_level_pct"]),
            "0130": (one_byte, v["warmups"]),
            "0131": (two_byte, v["distance_cleared_km"]),
            "0133": (one_byte, v["baro_kpa"]),
            "0142": (lambda p, x: two_byte(p, x * 1000), v["battery_v"]),
            "0145": (lambda p, x: one_byte(p, x * 255 / 100), v["rel_throttle_pct"]),
            "0146": (lambda p, x: one_byte(p, x + 40), v["ambient_temp_c"]),
            "014D": (two_byte, v["time_mil_min"]),
            "014E": (two_byte, v["time_cleared_min"]),
            "0151": (one_byte, v["fuel_type"]),
        }
        if cmd in pid_map:
            fn, val = pid_map[cmd]
            hex_resp = fn(cmd, val)
            return (hex_resp, {"command": cmd, "raw": hex_resp, "value": val})

        # 01A6 Odometer (4 bytes)
        if cmd == "01A6":
            km = int(v["odometer_km"] * 10)
            a = (km >> 24) & 0xFF
            b = (km >> 16) & 0xFF
            c = (km >> 8) & 0xFF
            d = km & 0xFF
            hex_resp = f"41 A6 {a:02X} {b:02X} {c:02X} {d:02X}"
            return (hex_resp, {"command": "01A6", "odometer_km": v["odometer_km"], "raw": hex_resp})

        return ("NO DATA", {"command": cmd, "raw": "NO DATA"})


def _obd_line(cmd: str, response: str) -> str:
    """Full line to send: response + prompt."""
    return response + "\r\r>"


# --- Session logging and ground truth ---


class SessionLogger:
    def __init__(self, session_id: str):
        self.session_id = session_id
        self.started_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        self.ended_at: str | None = None
        self.command_log: list[dict] = []
        self.connection_events: list[dict] = []

    def log_command(self, command: str, response_value: dict):
        self.command_log.append(
            {"ts": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"), "command": command, "response": response_value}
        )

    def log_connect(self, peer: str = ""):
        self.connection_events.append(
            {"ts": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"), "event": "connect", "peer": peer}
        )

    def log_disconnect(self, peer: str = ""):
        self.connection_events.append(
            {"ts": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"), "event": "disconnect", "peer": peer}
        )
        self.ended_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    def to_ground_truth(self) -> dict:
        return {
            "session_id": self.session_id,
            "started_at": self.started_at,
            "ended_at": self.ended_at,
            "commands": self.command_log,
            "connection_events": self.connection_events,
        }

    def write_ground_truth_file(self, out_dir: Path):
        out_dir.mkdir(parents=True, exist_ok=True)
        path = out_dir / f"simulator_ground_truth_{self.session_id}.json"
        with open(path, "w") as f:
            json.dump(self.to_ground_truth(), f, indent=2)
        return path


# --- TCP server ---


def handle_tcp_client(
    conn: socket.socket,
    addr,
    engine: PayloadEngine,
    scans_dir: Path,
):
    session_id = str(uuid.uuid4())
    logger = SessionLogger(session_id)
    logger.log_connect(peer=f"{addr[0]}:{addr[1]}")
    buf = b""
    try:
        while True:
            data = conn.recv(1024)
            if not data:
                break
            buf += data
            while b"\r" in buf or b"\n" in buf:
                line, _, buf = buf.partition(b"\r")
                if not line:
                    line, _, buf = buf.partition(b"\n")
                else:
                    buf = buf.lstrip(b"\n")
                cmd = line.decode("ascii", errors="replace").strip()
                if not cmd:
                    continue
                resp_line, truth = engine.response(cmd)
                logger.log_command(cmd, truth)
                to_send = _obd_line(cmd, resp_line)
                conn.send(to_send.encode("ascii"))
    except (ConnectionResetError, BrokenPipeError, OSError):
        pass
    finally:
        logger.log_disconnect(peer=f"{addr[0]}:{addr[1]}")
        path = logger.write_ground_truth_file(scans_dir)
        print(f"[Session {session_id[:8]}] Ground truth written to {path}")
        conn.close()


def run_tcp_server(host: str, port: int, engine: PayloadEngine, scans_dir: Path):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((host, port))
    sock.listen(1)
    print(f"OBD Simulator TCP listening on {host}:{port} (scenario: {engine.v.get('vin', 'healthy')[:17]})")
    print("Connect app or WIFI_SCAN_FULL to this host. Ground truth saved on disconnect.")
    while True:
        conn, addr = sock.accept()
        print(f"Client connected: {addr[0]}:{addr[1]}")
        threading.Thread(
            target=handle_tcp_client,
            args=(conn, addr, engine, scans_dir),
            daemon=True,
        ).start()


# --- Serial mode (ELM327-style line protocol) ---


def run_serial_mode(serial_port: str, engine: PayloadEngine, scans_dir: Path):
    try:
        import serial
    except ImportError:
        print("Serial mode requires pyserial: pip3 install pyserial")
        sys.exit(1)
    session_id = str(uuid.uuid4())
    logger = SessionLogger(session_id)
    logger.log_connect(peer=serial_port)
    try:
        ser = serial.Serial(serial_port, 38400, timeout=0.5)
    except Exception as e:
        print(f"Failed to open {serial_port}: {e}")
        sys.exit(1)
    print(f"OBD Simulator Serial on {serial_port} (session {session_id[:8]})")
    print("Adapter expectation: ELM327-style line protocol. Send one command per line (e.g. ATZ\\r, 010C\\r).")
    buf = b""
    try:
        while True:
            if ser.in_waiting:
                buf += ser.read(ser.in_waiting)
            while b"\r" in buf or b"\n" in buf:
                line, _, buf = buf.partition(b"\r")
                if not line:
                    line, _, buf = buf.partition(b"\n")
                else:
                    buf = buf.lstrip(b"\n")
                cmd = line.decode("ascii", errors="replace").strip()
                if not cmd:
                    continue
                resp_line, truth = engine.response(cmd)
                logger.log_command(cmd, truth)
                to_send = _obd_line(cmd, resp_line)
                ser.write(to_send.encode("ascii"))
            time.sleep(0.02)
    except (KeyboardInterrupt, serial.SerialException):
        pass
    finally:
        logger.log_disconnect(peer=serial_port)
        logger.ended_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        path = logger.write_ground_truth_file(scans_dir)
        print(f"Ground truth written to {path}")
        ser.close()


# --- CLI ---


def main():
    ap = argparse.ArgumentParser(description="MintCheck OBD-II Simulator (TCP or Serial)")
    ap.add_argument("--mode", choices=["tcp", "serial"], default="tcp")
    ap.add_argument("--port", type=int, default=35000)
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--serial-port", default="")
    ap.add_argument("--vin", default="", help="Override VIN (17 chars)")
    ap.add_argument("--scenario", choices=list(SCENARIOS), default="healthy")
    ap.add_argument("--scans-dir", type=Path, default=SCANS_DIR, help="Ground truth output directory")
    args = ap.parse_args()

    vin_override = args.vin if len(args.vin) >= 17 else (args.vin or None)
    engine = PayloadEngine(args.scenario, vin_override)

    if args.mode == "tcp":
        run_tcp_server(args.host, args.port, engine, args.scans_dir)
    else:
        if not args.serial_port:
            print("Serial mode requires --serial-port (e.g. /dev/cu.usbserial-XXXX)")
            sys.exit(1)
        run_serial_mode(args.serial_port, engine, args.scans_dir)


if __name__ == "__main__":
    main()
