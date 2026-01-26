import { Menu, X as XIcon } from 'lucide-react';
import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router';

export default function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  const handleAnchorClick = (e: React.MouseEvent<HTMLAnchorElement>, hash: string) => {
    e.preventDefault();
    const targetId = hash.replace('#', '');
    
    // If we're on the home page, scroll to the section
    if (location.pathname === '/') {
      const element = document.getElementById(targetId);
      if (element) {
        const offset = 80; // Account for sticky navbar
        const elementPosition = element.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - offset;
        
        window.scrollTo({
          top: offsetPosition,
          behavior: 'smooth'
        });
        setMobileMenuOpen(false);
      }
    } else {
      // Navigate to home page with hash, then scroll
      navigate(`/${hash}`);
      setTimeout(() => {
        const element = document.getElementById(targetId);
        if (element) {
          const offset = 80;
          const elementPosition = element.getBoundingClientRect().top;
          const offsetPosition = elementPosition + window.pageYOffset - offset;
          
          window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
          });
        }
      }, 100);
      setMobileMenuOpen(false);
    }
  };

  return (
    <nav className="sticky top-0 z-50 bg-white border-b border-border" aria-label="Main navigation">
      <div className="max-w-6xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          <Link to="/" aria-label="MintCheck home">
            <img 
              src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo-text/lockup-mint.svg" 
              alt="MintCheck" 
              className="h-10"
            />
          </Link>
          
          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-8" role="navigation" aria-label="Desktop navigation">
            <a 
              href="#how-it-works" 
              onClick={(e) => handleAnchorClick(e, '#how-it-works')}
              className="text-muted-foreground hover:text-foreground transition-colors" 
              style={{ fontWeight: 600 }}
            >
              How It Works
            </a>
            <a 
              href="#use-cases" 
              onClick={(e) => handleAnchorClick(e, '#use-cases')}
              className="text-muted-foreground hover:text-foreground transition-colors" 
              style={{ fontWeight: 600 }}
            >
              Use Cases
            </a>
            <a 
              href="#scanners" 
              onClick={(e) => handleAnchorClick(e, '#scanners')}
              className="text-muted-foreground hover:text-foreground transition-colors" 
              style={{ fontWeight: 600 }}
            >
              Get a Scanner
            </a>
            <Link 
              to="/download" 
              className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-6 py-2.5 rounded-lg transition-opacity hover:opacity-90"
              style={{ fontWeight: 600 }}
            >
              <img 
                src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo/logo-white.svg" 
                alt="MintCheck" 
                className="w-4 h-4"
              />
              Get the App
            </Link>
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
          <div className="md:hidden pt-4 pb-4 flex flex-col gap-4" role="navigation" aria-label="Mobile navigation">
            <a 
              href="#how-it-works" 
              onClick={(e) => handleAnchorClick(e, '#how-it-works')}
              className="text-muted-foreground hover:text-foreground transition-colors py-2"
              style={{ fontWeight: 600 }}
            >
              How It Works
            </a>
            <a 
              href="#use-cases" 
              onClick={(e) => handleAnchorClick(e, '#use-cases')}
              className="text-muted-foreground hover:text-foreground transition-colors py-2"
              style={{ fontWeight: 600 }}
            >
              Use Cases
            </a>
            <a 
              href="#scanners" 
              onClick={(e) => handleAnchorClick(e, '#scanners')}
              className="text-muted-foreground hover:text-foreground transition-colors py-2"
              style={{ fontWeight: 600 }}
            >
              Get a Scanner
            </a>
            <Link 
              to="/download" 
              className="inline-flex items-center justify-center gap-2 bg-primary text-primary-foreground px-6 py-3 rounded-lg transition-opacity hover:opacity-90 mt-2"
              style={{ fontWeight: 600 }}
              onClick={() => setMobileMenuOpen(false)}
            >
              <img 
                src="https://iawkgqbrxoctatfrjpli.supabase.co/storage/v1/object/public/assets/Logo/SVGs/logo/logo-white.svg" 
                alt="MintCheck" 
                className="w-4 h-4"
              />
              Get the App
            </Link>
          </div>
        )}
      </div>
    </nav>
  );
}
