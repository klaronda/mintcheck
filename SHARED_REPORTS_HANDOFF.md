# Shared Reports Page - Implementation Handoff

## Overview

The MintCheck iOS app now supports sharing scan reports via email with optional shareable links. When a user creates a shareable link, it generates a URL like:

```
https://mintcheckapp.com/report/ABC123xyz456
```

This document provides everything needed to implement the public report page on the website.

## Database Schema

A new `shared_reports` table exists in Supabase:

```sql
shared_reports (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,        -- Owner of the report
  scan_id UUID NOT NULL,        -- Reference to original scan
  share_code TEXT NOT NULL,     -- 12-char alphanumeric code (e.g., "ABC123xyz456")
  vin TEXT,                     -- Vehicle VIN (for deduplication)
  report_data JSONB NOT NULL,   -- Snapshot of report at share time
  created_at TIMESTAMPTZ        -- When link was created
)
```

### Report Data Structure

The `report_data` JSONB column contains:

```typescript
interface ReportData {
  vehicleYear: string;
  vehicleMake: string;
  vehicleModel: string;
  vin?: string;
  recommendation: 'safe' | 'caution' | 'not-recommended';
  scanDate: string;              // ISO 8601 format
  summary?: string;              // AI-generated summary
  findings?: string[];           // Key findings list
  valuationLow?: number;         // Estimated value low
  valuationHigh?: number;        // Estimated value high
  odometerReading?: number;      // Odometer in miles
  askingPrice?: number;          // Seller's asking price
}
```

## Route to Add

Add to `src/app/routes.ts`:

```typescript
import ReportPage from './pages/ReportPage';

// Add to children array:
{
  path: '/report/:shareCode',
  Component: ReportPage,
}
```

## Fetching Report Data

The `shared_reports` table has a public read policy, so you can fetch without authentication:

```typescript
// In src/lib/supabase.ts - add this API helper
export const sharedReportsApi = {
  async getByShareCode(shareCode: string) {
    const { data, error } = await supabase
      .from('shared_reports')
      .select('*')
      .eq('share_code', shareCode)
      .single();

    if (error) throw error;
    return data;
  },
};
```

## Scan Freshness Badge

Display a freshness badge based on scan age (from `scanDate`):

| Status | Days Old | Badge Color |
|--------|----------|-------------|
| Current | 0-10 days | Green (`#E6F4EE` bg, `#2D7A5E` text) |
| Expires Soon | 11-14 days | Amber (`#FFF8E6` bg, `#9A7B2C` text) |
| Expired | 15+ days | Red (`#FFE6E6` bg, `#9A3A3A` text) |

**Header format:** `[Badge] Report expires on [scan date + 14 days; Month Day, Year]`

**Disclaimer (at bottom of report):**
> Disclaimer: MintCheck scan was run on this vehicle on [Month Day, Year] and is valid for 14 days.

## Recommendation Section

The recommendation should be displayed as a prominent section with the headline and AI summary:

| Recommendation | Badge Label | Headline | Colors |
|----------------|-------------|----------|--------|
| `safe` | Healthy | Car is Healthy | Green (`#E6F4EE` bg, `#3EB489` border, `#2D7A5E` text) |
| `caution` | Caution | Proceed with Caution | Amber (`#FFF9E6` bg, `#E3B341` border, `#9A7B2C` text) |
| `not-recommended` | Walk Away | Walk Away | Red (`#FFE6E6` bg, `#C94A4A` border, `#9A3A3A` text) |

**Structure:**
```
┌─────────────────────────────────────────┐
│ [Headline: "Car is Healthy"]            │
│                                         │
│ [AI Summary text from report_data]      │
└─────────────────────────────────────────┘
```

## Page Requirements

### SEO / Indexing
- Add `<meta name="robots" content="noindex, nofollow">` to prevent search indexing
- These are private reports shared intentionally, not meant for public discovery

### Page Sections

1. **Header**
   - MintCheck logo: `https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo-text/lockup-mint.svg`
   - "Vehicle Scan Report" title

2. **Vehicle Info Card**
   - Year Make Model
   - VIN (if available)
   - Odometer (if available)
   - Freshness Badge (Current/Expires Soon/Expired) + "Report expires on [Month Day, Year]"

3. **Recommendation Section** (prominent!)
   - Large headline: "Car is Healthy" / "Proceed with Caution" / "Walk Away"
   - AI-generated summary text below headline
   - Background color matches recommendation (see table above)

4. **Vehicle Details** (if available)
   - All vehicle-specific data from the scan

5. **Key Findings** (if available)
   - Bulleted list of findings

6. **Disclaimer**
   ```
   Disclaimer: MintCheck scan was run on this vehicle on [Month Day, Year] and is valid for 14 days.
   ```

7. **Download CTA**
   - "Get your own vehicle scanned with MintCheck"
   - Black button with Apple logo: "Get the MintCheck App on iOS"
   - Apple logo: `https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/3P-content/logos/Apple_logo_black.svg` (invert to white)

8. **Footer Disclaimer**
   ```
   If you are the owner of this scan and wish to remove this page, 
   sign in to the MintCheck app and manage your shared links from the Settings tab.
   ```

**NOTE:** Do NOT show estimated value on the public page.

### 404 Handling
- If `share_code` not found, show a friendly "Report not found" page
- Suggest the link may have been removed by the owner

## Design Reference

The email template in the Edge Function (`supabase/functions/share-report/index.ts`) contains the exact HTML structure and styling. The web page should match this design using your existing Tailwind/component setup.

Key brand colors:
- MintCheck Green: `#3EB489`
- Text Primary: `#1A1A1A`
- Text Secondary: `#666666`
- Background: `#F8F8F7`
- Border: `#E5E5E5`

## Example Implementation Skeleton

```tsx
// src/app/pages/ReportPage.tsx
import { useParams } from 'react-router';
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

export default function ReportPage() {
  const { shareCode } = useParams();
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    async function fetchReport() {
      try {
        const { data, error } = await supabase
          .from('shared_reports')
          .select('*')
          .eq('share_code', shareCode)
          .single();
        
        if (error) throw error;
        setReport(data);
      } catch (err) {
        setError(true);
      } finally {
        setLoading(false);
      }
    }
    fetchReport();
  }, [shareCode]);

  if (loading) return <LoadingState />;
  if (error || !report) return <NotFoundState />;

  const reportData = report.report_data;
  const scanDate = new Date(reportData.scanDate);
  const validUntil = new Date(scanDate);
  validUntil.setDate(validUntil.getDate() + 14);

  // Calculate freshness
  const daysOld = Math.floor((Date.now() - scanDate.getTime()) / (1000 * 60 * 60 * 24));
  const freshness = daysOld <= 10 ? 'Current' : daysOld <= 14 ? 'Expires Soon' : 'Expired';
  
  // Get recommendation labels
  const recommendationLabels = {
    'safe': { badge: 'Healthy', headline: 'Car is Healthy' },
    'caution': { badge: 'Caution', headline: 'Proceed with Caution' },
    'not-recommended': { badge: 'Walk Away', headline: 'Walk Away' },
  };

  return (
    <>
      <head>
        <meta name="robots" content="noindex, nofollow" />
        <title>Vehicle Report - {reportData.vehicleYear} {reportData.vehicleMake} {reportData.vehicleModel}</title>
      </head>
      
      {/* Implement page content here */}
      
      {/* Footer disclaimer */}
      <p className="text-center text-sm text-gray-500 mt-8">
        If you are the owner of this scan and wish to remove this page,
        sign in to the MintCheck app and manage your shared links from the Settings tab.
      </p>
    </>
  );
}
```

## Questions?

The share functionality is fully implemented in the iOS app. Users can:
- Share reports via email (with or without shareable link)
- Manage their shared links in Settings (view, copy, delete)
- Same VIN shared again replaces the old link (no duplicates)

Let me know if you need any additional details!
