#!/usr/bin/env python3
"""
MintCheck WiFi OBD-II Scanner - FULL VERSION
Pulls ALL available data from the vehicle

Usage:
  python3 WIFI_SCAN_FULL.py
"""

import socket
import time
import json
from datetime import datetime

HOST = '192.168.0.10'
PORT = 35000

def send_command(sock, cmd, delay=0.5):
    """Send command and get response"""
    sock.send((cmd + '\r').encode())
    time.sleep(delay)
    try:
        response = sock.recv(4096).decode('ascii', errors='replace').strip()
        return response
    except:
        return ''

def parse_hex_bytes(raw):
    """Extract hex bytes from response"""
    clean = raw.replace('>', '').replace('\r', '').replace('\n', '').strip()
    clean = clean.replace(' ', '').upper()
    
    # Find the response part (starts with 41, 43, 49, etc.)
    for marker in ['41', '43', '49']:
        if marker in clean:
            idx = clean.find(marker)
            clean = clean[idx:]
            break
    
    bytes_list = []
    for i in range(0, len(clean), 2):
        if i+1 < len(clean):
            try:
                bytes_list.append(int(clean[i:i+2], 16))
            except:
                pass
    return bytes_list, clean

def parse_vin(raw):
    """Parse VIN from Mode 09 PID 02 response"""
    clean = raw.replace('>', '').replace('\r', ' ').replace('\n', ' ').strip()
    vin_chars = []
    parts = clean.split()
    
    in_vin = False
    skip_next = 0
    for i, part in enumerate(parts):
        if skip_next > 0:
            skip_next -= 1
            continue
        if part == '49' and i+1 < len(parts) and parts[i+1] == '02':
            in_vin = True
            skip_next = 2  # Skip 49 02 XX
            continue
        if in_vin:
            try:
                val = int(part, 16)
                if 48 <= val <= 57 or 65 <= val <= 90:
                    vin_chars.append(chr(val))
            except:
                pass
    
    if len(vin_chars) >= 17:
        return ''.join(vin_chars[:17])
    elif len(vin_chars) > 0:
        return ''.join(vin_chars)
    return None

# PID Definitions with formulas
PIDS = {
    # Mode 01 - Live Data
    '0100': {'name': 'Supported PIDs [01-20]', 'type': 'bitmap'},
    '0101': {'name': 'Monitor Status', 'type': 'special'},
    '0103': {'name': 'Fuel System Status', 'type': 'enum', 
             'values': {1: 'Open loop', 2: 'Closed loop', 4: 'Open loop (driving)', 8: 'Open loop (fault)', 16: 'Closed loop (fault)'}},
    '0104': {'name': 'Engine Load', 'formula': lambda a: round(a * 100 / 255, 1), 'unit': '%'},
    '0105': {'name': 'Coolant Temp', 'formula': lambda a: a - 40, 'unit': '°C'},
    '0106': {'name': 'Short Term Fuel Trim B1', 'formula': lambda a: round((a - 128) * 100 / 128, 1), 'unit': '%'},
    '0107': {'name': 'Long Term Fuel Trim B1', 'formula': lambda a: round((a - 128) * 100 / 128, 1), 'unit': '%'},
    '010A': {'name': 'Fuel Pressure', 'formula': lambda a: a * 3, 'unit': 'kPa'},
    '010B': {'name': 'Intake Manifold Pressure', 'formula': lambda a: a, 'unit': 'kPa'},
    '010C': {'name': 'Engine RPM', 'formula': lambda a, b: round((a * 256 + b) / 4, 0), 'unit': 'RPM', 'bytes': 2},
    '010D': {'name': 'Vehicle Speed', 'formula': lambda a: a, 'unit': 'km/h'},
    '010E': {'name': 'Timing Advance', 'formula': lambda a: round(a / 2 - 64, 1), 'unit': '°'},
    '010F': {'name': 'Intake Air Temp', 'formula': lambda a: a - 40, 'unit': '°C'},
    '0110': {'name': 'MAF Air Flow', 'formula': lambda a, b: round((a * 256 + b) / 100, 2), 'unit': 'g/s', 'bytes': 2},
    '0111': {'name': 'Throttle Position', 'formula': lambda a: round(a * 100 / 255, 1), 'unit': '%'},
    '011C': {'name': 'OBD Standard', 'type': 'enum',
             'values': {1: 'OBD-II CARB', 2: 'OBD EPA', 3: 'OBD + OBD-II', 6: 'EOBD', 7: 'EOBD + OBD-II'}},
    '011F': {'name': 'Engine Run Time', 'formula': lambda a, b: a * 256 + b, 'unit': 'sec', 'bytes': 2},
    '0121': {'name': 'Distance with MIL On', 'formula': lambda a, b: a * 256 + b, 'unit': 'km', 'bytes': 2},
    '012F': {'name': 'Fuel Level', 'formula': lambda a: round(a * 100 / 255, 1), 'unit': '%'},
    '0130': {'name': 'Warmups Since Cleared', 'formula': lambda a: a, 'unit': 'count'},
    '0131': {'name': 'Distance Since Cleared', 'formula': lambda a, b: a * 256 + b, 'unit': 'km', 'bytes': 2},
    '0133': {'name': 'Barometric Pressure', 'formula': lambda a: a, 'unit': 'kPa'},
    '0142': {'name': 'Battery Voltage', 'formula': lambda a, b: round((a * 256 + b) / 1000, 2), 'unit': 'V', 'bytes': 2},
    '0145': {'name': 'Relative Throttle Pos', 'formula': lambda a: round(a * 100 / 255, 1), 'unit': '%'},
    '0146': {'name': 'Ambient Air Temp', 'formula': lambda a: a - 40, 'unit': '°C'},
    '014D': {'name': 'Time with MIL On', 'formula': lambda a, b: a * 256 + b, 'unit': 'min', 'bytes': 2},
    '014E': {'name': 'Time Since Cleared', 'formula': lambda a, b: a * 256 + b, 'unit': 'min', 'bytes': 2},
    '0151': {'name': 'Fuel Type', 'type': 'enum',
             'values': {0: 'N/A', 1: 'Gasoline', 2: 'Methanol', 3: 'Ethanol', 4: 'Diesel', 5: 'LPG', 6: 'CNG', 
                       8: 'Electric', 17: 'Hybrid Gasoline', 18: 'Hybrid Ethanol', 19: 'Hybrid Diesel', 
                       20: 'Hybrid Electric'}},
    '01A6': {'name': 'Odometer', 'formula': lambda a, b, c, d: round((a*16777216 + b*65536 + c*256 + d) / 10, 1), 'unit': 'km', 'bytes': 4},
    
    # Mode 03 - DTCs
    '03': {'name': 'Diagnostic Trouble Codes', 'type': 'dtc'},
}

def parse_pid(pid, raw):
    """Parse a PID response"""
    if 'NO DATA' in raw.upper() or 'ERROR' in raw.upper() or 'UNABLE' in raw.upper():
        return None
    if 'SEARCHING' in raw.upper():
        return None
    
    bytes_list, clean = parse_hex_bytes(raw)
    
    if pid not in PIDS:
        return None
    
    config = PIDS[pid]
    
    try:
        # DTC parsing
        if config.get('type') == 'dtc':
            if '4300' in clean or (len(bytes_list) >= 2 and bytes_list[0] == 0x43 and bytes_list[1] == 0x00):
                return {'value': 'None', 'display': '✅ No trouble codes'}
            else:
                return {'value': clean, 'display': f'⚠️ DTCs present: {clean}'}
        
        # Enum parsing
        if config.get('type') == 'enum':
            # Find the response byte (after 41 XX)
            if len(bytes_list) >= 3 and bytes_list[0] == 0x41:
                val = bytes_list[2]
                values = config.get('values', {})
                return {'value': val, 'display': values.get(val, f'Unknown ({val})')}
        
        # Bitmap parsing
        if config.get('type') == 'bitmap':
            if len(bytes_list) >= 6 and bytes_list[0] == 0x41:
                supported = bytes_list[2:6]
                return {'value': supported, 'display': f'{supported[0]:08b} {supported[1]:08b} {supported[2]:08b} {supported[3]:08b}'}
        
        # Formula-based parsing
        if 'formula' in config:
            num_bytes = config.get('bytes', 1)
            if len(bytes_list) >= 2 + num_bytes and bytes_list[0] == 0x41:
                if num_bytes == 1:
                    val = config['formula'](bytes_list[2])
                elif num_bytes == 2:
                    val = config['formula'](bytes_list[2], bytes_list[3])
                elif num_bytes == 4:
                    val = config['formula'](bytes_list[2], bytes_list[3], bytes_list[4], bytes_list[5])
                else:
                    return None
                
                unit = config.get('unit', '')
                return {'value': val, 'unit': unit, 'display': f'{val} {unit}'}
    except Exception as e:
        pass
    
    return None

def main():
    print("=" * 65)
    print("🚗 MintCheck WiFi OBD-II Scanner - COMPREHENSIVE SCAN")
    print("=" * 65)
    print()
    
    # Connect
    sock = None
    for host, port in [('192.168.0.10', 35000), ('192.168.0.10', 23)]:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            sock.connect((host, port))
            print(f"✓ Connected to {host}:{port}")
            break
        except:
            sock = None
    
    if not sock:
        print("❌ Could not connect. Make sure you're on the OBD2 WiFi network.")
        return
    
    # Initialize
    print("Initializing device...")
    init_resp = send_command(sock, 'ATZ', 1.5)
    elm_version = 'Unknown'
    if 'ELM327' in init_resp:
        elm_version = 'ELM327 ' + init_resp.split('ELM327')[-1].strip().split()[0] if 'ELM327' in init_resp else 'Unknown'
        print(f"✓ Device: {elm_version}")
    
    send_command(sock, 'ATE0', 0.2)
    send_command(sock, 'ATL0', 0.2)
    send_command(sock, 'ATS1', 0.2)
    send_command(sock, 'ATH0', 0.2)
    send_command(sock, 'ATSP0', 1.0)
    
    # Get protocol
    proto_resp = send_command(sock, 'ATDPN', 0.5)
    protocol = proto_resp.replace('>', '').strip() if proto_resp else 'Unknown'
    print(f"✓ Protocol: {protocol}")
    
    # Trigger protocol detection
    send_command(sock, '0100', 2.0)
    
    results = {
        'scan_time': datetime.now().isoformat(),
        'device': elm_version,
        'protocol': protocol,
        'data': {}
    }
    
    # ============ VEHICLE IDENTIFICATION ============
    print()
    print("-" * 65)
    print("🔍 VEHICLE IDENTIFICATION")
    print("-" * 65)
    
    # VIN
    vin_raw = send_command(sock, '0902', 2.0)
    vin = parse_vin(vin_raw)
    results['vin'] = vin
    print(f"  VIN:                         {vin if vin else '(not available)'}")
    
    # Odometer
    odo_result = parse_pid('01A6', send_command(sock, '01A6', 1.0))
    if odo_result:
        odo_km = odo_result['value']
        odo_mi = round(odo_km * 0.621371, 1)
        results['odometer_km'] = odo_km
        results['odometer_mi'] = odo_mi
        print(f"  Odometer:                    {odo_km:,.1f} km / {odo_mi:,.1f} mi")
    else:
        print(f"  Odometer:                    (not supported)")
    
    # Fuel Type
    fuel_result = parse_pid('0151', send_command(sock, '0151', 0.7))
    if fuel_result:
        results['fuel_type'] = fuel_result['display']
        print(f"  Fuel Type:                   {fuel_result['display']}")
    else:
        print(f"  Fuel Type:                   (not available)")
    
    # OBD Standard
    obd_result = parse_pid('011C', send_command(sock, '011C', 0.7))
    if obd_result:
        results['obd_standard'] = obd_result['display']
        print(f"  OBD Standard:                {obd_result['display']}")
    
    # ============ DIAGNOSTIC CODES ============
    print()
    print("-" * 65)
    print("🔧 DIAGNOSTIC TROUBLE CODES")
    print("-" * 65)
    
    dtc_result = parse_pid('03', send_command(sock, '03', 1.0))
    if dtc_result:
        results['dtcs'] = dtc_result['value']
        print(f"  Status:                      {dtc_result['display']}")
    else:
        print(f"  Status:                      (could not read)")
    
    # ============ ENGINE & PERFORMANCE ============
    print()
    print("-" * 65)
    print("⚡ ENGINE & PERFORMANCE")
    print("-" * 65)
    
    engine_pids = ['010C', '0104', '0105', '010F', '010E', '0110', '010B']
    for pid in engine_pids:
        if pid in PIDS:
            result = parse_pid(pid, send_command(sock, pid, 0.7))
            name = PIDS[pid]['name']
            if result:
                results['data'][pid] = result['value']
                # Add Fahrenheit for temps
                if '°C' in result.get('unit', ''):
                    temp_f = round(result['value'] * 9/5 + 32, 0)
                    print(f"  {name:28} {result['display']} / {temp_f}°F")
                else:
                    print(f"  {name:28} {result['display']}")
            else:
                print(f"  {name:28} —")
    
    # ============ FUEL & EMISSIONS ============
    print()
    print("-" * 65)
    print("⛽ FUEL & EMISSIONS")
    print("-" * 65)
    
    fuel_pids = ['012F', '0103', '0106', '0107', '010A', '0133']
    for pid in fuel_pids:
        if pid in PIDS:
            result = parse_pid(pid, send_command(sock, pid, 0.7))
            name = PIDS[pid]['name']
            if result:
                results['data'][pid] = result.get('value')
                print(f"  {name:28} {result['display']}")
            else:
                print(f"  {name:28} —")
    
    # ============ ELECTRICAL ============
    print()
    print("-" * 65)
    print("🔋 ELECTRICAL")
    print("-" * 65)
    
    elec_pids = ['0142', '0111', '0145']
    for pid in elec_pids:
        if pid in PIDS:
            result = parse_pid(pid, send_command(sock, pid, 0.7))
            name = PIDS[pid]['name']
            if result:
                results['data'][pid] = result['value']
                print(f"  {name:28} {result['display']}")
            else:
                print(f"  {name:28} —")
    
    # ============ ENVIRONMENTAL ============
    print()
    print("-" * 65)
    print("🌡️  ENVIRONMENTAL")
    print("-" * 65)
    
    env_pids = ['0146', '010D']
    for pid in env_pids:
        if pid in PIDS:
            result = parse_pid(pid, send_command(sock, pid, 0.7))
            name = PIDS[pid]['name']
            if result:
                results['data'][pid] = result['value']
                if '°C' in result.get('unit', ''):
                    temp_f = round(result['value'] * 9/5 + 32, 0)
                    print(f"  {name:28} {result['display']} / {temp_f}°F")
                else:
                    print(f"  {name:28} {result['display']}")
            else:
                print(f"  {name:28} —")
    
    # ============ MAINTENANCE INFO ============
    print()
    print("-" * 65)
    print("🔧 MAINTENANCE INFO")
    print("-" * 65)
    
    maint_pids = ['0121', '0131', '0130', '014D', '014E', '011F']
    for pid in maint_pids:
        if pid in PIDS:
            result = parse_pid(pid, send_command(sock, pid, 0.7))
            name = PIDS[pid]['name']
            if result:
                results['data'][pid] = result['value']
                val = result['value']
                unit = result.get('unit', '')
                
                # Convert time units
                if unit == 'min':
                    if val >= 60:
                        hours = val // 60
                        mins = val % 60
                        print(f"  {name:28} {hours}h {mins}m ({val} min)")
                    else:
                        print(f"  {name:28} {val} min")
                elif unit == 'sec':
                    if val >= 60:
                        mins = val // 60
                        secs = val % 60
                        print(f"  {name:28} {mins}m {secs}s")
                    else:
                        print(f"  {name:28} {val} sec")
                elif unit == 'km':
                    miles = round(val * 0.621371, 1)
                    print(f"  {name:28} {val} km / {miles} mi")
                else:
                    print(f"  {name:28} {result['display']}")
            else:
                print(f"  {name:28} —")
    
    sock.close()
    
    # ============ SUMMARY ============
    print()
    print("=" * 65)
    print("✅ SCAN COMPLETE!")
    print("=" * 65)
    
    if vin:
        print(f"\n📋 VIN: {vin}")
    
    # Save to JSON
    filename = f"scan_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(filename, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"📁 Results saved to: {filename}")

if __name__ == '__main__':
    main()
