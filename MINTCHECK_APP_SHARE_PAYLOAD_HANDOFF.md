# MintCheck App – Share Payload Build Recommendation

**For:** mintcheck-app chat  
**Purpose:** Handoff for adding **dtcAnalyses** and **nhtsaData** to the share-report payload so the web report page can show accurate System Details and NHTSA “More Model Details.”

---

## Context

- **Web report page** (e.g. `https://mintcheckapp.com/report/:shareCode`) shows shared scan reports.
- It uses `report_data.dtcAnalyses` for **System Details** (Engine/Emissions/etc. » Needs Attention with P-codes) and will use **NHTSA** data for “More Model Details” when available.
- Right now, the **app never sends** `dtcAnalyses` or `nhtsaData` when creating a share link. Share goes through `ShareReportSheet` → `ShareService.shareReport` → `share-report` Edge Function. The backend already accepts and stores `dtcAnalyses` in `report_data`; it will be extended to accept and store `nhtsaData` (e.g. `nhtsa_data` column on `shared_reports`).
- **Goal:** Include both in the share payload so new shared links have correct System Details and NHTSA on the web.

---

## App-Specific Tasks

### 1. Extend `ShareService.ReportData` and `shareReport`

**File:** `MintCheck/MintCheck/MintCheck/Services/ShareService.swift`

- Add `dtcAnalyses` and `nhtsaData` to `ReportData`:
  - `dtcAnalyses: [[String: Any]]?` or a small `Codable` type. Backend expects:
    ```json
    [
      {
        "code": "P0420",
        "name": "Catalyst system efficiency below threshold",
        "description": "...",
        "repairCostLow": 500,
        "repairCostHigh": 1500,
        "urgency": "medium"
      }
    ]
    ```
  - `nhtsaData: NHTSADataJSON?` — use the same `NHTSADataJSON` / `VehicleHistoryReport.toJSON()` shape already used for `scans.nhtsa_data` (see `VehicleHistoryService.swift`).
- Add parameters to `shareReport(...)`:
  - `dtcAnalyses: [DTCAnalysisService.DTCAnalysis]?`
  - `nhtsaData: NHTSADataJSON?` (or equivalent)
- When building `ReportData` for the request:
  - Map `dtcAnalyses` → array of `{ code, name, description, repairCostLow, repairCostHigh, urgency }` (match backend `ReportData.dtcAnalyses`).
  - Set `nhtsaData` from the passed-in value (already JSON-serializable).
- Ensure both are encoded and sent in the `ShareRequest` body (either inside `reportData` or as top-level fields, depending on what `share-report` is updated to accept; backend handoff will specify).

### 2. Extend `ShareReportSheet` and wire up callers

**File:** `MintCheck/MintCheck/MintCheck/Views/ShareReportSheet.swift`

- Add optional parameters:
  - `dtcAnalyses: [DTCAnalysisService.DTCAnalysis]?`
  - `nhtsaData: NHTSADataJSON?` (or `VehicleHistoryReport?` and call `.toJSON()` when calling `shareReport`).
- In `sendReport()`, when calling `ShareService.shared.shareReport(...)`, pass these through.

**File:** `MintCheck/MintCheck/MintCheck/ContentView.swift`

- Where `ShareReportSheet` is presented (e.g. `showShareSheet`), pass:
  - `dtcAnalyses: nav.currentScanData.dtcAnalysis?.analyses`
  - `nhtsaData: nav.currentScanData.historyReport?.toJSON()` (or the existing `NHTSADataJSON`-compatible value used for the scan).

---

## Data Sources in the App

| Payload field   | Source |
|-----------------|--------|
| `dtcAnalyses`   | `nav.currentScanData.dtcAnalysis?.analyses` (`DTCAnalysisService.DTCAnalysis`) |
| `nhtsaData`     | `nav.currentScanData.historyReport?.toJSON()` → `NHTSADataJSON` |

Both are available when the user opens the share sheet from the results screen.

---

## Backend / Web Status (no app changes required)

- **share-report** already accepts `report_data.dtcAnalyses` and persists it. Web uses it for System Details.
- **share-report** will be updated to accept `nhtsaData` (top-level or in `report_data`) and store it (e.g. `shared_reports.nhtsa_data`). **Web** will fetch it and show “More Model Details” only when present.
- **Web** already uses `dtcAnalyses`; no extra app work needed for that.

---

## Payload Shape Reference

**dtcAnalyses** (each element):

| Field           | Type   | Notes |
|-----------------|--------|-------|
| `code`          | String | e.g. `"P0420"` |
| `name`          | String | Short label |
| `description`   | String | Optional for share; include if available |
| `repairCostLow` | Int    | Optional for share |
| `repairCostHigh`| Int    | Optional for share |
| `urgency`       | String | e.g. `"low"`, `"medium"`, `"high"`, `"critical"` |

**nhtsaData**: Same structure as `NHTSADataJSON` in `VehicleHistoryService.swift` (`recalls`, `safetyRatings`, etc.). Same as used for `scans.nhtsa_data`.

---

## Testing

1. Create a share link from a scan that has DTCs (e.g. P0420) and NHTSA data.
2. Open the share URL on the web. Confirm:
   - **System Details** shows Engine/Emissions (or others) as “Needs Attention” with the correct P-codes.
   - **More Model Details** (NHTSA) appears when `nhtsaData` was sent; it does not appear when `nhtsaData` is `nil`.

---

## Related Files

- `ShareService.swift` – share API, `ReportData`, `shareReport`
- `ShareReportSheet.swift` – UI, calls `shareReport`
- `ContentView.swift` – presents share sheet, has `dtcAnalysis` and `historyReport`
- `VehicleHistoryService.swift` – `NHTSADataJSON`, `VehicleHistoryReport.toJSON()`
- `DTCAnalysisService.swift` – `DTCAnalysis`, `AnalysisResponse.analyses`
- `supabase/functions/share-report/index.ts` – backend contract for `reportData` (and `nhtsaData` once added)
