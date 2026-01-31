import { Menu, X as XIcon } from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router';

const LOGO_MINT = 'https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo/logo-mint.svg';

export default function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <nav className="sticky top-0 z-50 bg-white border-b border-border">
      <div className="max-w-6xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          <Link to="/">
            <img 
              src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo-text/lockup-mint.svg" 
              alt="MintCheck" 
              className="h-10"
            />
          </Link>
          
          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-8">
            <Link to="/#how-it-works" className="text-muted-foreground hover:text-foreground transition-colors" style={{ fontWeight: 600 }}>
              How It Works
            </Link>
            <Link to="/#use-cases" className="text-muted-foreground hover:text-foreground transition-colors" style={{ fontWeight: 600 }}>
              Use Cases
            </Link>
            <Link to="/#scanners" className="text-muted-foreground hover:text-foreground transition-colors" style={{ fontWeight: 600 }}>
              Get a Scanner
            </Link>
            <div className="flex flex-col items-end">
              <span className="text-xs text-muted-foreground mb-1">Coming Spring 2026!</span>
              <span 
                className="inline-flex items-center gap-2 bg-primary/40 text-primary-foreground/70 px-6 py-2.5 rounded-lg cursor-not-allowed opacity-70"
                style={{ fontWeight: 600 }}
                aria-disabled
              >
                <img src={LOGO_MINT} alt="" className="w-4 h-4 brightness-0 invert opacity-70" aria-hidden />
                Get the App
              </span>
            </div>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 text-foreground"
            aria-label="Toggle menu"
          >
            {mobileMenuOpen ? (
              <XIcon className="w-6 h-6" />
            ) : (
              <Menu className="w-6 h-6" />
            )}
          </button>
        </div>

        {/* Mobile Navigation */}
        {mobileMenuOpen && (
          <div className="md:hidden pt-4 pb-4 flex flex-col gap-4">
            <Link 
              to="/#how-it-works" 
              className="text-muted-foreground hover:text-foreground transition-colors py-2"
              style={{ fontWeight: 600 }}
              onClick={() => setMobileMenuOpen(false)}
            >
              How It Works
            </Link>
            <Link 
              to="/#use-cases" 
              className="text-muted-foreground hover:text-foreground transition-colors py-2"
              style={{ fontWeight: 600 }}
              onClick={() => setMobileMenuOpen(false)}
            >
              Use Cases
            </Link>
            <Link 
              to="/#scanners" 
              className="text-muted-foreground hover:text-foreground transition-colors py-2"
              style={{ fontWeight: 600 }}
              onClick={() => setMobileMenuOpen(false)}
            >
              Get a Scanner
            </Link>
            <div className="mt-2">
              <span className="text-xs text-muted-foreground block mb-1">Coming Spring 2026!</span>
              <span 
                className="inline-flex items-center justify-center gap-2 bg-primary/40 text-primary-foreground/70 px-6 py-3 rounded-lg cursor-not-allowed opacity-70 w-full"
                style={{ fontWeight: 600 }}
                aria-disabled
              >
                <img src={LOGO_MINT} alt="" className="w-4 h-4 brightness-0 invert opacity-70" aria-hidden />
                Get the App
              </span>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}
