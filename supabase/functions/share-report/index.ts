import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Environment variables
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const RESEND_FROM_EMAIL = Deno.env.get('RESEND_FROM_EMAIL') || 'MintCheck App <reports@mintcheckapp.com>';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

// Request interface
interface ShareRequest {
  scanId: string;
  recipients: string[];
  message?: string;
  createLink: boolean;
  reportData: ReportData;
  userEmail: string;
  userName: string;
}

interface ReportData {
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
  /** Combined AI range for all codes (preferred over summing per-code on the web report). */
  totalRepairCostLow?: number;
  totalRepairCostHigh?: number;
  dtcAnalyses?: Array<{
    code: string;
    name: string;
    description: string;
    repairCostLow?: number;
    repairCostHigh?: number;
    urgency: string;
  }>;
  nhtsaData?: {
    recalls?: Array<{
      campaignNumber?: string;
      component?: string;
      summary?: string;
      consequence?: string;
      remedy?: string;
      manufacturer?: string;
      reportDate?: string;
    }>;
    safetyRatings?: {
      overallRating?: string;
      frontalCrashRating?: string;
      sideCrashRating?: string;
      rolloverRating?: string;
      sidePoleCrashRating?: string;
      vehicleDescription?: string;
    };
  };
}

// Generate a unique alphanumeric share code
function generateShareCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let code = '';
  for (let i = 0; i < 12; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// Calculate scan freshness
function getScanFreshness(scanDate: string): { status: string; daysOld: number; expiresOn: string; scanDateFormatted: string } {
  const scan = new Date(scanDate);
  const now = new Date();
  const diffTime = now.getTime() - scan.getTime();
  const daysOld = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  // Expires on scan date + 14 days
  const expiresOn = new Date(scan);
  expiresOn.setDate(expiresOn.getDate() + 14);
  
  let status: string;
  if (daysOld <= 10) {
    status = 'Current';
  } else if (daysOld <= 14) {
    status = 'Expires Soon';
  } else {
    status = 'Expired';
  }
  
  const scanDateFormatted = scan.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
  
  return { 
    status, 
    daysOld, 
    expiresOn: expiresOn.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' }),
    scanDateFormatted
  };
}

// Format date for display
function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

/** Prefer AI totals; otherwise sum per-code repair rows (legacy snapshots). */
function computeRepairCostDisplay(data: ReportData): { low: number; high: number } | null {
  const tl = data.totalRepairCostLow;
  const th = data.totalRepairCostHigh;
  if (typeof tl === 'number' && typeof th === 'number' && (tl > 0 || th > 0)) {
    return { low: Math.min(tl, th), high: Math.max(tl, th) };
  }
  const arr = data.dtcAnalyses;
  if (!arr?.length) return null;
  let low = 0;
  let high = 0;
  for (const d of arr) {
    low += d.repairCostLow ?? 0;
    high += d.repairCostHigh ?? 0;
  }
  if (low <= 0 && high <= 0) return null;
  return { low, high };
}

// Get status colors based on recommendation
// Border / icon bg / headline = accent; icon = #FFFFFF; support = #1a1a1a; card bg = bg
function getStatusColors(recommendation: string): { bg: string; border: string; text: string; icon: string; support: string; label: string; headline: string } {
  switch (recommendation) {
    case 'safe':
      return { bg: '#E6F4EE', border: '#3DB489', text: '#3DB489', icon: '#FFFFFF', support: '#1a1a1a', label: 'Healthy', headline: 'Car is Healthy' };
    case 'caution':
      return { bg: '#FFF9E6', border: '#E4B340', text: '#E4B340', icon: '#FFFFFF', support: '#1a1a1a', label: 'Caution', headline: 'Proceed with Caution' };
    case 'not-recommended':
      return { bg: '#FFE6E5', border: '#C94B4B', text: '#C94B4B', icon: '#FFFFFF', support: '#1a1a1a', label: 'Walk Away', headline: 'Walk Away' };
    default:
      return { bg: '#F0F0F0', border: '#999999', text: '#666666', icon: '#FFFFFF', support: '#1a1a1a', label: 'Unknown', headline: 'Unknown' };
  }
}

// Get freshness badge colors
function getFreshnessBadgeColors(status: string): { bg: string; text: string } {
  switch (status) {
    case 'Current':
      return { bg: '#E6F4EE', text: '#2D7A5E' };
    case 'Expires Soon':
      return { bg: '#FFF8E6', text: '#9A7B2C' };
    case 'Expired':
      return { bg: '#FFE6E6', text: '#9A3A3A' };
    default:
      return { bg: '#F0F0F0', text: '#666666' };
  }
}

// Generate email HTML
function generateEmailHTML(
  reportData: ReportData,
  senderName: string,
  customMessage: string | undefined,
  shareUrl: string | undefined
): string {
  const vehicleName = `${reportData.vehicleYear} ${reportData.vehicleMake} ${reportData.vehicleModel}`;
  const statusColors = getStatusColors(reportData.recommendation);
  const freshness = getScanFreshness(reportData.scanDate);
  const freshnessColors = getFreshnessBadgeColors(freshness.status);
  const scanDateFormatted = formatDate(reportData.scanDate);
  
  // Build findings list HTML
  let findingsHTML = '';
  if (reportData.findings && reportData.findings.length > 0) {
    findingsHTML = reportData.findings.map(f => `<li style="margin-bottom: 8px; color: #666666;">${f}</li>`).join('');
  } else if (reportData.recommendation === 'safe') {
    findingsHTML = '<li style="margin-bottom: 8px; color: #666666;">No diagnostic trouble codes detected</li>';
  }
  const repairDisplay = computeRepairCostDisplay(reportData);
  if (repairDisplay) {
    const { low, high } = repairDisplay;
    const costLine =
      low === high
        ? `Estimated repair cost: $${low.toLocaleString()}`
        : `Estimated repair cost: $${low.toLocaleString()} - $${high.toLocaleString()}`;
    findingsHTML += `<li style="margin-bottom: 8px; color: #666666;">${costLine}</li>`;
  }
  
  // Build share link button
  const shareLinkHTML = shareUrl ? `
    <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 24px 0;">
      <tr>
        <td align="center">
          <a href="${shareUrl}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 8px; font-size: 15px; font-weight: 600;">View Full Report</a>
        </td>
      </tr>
    </table>
    <p style="margin: 0 0 24px 0; color: #999999; font-size: 13px; text-align: center;">
      Or copy this link: <a href="${shareUrl}" style="color: #3EB489; text-decoration: none;">${shareUrl}</a>
    </p>
  ` : '';
  
  // Build custom message section — green left bar inside container, 8px rounded
  const messageHTML = customMessage ? `
    <table role="presentation" style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 24px 0;">
      <tr>
        <td style="width: 4px; background-color: #3EB489; border-radius: 8px 0 0 8px; vertical-align: top;"></td>
        <td style="background-color: #F8F8F7; padding: 16px 16px 16px 12px; border-radius: 0 8px 8px 0; vertical-align: top;">
          <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 14px; font-weight: 600;">Message from ${senderName}:</p>
          <p style="margin: 0; color: #666666; font-size: 14px; line-height: 1.6; white-space: pre-wrap;">${customMessage}</p>
        </td>
      </tr>
    </table>
  ` : '';

  // Get recommendation icon HTML (email-compatible with background circle)
  // Icon background = border color; icon = white
  const getRecommendationIcon = (recommendation: string): string => {
    const iconBg = statusColors.border;
    const iconColor = statusColors.icon;
    
    let iconSymbol = '';
    switch (recommendation) {
      case 'safe':
        iconSymbol = '✓'; // Checkmark
        break;
      case 'caution':
        iconSymbol = '!'; // Exclamation mark
        break;
      case 'not-recommended':
        iconSymbol = '✗'; // X mark
        break;
      default:
        return '';
    }
    
    return `
      <table role="presentation" style="border-collapse: collapse; margin: 0; width: 36px;">
        <tr>
          <td style="width: 36px; height: 36px; background-color: ${iconBg}; border-radius: 8px; text-align: center; vertical-align: middle; padding: 0;">
            <span style="color: ${iconColor}; font-size: 18px; font-weight: bold; line-height: 32px; display: inline-block;">${iconSymbol}</span>
          </td>
        </tr>
      </table>
    `;
  };

  const recommendationIcon = getRecommendationIcon(reportData.recommendation);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Vehicle Scan Report - ${vehicleName}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          
          <!-- Header with Logo -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 8px 8px 0 0;">
              <table role="presentation" style="border-collapse: collapse; margin-bottom: 16px;">
                <tr>
                  <td>
                    <a href="https://mintcheckapp.com" style="display: block;">
                      <img src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/PNGs/lockup-mint.png" alt="MintCheck" style="height: 40px; display: block;" />
                    </a>
                  </td>
                </tr>
              </table>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Vehicle Scan Report</h2>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                ${senderName} has shared a MintCheck vehicle scan report with you.
              </p>
              
              ${messageHTML}
              
              <!-- Vehicle Info Card — inside border, 8px rounded -->
              <table role="presentation" style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: #E5E5E5; padding: 1px; border-radius: 8px;">
                    <table role="presentation" style="width: 100%; border-collapse: collapse;">
                      <tr>
                        <td style="background-color: #FFFFFF; padding: 20px; border-radius: 7px;">
                          <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 17px; font-weight: 600;">${vehicleName}</p>
                          ${reportData.vin ? `<p style="margin: 0 0 8px 0; color: #666666; font-size: 14px;">VIN: ${reportData.vin}</p>` : ''}
                          ${reportData.odometerReading ? `<p style="margin: 0 0 8px 0; color: #666666; font-size: 14px;">Odometer: ${reportData.odometerReading.toLocaleString()} miles</p>` : ''}
                          <div style="display: inline-block; margin-top: 8px;">
                            <span style="display: inline-block; background-color: ${freshnessColors.bg}; color: ${freshnessColors.text}; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600;">${freshness.status}</span>
                            <span style="color: #666666; font-size: 12px; margin-left: 8px;">Report expires on ${freshness.expiresOn}</span>
                          </div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              
              <!-- Recommendation Section — inside border, 8px rounded -->
              <table role="presentation" style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: ${statusColors.border}; padding: 2px; border-radius: 8px;">
                    <table role="presentation" style="width: 100%; border-collapse: collapse;">
                      <tr>
                        <td style="background-color: ${statusColors.bg}; padding: 24px; border-radius: 6px;">
                          <table role="presentation" style="width: 100%; border-collapse: collapse;">
                            <tr>
                              <td style="width: 40px; vertical-align: middle; padding-right: 12px;">
                                ${recommendationIcon}
                              </td>
                              <td style="vertical-align: middle;">
                                <p style="margin: 0; color: ${statusColors.border}; font-size: 20px; font-weight: 700;">${statusColors.headline}</p>
                              </td>
                            </tr>
                            ${reportData.summary ? `
                            <tr>
                              <td colspan="2" style="padding-top: 12px; padding-left: 0; padding-right: 0;">
                                <p style="margin: 0; color: #1a1a1a; font-size: 15px; line-height: 1.6;">${reportData.summary}</p>
                              </td>
                            </tr>
                            ` : ''}
                          </table>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              
              ${shareLinkHTML}
              
              <!-- Key Findings -->
              ${findingsHTML ? `
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: #FFFFFF; padding: 20px; border-radius: 8px;">
                    <p style="margin: 0 0 12px 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">Key Findings</p>
                    <ul style="margin: 0; padding-left: 20px; font-size: 15px; line-height: 1.7;">
                      ${findingsHTML}
                    </ul>
                  </td>
                </tr>
              </table>
              ` : ''}
              
              <!-- Disclaimer -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 24px 0;">
                <tr>
                  <td style="background-color: #FCFCFB; padding: 16px; border-radius: 8px;">
                    <p style="margin: 0; color: #666666; font-size: 13px; line-height: 1.6; font-style: italic;">
                      MintCheck scan was run on this vehicle on ${freshness.scanDateFormatted} and is valid for 14 days.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 8px 8px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #666666; font-size: 14px; line-height: 1.6;">
                Get your own vehicle scanned with MintCheck
              </p>
              <table role="presentation" style="border-collapse: collapse; margin: 0 auto;">
                <tr>
                  <td style="background-color: #3EB489; border-radius: 8px;">
                    <a href="https://mintcheckapp.com/download" style="display: inline-block; padding: 12px 24px; color: #FFFFFF; text-decoration: none; font-size: 14px; font-weight: 600;">
                      <img src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/3P-content/logos/apple-logo-wh.png" alt="" style="height: 18px; vertical-align: middle; margin-right: 8px;" />
                      Get the MintCheck App on iOS
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin: 24px 0 0 0; color: #999999; font-size: 13px; line-height: 1.6;">
                © 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 8px 0 0 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="https://mintcheckapp.com/privacy" style="color: #3EB489; text-decoration: none;">Privacy</a> • 
                <a href="https://mintcheckapp.com/terms" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Validate environment
    if (!RESEND_API_KEY) {
      console.error('RESEND_API_KEY not configured');
      return new Response(
        JSON.stringify({ error: 'Email service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      console.error('Supabase credentials not configured');
      return new Response(
        JSON.stringify({ error: 'Database service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get authorization header for user context
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    let requestData: ShareRequest;
    try {
      requestData = await req.json();
      console.log('Share request:', JSON.stringify({ ...requestData, reportData: '...' }, null, 2));
    } catch (parseError) {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON in request body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { scanId, recipients, message, createLink, reportData, userEmail, userName } = requestData;

    // Validate required fields
    if (!scanId || !reportData || !userEmail || !userName) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: scanId, reportData, userEmail, userName' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase client with service role for database operations
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get user ID from JWT
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabase.auth.getUser(jwt);
    
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid authorization token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Ensure scan exists and belongs to user (avoids 500/FK when share is tapped before save completes)
    const { data: scanRow, error: scanCheckError } = await supabase
      .from('scans')
      .select('id')
      .eq('id', scanId)
      .eq('user_id', user.id)
      .maybeSingle();

    if (scanCheckError || !scanRow) {
      return new Response(
        JSON.stringify({ error: 'Scan not found. Save the report first, then try sharing again. If you just finished scanning, wait a moment or close and reopen the report.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    let shareCode: string | undefined;
    let shareUrl: string | undefined;

    // Check if there's an existing share link for this scan
    const { data: existingShare } = await supabase
      .from('shared_reports')
      .select('share_code')
      .eq('scan_id', scanId)
      .single();
    
    if (existingShare?.share_code) {
      shareCode = existingShare.share_code;
      shareUrl = `https://mintcheckapp.com/report/${shareCode}`;
    }

    // Create shareable link if requested and doesn't exist
    if (createLink && !shareCode) {
      shareCode = generateShareCode();
      shareUrl = `https://mintcheckapp.com/report/${shareCode}`;

      // Check if user already has a shared link for this VIN
      if (reportData.vin) {
        const { data: existingLink } = await supabase
          .from('shared_reports')
          .select('id')
          .eq('user_id', user.id)
          .eq('vin', reportData.vin)
          .single();

        if (existingLink) {
          // Update existing link with new scan data
          const { error: updateError } = await supabase
            .from('shared_reports')
            .update({
              scan_id: scanId,
              share_code: shareCode,
              report_data: reportData,
              summary: reportData.summary || null,
              created_at: new Date().toISOString()
            })
            .eq('id', existingLink.id);

          if (updateError) {
            console.error('Error updating shared report:', updateError);
            return new Response(
              JSON.stringify({ error: 'Failed to update shared report' }),
              { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
          }
        } else {
          // Insert new shared report
          const { error: insertError } = await supabase
            .from('shared_reports')
            .insert({
              user_id: user.id,
              scan_id: scanId,
              share_code: shareCode,
              vin: reportData.vin,
              report_data: reportData,
              summary: reportData.summary || null
            });

          if (insertError) {
            console.error('Error creating shared report:', insertError);
            return new Response(
              JSON.stringify({ error: 'Failed to create shared report' }),
              { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
          }
        }
      } else {
        // No VIN, just insert new link
        const { error: insertError } = await supabase
          .from('shared_reports')
          .insert({
            user_id: user.id,
            scan_id: scanId,
            share_code: shareCode,
            vin: null,
            report_data: reportData,
            summary: reportData.summary || null
          });

        if (insertError) {
          console.error('Error creating shared report:', insertError);
          return new Response(
            JSON.stringify({ error: 'Failed to create shared report' }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }
      }

      // Also update the scans table with the share_code for persistence
      const { error: scanUpdateError } = await supabase
        .from('scans')
        .update({ share_code: shareCode })
        .eq('id', scanId);

      if (scanUpdateError) {
        console.error('Error updating scan with share_code:', scanUpdateError);
        // Don't fail the request, just log the error
      }
    }

    // Fetch summary from database if not in reportData
    let summary = reportData.summary;
    if (!summary) {
      // Try to get from shared_reports first (by scan_id or share_code)
      const { data: sharedReport } = await supabase
        .from('shared_reports')
        .select('summary')
        .eq('scan_id', scanId)
        .maybeSingle();
      if (sharedReport?.summary) {
        summary = sharedReport.summary;
      }
      
      // If still no summary, try to get from scans table
      if (!summary) {
        const { data: scan } = await supabase
          .from('scans')
          .select('summary')
          .eq('id', scanId)
          .single();
        if (scan?.summary) {
          summary = scan.summary;
        }
      }
    }

    // Update reportData with fetched summary
    const reportDataWithSummary = { ...reportData, summary };

    // Keep the public web report in sync whenever the user sends again (link may have been created earlier).
    const { error: refreshSnapshotError } = await supabase
      .from('shared_reports')
      .update({
        report_data: reportDataWithSummary,
        summary: reportDataWithSummary.summary ?? null,
      })
      .eq('scan_id', scanId)
      .eq('user_id', user.id);

    if (refreshSnapshotError) {
      console.error('Failed to refresh shared report snapshot:', refreshSnapshotError);
    }

    // Generate email HTML
    const emailHTML = generateEmailHTML(reportDataWithSummary, userName, message, shareUrl);

    // Prepare recipient list (user + any additional recipients)
    const allRecipients = [userEmail];
    if (recipients && recipients.length > 0) {
      // Filter out empty strings and duplicates
      const validRecipients = recipients
        .map(r => r.trim().toLowerCase())
        .filter(r => r && r !== userEmail.toLowerCase());
      allRecipients.push(...validRecipients);
    }

    const vehicleName = `${reportData.vehicleYear} ${reportData.vehicleMake} ${reportData.vehicleModel}`;

    // Send email via Resend (click tracking is domain-level). Our CTA uses a plain absolute URL.
    // If "View Full Report" redirect fails, try signed-in state (e.g. Gmail); tracking redirects
    // can misbehave when the recipient is signed out. Otherwise contact Resend with the failing URL.
    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: RESEND_FROM_EMAIL,
        to: allRecipients,
        subject: `Vehicle Scan Report - ${vehicleName}`,
        html: emailHTML
        // Note: PDF attachment will be added by the iOS app via a separate attachment mechanism
        // or we could generate it server-side in a future iteration
      })
    });

    if (!emailResponse.ok) {
      const errorText = await emailResponse.text();
      console.error('Resend API error:', emailResponse.status, errorText);
      return new Response(
        JSON.stringify({ error: 'Failed to send email', details: errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const emailResult = await emailResponse.json();
    console.log('Email sent successfully:', emailResult);

    return new Response(
      JSON.stringify({
        success: true,
        emailId: emailResult.id,
        shareCode: shareCode,
        shareUrl: shareUrl,
        recipientCount: allRecipients.length
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error: unknown) {
    console.error('Error in share-report:', error);
    const message = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
