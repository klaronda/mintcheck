# OBD Simulator

The simulator emulates a car ECU so you can test scanners and the MintCheck app without a real vehicle. It supports TCP (fake scanner) and serial (female OBD2 adapter).

## Modes

### TCP (default)

- Listens on `0.0.0.0:35000` (configurable). The app or `WIFI_SCAN_FULL.py` connects to your **computer’s IP** instead of a real scanner.
- One client at a time. Line-based ELM327 protocol: send one command per line (e.g. `ATZ\r`, `0902\r`), receive response + `\r\n>\r\n`.
- No female OBD2 hardware needed. Use when testing the app or Python scanners over WiFi.

### Serial (female OBD2)

- Uses a configurable serial port (e.g. USB female OBD2 adapter). The **scanner** is plugged into the female OBD2; the computer runs the simulator and drives the adapter so the bus carries our responses.
- Same response logic as TCP. The scanner (WiFi or Bluetooth) talks to the app as usual; the app sees whatever the scanner read from “the car” (our simulator).

## Serial adapter expectations

- **Protocol:** ELM327-style **line protocol**. The adapter is expected to present a serial port to the host. Each “request” is one line (commands like `ATZ`, `010C`, `0902`). The simulator sends one response line per command, ending with `\r\n>\r\n`.
- **Who sends what:** When the scanner (plugged into the female OBD2) sends an OBD request on the bus, the USB adapter may forward it to the computer as a line of text (e.g. `010C\r`). The simulator replies with a line (e.g. `41 0C 0B B8\r\r>`). The adapter then puts that reply on the bus so the scanner receives it.
- **Baud rate:** Default 38400; change in code if your adapter uses another rate.
- **Raw CAN:** If your adapter speaks raw CAN (ISO 15765-4) instead of text lines, the current script does not support that; you would need to add a serial path that parses binary frames and responds with the correct CAN IDs and data.

## Usage

```bash
# TCP (app or WIFI_SCAN_FULL connect to this machine’s IP)
python3 OBD_SIMULATOR.py
python3 OBD_SIMULATOR.py --port 35000 --scenario healthy

# Serial (scanner in female OBD2). Replace with your adapter's port (e.g. ls /dev/cu.*)
python3 OBD_SIMULATOR.py --mode serial --serial-port /dev/cu.usbserial-XXXX
```
If the port fails, the script prints available ports. You need a **data-capable** USB→female OBD2 adapter (not power-only like the Yeebline).

## Scenarios and ground truth

- `--scenario healthy|minor|serious`: Predefined value sets (VIN, RPM, DTCs, etc.).
- `--vin XXXXX`: Override VIN (17 characters).
- On each disconnect (TCP client or serial session end), the simulator writes a ground-truth JSON file to `engineering/scans/simulator_ground_truth_<session_id>.json`. Use that file with `eval_simulator_scan.py` to compare what we sent to what the scanner/app reported in Supabase.
