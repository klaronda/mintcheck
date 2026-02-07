#!/usr/bin/env python3
"""
MintCheck OBD-II Scanner - WORKING VERSION
This code successfully scanned a real car on 2026-01-17

Usage:
  python3 WORKING_SCAN.py

Requirements:
  pip3 install pyserial

Note: The Bluetooth ELM327 connection is unstable. 
      Recommend getting a WiFi OBD2 adapter for production use.
"""

import serial
import time

# Configuration
PORT = '/dev/cu.OBDII'  # Change this for your device
BAUD = 38400
TIMEOUT = 1

# PID Definitions
PIDS = {
    '03':   ('DTCs', 'Diagnostic Trouble Codes'),
    '010C': ('RPM', 'Engine RPM'),
    '0105': ('COOLANT', 'Coolant Temperature'),
    '010D': ('SPEED', 'Vehicle Speed'),
    '0111': ('THROTTLE', 'Throttle Position'),
    '012F': ('FUEL', 'Fuel Level'),
    '0142': ('VOLTAGE', 'Battery Voltage'),
    '010F': ('INTAKE_TEMP', 'Intake Air Temperature'),
}

def parse_response(pid, raw):
    """Parse raw hex response into human-readable value"""
    # Clean response
    clean = raw.replace('>', '').replace('\r', ' ').strip()
    parts = clean.split()
    
    if len(parts) < 3:
        return None, raw
    
    if pid == '03':  # DTCs
        if '43 00' in clean or parts[1] == '00':
            return 'No trouble codes', raw
        else:
            # Parse DTC bytes
            return f'DTCs present: {clean}', raw
    
    elif pid == '010C':  # RPM
        if len(parts) >= 4:
            a, b = int(parts[2], 16), int(parts[3], 16)
            rpm = ((a * 256) + b) / 4
            return f'{rpm:.0f} RPM', raw
    
    elif pid == '0105':  # Coolant Temp
        if len(parts) >= 3:
            a = int(parts[2], 16)
            temp_c = a - 40
            temp_f = (temp_c * 9/5) + 32
            return f'{temp_c}°C / {temp_f:.0f}°F', raw
    
    elif pid == '010D':  # Speed
        if len(parts) >= 3:
            speed_kmh = int(parts[2], 16)
            speed_mph = speed_kmh * 0.621371
            return f'{speed_kmh} km/h / {speed_mph:.0f} mph', raw
    
    elif pid == '0111':  # Throttle
        if len(parts) >= 3:
            a = int(parts[2], 16)
            throttle = (a / 255) * 100
            return f'{throttle:.1f}%', raw
    
    elif pid == '012F':  # Fuel Level
        if len(parts) >= 3:
            a = int(parts[2], 16)
            fuel = (a / 255) * 100
            return f'{fuel:.1f}%', raw
    
    elif pid == '0142':  # Battery Voltage
        if len(parts) >= 4:
            a, b = int(parts[2], 16), int(parts[3], 16)
            voltage = ((a * 256) + b) / 1000
            return f'{voltage:.2f}V', raw
    
    elif pid == '010F':  # Intake Air Temp
        if len(parts) >= 3:
            a = int(parts[2], 16)
            temp_c = a - 40
            temp_f = (temp_c * 9/5) + 32
            return f'{temp_c}°C / {temp_f:.0f}°F', raw
    
    return None, raw

def scan():
    """Perform full OBD-II scan"""
    print("=" * 50)
    print("MintCheck OBD-II Scanner")
    print("=" * 50)
    print()
    
    try:
        ser = serial.Serial(PORT, BAUD, timeout=TIMEOUT)
        print(f"✓ Connected to {PORT}")
        
        # Initialize
        ser.write(b'ATZ\r')
        time.sleep(1)
        init_response = ser.read(500).decode('ascii', errors='replace')
        
        if 'ELM327' in init_response:
            print(f"✓ Device: ELM327 detected")
        else:
            print(f"? Device response: {init_response.strip()}")
        
        # Configure
        for cmd in ['ATE0', 'ATL0', 'ATS0', 'ATH0', 'ATSP0']:
            ser.write((cmd + '\r').encode())
            time.sleep(0.1)
            ser.read(100)
        
        print()
        print("-" * 50)
        print("SCAN RESULTS")
        print("-" * 50)
        
        # Scan all PIDs
        for pid, (name, description) in PIDS.items():
            ser.reset_input_buffer()
            ser.write((pid + '\r').encode())
            time.sleep(0.3)
            raw = ser.read(200).decode('ascii', errors='replace').strip()
            
            value, raw_data = parse_response(pid, raw)
            
            if value:
                print(f"{description:25} {value}")
            else:
                print(f"{description:25} (no data)")
        
        ser.close()
        print()
        print("=" * 50)
        print("Scan complete!")
        
    except Exception as e:
        print(f"✗ Error: {e}")
        print()
        print("Troubleshooting:")
        print("  1. Is the OBDII device connected via Bluetooth?")
        print("  2. Is the car ignition ON?")
        print("  3. Is another app using the port?")

if __name__ == '__main__':
    scan()
