#!/usr/bin/env python3
"""
MintCheck WiFi OBD-II Scanner
Run this while connected to the OBD2 WiFi network

Usage:
  python3 WIFI_SCAN.py
"""

import socket
import time

# WiFi OBD2 settings (common defaults)
HOST = '192.168.0.10'
PORT = 35000

def send_command(sock, cmd, delay=0.5):
    """Send command and get response"""
    sock.send((cmd + '\r').encode())
    time.sleep(delay)
    try:
        response = sock.recv(1024).decode('ascii', errors='replace').strip()
        return response
    except:
        return ''

def parse_hex_bytes(raw):
    """Extract hex bytes from response, handling both spaced and non-spaced formats"""
    # Clean the response
    clean = raw.replace('>', '').replace('\r', '').replace('\n', '').strip()
    
    # Remove the command echo if present
    for prefix in ['03', '010C', '0105', '010D', '0111', '012F', '0142', '010F']:
        if clean.startswith(prefix):
            clean = clean[len(prefix):]
    
    # Remove spaces
    clean = clean.replace(' ', '').upper()
    
    # Extract pairs of hex characters
    bytes_list = []
    for i in range(0, len(clean), 2):
        if i+1 < len(clean):
            try:
                bytes_list.append(int(clean[i:i+2], 16))
            except:
                pass
    
    return bytes_list, clean

def parse_response(pid, raw):
    """Parse raw hex response into human-readable value"""
    bytes_list, clean = parse_hex_bytes(raw)
    
    # Check for errors or searching
    if 'SEARCHING' in raw.upper() or 'ERROR' in raw.upper() or 'UNABLE' in raw.upper():
        return '(device searching for protocol...)', raw
    
    if 'NO DATA' in raw.upper():
        return '(no data)', raw
    
    try:
        if pid == '03':  # DTCs
            # Response format: 43 XX YY ZZ... where 43 is response header
            if len(bytes_list) >= 2 and bytes_list[0] == 0x43:
                if bytes_list[1] == 0x00 or (len(bytes_list) == 2 and bytes_list[1] == 0x00):
                    return '✅ No trouble codes - car is healthy!', raw
                else:
                    # Parse DTC codes
                    return f'⚠️ DTCs may be present: {clean}', raw
            elif '4300' in clean:
                return '✅ No trouble codes - car is healthy!', raw
            return f'DTCs: {clean}', raw
        
        elif pid == '010C':  # RPM
            # Response: 41 0C XX YY -> RPM = ((XX * 256) + YY) / 4
            if len(bytes_list) >= 4 and bytes_list[0] == 0x41 and bytes_list[1] == 0x0C:
                a, b = bytes_list[2], bytes_list[3]
                rpm = ((a * 256) + b) / 4
                return f'{rpm:.0f} RPM', raw
        
        elif pid == '0105':  # Coolant Temp
            # Response: 41 05 XX -> Temp = XX - 40 (Celsius)
            if len(bytes_list) >= 3 and bytes_list[0] == 0x41 and bytes_list[1] == 0x05:
                temp_c = bytes_list[2] - 40
                temp_f = (temp_c * 9/5) + 32
                return f'{temp_c}°C / {temp_f:.0f}°F', raw
        
        elif pid == '010D':  # Speed
            # Response: 41 0D XX -> Speed = XX km/h
            if len(bytes_list) >= 3 and bytes_list[0] == 0x41 and bytes_list[1] == 0x0D:
                speed_kmh = bytes_list[2]
                speed_mph = speed_kmh * 0.621371
                return f'{speed_kmh} km/h / {speed_mph:.0f} mph', raw
        
        elif pid == '0111':  # Throttle
            # Response: 41 11 XX -> Throttle = (XX / 255) * 100
            if len(bytes_list) >= 3 and bytes_list[0] == 0x41 and bytes_list[1] == 0x11:
                throttle = (bytes_list[2] / 255) * 100
                return f'{throttle:.1f}%', raw
        
        elif pid == '012F':  # Fuel Level
            # Response: 41 2F XX -> Fuel = (XX / 255) * 100
            if len(bytes_list) >= 3 and bytes_list[0] == 0x41 and bytes_list[1] == 0x2F:
                fuel = (bytes_list[2] / 255) * 100
                return f'{fuel:.1f}%', raw
        
        elif pid == '0142':  # Battery Voltage
            # Response: 41 42 XX YY -> Voltage = ((XX * 256) + YY) / 1000
            if len(bytes_list) >= 4 and bytes_list[0] == 0x41 and bytes_list[1] == 0x42:
                a, b = bytes_list[2], bytes_list[3]
                voltage = ((a * 256) + b) / 1000
                return f'{voltage:.2f}V', raw
        
        elif pid == '010F':  # Intake Air Temp
            # Response: 41 0F XX -> Temp = XX - 40 (Celsius)
            if len(bytes_list) >= 3 and bytes_list[0] == 0x41 and bytes_list[1] == 0x0F:
                temp_c = bytes_list[2] - 40
                temp_f = (temp_c * 9/5) + 32
                return f'{temp_c}°C / {temp_f:.0f}°F', raw
    except Exception as e:
        pass
    
    return f'(parse error: {clean})', raw

def main():
    print("=" * 50)
    print("🚗 MintCheck WiFi OBD-II Scanner")
    print("=" * 50)
    print()
    
    # Try common IP/port combinations
    configs = [
        ('192.168.0.10', 35000),
        ('192.168.0.10', 23),
        ('192.168.1.10', 35000),
        ('192.168.1.1', 35000),
    ]
    
    sock = None
    for host, port in configs:
        print(f"Trying {host}:{port}...", end=' ')
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            sock.connect((host, port))
            print("✓ Connected!")
            break
        except Exception as e:
            print(f"✗")
            sock = None
    
    if not sock:
        print()
        print("❌ Could not connect to OBD2 adapter")
        print()
        print("Troubleshooting:")
        print("  1. Make sure you're connected to 'wifi obdii' network")
        print("  2. Make sure car ignition is ON")
        print("  3. Try unplugging/replugging the OBD2 adapter")
        return
    
    print()
    
    # Initialize
    print("Initializing device...")
    response = send_command(sock, 'ATZ', 1.5)
    if 'ELM' in response:
        print(f"✓ Device: ELM327 detected")
    else:
        print(f"? Response: {response}")
    
    # Configure
    print("Configuring...")
    send_command(sock, 'ATE0', 0.2)  # Echo off
    send_command(sock, 'ATL0', 0.2)  # Linefeeds off  
    send_command(sock, 'ATS1', 0.2)  # Spaces ON (easier parsing)
    send_command(sock, 'ATH0', 0.2)  # Headers off
    send_command(sock, 'ATSP0', 1.0)  # Auto protocol - needs time!
    
    # Do a dummy read to let protocol detection complete
    print("Detecting vehicle protocol...")
    send_command(sock, '0100', 2.0)  # Query supported PIDs - triggers protocol detection
    
    print()
    print("-" * 50)
    print("📊 SCAN RESULTS")
    print("-" * 50)
    print()
    
    # Scan PIDs
    pids = [
        ('03', 'Trouble Codes (DTCs)'),
        ('010C', 'Engine RPM'),
        ('0105', 'Coolant Temperature'),
        ('010D', 'Vehicle Speed'),
        ('0111', 'Throttle Position'),
        ('012F', 'Fuel Level'),
        ('0142', 'Battery Voltage'),
        ('010F', 'Intake Air Temp'),
    ]
    
    for pid, name in pids:
        raw = send_command(sock, pid, 0.7)
        value, _ = parse_response(pid, raw)
        print(f"  {name:25} {value}")
    
    sock.close()
    
    print()
    print("=" * 50)
    print("✅ Scan complete!")
    print("=" * 50)

if __name__ == '__main__':
    main()
