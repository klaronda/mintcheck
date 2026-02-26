# Vehicle History Report - Implementation Guide

## Overview

This guide explains how to parse raw CARFAX data and convert it into MintCheck-styled vehicle history reports. The implementation prioritizes critical safety information while maintaining a clean, user-friendly interface.

---

## 🎯 Data Parsing Strategy

### What We Keep (High Priority)

1. **Critical Safety Issues** - Branded titles, accidents, structural damage
2. **Key Metrics** - VIN, mileage, owner count, location
3. **Recent History** - Last 3 owners (most relevant)
4. **First 5 records per owner** - Most important events
5. **All accident records** - Safety critical

### What We Summarize/Simplify

1. **Ownership details** - Collapsed 9 owners into summary table
2. **Service records** - Only showing first few per owner
3. **Minor records** - Skipped routine inspections that passed
4. **Glossary** - Removed (users don't need legalese)
5. **CARFAX branding** - All promotional content

### What We Remove

1. **Buyback guarantee info** - CARFAX-specific
2. **Dealer information** - Not relevant to MintCheck users
3. **"Well Maintained" badges** - Marketing fluff
4. **Duplicate information** - Same data shown multiple ways
5. **Legal disclaimers** - Kept one simple disclaimer instead of many

---

## 📋 Recommended Implementation

### 1. Data Parsing Approach

```typescript
// Recommended parsing pipeline:
const parseCarfaxData = (rawCarfaxData: any) => {
  // Step 1: Extract critical alerts (branded titles, accidents)
  const criticalAlerts = extractCriticalAlerts(rawCarfaxData);
  
  // Step 2: Get key metrics for overview
  const keyMetrics = extractKeyMetrics(rawCarfaxData);
  
  // Step 3: Summarize ownership (limit to last 3 owners)
  const ownershipSummary = summarizeOwnership(rawCarfaxData, { limit: 3 });
  
  // Step 4: Filter and limit detailed records
  const detailedHistory = filterDetailedHistory(rawCarfaxData, {
    maxOwners: 3,
    maxRecordsPerOwner: 5,
    prioritizeAlerts: true
  });
  
  return {
    criticalAlerts,
    keyMetrics,
    ownershipSummary,
    detailedHistory
  };
};
```

### 2. Prioritization Logic

```typescript
// Order of importance for records:
const RECORD_PRIORITY = {
  BRANDED_TITLE: 10,      // Salvage/Junk/Rebuilt
  ACCIDENT: 9,            // Any collision
  STRUCTURAL_DAMAGE: 8,   // Frame/unibody damage
  AIRBAG_DEPLOYMENT: 7,
  THEFT: 6,
  FAILED_INSPECTION: 5,
  TITLE_CHANGE: 4,
  SERVICE: 3,
  ODOMETER_READING: 2,
  PASSED_INSPECTION: 1
};

// Filter function:
const prioritizeRecords = (records: any[]) => {
  return records
    .map(r => ({ ...r, priority: getPriority(r) }))
    .sort((a, b) => b.priority - a.priority)
    .slice(0, 5); // Keep top 5 per owner
};
```

### 3. Data Structure Expectations

```typescript
interface ParsedVehicleHistory {
  vehicle: {
    vin: string;
    year: string;
    make: string;
    model: string;
    trim?: string;
    engineInfo: string;
    bodyType: string;
    fuel: string;
  };
  
  status: {
    overall: 'safe' | 'caution' | 'not-recommended';
    hasBrandedTitle: boolean;
    hasAccidents: boolean;
    hasStructuralDamage: boolean;
  };
  
  keyMetrics: {
    lastOdometer: number;
    ownerCount: number;
    serviceRecords: number;
    lastLocation: string;
    ownershipType: string;
  };
  
  alerts: Array<{
    type: 'branded-title' | 'accident' | 'structural' | 'airbag' | 'odometer';
    severity: 'critical' | 'warning' | 'info';
    date?: string;
    description: string;
  }>;
  
  ownerHistory: Array<{
    ownerNumber: number;
    purchaseYear: number;
    ownerType: string;
    avgMilesPerYear?: number;
    lastOdometer?: number;
  }>;
  
  detailedRecords: Array<{
    ownerNumber: number;
    ownerInfo: { purchaseYear: number; type: string };
    records: Array<{
      date: string;
      mileage?: number;
      source: string;
      type: string; // 'alert' | 'service' | 'title' | 'inspection'
      description: string;
      details?: string[];
    }>;
  }>;
}
```

---

## 🛠️ Helper Functions

### 1. Determine Overall Status

```typescript
const calculateStatus = (data: any): 'safe' | 'caution' | 'not-recommended' => {
  const hasBrandedTitle = checkForBrandedTitles(data);
  const hasAccidents = checkForAccidents(data);
  const hasStructuralDamage = checkForStructuralDamage(data);
  
  if (hasBrandedTitle || (hasAccidents && hasStructuralDamage)) {
    return 'not-recommended';
  }
  if (hasAccidents || hasStructuralDamage) {
    return 'caution';
  }
  return 'safe';
};
```

### 2. Filter Displayed Data

```typescript
const filterDisplayedData = (item: any) => {
  return item.displayed !== false && 
         item.hidden !== true &&
         item.text?.trim().length > 0;
};
```

### 3. Strip HTML Tags

CARFAX loves putting HTML in their JSON. Always strip it:

```typescript
const stripHtml = (html: string): string => {
  return html
    .replace(/<\/?strong>/g, '')
    .replace(/<\/?[^>]+(>|$)/g, '')
    .replace(/&[^;]+;/g, ' ')
    .trim();
};
```

### 4. Limit to Recent Owners

```typescript
const limitToRecentOwners = (owners: any[], limit = 3): any[] => {
  return owners.slice(-limit); // Last N owners are most recent
};
```

---

## 🚨 Edge Cases to Handle

### Common CARFAX Data Issues

```typescript
// 1. Missing or null fields
const safeGet = (obj: any, path: string, defaultValue: any = null) => {
  return path.split('.').reduce((acc, part) => acc?.[part], obj) ?? defaultValue;
};

// 2. HTML in unexpected places
const cleanText = (text: any): string => {
  if (typeof text !== 'string') return '';
  return stripHtml(text);
};

// 3. Inconsistent date formats
const parseCarfaxDate = (dateStr: string): Date | null => {
  try {
    // CARFAX uses MM/DD/YYYY format
    const [month, day, year] = dateStr.split('/');
    return new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
  } catch {
    return null;
  }
};

// 4. Missing odometer readings
const formatMileage = (reading: any): string | null => {
  if (!reading?.displayed || !reading?.odometerReading) {
    return null;
  }
  return `${reading.odometerReading} ${reading.odometerReadingLabel || 'mi'}`;
};
```

---

## 🎨 UX Design Decisions

| Element | Why We Did This | Alternative Approach |
|---------|----------------|---------------------|
| **Limited to 3 owners** | Most users care about recent history, not all 9 owners | Show all owners in expandable accordion |
| **5 records per owner** | Prevents overwhelming users with data | "Load more" button for full history |
| **Removed glossary** | Users don't read legal definitions | Link to external glossary page |
| **Single status badge** | Clear at-a-glance decision | Multiple badges (confusing) |
| **Timeline view** | Easy to scan chronologically | Table view (harder to read) |
| **Color-coded alerts** | Visual hierarchy for severity | All same color (less clear) |

---

## 🎨 MintCheck Styling

### Brand Colors

```typescript
const COLORS = {
  // Primary
  mintGreen: '#3EB489',
  
  // Backgrounds
  warmGray: '#F8F8F7',
  white: '#FFFFFF',
  
  // Text
  nearBlack: '#1A1A1A',
  gray: '#666666',
  lightGray: '#999999',
  
  // Alerts
  dangerRed: '#C94A4A',
  dangerBg: '#FFE6E6',
  warningYellow: '#E3B341',
  warningBg: '#FFF9E6',
  successGreen: '#3EB489',
  successBg: '#E6F4EE',
  
  // Borders
  border: '#E5E5E5'
};
```

### Design Tokens

```typescript
const DESIGN = {
  borderRadius: '4px',
  cardPadding: '32px',
  sectionGap: '24px',
  gridGap: '16px'
};
```

---

## ⚡ Performance Considerations

For large CARFAX reports (some have 50+ owners):

```typescript
// 1. Lazy load detailed history
const [visibleOwners, setVisibleOwners] = useState(3);
const loadMore = () => setVisibleOwners(prev => prev + 3);

// 2. Memoize parsed data
const parsedData = useMemo(() => parseCarfaxData(rawData), [rawData]);

// 3. Virtual scrolling for very long histories
import { FixedSizeList } from 'react-window';
```

---

## 🧪 Testing Scenarios

Test with these edge cases:

```typescript
const testCases = {
  // Clean vehicle
  cleanHistory: { 
    owners: 1, 
    accidents: 0, 
    brandedTitles: 0 
  },
  
  // Minor issues
  minorIssues: { 
    owners: 3, 
    accidents: 1, 
    brandedTitles: 0 
  },
  
  // Major problems (like the sample)
  majorProblems: { 
    owners: 9, 
    accidents: 1, 
    brandedTitles: ['Salvage', 'Junk', 'Rebuilt'] 
  },
  
  // Missing data
  incompleteData: { 
    vin: null, 
    odometer: null, 
    someOwnersWithNoRecords: true 
  }
};
```

---

## 📁 Recommended File Structure

```
/src/utils/
  ├── carfax-parser.ts       // Main parsing logic
  ├── carfax-types.ts        // TypeScript interfaces
  └── carfax-filters.ts      // Filtering/prioritization

/src/components/
  └── vehicle-history-report.tsx  // Main component (already created)
```

---

## 🚀 Quick Implementation Steps

1. **Start with the parser** - Create `carfax-parser.ts` with the functions above
2. **Define types** - Use the `ParsedVehicleHistory` interface
3. **Test with sample data** - Use the data structure already created in App.tsx
4. **Add real CARFAX JSON** - Parse it through your pipeline
5. **Handle edge cases** - Add null checks and fallbacks
6. **Optimize** - Add memoization and lazy loading if needed

---

## 💡 Pro Tips

- **Always strip HTML** - CARFAX loves putting `<strong>` tags in their JSON
- **Check the `displayed` flag** - Many records have `displayed: false`
- **Filter by `hidden: false`** - Some records are marked as hidden
- **Recent = relevant** - Users care most about the last 2-3 years
- **Icons over text** - Use lucide-react icons for visual clarity
- **Mobile-first** - CARFAX reports are often viewed on phones

---

## 🔍 CARFAX JSON Structure Notes

### Common Paths in Raw Data

```typescript
// Vehicle info
vhr.headerSection.vehicleInformationSection.vin
vhr.headerSection.vehicleInformationSection.yearMakeModel

// Overview stats
vhr.headerSection.historyOverview.rows[]

// Title issues
vhr.titleHistorySection.rows[]

// Accident records
vhr.accidentDamageSection.accidentDamageRecords[]

// Ownership
vhr.ownershipHistorySection.rows[]

// Detailed records
vhr.detailsSection.ownerBlocks.ownerBlocks[]
```

### Common Field Patterns

```typescript
// Most sections follow this pattern:
{
  displayed: boolean,      // Check this first
  hidden?: boolean,        // Also check this
  text: string,           // Usually contains HTML
  translatedText?: {      // Language variations
    en: string,
    es: string
  }
}

// Records often have:
{
  dateDisplay: string,           // MM/DD/YYYY format
  odometerReading: {
    displayed: boolean,
    odometerReading: string,     // Number as string
    odometerReadingLabel: string // Usually "mi"
  },
  source: {
    sourceLines: Array<{
      displayed: boolean,
      sourceTextLine: {
        text: string,
        hidden: boolean
      }
    }>
  },
  comments: {
    commentsGroups: Array<{
      outerLine: { 
        commentsTextLine: { 
          text: string,
          alert: boolean  // Important! Indicates severity
        } 
      },
      innerLines: Array<{
        commentsTextLine: { 
          text: string,
          alert: boolean
        }
      }>
    }>
  }
}
```

---

## 🐛 Common Pitfalls

1. **Assuming fields exist** - Always use optional chaining (`?.`)
2. **Not stripping HTML** - Text fields often contain `<strong>`, `<br>`, etc.
3. **Ignoring the `displayed` flag** - CARFAX hides a lot of data
4. **Not prioritizing records** - Show important stuff first
5. **Including too much data** - Users get overwhelmed
6. **Hard-coding owner count** - Some vehicles have 15+ owners
7. **Not handling missing mileage** - Many records don't have odometer readings

---

## 📊 Sample Data Provided

A complete sample CARFAX data structure is available in `/src/app/App.tsx` as `sampleCarfaxData`. This includes:

- Vehicle with branded titles (Salvage, Junk, Rebuilt)
- 9 owners across multiple years
- Accident history with details
- Service records
- Properly structured with all required fields

Use this as a reference for the expected data structure.

---

## 🎯 Success Criteria

Your implementation should:

- ✅ Parse raw CARFAX JSON without errors
- ✅ Display critical alerts prominently (red for danger)
- ✅ Show key metrics at a glance
- ✅ Limit displayed data to avoid overwhelming users
- ✅ Handle missing/null data gracefully
- ✅ Match MintCheck brand styling
- ✅ Be mobile-responsive
- ✅ Load quickly even with large reports

---

## 📞 Questions?

If you encounter issues with:
- Parsing specific CARFAX fields
- Handling edge cases
- Styling consistency
- Performance optimization

Refer back to the sample implementation in `/src/app/components/vehicle-history-report.tsx` for examples of how these challenges were solved.

---

**Last Updated:** February 3, 2026  
**Component Version:** 1.0.0  
**MintCheck Design System Version:** Latest (4px border radius, #3EB489 green)
