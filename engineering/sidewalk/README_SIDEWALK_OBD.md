# Sidewalk + OBD-II (Future Use)

**Status:** Reference only. No PDF was available at handoff; this doc and the Python tool are for when you have the Sidewalk spec or PDF.

## Can Sidewalk connect to an OBD port?

**Short answer:** Not directly. There is no “Sidewalk to OBD” dongle or standard. You need a **gateway** in the middle.

| Layer | Role |
|-------|------|
| **OBD-II** | In-car bus; you need a dongle (WiFi/BT/Serial) to read it. |
| **Gateway** | Device that reads OBD (e.g. existing dongle or custom board) and has a **Sidewalk radio**. |
| **Sidewalk** | Long-range, low-bandwidth network (LoRa/GFSK/BLE). Gateways (Echo, Ring, etc.) relay to AWS. |
| **Cloud** | AWS IoT Core for Amazon Sidewalk receives data; your app/backend consumes it. |

So: **OBD dongle → gateway with Sidewalk radio → Sidewalk network → AWS → your app.** The “connect to OBD port” part is still the same (OBD dongle); Sidewalk is only the **backhaul** from the gateway to the cloud.

## Why Sidewalk for MintCheck?

- **Range:** Car can be in driveway/garage; Sidewalk can reach a neighbor’s Echo/Ring.
- **No phone/WiFi at car:** User doesn’t need to be in the car or on the same WiFi to trigger or receive a health check.
- **Low data:** A MintCheck summary (VIN, DTCs, a few PIDs) is small and fits Sidewalk’s limits (e.g. 80 Kbps, 500 MB/month per customer).

## What you’d need

1. **Hardware:** OBD reader + Sidewalk-capable MCU/radio (e.g. Silicon Labs Sidewalk SDK, or AWS reference designs). No off-the-shelf “Sidewalk OBD dongle” today.
2. **Firmware:** Read OBD (ELM327-style AT/OBD commands over UART), then send a small payload over Sidewalk to AWS IoT Core.
3. **Cloud:** AWS IoT Core for Amazon Sidewalk (onboarding, topics, rules).
4. **App/backend:** Subscribe to the device topic and show MintCheck results (same as today, but data source is Sidewalk instead of local WiFi/BT).

## References

- [AWS IoT Core for Amazon Sidewalk](https://aws.amazon.com/iot-core/sidewalk/)
- [Connecting to AWS IoT Core for Amazon Sidewalk](https://docs.aws.amazon.com/iot-wireless/latest/developerguide/iot-sidewalk-onboard.html)
- [How Amazon Sidewalk works](https://docs.sidewalk.amazon/introduction/sidewalk-how-works.html)

## If you have a PDF/spec

If you have a PDF (e.g. “sidewalk-network for mintcheck.pdf”) or a short written spec:

1. Put it in this folder or note its path in this README.
2. Use `sidewalk_obd_reference.py` to:
   - Ingest an existing MintCheck scan JSON,
   - Build a minimal “Sidewalk payload” (VIN, DTC count, key PIDs),
   - Optionally validate payload size against Sidewalk limits.

That will keep the design ready for when you add real Sidewalk hardware/firmware.
