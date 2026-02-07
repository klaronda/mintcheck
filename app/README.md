# MintCheck iOS App

Mobile app for MintCheck - check used vehicle health via OBD-II diagnostics.

## Stack
- **SwiftUI** - Native iOS UI framework
- **Supabase** - Authentication and database backend
- **Network Framework** - TCP socket communication with OBD-II adapters
- **NHTSA API** - VIN decoding

## Status
✅ **MVP Complete** - Ready for testing

## Folders

| Folder | Description |
|--------|-------------|
| `MintCheck/` | SwiftUI iOS app source code |
| `MintCheck_UX-UI/` | React UI designs (reference) |

## Quick Start

1. Install Xcode from the Mac App Store
2. Read `MintCheck/README.md` for setup instructions
3. Create a new Xcode project and add the source files
4. Build and run on simulator or device

## Features

- User authentication (sign up/sign in)
- Vehicle details entry with VIN decoding
- WiFi OBD-II scanner connection
- Real-time vehicle scan with progress
- Visual inspection checklist
- Comprehensive results with recommendations
- Scan history on dashboard
