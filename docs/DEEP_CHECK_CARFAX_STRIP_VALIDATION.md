# Deep Check CARFAX branding strip – validation

## When the report matches the ideal (full MintCheck-styled view)

- The **ideal look** (e.g. [Q7GNDZZrNdFn](https://mintcheckapp.com/deep-check/report/Q7GNDZZrNdFn)) is the **structured path**: the report HTML contains `window.__INITIAL__DATA__` with the full vhr JSON. The frontend uses `extractCarfaxVhrFromHtml` and renders `VehicleHistoryReport` with complete data (title history, additional history, ownership, detailed history, accidents).
- To have **all** reports match that ideal, the report source (e.g. backend/API) must return HTML that includes the `window.__INITIAL__DATA__` script. If your provider only returns HTML without that script, you will get the iframe path instead.

## Live report behavior (no structured data)

- **Stored live HTML** (e.g. from CheapCARFAX / CarfaxDATA.rtfd) **does not contain** `window.__INITIAL__DATA__`, so structured vhr extraction returns null (see `deep-check-klaronda-metadata.json`).
- For those reports we use the **iframe path**: the full HTML is rendered in an iframe after `stripBrandingAndApplyMintCheckStyle()` in `website/src/app/utils/deepCheckReportHtml.ts`. Users see the complete report content with CARFAX branding stripped and MintCheck styling applied; no partial parsed view is shown.

## Fix (Jan 2026)

1. **Structured path (when extraction is possible)**  
   - `extractCarfaxVhrFromHtml.ts`: marker search is robust to different whitespace (exact `window.__INITIAL__DATA__` or regex with flexible spaces).  
   - `DeepCheckReportPage.tsx`: `useReactReport` is true when we have `headerSection` and either `vehicleInformationSection` or any other usable section (title history, additional history, ownership, accident/damage, details, history overview).  
   - `VehicleHistoryReport.tsx`: renders even when `vehicleInformationSection` is missing (generic header; other sections still shown).

2. **Iframe branding strip** (`deepCheckReportHtml.ts`)  
   - Scripts removed, then:  
     - Global **CARFAX** / **Carfax** → **MintCheck** in visible text.  
     - Document `<title>` replaced with "Vehicle History Report – MintCheck".  
     - Long CARFAX disclaimer, Buyback Guarantee, "reported to Carfax" → MintCheck copy or removed.  
     - Extra phrases: "Vehicle History Report provided by CARFAX", "Data provided by CARFAX", "Powered by CARFAX", etc. → MintCheck or removed.  
   - CSS: MintCheck palette, hide CARFAX logos/branding (img, class/id with carfax-logo, branding, report-provider, data-provider), hide .powered-by, zero out report-title/main-title for visible CARFAX headings, hide footer/glossary/social.

## How to validate

- **With a live report**: Open a shared report URL (e.g. `https://mintcheckapp.com/deep-check/report/{code}`) for a report that uses the iframe path. Confirm the iframe content and tab title show no CARFAX branding (only MintCheck and neutral copy).
- **With CarfaxDATA.rtfd**: Extract the `html` field from the JSON inside the RTF (e.g. one-off Node script), run `stripBrandingAndApplyMintCheckStyle(html)`, and search the result for "CARFAX" / "Carfax"; there should be no matches (or only inside comments/selectors that don’t affect visible text).
