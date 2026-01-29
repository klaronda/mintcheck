import { useParams, Link } from 'react-router';
import { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';

const LOGO_SRC =
  'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo-text/lockup-mint.svg';

type ReportState = 'loading' | 'found' | 'not_found' | 'error';

interface ReportPayload {
  html: string;
  yearMakeModel?: string;
}

export default function DeepCheckReportPage() {
  const { code } = useParams<{ code: string }>();
  const [state, setState] = useState<ReportState>('loading');
  const [payload, setPayload] = useState<ReportPayload | null>(null);

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

  if (state === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#F8F8F7' }}>
        <Helmet>
          <title>Deep Vehicle Check – MintCheck</title>
        </Helmet>
        <div className="text-center">
          <div
            className="w-8 h-8 border-4 border-[#3EB489] border-t-transparent rounded-full animate-spin mx-auto mb-4"
          />
          <p className="text-[#666666]">Loading report…</p>
        </div>
      </div>
    );
  }

  if (state === 'not_found' || state === 'error') {
    return (
      <div className="min-h-screen flex items-center justify-center px-6" style={{ backgroundColor: '#F8F8F7' }}>
        <Helmet>
          <title>Report not found – MintCheck</title>
        </Helmet>
        <div className="max-w-md w-full text-center">
          <h1 className="text-2xl mb-4" style={{ fontWeight: 600, color: '#1A1A1A' }}>
            Report not found
          </h1>
          <p className="text-[#666666] mb-6 leading-relaxed">
            This link may be invalid or the report may no longer be available.
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

  return (
    <div className="min-h-screen flex flex-col" style={{ backgroundColor: '#F8F8F7' }}>
      <Helmet>
        <title>
          {payload?.yearMakeModel ? `Deep Vehicle Check – ${payload.yearMakeModel}` : 'Deep Vehicle Check'} –
          MintCheck
        </title>
      </Helmet>
      <header className="bg-white border-b flex-shrink-0" style={{ borderColor: '#E5E5E5' }}>
        <div className="max-w-[900px] mx-auto px-6 py-4 flex items-center justify-between">
          <Link to="/" aria-label="MintCheck home">
            <img src={LOGO_SRC} alt="MintCheck" className="h-10" />
          </Link>
          <h2 className="text-lg md:text-xl" style={{ fontWeight: 600, color: '#1A1A1A' }}>
            Deep Vehicle Check
          </h2>
        </div>
      </header>
      <main className="flex-1 min-h-0 p-4">
        <div className="max-w-[900px] mx-auto bg-white rounded-lg overflow-hidden border" style={{ borderColor: '#E5E5E5', minHeight: 480 }}>
          <iframe
            title="Carfax report"
            srcDoc={payload?.html ?? ''}
            sandbox="allow-same-origin"
            className="w-full h-full min-h-[70vh] border-0"
          />
        </div>
      </main>
    </div>
  );
}
