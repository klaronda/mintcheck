# MintCheck OBD-II Communication Layer (Swift)

Direct communication with ELM327-based OBD-II devices over Bluetooth Classic (SPP) using Swift.

## Overview

This module provides a minimal, reliable OBD-II communication layer for MintCheck. It handles:
- Bluetooth Classic SPP connection to ELM327 devices
- AT command initialization and handshake
- Mode 01 PID queries (read-only diagnostics)
- Response parsing and normalization
- Error detection and logging

## Requirements

- macOS 12.0+
- Xcode 14+ (or Swift 5.9+)
- ELM327-based OBD-II device (paired via System Preferences)

## Building

```bash
swift build
```

## Running

```bash
swift run
```

Or after building:

```bash
.build/debug/mintcheck-obd2
```

## Architecture

- **Transport Layer**: Bluetooth serial port connection via IOBluetooth
- **Command Layer**: AT commands and OBD PID requests
- **Parser**: Hex response decoding per SAE J1979
- **Logger**: Raw TX/RX visibility with timestamps

## Phase Status

- [x] Phase 1: Connection & Handshake
- [x] Phase 2: Basic OBD Queries
- [x] Phase 3: Reliability & Guardrails
