import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { AUTH_KEY, CREDENTIALS_KEY } from '@/app/contexts/AdminContext';

export default function AdminLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const stored = localStorage.getItem(CREDENTIALS_KEY);
    if (stored) {
      const credentials = JSON.parse(stored);
      if (email === credentials.email && password === credentials.password) {
        localStorage.setItem(AUTH_KEY, 'true');
        navigate('/admin/dashboard');
      } else {
        setError('Invalid email or password');
      }
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center px-4">
      <Helmet>
        <title>Admin Login | MintCheck</title>
        <meta name="robots" content="noindex, nofollow" />
      </Helmet>

      <div className="max-w-md w-full">
        <div className="text-center mb-8">
          <h1 className="text-3xl mb-2" style={{ fontWeight: 600 }}>
            MintCheck Admin
          </h1>
          <p className="text-muted-foreground">Sign in to manage content</p>
        </div>

        <div className="bg-white rounded-lg border border-border p-8">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="email" className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                Email
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                required
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                Password
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                required
              />
            </div>

            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              className="w-full bg-[#3EB489] text-white py-3 rounded-lg hover:bg-[#359e7a] transition-colors"
              style={{ fontWeight: 600 }}
            >
              Sign In
            </button>
          </form>

          <div className="mt-6 pt-6 border-t border-border text-center text-sm text-muted-foreground">
            <p>Default credentials:</p>
            <p className="mt-1">admin@mintcheckapp.com / mintcheck2024</p>
          </div>
        </div>
      </div>
    </div>
  );
}
