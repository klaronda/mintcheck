import { Helmet } from 'react-helmet-async';

const DEEP_CHECK_SUCCESS_DEEPLINK = 'mintcheck://deep-check/success';

export default function DeepCheckSuccess() {
  return (
    <div className="min-h-screen bg-white flex flex-col items-center justify-center px-6">
      <Helmet>
        <title>Payment successful – MintCheck</title>
        <meta name="robots" content="noindex,nofollow" />
        <link rel="canonical" href="https://mintcheckapp.com/deep-check/success" />
      </Helmet>

      <div className="text-center max-w-md">
        <h1 className="text-xl font-semibold text-gray-900 mb-2">
          Payment successful
        </h1>
        <p className="text-gray-600 mb-6">
          Opening MintCheck…
        </p>
        <a
          href={DEEP_CHECK_SUCCESS_DEEPLINK}
          className="inline-flex items-center justify-center rounded-lg bg-primary px-4 py-2.5 text-sm font-medium text-primary-foreground hover:opacity-90"
        >
          Open in app
        </a>
      </div>
    </div>
  );
}
