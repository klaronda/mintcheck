import { useEffect } from 'react';
import { useRouteError, Link } from 'react-router';
import * as Sentry from '@sentry/react';

export default function SentryRouteError() {
  const error = useRouteError() as Error;

  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center px-6" style={{ backgroundColor: '#F8F8F7' }}>
      <div className="max-w-md w-full text-center">
        <h1 className="text-2xl mb-4" style={{ fontWeight: 600, color: '#1A1A1A' }}>
          Something went wrong
        </h1>
        <p className="mb-6 leading-relaxed" style={{ color: '#666666' }}>
          An unexpected error occurred. The team has been notified.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="inline-flex items-center justify-center px-6 py-3 rounded-lg text-white transition-opacity hover:opacity-90"
            style={{ backgroundColor: '#3EB489', fontWeight: 600 }}
          >
            Reload page
          </button>
          <Link
            to="/"
            className="inline-flex items-center justify-center px-6 py-3 rounded-lg border transition-colors hover:bg-gray-50"
            style={{ borderColor: '#E5E5E5', color: '#1A1A1A', fontWeight: 600 }}
          >
            Go to home
          </Link>
        </div>
      </div>
    </div>
  );
}
