import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in environment');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export interface ReportData {
  vehicleYear: string;
  vehicleMake: string;
  vehicleModel: string;
  vin?: string;
  recommendation: 'safe' | 'caution' | 'not-recommended';
  scanDate: string;
  summary?: string;
  findings?: string[];
  valuationLow?: number;
  valuationHigh?: number;
  odometerReading?: number;
  askingPrice?: number;
  dtcAnalyses?: { code: string; name: string }[];
}

export interface SharedReport {
  id: string;
  user_id: string;
  scan_id: string;
  share_code: string;
  vin?: string | null;
  report_data: ReportData;
  summary?: string | null;  // AI-generated summary (dedicated column)
  created_at: string;
}

export const sharedReportsApi = {
  async getByShareCode(shareCode: string): Promise<SharedReport> {
    const { data, error } = await supabase
      .from('shared_reports')
      .select('*')
      .eq('share_code', shareCode)
      .single();

    if (error) throw error;
    return data as SharedReport;
  },
};
