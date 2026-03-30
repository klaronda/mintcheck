import { Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { CheckCircle } from 'lucide-react';
import { APP_STORE_URL, APPLE_LOGO_SVG_URL } from '@/app/constants/appStore';

export default function StarterKitSuccess() {
  return (
    <div className="min-h-screen bg-white flex flex-col items-center justify-center px-6">
      <Helmet>
        <title>Order confirmed – MintCheck Starter Kit</title>
        <meta name="robots" content="noindex,nofollow" />
        <link rel="canonical" href="https://mintcheckapp.com/starter-kit/success" />
      </Helmet>

      <div className="text-center max-w-md space-y-5">
        <CheckCircle className="w-14 h-14 text-primary mx-auto" />

        <h1 className="text-2xl font-semibold text-foreground">
          Order confirmed
        </h1>

        <p className="text-muted-foreground leading-relaxed">
          Your MintCheck Starter Kit is on its way. You’ll receive a shipping
          confirmation email once it ships.
        </p>

        <p className="text-muted-foreground leading-relaxed">
          While you wait, download the MintCheck app so you’re ready to scan as
          soon as your kit arrives.
        </p>

        <div className="flex flex-col gap-3 pt-2">
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-primary px-6 py-3 text-primary-foreground hover:opacity-90 w-full"
            style={{ fontWeight: 600 }}
          >
            <img
              src={APPLE_LOGO_SVG_URL}
              alt=""
              className="w-5 h-5 shrink-0 brightness-0 invert"
              aria-hidden
            />
            Get the iOS App
          </a>

          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-lg border border-border px-6 py-3 hover:bg-muted/50 w-full"
            style={{ fontWeight: 600 }}
          >
            Back to MintCheck
          </Link>
        </div>
      </div>
    </div>
  );
}
