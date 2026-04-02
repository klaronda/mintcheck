import { RouterProvider } from 'react-router';
import * as Sentry from '@sentry/react';
import { router } from './routes';
import { HelmetProvider } from 'react-helmet-async';
import { AdminProvider } from './contexts/AdminContext';

function FallbackError() {
  return (
    <div className="min-h-screen flex items-center justify-center px-6" style={{ backgroundColor: '#F8F8F7' }}>
      <div className="max-w-md w-full text-center">
        <h1 className="text-2xl mb-4" style={{ fontWeight: 600, color: '#1A1A1A' }}>
          Something went wrong
        </h1>
        <p className="mb-6 leading-relaxed" style={{ color: '#666666' }}>
          An unexpected error occurred. The team has been notified.
        </p>
        <button
          type="button"
          onClick={() => window.location.reload()}
          className="inline-flex items-center justify-center px-6 py-3 rounded-lg text-white transition-opacity hover:opacity-90"
          style={{ backgroundColor: '#3EB489', fontWeight: 600 }}
        >
          Reload page
        </button>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <Sentry.ErrorBoundary fallback={<FallbackError />}>
      <HelmetProvider>
        <AdminProvider>
          <RouterProvider router={router} />
        </AdminProvider>
      </HelmetProvider>
    </Sentry.ErrorBoundary>
  );
}
