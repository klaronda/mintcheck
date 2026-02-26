-- Investigate shared_reports FK error for johi.pirrello@hotmail.com
-- Run in Supabase SQL Editor. Replace the scan_id below if needed.

-- 1) User id for johi.pirrello@hotmail.com
SELECT id AS user_id, email, created_at
FROM auth.users
WHERE email = 'johi.pirrello@hotmail.com';

-- 2) Does the failing scan_id exist in scans?
SELECT id, user_id, created_at, vin
FROM scans
WHERE id = 'f756ba46-1df2-45bb-b09f-d55d3b86c4a9'::uuid;
-- If empty: scan was never saved or was deleted → explains FK error.

-- 3) Recent scans for this user (use user_id from step 1 if needed)
SELECT s.id, s.user_id, s.created_at, s.vin
FROM scans s
JOIN auth.users u ON u.id = s.user_id
WHERE u.email = 'johi.pirrello@hotmail.com'
ORDER BY s.created_at DESC
LIMIT 20;

-- 4) shared_reports for this user
SELECT sr.id, sr.scan_id, sr.share_code, sr.created_at
FROM shared_reports sr
JOIN auth.users u ON u.id = sr.user_id
WHERE u.email = 'johi.pirrello@hotmail.com'
ORDER BY sr.created_at DESC
LIMIT 20;

-- 5) Any shared_reports rows pointing at the missing scan_id (orphans)
SELECT * FROM shared_reports
WHERE scan_id = 'f756ba46-1df2-45bb-b09f-d55d3b86c4a9'::uuid;
