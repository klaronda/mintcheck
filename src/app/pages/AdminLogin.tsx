import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { AUTH_KEY } from '@/app/contexts/AdminContext';
import { supabase } from '@/lib/supabase';

const ALLOWED_ADMIN_EMAIL = import.meta.env.VITE_ADMIN_EMAIL ?? 'contact@mintcheckapp.com';

export default function AdminLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const { data, error: signInError } = await supabase.auth.signInWithPassword({ email, password });
      if (signInError) {
        setError(signInError.message ?? 'Invalid email or password');
        return;
      }
      const allowed = (data.user?.email ?? '').toLowerCase() === ALLOWED_ADMIN_EMAIL.toLowerCase();
      if (!allowed) {
        await supabase.auth.signOut();
        setError('Access restricted to authorized admin.');
        return;
      }
      localStorage.setItem(AUTH_KEY, 'true');
      navigate('/admin/dashboard');
    } catch {
      setError('Invalid email or password');
    } finally {
      setLoading(false);
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
              disabled={loading}
              className="w-full bg-[#3EB489] text-white py-3 rounded-lg hover:bg-[#359e7a] transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
              style={{ fontWeight: 600 }}
            >
              {loading ? 'Signing in…' : 'Sign In'}
            </button>
          </form>

        </div>
      </div>
    </div>
  );
}
