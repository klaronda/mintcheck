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

const LOGO_SRC =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo-text/lockup-mint.svg';
const APPLE_LOGO_SRC =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/3P-content/logos/Apple_logo_black.svg';

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

function ReportContent({ report }: { report: SharedReport }) {
  const rd = report.report_data as ReportData;
  const vehicleName = `${rd.vehicleYear} ${rd.vehicleMake} ${rd.vehicleModel}`;
  const freshness = getScanFreshness(rd.scanDate);
  const freshnessStyle = getFreshnessBadgeStyle(freshness.status);
  const recoStyle = getRecommendationStyle(rd.recommendation);
  const scanDateLong = formatReportDateLong(rd.scanDate);

  const findings =
    rd.findings && rd.findings.length > 0
      ? rd.findings
      : rd.recommendation === 'safe'
        ? ['No trouble codes detected']
        : null;

  return (
    <main id="main-content" className="max-w-[600px] mx-auto px-6 py-8" style={{ backgroundColor: '#F8F8F7' }}>
      {/* Vehicle info card */}
      <div
        className="rounded-lg border p-5 mb-6"
        style={{ backgroundColor: '#F8F8F7', borderColor: '#E5E5E5' }}
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

      {/* Recommendation section: headline + AI summary */}
      <div
        className="rounded-lg border-2 p-6 mb-6"
        style={{
          backgroundColor: recoStyle.bg,
          borderColor: recoStyle.border,
          color: recoStyle.text,
        }}
      >
        <h2 className="m-0 mb-4" style={{ fontSize: '1.5rem', fontWeight: 600 }}>
          {recoStyle.headline}
        </h2>
        {rd.summary && (
          <p className="m-0 leading-relaxed" style={{ fontSize: '0.9375rem', opacity: 0.95 }}>
            {rd.summary}
          </p>
        )}
      </div>

      {/* Key findings */}
      {findings && findings.length > 0 && (
        <div className="mb-6">
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

      {/* Disclaimer */}
      <div
        className="rounded-lg border py-3 px-4 text-center mb-8"
        style={{ backgroundColor: '#FCFCFB', borderColor: '#E5E5E5' }}
      >
        <p className="m-0 text-sm" style={{ color: '#666666', lineHeight: 1.5 }}>
          Disclaimer: MintCheck scan was run on this vehicle on {scanDateLong} and is valid for 14 days.
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
          style={{ backgroundColor: '#1A1A1A', color: '#fff', fontWeight: 600 }}
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
        className="text-center text-sm mt-8"
        style={{ color: '#666666', lineHeight: 1.6 }}
      >
        If you are the owner of this scan and wish to remove this page, sign in to the MintCheck app and
        manage your shared links from the Settings tab.
      </p>
    </main>
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
