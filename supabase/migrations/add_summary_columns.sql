-- Migration: Add summary column to scans and shared_reports tables
-- This allows the AI-generated recommendation summary to be stored in a dedicated column
-- for easier querying and to provide more content on the shared report web page

-- Add summary column to scans table
ALTER TABLE scans 
ADD COLUMN IF NOT EXISTS summary TEXT;

-- Add summary column to shared_reports table
ALTER TABLE shared_reports 
ADD COLUMN IF NOT EXISTS summary TEXT;

-- Add comment to document the column
COMMENT ON COLUMN scans.summary IS 'AI-generated recommendation summary text from DTC analysis';
COMMENT ON COLUMN shared_reports.summary IS 'AI-generated recommendation summary text for shared reports';
