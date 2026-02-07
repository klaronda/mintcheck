# Troubleshooting Guide

## Issue: Stuck on `[TX] → ATZ` (No Response)

If the program sends commands but doesn't receive responses, try these steps:

### 1. Check Device Status
- Make sure the car's **ignition is ON** (not just accessory)
- The OBDII device LED should be blinking (shows it's powered and connected)
- The device should be firmly plugged into the OBD port

### 2. Check for Other Apps Using the Device
- Close any other OBD apps (Torque, Car Scanner, etc.)
- The serial port can only be used by one app at a time
- Check Activity Monitor for other processes using the port

### 3. Reset the Device
1. Unplug the OBDII device from the car
2. Wait 5 seconds
3. Plug it back in
4. Wait for the LED to stabilize
5. Run the program again

### 4. Check Serial Port Permissions
```bash
ls -la /dev/cu.OBDII
```
Should show `crw-rw-rw-` (readable/writable by all)

### 5. Test the Serial Port Manually
You can test if the port is working by trying to read from it:
```bash
# This will show any data coming from the device
cat /dev/cu.OBDII
```
(You'll need to Ctrl+C to stop it)

### 6. Try a Different Terminal/App
Sometimes the serial port gets "stuck" in a terminal session. Try:
- Closing all terminal windows
- Restarting the terminal app
- Running the program again

### 7. Check Bluetooth Connection
- Go to System Preferences → Bluetooth
- Make sure the OBDII device shows as "Connected"
- If not, click "Connect"
- Try running the program again

### 8. Restart Bluetooth
If nothing else works:
1. Turn Bluetooth off in System Preferences
2. Wait 5 seconds
3. Turn Bluetooth back on
4. Wait for devices to reconnect
5. Run the program again

## Common Issues

### "Failed to open serial port"
- Another app is using the port
- Device is not paired
- Bluetooth is off

### "Command timeout"
- Car's ignition is not ON
- Device is not responding
- Wrong serial port selected

### "No diagnostic trouble codes found"
- This is normal if your car has no stored codes
- The car might need to be running for some PIDs to work

## Still Stuck?

If none of these work, the device might be:
- Incompatible with your car's OBD protocol
- A faulty/clone ELM327 device
- Not properly paired with macOS

Try using a different OBD app (like Torque) to verify the device works, then come back to this program.
