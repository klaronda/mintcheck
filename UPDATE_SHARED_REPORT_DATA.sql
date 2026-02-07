-- Update shared_reports table with dtcAnalyses and nhtsaData
-- For share_code: xbrGr7rmXBfp

UPDATE shared_reports
SET report_data = jsonb_set(
  jsonb_set(
    report_data,
    '{dtcAnalyses}',
    '[
      {
        "code": "P0420",
        "name": "Catalyst System Efficiency Below Threshold",
        "description": "The catalytic converter is not efficiently converting harmful emissions to less harmful substances.",
        "repairCostLow": 500,
        "repairCostHigh": 1200,
        "urgency": "medium"
      }
    ]'::jsonb
  ),
  '{nhtsaData}',
  '{
    "recalls": [],
    "safetyRatings": {
      "overallRating": "4",
      "frontalCrashRating": "4",
      "sideCrashRating": "5",
      "rolloverRating": "4",
      "sidePoleCrashRating": "5",
      "vehicleDescription": "2015 Dodge Grand Caravan VAN FWD"
    }
  }'::jsonb
)
WHERE share_code = 'xbrGr7rmXBfp';

-- Verify the update
SELECT 
  share_code,
  report_data->>'vehicleYear' as year,
  report_data->>'vehicleMake' as make,
  report_data->>'vehicleModel' as model,
  jsonb_array_length(report_data->'dtcAnalyses') as dtc_count,
  report_data->'nhtsaData'->'safetyRatings'->>'overallRating' as safety_rating
FROM shared_reports
WHERE share_code = 'xbrGr7rmXBfp';
