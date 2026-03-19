import { Link } from 'react-router';
import { Helmet } from 'react-helmet-async';
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-white">
      <Helmet>
        <title>Page Not Found (404) | MintCheck</title>
        <meta
          name="description"
          content="The page you are looking for could not be found."
        />
        <meta name="robots" content="noindex, follow" />
      </Helmet>

      <Navbar />

      <main className="max-w-4xl mx-auto px-6 py-20">
        <div className="border border-border rounded-xl p-8 md:p-10">
          <p className="text-sm text-muted-foreground mb-2">404</p>
          <h1 className="text-3xl md:text-4xl mb-4" style={{ fontWeight: 600 }}>
            Page not found
          </h1>
          <p className="text-muted-foreground leading-relaxed mb-8">
            The page you requested does not exist or may have moved.
          </p>
          <div className="flex flex-wrap gap-3">
            <Link
              to="/"
              className="inline-flex items-center justify-center rounded-lg bg-primary text-primary-foreground px-5 py-2.5 hover:opacity-90 transition-opacity"
              style={{ fontWeight: 600 }}
            >
              Go to Home
            </Link>
            <Link
              to="/support"
              className="inline-flex items-center justify-center rounded-lg border border-border px-5 py-2.5 text-foreground hover:bg-accent transition-colors"
              style={{ fontWeight: 600 }}
            >
              Visit Support
            </Link>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
