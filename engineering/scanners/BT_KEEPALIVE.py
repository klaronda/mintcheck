#!/usr/bin/env python3
"""
MintCheck Bluetooth OBD-II Scanner – Persistent Keep-Alive Edition

Keeps a Bluetooth OBD connection alive indefinitely so it doesn't drop.
Watches for the BT serial port, auto-connects, sends AT keep-alive
every 2 seconds, and lets you trigger a full scan with Enter.

Usage:
  python3 BT_KEEPALIVE.py

  Then just leave it running. It will:
    1. Wait for the BT OBD adapter to appear
    2. Connect and hold the link with keep-alive pings
    3. Press Enter to run a full scan at any time
    4. Auto-reconnect if the connection drops

  Press Ctrl+C to quit.

Requirements:
  pip3 install pyserial
"""

import serial
import serial.tools.list_ports
import time
import threading
import sys
import json
from datetime import datetime
from pathlib import Path

KEEPALIVE_INTERVAL = 2.0  # seconds between AT pings
PORT_POLL_INTERVAL = 2.0  # seconds between port-detection polls
SCAN_CMD_DELAY = 1.2  # seconds to wait for BT OBD response (longer than keep-alive)
# Many BT ELM327 clones expect \r\n and return "?" for \r-only; use \r\n for OBD commands
OBD_LINE_ENDING = '\r\n'
BAUD_RATES = [9600, 38400, 115200]  # 9600 first – many BT OBD adapters default to it
CONNECT_RETRY_DELAYS = [2, 4, 6]    # seconds between connection attempts
SCAN_DIR = Path(__file__).resolve().parent.parent / "scans"

# ──────────────────────────────────────────────
# Port detection (same logic as BT_SCAN.py)
# ──────────────────────────────────────────────

def find_obd_port():
    ports = serial.tools.list_ports.comports()
    priority_names = ['obdii', 'veepeak']
    for port in ports:
        if any(p in port.device.lower() for p in priority_names):
            return port.device
    for port in ports:
        combined = (port.device + ' ' + port.description).lower()
        if any(k in combined for k in ['obd', 'elm']):
            return port.device
    return None


def wait_for_port():
    """Block until a BT OBD serial port appears. Returns port path."""
    shown_waiting = False
    while True:
        port = find_obd_port()
        if port:
            return port
        if not shown_waiting:
            print("\n⏳ Waiting for Bluetooth OBD device...")
            print("   Pair your adapter in System Settings → Bluetooth")
            shown_waiting = True
        time.sleep(PORT_POLL_INTERVAL)

# ──────────────────────────────────────────────
# Serial helpers
# ──────────────────────────────────────────────

def send_command(ser, cmd, delay=0.5, line_ending='\r'):
    ser.reset_input_buffer()
    ser.write((cmd + line_ending).encode())
    time.sleep(delay)
    try:
        return ser.read(ser.in_waiting or 500).decode('ascii', errors='replace').strip()
    except Exception:
        return ''


def open_connection(port):
    """Try each baud rate. Returns (serial, device_id) or (None, None)."""
    for baud in BAUD_RATES:
        try:
            ser = serial.Serial(port, baud, timeout=2)
            time.sleep(1.0)  # let BT adapter settle before ATZ
            resp = send_command(ser, 'ATZ', 1.5)
            if 'ELM' in resp:
                device_id = 'ELM' + resp.split('ELM')[1].split()[0]
                for cmd in ['ATE0', 'ATL0', 'ATS0', 'ATH0', 'ATSP0']:
                    send_command(ser, cmd, 0.2)
                return ser, device_id
            ser.close()
        except Exception:
            pass
    return None, None

# ──────────────────────────────────────────────
# Keep-alive thread
# ──────────────────────────────────────────────

class KeepAlive:
    def __init__(self, ser):
        self._ser = ser
        self._stop = threading.Event()
        self._lock = threading.Lock()
        self._thread = None
        self._alive = False
        self._pings = 0

    @property
    def alive(self):
        return self._alive

    @property
    def pings(self):
        return self._pings

    def start(self):
        self._stop.clear()
        self._alive = True
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self):
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=5)
        self._alive = False

    def pause(self):
        """Pause keep-alive and acquire serial lock (for scanning)."""
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=5)
        self._lock.acquire()

    def resume(self):
        """Release serial lock and restart keep-alive."""
        self._lock.release()
        self._stop.clear()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def _run(self):
        while not self._stop.wait(KEEPALIVE_INTERVAL):
            with self._lock:
                try:
                    self._ser.reset_input_buffer()
                    self._ser.write(b'AT\r')
                    time.sleep(0.1)
                    resp = self._ser.read(self._ser.in_waiting or 64)
                    if resp:
                        self._pings += 1
                        self._alive = True
                    else:
                        self._alive = False
                        return
                except Exception:
                    self._alive = False
                    return

# ──────────────────────────────────────────────
# Detect AT/banner responses (not OBD data) – avoid saving as real values
# ──────────────────────────────────────────────

def is_at_or_banner_response(raw):
    """True if response looks like ATZ/ELM327 banner, OK, or prompt – not OBD PID data."""
    if not raw or len(raw) < 2:
        return True
    s = raw.upper().replace('\r', ' ').replace('\n', ' ')
    return any(x in s for x in ('ELM327', 'ELM', 'ATZ', 'OK', 'NO DATA', 'UNABLE TO CONNECT', 'SEARCHING', '?'))


def drain_until_prompt(ser, timeout=0.5, max_reads=20):
    """Read and discard until we see '>' (prompt) or no data for a bit."""
    deadline = time.time() + timeout
    saw_prompt = False
    while time.time() < deadline and max_reads > 0:
        time.sleep(0.05)
        n = ser.in_waiting
        if n:
            buf = ser.read(n)
            if b'>' in buf:
                saw_prompt = True
        else:
            if saw_prompt:
                break
        max_reads -= 1
    ser.reset_input_buffer()


# ──────────────────────────────────────────────
# PID parsing (same as BT_SCAN.py)
# ──────────────────────────────────────────────

def parse_pid(pid, raw):
    if is_at_or_banner_response(raw):
        return None
    clean = raw.replace('>', '').replace('\r', ' ').strip()
    parts = clean.split()
    if len(parts) < 3:
        return None
    try:
        if pid == '03':
            if '43 00' in clean or (len(parts) >= 2 and parts[1] == '00'):
                return '✅ No trouble codes'
            else:
                return f'⚠️ DTCs: {clean}'
        elif pid == '010C':
            if len(parts) >= 4:
                a, b = int(parts[2], 16), int(parts[3], 16)
                return f'{((a * 256) + b) / 4:.0f} RPM'
        elif pid == '0105':
            if len(parts) >= 3:
                c = int(parts[2], 16) - 40
                return f'{c}°C / {(c * 9/5) + 32:.0f}°F'
        elif pid == '010D':
            if len(parts) >= 3:
                k = int(parts[2], 16)
                return f'{k} km/h / {k * 0.621371:.0f} mph'
        elif pid == '0111':
            if len(parts) >= 3:
                return f'{(int(parts[2], 16) / 255) * 100:.1f}%'
        elif pid == '012F':
            if len(parts) >= 3:
                return f'{(int(parts[2], 16) / 255) * 100:.1f}%'
        elif pid == '0142':
            if len(parts) >= 4:
                a, b = int(parts[2], 16), int(parts[3], 16)
                return f'{((a * 256) + b) / 1000:.2f}V'
        elif pid == '010F':
            if len(parts) >= 3:
                c = int(parts[2], 16) - 40
                return f'{c}°C / {(c * 9/5) + 32:.0f}°F'
    except Exception:
        pass
    return None

# ──────────────────────────────────────────────
# Full scan
# ──────────────────────────────────────────────

PIDS = [
    ('03',   'Trouble Codes (DTCs)'),
    ('010C', 'Engine RPM'),
    ('0105', 'Coolant Temperature'),
    ('010D', 'Vehicle Speed'),
    ('0111', 'Throttle Position'),
    ('012F', 'Fuel Level'),
    ('0142', 'Battery Voltage'),
    ('010F', 'Intake Air Temp'),
]


def run_scan(ser):
    # Re-establish OBD mode and drain until adapter is idle (reduces ATZ bleed-through)
    ser.reset_input_buffer()
    send_command(ser, 'ATSP0', 0.8, line_ending=OBD_LINE_ENDING)
    drain_until_prompt(ser, timeout=0.6)
    time.sleep(0.2)

    print()
    print("-" * 50)
    print("📊 SCAN RESULTS")
    print("-" * 50)
    print()

    results = {}
    for pid, name in PIDS:
        raw = send_command(ser, pid, SCAN_CMD_DELAY, line_ending=OBD_LINE_ENDING)
        value = parse_pid(pid, raw)
        # If we got AT/banner instead of OBD data, drain and retry once (flaky BT)
        if not value and raw and is_at_or_banner_response(raw):
            drain_until_prompt(ser, timeout=0.3)
            time.sleep(0.15)
            raw = send_command(ser, pid, SCAN_CMD_DELAY, line_ending=OBD_LINE_ENDING)
            value = parse_pid(pid, raw)
        results[name] = value or '—'
        display = value or '—'
        if not value and raw and not is_at_or_banner_response(raw):
            display = f"{display}  (raw: {raw[:60]!r})"
        print(f"  {name:25} {display}")

    # Save JSON
    SCAN_DIR.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = SCAN_DIR / f"scan_bt_{ts}.json"
    with open(path, 'w') as f:
        json.dump({"scan_time": datetime.now().isoformat(), "device": "BT_KEEPALIVE", "results": results}, f, indent=2)
    print()
    print(f"  💾 Saved → {path}")
    print()
    return results

# ──────────────────────────────────────────────
# Input listener (non-blocking Enter detection)
# ──────────────────────────────────────────────

class ScanTrigger:
    def __init__(self):
        self._triggered = threading.Event()
        self._quit = threading.Event()
        self._thread = threading.Thread(target=self._listen, daemon=True)
        self._thread.start()

    def _listen(self):
        while not self._quit.is_set():
            try:
                line = input()
                self._triggered.set()
            except EOFError:
                self._quit.set()
                return

    def wait(self, timeout=None):
        return self._triggered.wait(timeout=timeout)

    def clear(self):
        self._triggered.clear()

    @property
    def should_quit(self):
        return self._quit.is_set()

# ──────────────────────────────────────────────
# Main loop
# ──────────────────────────────────────────────

def main():
    print("=" * 55)
    print("🔵 MintCheck Bluetooth OBD-II – Keep-Alive Mode")
    print("=" * 55)
    print()
    print("This script keeps your BT OBD connection alive.")
    print("Press Enter at any time to run a full scan.")
    print("Press Ctrl+C to quit.")
    print()

    trigger = ScanTrigger()

    while True:
        # Phase 1: wait for BT port
        port = wait_for_port()
        print(f"\n✓ Found port: {port}")

        # Phase 2: connect (retry with backoff)
        print("  Connecting...", end=' ', flush=True)
        ser, device_id = None, None
        for attempt, wait in enumerate(CONNECT_RETRY_DELAYS):
            ser, device_id = open_connection(port)
            if ser:
                break
            print("✗ Could not connect.", end=' ', flush=True)
            if attempt < len(CONNECT_RETRY_DELAYS) - 1:
                print(f"Retrying in {wait}s...")
                time.sleep(wait)
            else:
                print("Retrying from port detection...")
                time.sleep(wait)
        if not ser:
            continue
        print(f"✓ {device_id}")

        # Phase 3: keep-alive loop
        ka = KeepAlive(ser)
        ka.start()
        print(f"  🟢 Keep-alive active (ping every {KEEPALIVE_INTERVAL:.0f}s)")
        print(f"  Press Enter to scan ...")
        print()

        try:
            while ka.alive:
                if trigger.wait(timeout=1.0):
                    trigger.clear()
                    ka.pause()
                    try:
                        run_scan(ser)
                    finally:
                        ka.resume()
                    print("  🟢 Keep-alive resumed. Press Enter to scan again ...")

                if trigger.should_quit:
                    raise KeyboardInterrupt

                # Status heartbeat every ~30 pings (60s)
                if ka.pings > 0 and ka.pings % 30 == 0:
                    print(f"  ♥ Connection alive ({ka.pings} pings sent)")

        except KeyboardInterrupt:
            print("\n\n👋 Shutting down...")
            ka.stop()
            ser.close()
            sys.exit(0)

        # If we got here, keep-alive detected a drop
        ka.stop()
        try:
            ser.close()
        except Exception:
            pass
        print("\n  🔴 Connection lost. Will auto-reconnect...")
        time.sleep(2)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Bye!")
        sys.exit(0)
