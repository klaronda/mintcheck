#!/usr/bin/env python3
"""
MintCheck Bluetooth OBD-II Scanner
Tests Bluetooth ELM327 via serial port (macOS)

Usage:
  python3 BT_SCAN.py

Requirements:
  pip3 install pyserial
"""

import serial
import serial.tools.list_ports
import time

def find_obd_port():
    """Find OBD-II serial port"""
    ports = serial.tools.list_ports.comports()
    
    # Priority order: OBDII, VEEPEAK, then any OBD/ELM
    priority_names = ['obdii', 'veepeak']
    
    # First, try priority names
    for port in ports:
        name = port.device.lower()
        if any(priority in name for priority in priority_names):
            return port.device
    
    # Then look for OBD/ELM in description or name
    for port in ports:
        desc = port.description.lower()
        name = port.device.lower()
        
        if any(keyword in desc or keyword in name for keyword in ['obd', 'elm']):
            return port.device
    
    # Fallback: list all ports
    print("Available ports:")
    for port in ports:
        print(f"  {port.device} - {port.description}")
    
    return None

def send_command(ser, cmd, delay=0.5):
    """Send command and get response"""
    ser.reset_input_buffer()
    ser.write((cmd + '\r').encode())
    time.sleep(delay)
    try:
        response = ser.read(500).decode('ascii', errors='replace').strip()
        return response
    except:
        return ''

def parse_pid(pid, raw):
    """Parse PID response"""
    clean = raw.replace('>', '').replace('\r', ' ').strip()
    parts = clean.split()
    
    if len(parts) < 3:
        return None
    
    try:
        if pid == '03':  # DTCs
            if '43 00' in clean or (len(parts) >= 2 and parts[1] == '00'):
                return '✅ No trouble codes'
            else:
                return f'⚠️ DTCs: {clean}'
        
        elif pid == '010C':  # RPM
            if len(parts) >= 4:
                a, b = int(parts[2], 16), int(parts[3], 16)
                rpm = ((a * 256) + b) / 4
                return f'{rpm:.0f} RPM'
        
        elif pid == '0105':  # Coolant Temp
            if len(parts) >= 3:
                temp_c = int(parts[2], 16) - 40
                temp_f = (temp_c * 9/5) + 32
                return f'{temp_c}°C / {temp_f:.0f}°F'
        
        elif pid == '010D':  # Speed
            if len(parts) >= 3:
                speed_kmh = int(parts[2], 16)
                speed_mph = speed_kmh * 0.621371
                return f'{speed_kmh} km/h / {speed_mph:.0f} mph'
        
        elif pid == '0111':  # Throttle
            if len(parts) >= 3:
                throttle = (int(parts[2], 16) / 255) * 100
                return f'{throttle:.1f}%'
        
        elif pid == '012F':  # Fuel Level
            if len(parts) >= 3:
                fuel = (int(parts[2], 16) / 255) * 100
                return f'{fuel:.1f}%'
        
        elif pid == '0142':  # Battery Voltage
            if len(parts) >= 4:
                a, b = int(parts[2], 16), int(parts[3], 16)
                voltage = ((a * 256) + b) / 1000
                return f'{voltage:.2f}V'
        
        elif pid == '010F':  # Intake Air Temp
            if len(parts) >= 3:
                temp_c = int(parts[2], 16) - 40
                temp_f = (temp_c * 9/5) + 32
                return f'{temp_c}°C / {temp_f:.0f}°F'
    except:
        pass
    
    return None

def main():
    print("=" * 50)
    print("🔵 MintCheck Bluetooth OBD-II Scanner")
    print("=" * 50)
    print()
    
    # Find port
    port = find_obd_port()
    if not port:
        print("❌ No OBD-II port found")
        print()
        print("Make sure:")
        print("  1. Bluetooth OBD device is paired (System Preferences → Bluetooth)")
        print("  2. Device is plugged into car's OBD port")
        print("  3. Car ignition is ON")
        return
    
    print(f"✓ Found port: {port}")
    print()
    
    # Try common baud rates
    baud_rates = [38400, 9600, 115200]
    ser = None
    
    for baud in baud_rates:
        try:
            print(f"Trying {port} at {baud} baud...", end=' ')
            ser = serial.Serial(port, baud, timeout=2)
            time.sleep(0.5)
            
            # Test connection
            response = send_command(ser, 'ATZ', 1.5)
            if 'ELM' in response:
                print(f"✓ Connected!")
                print(f"  Device: {response.split('ELM')[1].split()[0] if 'ELM' in response else 'Unknown'}")
                break
            else:
                ser.close()
                ser = None
                print("✗")
        except Exception as e:
            if ser:
                ser.close()
            ser = None
            print(f"✗ ({e})")
    
    if not ser:
        print()
        print("❌ Could not connect to device")
        return
    
    print()
    print("Initializing...")
    
    # Configure
    for cmd in ['ATE0', 'ATL0', 'ATS0', 'ATH0', 'ATSP0']:
        send_command(ser, cmd, 0.2)
    
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
        raw = send_command(ser, pid, 0.7)
        value = parse_pid(pid, raw)
        
        if value:
            print(f"  {name:25} {value}")
        else:
            print(f"  {name:25} —")
    
    ser.close()
    
    print()
    print("=" * 50)
    print("✅ Scan complete!")
    print("=" * 50)

if __name__ == '__main__':
    main()
