import { useEffect, useMemo, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { Link } from 'react-router';

function buildDeepLink(kind: 'confirm' | 'reset', search: string) {
  return `mintcheck://auth/${kind}${search || ''}`;
}

export default function AuthReset() {
  const [didAttemptOpen, setDidAttemptOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const token = useMemo(() => {
    const params = new URLSearchParams(window.location.search);
    return params.get('token') ?? '';
  }, []);

  const deepLink = useMemo(() => buildDeepLink('reset', window.location.search), []);

  useEffect(() => {
    window.location.href = deepLink;
    setDidAttemptOpen(true);
  }, [deepLink]);

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(window.location.href);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // no-op
    }
  }

  const isMissingToken = !token;

  return (
    <div className="min-h-screen bg-white flex items-center justify-center px-6">
      <Helmet>
        <title>Open MintCheck</title>
        <meta name="robots" content="noindex,nofollow" />
        <link rel="canonical" href={`https://mintcheckapp.com/auth/reset${window.location.search}`} />
      </Helmet>

      <div className="w-full max-w-md text-center space-y-4">
        <h1 className="text-2xl tracking-tight" style={{ fontWeight: 600 }}>
          Opening MintCheck…
        </h1>

        {isMissingToken ? (
          <p className="text-muted-foreground">
            This link looks invalid or expired. If you requested a new link, try again from the latest email.
          </p>
        ) : (
          <p className="text-muted-foreground">
            If the app didn’t open, you can download it or copy this link and open it on your phone.
          </p>
        )}

        <div className="pt-2 space-y-3">
          <Link
            to="/download"
            className="inline-flex w-full justify-center items-center bg-primary text-primary-foreground px-6 py-3 rounded-lg transition-opacity hover:opacity-90"
            style={{ fontWeight: 600 }}
          >
            Download the app
          </Link>

          <button
            type="button"
            onClick={copyLink}
            className="inline-flex w-full justify-center items-center border border-border px-6 py-3 rounded-lg hover:bg-muted/40"
            style={{ fontWeight: 600 }}
          >
            {copied ? 'Copied' : 'Copy link'}
          </button>
        </div>

        {didAttemptOpen ? (
          <p className="text-xs text-muted-foreground">
            Tip: Universal Links require the app to be installed and the domain to be configured.
          </p>
        ) : null}
      </div>
    </div>
  );
}

