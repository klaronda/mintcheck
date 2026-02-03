import { useParams, Link } from 'react-router';
import { useEffect, useState, useMemo } from 'react';
import { Helmet } from 'react-helmet-async';
import { stripBrandingAndApplyMintCheckStyle } from '@/app/utils/deepCheckReportHtml';
import { extractCarfaxVhrFromHtml } from '@/app/utils/extractCarfaxVhrFromHtml';
import { VehicleHistoryReport } from '@/app/components/VehicleHistoryReport';

const LOGO_SRC =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo-text/lockup-mint.svg';

type ReportState = 'loading' | 'found' | 'not_found' | 'error';

interface ReportPayload {
  html: string;
  yearMakeModel?: string;
  reportEmailedAt?: string; // ISO timestamp when report was emailed to purchaser
}

function formatEmailedAt(iso: string): string {
  try {
    const d = new Date(iso);
    const date = d.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
    const time = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone ?? '';
    return `Emailed to you on ${date} at ${time} ${tz}`;
  } catch {
    return '';
  }
}

export default function DeepCheckReportPage() {
  const { code } = useParams<{ code: string }>();
  const [state, setState] = useState<ReportState>('loading');
  const [payload, setPayload] = useState<ReportPayload | null>(null);
  const [emailSending, setEmailSending] = useState(false);
  const [emailSent, setEmailSent] = useState(false);

  useEffect(() => {
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
    if (!code?.trim() || !supabaseUrl || !anonKey) {
      setState('not_found');
      return;
    }

    const url = `${supabaseUrl}/functions/v1/get-deep-check-report?code=${encodeURIComponent(code.trim())}`;
    fetch(url, {
      headers: { Authorization: `Bearer ${anonKey}` },
    })
      .then((res) => {
        if (!res.ok) {
          setState(res.status === 404 ? 'not_found' : 'error');
          return null;
        }
        return res.json();
      })
      .then((data: ReportPayload | null) => {
        if (data?.html) {
          setPayload(data);
          setState('found');
        } else {
          setState('not_found');
        }
      })
      .catch(() => setState('error'));
  }, [code]);

  const styledHtml = useMemo(
    () => (payload?.html ? stripBrandingAndApplyMintCheckStyle(payload.html) : ''),
    [payload?.html]
  );

  const extractedVhr = useMemo(() => {
    if (!payload?.html) return null;
    const result = extractCarfaxVhrFromHtml(payload.html);
    if (!result?.vhr || typeof result.vhr !== 'object') return null;
    const vhr = result.vhr as Record<string, unknown>;
    if (!vhr?.headerSection || typeof vhr.headerSection !== 'object') return null;
    const header = vhr.headerSection as Record<string, unknown>;
    if (!header?.vehicleInformationSection) return null;
    return result;
  }, [payload?.html]);

  const useReactReport = extractedVhr != null;

  if (state === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#F8F8F7]">
        <Helmet>
          <title>Deep Vehicle Check – MintCheck</title>
        </Helmet>
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-muted-foreground">Loading report…</p>
        </div>
      </div>
    );
  }

  if (state === 'not_found' || state === 'error') {
    return (
      <div className="min-h-screen flex items-center justify-center px-6 bg-[#F8F8F7]">
        <Helmet>
          <title>Report not found – MintCheck</title>
        </Helmet>
        <div className="max-w-md w-full text-center">
          <h1 className="text-2xl mb-4 font-semibold text-foreground">Report not found</h1>
          <p className="text-muted-foreground mb-6 leading-relaxed">
            This link may be invalid or the report may no longer be available.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              to="/"
              className="inline-flex items-center justify-center px-6 py-3 rounded-lg bg-primary text-primary-foreground font-semibold transition-opacity hover:opacity-90"
            >
              Go to MintCheck
            </Link>
            <Link
              to="/download"
              className="inline-flex items-center justify-center px-6 py-3 rounded-lg border border-border bg-background font-semibold transition-colors hover:bg-muted/50"
            >
              Download the app
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#F8F8F7]">
      <Helmet>
        <title>
          {payload?.yearMakeModel ? `Deep Vehicle Check – ${payload.yearMakeModel}` : 'Deep Vehicle Check'} –
          MintCheck
        </title>
      </Helmet>
      <header className="bg-white border-b border-border flex-shrink-0">
        <div className="max-w-[900px] mx-auto px-6 py-4 flex items-center justify-between">
          <Link to="/" aria-label="MintCheck home">
            <img src={LOGO_SRC} alt="MintCheck" className="h-10" />
          </Link>
          <h2 className="text-lg md:text-xl font-semibold text-foreground">Deep Vehicle Check</h2>
        </div>
      </header>
      {/* Emailed status or Email me report — above content, below header */}
      {payload && (
        <div className="max-w-[900px] mx-auto w-full px-4 md:px-6 py-3 flex items-center justify-center gap-3 border-b border-border/50 bg-white/80">
          {payload.reportEmailedAt ? (
            <span className="text-sm text-muted-foreground">
              {formatEmailedAt(payload.reportEmailedAt)}
            </span>
          ) : emailSent ? (
            <span className="text-sm text-primary font-medium">Report sent to your email.</span>
          ) : (
            <button
              type="button"
              disabled={emailSending}
              onClick={async () => {
                if (!code?.trim()) return;
                setEmailSending(true);
                const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
                const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
                try {
                  const res = await fetch(`${supabaseUrl}/functions/v1/email-deep-check-report`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${anonKey}` },
                    body: JSON.stringify({ code: code.trim() }),
                  });
                  if (res.ok) setEmailSent(true);
                } finally {
                  setEmailSending(false);
                }
              }}
              className="inline-flex items-center justify-center px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 disabled:opacity-60"
            >
              {emailSending ? 'Sending…' : 'Email me report'}
            </button>
          )}
        </div>
      )}
      <main className="flex-1 min-h-0 p-4 md:p-6">
        {useReactReport ? (
          <div className="max-w-[1200px] mx-auto">
            <VehicleHistoryReport carfaxData={{ vhr: extractedVhr.vhr }} />
          </div>
        ) : (
          <>
            {payload?.yearMakeModel && (
              <p className="max-w-[900px] mx-auto mb-3 text-muted-foreground font-medium">
                {payload.yearMakeModel}
              </p>
            )}
            <div
              className="max-w-[900px] mx-auto bg-white rounded-xl overflow-hidden border shadow-sm"
              style={{ borderColor: 'var(--border)', minHeight: 480 }}
            >
              <iframe
                title="Deep Vehicle Check report"
                srcDoc={styledHtml}
                sandbox="allow-same-origin"
                className="w-full h-full min-h-[70vh] border-0"
              />
            </div>
          </>
        )}
      </main>
    </div>
  );
}
