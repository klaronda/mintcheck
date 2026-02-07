# Summary Column Setup - Implementation Guide

## Overview

This document describes the changes made to add a dedicated `summary` column to the `scans` and `shared_reports` tables. This allows the AI-generated recommendation summary to be stored in a dedicated column for easier querying and to provide more content on the shared report web page.

## Database Migration

### SQL Migration File
**Location**: `/supabase/migrations/add_summary_columns.sql`

Run this migration in your Supabase SQL Editor:

```sql
-- Add summary column to scans table
ALTER TABLE scans 
ADD COLUMN IF NOT EXISTS summary TEXT;

-- Add summary column to shared_reports table
ALTER TABLE shared_reports 
ADD COLUMN IF NOT EXISTS summary TEXT;

-- Add comments to document the columns
COMMENT ON COLUMN scans.summary IS 'AI-generated recommendation summary text from DTC analysis';
COMMENT ON COLUMN shared_reports.summary IS 'AI-generated recommendation summary text for shared reports';
```

## Code Changes

### 1. iOS App - ScanResult Model
**File**: `MintCheck/MintCheck/MintCheck/Models/ScanResult.swift`

- Added `summary: String?` property to `ScanResult` struct
- Added `summary` to `CodingKeys` enum

### 2. iOS App - ScanService
**File**: `MintCheck/MintCheck/MintCheck/Services/ScanService.swift`

- Updated `saveScan()` method to accept optional `summary: String?` parameter
- Updated `ScanInsert` struct to include `summary` field
- Summary is now saved to the dedicated column when saving scans

### 3. iOS App - ContentView
**File**: `MintCheck/MintCheck/MintCheck/ContentView.swift`

- Updated `saveScanToSupabase()` to pass `nav.currentScanData.dtcAnalysis?.summary` to the `saveScan()` method

### 4. Supabase Edge Function - share-report
**File**: `supabase/functions/share-report/index.ts`

- Updated all three places where `shared_reports` are inserted/updated:
  - When updating existing link (line ~432)
  - When inserting new link with VIN (line ~452)
  - When inserting new link without VIN (line ~472)
- All now include `summary: reportData.summary || null` in the insert/update operations

### 5. Website - Supabase Types
**File**: `website/src/lib/supabase.ts`

- Updated `SharedReport` interface to include `summary?: string | null` field

### 6. Website - ReportPage Component
**File**: `website/src/app/pages/ReportPage.tsx`

- Updated `ReportContent` function to get summary from dedicated column with fallback:
  ```typescript
  const summary = report.summary || rd.summary;
  ```
- Updated the recommendation section to display `summary` instead of `rd.summary`

## Data Flow

1. **AI Analysis**: The `analyze-dtcs` Edge Function returns a `summary` field in the `AnalysisResponse`
2. **iOS App**: When saving a scan, the summary from `dtcAnalysis.summary` is passed to `saveScan()` and stored in the `scans.summary` column
3. **Sharing**: When creating a shared report link, the `share-report` Edge Function saves the summary to both:
   - `shared_reports.report_data.summary` (JSONB, for backward compatibility)
   - `shared_reports.summary` (dedicated column, for easier querying)
4. **Web Display**: The `ReportPage` component reads from `report.summary` (dedicated column) with fallback to `report.report_data.summary` (JSONB) for backward compatibility

## Backward Compatibility

The implementation maintains backward compatibility:
- Old scans without a `summary` column value will still work
- The website falls back to `report_data.summary` if the dedicated column is null
- The JSONB storage in `scan_data.aiAnalysis.summary` and `report_data.summary` is preserved

## Testing Checklist

After running the migration and deploying the code:

- [ ] Run the SQL migration in Supabase
- [ ] Test saving a new scan from iOS app - verify summary is saved
- [ ] Test creating a shared report link - verify summary appears in both columns
- [ ] Test viewing a shared report on the web - verify summary displays correctly
- [ ] Test viewing an old shared report (created before migration) - verify fallback works
- [ ] Verify the summary appears in the recommendation section on the web page

## Benefits

1. **Easier Querying**: Can now query summaries directly without JSONB path extraction
2. **Better Performance**: Direct column access is faster than JSONB path queries
3. **More Content**: The shared web page now has richer content with the AI-generated summary
4. **Future-Proof**: Dedicated column makes it easier to add features like search, filtering, or analytics
