import { Helmet } from 'react-helmet-async';

const OPEN_IN_APP_URL = 'mintcheck://buyer-pass/success';

export default function BuyerPassSuccess() {
  return (
    <div className="min-h-screen bg-white flex flex-col items-center justify-center px-6">
      <Helmet>
        <title>Buyer Pass activated – MintCheck</title>
        <meta name="robots" content="noindex,nofollow" />
        <link rel="canonical" href="https://mintcheckapp.com/buyer-pass/success" />
      </Helmet>

      <div className="text-center max-w-md">
        <h1 className="text-xl font-semibold text-gray-900 mb-2">
          Buyer Pass activated
        </h1>
        <p className="text-gray-600 mb-6">
          You now have 60 days of unlimited scanning — up to 10 vehicles per day. Open MintCheck to get started.
        </p>
        <a
          href={OPEN_IN_APP_URL}
          className="inline-flex items-center justify-center rounded-lg bg-primary px-4 py-2.5 text-sm font-medium text-primary-foreground hover:opacity-90 mb-3 w-full"
        >
          Open MintCheck
        </a>
        <p className="text-gray-500 text-sm">
          Don't have the app?{' '}
          <a href="https://apps.apple.com/app/mintcheck" className="text-primary font-medium hover:underline">
            Get MintCheck on the App Store
          </a>
        </p>
      </div>
    </div>
  );
}
