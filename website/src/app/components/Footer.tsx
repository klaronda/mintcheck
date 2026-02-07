import { useState, useRef } from 'react';
import { Link, useNavigate } from 'react-router';
import { Mail } from 'lucide-react';

export default function Footer() {
  const navigate = useNavigate();
  const [clickCount, setClickCount] = useState(0);
  const timeoutRef = useRef<NodeJS.Timeout>();

  const handleCopyrightClick = () => {
    const newCount = clickCount + 1;
    setClickCount(newCount);

    // Clear existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    // Check if 3 clicks achieved
    if (newCount === 3) {
      setClickCount(0);
      navigate('/admin/login');
      return;
    }

    // Reset counter after 2 seconds of inactivity
    timeoutRef.current = setTimeout(() => {
      setClickCount(0);
    }, 2000);
  };

  return (
    <footer className="bg-[#3EB489] mt-16">
      <div className="max-w-4xl mx-auto px-6 py-12">
        <div className="flex flex-col md:flex-row justify-between items-center gap-6 text-sm text-white/90">
          <div className="flex items-center gap-2">
            <span style={{ fontWeight: 600 }} className="text-white">MintCheck</span>
            <button
              onClick={handleCopyrightClick}
              className="hover:opacity-80 transition-opacity cursor-pointer select-none"
              aria-label="Copyright"
            >
              © 2026
            </button>
          </div>
          <div className="flex flex-wrap justify-center md:justify-start items-center gap-4 md:gap-8">
            <Link to="/support" className="hover:text-white transition-colors">
              Support
            </Link>
            <Link to="/blog" className="hover:text-white transition-colors">
              Blog
            </Link>
            <Link to="/privacy" className="hover:text-white transition-colors">
              Privacy Policy
            </Link>
            <Link to="/terms" className="hover:text-white transition-colors">
              Terms of Use
            </Link>
            <a href="mailto:support@mintcheckapp.com" className="flex items-center gap-2 hover:text-white transition-colors">
              <Mail className="w-4 h-4 shrink-0" />
              support@mintcheckapp.com
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
