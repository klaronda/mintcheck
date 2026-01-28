import { useParams, Link } from 'react-router';
import { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { sharedReportsApi } from '@/lib/supabase';
import type { SharedReport, ReportData } from '@/lib/supabase';
import {
  getScanFreshness,
  formatReportDateLong,
  getRecommendationStyle,
  getFreshnessBadgeStyle,
} from '@/app/utils/reportUtils';
import { CheckCircle, AlertCircle, XCircle, ChevronDown, ChevronUp, Mail } from 'lucide-react';

const LOGO_SRC =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo-text/lockup-mint.svg';
const APPLE_LOGO_SRC =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/3P-content/logos/Apple_logo_black.svg';

// Recommendation icon component
function RecommendationIcon({ recommendation }: { recommendation: 'safe' | 'caution' | 'not-recommended' }) {
  const recoStyle = getRecommendationStyle(recommendation);
  const iconProps = { size: 32, strokeWidth: 2.5, color: recoStyle.text };
  
  switch (recommendation) {
    case 'safe':
      return <CheckCircle {...iconProps} />;
    case 'caution':
      return <AlertCircle {...iconProps} />;
    case 'not-recommended':
      return <XCircle {...iconProps} />;
    default:
      return null;
  }
}

// System detail type
interface SystemDetailData {
  name: string;
  status: string;
  color: string;
  details: string[];
  explanation: string;
}

function LoadingState() {
  return (
    <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#F8F8F7' }}>
      <div className="text-center">
        <div className="w-8 h-8 border-4 border-[#3EB489] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
        <p className="text-[#666666]">Loading report…</p>
      </div>
    </div>
  );
}

function NotFoundState() {
  return (
    <div className="min-h-screen flex items-center justify-center px-6" style={{ backgroundColor: '#F8F8F7' }}>
      <div className="max-w-md w-full text-center">
        <h1 className="text-2xl mb-4" style={{ fontWeight: 600, color: '#1A1A1A' }}>
          Report not found
        </h1>
        <p className="text-[#666666] mb-6 leading-relaxed">
          This link may have been removed by the person who shared it, or the report may no longer be available.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link
            to="/"
            className="inline-flex items-center justify-center px-6 py-3 rounded-lg text-white transition-opacity hover:opacity-90"
            style={{ backgroundColor: '#3EB489', fontWeight: 600 }}
          >
            Go to MintCheck
          </Link>
          <Link
            to="/download"
            className="inline-flex items-center justify-center px-6 py-3 rounded-lg border transition-colors hover:bg-gray-50"
            style={{ borderColor: '#E5E5E5', color: '#1A1A1A', fontWeight: 600 }}
          >
            Download the app
          </Link>
        </div>
      </div>
    </div>
  );
}

function ReportHeader() {
  return (
    <header className="bg-white border-b" style={{ borderColor: '#E5E5E5' }}>
      <div className="max-w-[600px] mx-auto px-6 py-4 flex items-center justify-between">
        <Link to="/" aria-label="MintCheck home">
          <img src={LOGO_SRC} alt="MintCheck" className="h-10" />
        </Link>
        <h2 className="text-lg md:text-xl" style={{ fontWeight: 600, color: '#1A1A1A' }}>
          Vehicle Scan Report
        </h2>
      </div>
    </header>
  );
}

// Generate system details from report data
function generateSystemDetails(rd: ReportData): SystemDetailData[] {
  const dtcs = rd.dtcAnalyses || [];
  const hasDTCs = dtcs.length > 0;
  
  // Engine status
  const engineDTCs = dtcs.filter(d => d.code.startsWith('P0') || d.code.startsWith('P1'));
  const engineOK = engineDTCs.length === 0;
  const engineStatus = engineOK ? 'OK' : `${engineDTCs.length} Issue${engineDTCs.length > 1 ? 's' : ''}`;
  const engineColor = engineOK ? '#3EB489' : '#C94A4A';
  const engineDetails = engineOK 
    ? ['No engine trouble codes detected', 'Engine systems functioning normally']
    : engineDTCs.map(d => `${d.code}: ${d.name}`);
  const engineExplanation = engineOK
    ? 'The engine control systems are functioning properly with no diagnostic trouble codes.'
    : 'Engine-related diagnostic trouble codes were found. These may indicate issues that need attention.';
  
  // Fuel system
  const fuelDTCs = dtcs.filter(d => d.code.startsWith('P02') || d.code.startsWith('P017'));
  const fuelOK = fuelDTCs.length === 0;
  const fuelStatus = fuelOK ? 'OK' : `${fuelDTCs.length} Issue${fuelDTCs.length > 1 ? 's' : ''}`;
  const fuelColor = fuelOK ? '#3EB489' : '#E3B341';
  const fuelDetails = fuelOK 
    ? ['Fuel system operating normally', 'No fuel-related codes detected']
    : fuelDTCs.map(d => `${d.code}: ${d.name}`);
  const fuelExplanation = fuelOK
    ? 'The fuel delivery and injection systems are operating within normal parameters.'
    : 'Fuel system codes were detected which may affect fuel efficiency or performance.';
  
  // Emissions
  const emissionsDTCs = dtcs.filter(d => d.code.startsWith('P04') || d.code.startsWith('P042'));
  const emissionsOK = emissionsDTCs.length === 0;
  const emissionsStatus = emissionsOK ? 'OK' : `${emissionsDTCs.length} Issue${emissionsDTCs.length > 1 ? 's' : ''}`;
  const emissionsColor = emissionsOK ? '#3EB489' : '#E3B341';
  const emissionsDetails = emissionsOK 
    ? ['Emissions systems operating normally', 'Catalytic converter functioning properly']
    : emissionsDTCs.map(d => `${d.code}: ${d.name}`);
  const emissionsExplanation = emissionsOK
    ? 'The emissions control systems including the catalytic converter are functioning properly.'
    : 'Emissions-related codes were found. The vehicle may not pass emissions testing.';
  
  // Electrical
  const electricalDTCs = dtcs.filter(d => d.code.startsWith('B') || d.code.startsWith('U'));
  const electricalOK = electricalDTCs.length === 0;
  const electricalStatus = electricalOK ? 'OK' : `${electricalDTCs.length} Issue${electricalDTCs.length > 1 ? 's' : ''}`;
  const electricalColor = electricalOK ? '#3EB489' : '#E3B341';
  const electricalDetails = electricalOK 
    ? ['Battery and charging system normal', 'No electrical faults detected']
    : electricalDTCs.map(d => `${d.code}: ${d.name}`);
  const electricalExplanation = electricalOK
    ? 'The electrical system is functioning properly.'
    : 'Electrical system codes were detected which may indicate wiring or sensor issues.';
  
  return [
    { name: 'Engine', status: engineStatus, color: engineColor, details: engineDetails, explanation: engineExplanation },
    { name: 'Fuel System', status: fuelStatus, color: fuelColor, details: fuelDetails, explanation: fuelExplanation },
    { name: 'Emissions', status: emissionsStatus, color: emissionsColor, details: emissionsDetails, explanation: emissionsExplanation },
    { name: 'Electrical', status: electricalStatus, color: electricalColor, details: electricalDetails, explanation: electricalExplanation },
  ];
}

// System Details Accordion Component
function SystemDetailsAccordion({ systems }: { systems: SystemDetailData[] }) {
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set());
  
  const toggleSection = (name: string) => {
    setExpandedSections(prev => {
      const next = new Set(prev);
      if (next.has(name)) {
        next.delete(name);
      } else {
        next.add(name);
      }
      return next;
    });
  };
  
  return (
    <div className="rounded-lg border bg-white mb-6" style={{ borderColor: '#E5E5E5' }}>
      <div className="p-5 border-b" style={{ borderColor: '#E5E5E5' }}>
        <h3 className="m-0" style={{ fontSize: '1.125rem', fontWeight: 600, color: '#1A1A1A' }}>
          System Details
        </h3>
      </div>
      {systems.map((system, index) => {
        const isExpanded = expandedSections.has(system.name);
        const isLast = index === systems.length - 1;
        
        return (
          <div key={system.name}>
            <button
              onClick={() => toggleSection(system.name)}
              className="w-full flex items-center justify-between p-4 text-left transition-colors hover:bg-gray-50"
              style={{ backgroundColor: isExpanded ? '#F8F8F7' : 'transparent' }}
            >
              <div className="flex items-center gap-3">
                <span
                  className="w-2 h-2 rounded-full"
                  style={{ backgroundColor: system.color }}
                />
                <span style={{ fontWeight: 600, color: '#1A1A1A' }}>{system.name}</span>
              </div>
              <div className="flex items-center gap-3">
                <span style={{ color: '#666666', fontWeight: 500 }}>{system.status}</span>
                {isExpanded ? (
                  <ChevronUp size={16} color="#666666" />
                ) : (
                  <ChevronDown size={16} color="#666666" />
                )}
              </div>
            </button>
            
            {isExpanded && (
              <div className="px-4 pb-4 pt-2" style={{ backgroundColor: '#FCFCFB' }}>
                <p className="mb-3 leading-relaxed" style={{ fontSize: '0.9375rem', color: '#1A1A1A' }}>
                  {system.explanation}
                </p>
                <ul className="m-0 pl-5 space-y-1" style={{ fontSize: '0.875rem', color: '#666666' }}>
                  {system.details.map((detail, i) => (
                    <li key={i}>{detail}</li>
                  ))}
                </ul>
              </div>
            )}
            
            {!isLast && <div className="border-b" style={{ borderColor: '#E5E5E5' }} />}
          </div>
        );
      })}
    </div>
  );
}

// Report Footer Component
function ReportFooter() {
  return (
    <footer className="mt-12 py-8 px-6 text-center" style={{ backgroundColor: '#3EB489' }}>
      <div className="max-w-[600px] mx-auto">
        <div className="flex flex-col sm:flex-row justify-between items-center gap-4 text-sm text-white/90">
          <div className="flex items-center gap-2">
            <span style={{ fontWeight: 600 }} className="text-white">MintCheck</span>
            <span>© 2026</span>
          </div>
          <div className="flex flex-wrap items-center justify-center gap-4 sm:gap-6">
            <Link to="/support" className="hover:text-white transition-colors">
              Support
            </Link>
            <Link to="/contact" className="hover:text-white transition-colors">
              Contact
            </Link>
            <Link to="/privacy" className="hover:text-white transition-colors">
              Privacy Policy
            </Link>
            <Link to="/terms" className="hover:text-white transition-colors">
              Terms of Use
            </Link>
            <a href="mailto:support@mintcheckapp.com" className="flex items-center gap-2 hover:text-white transition-colors">
              <Mail className="w-4 h-4" />
              <span className="hidden sm:inline">support@mintcheckapp.com</span>
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}

function ReportContent({ report }: { report: SharedReport }) {
  const rd = report.report_data as ReportData;
  const vehicleName = `${rd.vehicleYear} ${rd.vehicleMake} ${rd.vehicleModel}`;
  const freshness = getScanFreshness(rd.scanDate);
  const freshnessStyle = getFreshnessBadgeStyle(freshness.status);
  const recoStyle = getRecommendationStyle(rd.recommendation);
  const scanDateLong = formatReportDateLong(rd.scanDate);
  
  // Generate system details
  const systemDetails = generateSystemDetails(rd);

  // Get summary from dedicated column, fallback to report_data.summary
  const summary = report.summary || rd.summary;

  const findings =
    rd.findings && rd.findings.length > 0
      ? rd.findings
      : rd.recommendation === 'safe'
        ? ['No trouble codes detected']
        : null;

  return (
    <>
      <main id="main-content" className="max-w-[600px] mx-auto px-6 py-8" style={{ backgroundColor: '#F8F8F7' }}>
        {/* Vehicle info card */}
        <div
          className="rounded-lg border p-5 mb-6"
          style={{ backgroundColor: '#FFFFFF', borderColor: '#E5E5E5' }}
        >
          <p className="mb-2" style={{ fontSize: '1.0625rem', fontWeight: 600, color: '#1A1A1A' }}>
            {vehicleName}
          </p>
          {rd.vin && (
            <p className="mb-2 text-sm" style={{ color: '#666666' }}>
              VIN: {rd.vin}
            </p>
          )}
          {rd.odometerReading != null && (
            <p className="mb-2 text-sm" style={{ color: '#666666' }}>
              Odometer: {rd.odometerReading.toLocaleString()} miles
            </p>
          )}
          <div className="flex flex-wrap items-center gap-2 mt-2">
            <span
              className="inline-block px-2.5 py-1 rounded-full text-xs font-semibold"
              style={{ backgroundColor: freshnessStyle.bg, color: freshnessStyle.text }}
            >
              {freshness.status}
            </span>
            <span className="text-xs" style={{ color: '#666666' }}>
              Report expires on {freshness.expiresOnFormatted}
            </span>
          </div>
        </div>

        {/* Recommendation section with icon */}
        <div
          className="rounded-lg border-2 p-6 mb-6"
          style={{
            backgroundColor: recoStyle.bg,
            borderColor: recoStyle.border,
          }}
        >
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 mt-1">
              <RecommendationIcon recommendation={rd.recommendation} />
            </div>
            <h2 className="m-0 flex-1" style={{ fontSize: '1.5rem', fontWeight: 700, color: recoStyle.text }}>
              {recoStyle.headline}
            </h2>
          </div>
          {summary && (
            <p
              className="m-0 mt-3 leading-relaxed"
              style={{ fontSize: '0.9375rem', color: '#666666' }}
            >
              {summary}
            </p>
          )}
        </div>

        {/* Key findings */}
        {findings && findings.length > 0 && (
          <div className="rounded-lg border bg-white p-5 mb-6" style={{ borderColor: '#E5E5E5' }}>
            <p className="mb-3" style={{ fontSize: '0.9375rem', fontWeight: 600, color: '#1A1A1A' }}>
              Key Findings
            </p>
            <ul className="m-0 pl-5 space-y-2" style={{ fontSize: '0.9375rem', color: '#666666', lineHeight: 1.7 }}>
              {findings.map((f, i) => (
                <li key={i}>{f}</li>
              ))}
            </ul>
          </div>
        )}

        {/* System Details Accordion */}
        <SystemDetailsAccordion systems={systemDetails} />

        {/* Disclaimer */}
        <div
          className="rounded-lg border py-3 px-4 text-center mb-8"
          style={{ backgroundColor: '#FCFCFB', borderColor: '#E5E5E5' }}
        >
          <p className="m-0 text-sm italic" style={{ color: '#666666', lineHeight: 1.5 }}>
            MintCheck scan was run on this vehicle on {scanDateLong} and is valid for 14 days.
          </p>
        </div>

        {/* Download CTA */}
        <div className="text-center mb-10">
          <p className="mb-4" style={{ fontSize: '0.875rem', color: '#666666', lineHeight: 1.6 }}>
            Get your own vehicle scanned with MintCheck
          </p>
          <a
            href="https://apps.apple.com/app/mintcheck"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-3 px-8 py-4 rounded-lg transition-opacity hover:opacity-90"
            style={{ backgroundColor: '#3EB489', color: '#fff', fontWeight: 600 }}
          >
            <img
              src={APPLE_LOGO_SRC}
              alt=""
              className="w-5 h-5"
              style={{ filter: 'brightness(0) invert(1)' }}
            />
            Get the MintCheck App on iOS
          </a>
        </div>

        {/* Footer disclaimer */}
        <p
          className="text-center text-sm"
          style={{ color: '#666666', lineHeight: 1.6 }}
        >
          If you are the owner of this scan and wish to remove this page, sign in to the MintCheck app and
          manage your shared links from the Settings tab.
        </p>
      </main>
      
      <ReportFooter />
    </>
  );
}

export default function ReportPage() {
  const { shareCode } = useParams<{ shareCode: string }>();
  const [report, setReport] = useState<SharedReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    if (!shareCode?.trim()) {
      setLoading(false);
      setNotFound(true);
      return;
    }

    let cancelled = false;

    async function fetchReport() {
      try {
        const data = await sharedReportsApi.getByShareCode(shareCode!);
        if (!cancelled) {
          setReport(data);
          setNotFound(false);
        }
      } catch {
        if (!cancelled) setNotFound(true);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    fetchReport();
    return () => {
      cancelled = true;
    };
  }, [shareCode]);

  if (loading) return <LoadingState />;
  if (notFound || !report) return <NotFoundState />;

  const rd = report.report_data as ReportData;
  const vehicleName = `${rd.vehicleYear} ${rd.vehicleMake} ${rd.vehicleModel}`;

  return (
    <div className="min-h-screen" style={{ backgroundColor: '#F8F8F7' }}>
      <Helmet>
        <title>Vehicle Report: {vehicleName}</title>
        <meta name="robots" content="noindex, nofollow" />
      </Helmet>
      <ReportHeader />
      <ReportContent report={report} />
    </div>
  );
}
