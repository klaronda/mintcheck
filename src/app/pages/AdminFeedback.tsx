import { useState, useEffect, Fragment } from 'react';
import { useNavigate } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { LogOut, ChevronDown, ChevronUp } from 'lucide-react';
import { AUTH_KEY } from '@/app/contexts/AdminContext';

interface FeedbackRow {
  id: string;
  created_at: string;
  user_id: string | null;
  category: string;
  message: string | null;
  email: string | null;
  context: Record<string, unknown>;
  status: string;
  source: string;
}

export default function AdminFeedback() {
  const navigate = useNavigate();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [feedback, setFeedback] = useState<FeedbackRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => {
    const auth = localStorage.getItem(AUTH_KEY);
    if (auth !== 'true') {
      navigate('/admin/login');
    } else {
      setIsAuthenticated(true);
    }
  }, [navigate]);

  useEffect(() => {
    if (!isAuthenticated) return;

    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    const secret = import.meta.env.VITE_ADMIN_FEEDBACK_SECRET;
    if (!supabaseUrl) {
      setError('VITE_SUPABASE_URL not set');
      setLoading(false);
      return;
    }

    const url = `${supabaseUrl}/functions/v1/list-feedback?limit=100`;
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (secret) headers['x-admin-secret'] = secret;

    fetch(url, { headers })
      .then((res) => {
        if (!res.ok) {
          if (res.status === 401) throw new Error('Unauthorized. Set VITE_ADMIN_FEEDBACK_SECRET and ADMIN_FEEDBACK_SECRET in Supabase.');
          throw new Error(`Failed to load feedback: ${res.status}`);
        }
        return res.json();
      })
      .then((data) => {
        setFeedback(data.feedback ?? []);
        setError(null);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [isAuthenticated]);

  const handleLogout = () => {
    localStorage.removeItem(AUTH_KEY);
    navigate('/admin/login');
  };

  const formatDate = (iso: string) => {
    try {
      return new Date(iso).toLocaleString();
    } catch {
      return iso;
    }
  };

  const truncate = (s: string | null, len: number) => {
    if (!s) return '—';
    return s.length <= len ? s : s.slice(0, len) + '…';
  };

  if (!isAuthenticated) return null;

  return (
    <div className="min-h-screen bg-muted/30">
      <Helmet>
        <title>Feedback Inbox | MintCheck Admin</title>
      </Helmet>

      <header className="sticky top-0 z-10 border-b border-border bg-white">
        <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={() => navigate('/admin/dashboard')}
              className="text-muted-foreground hover:text-foreground"
            >
              ← Dashboard
            </button>
            <h1 className="text-xl font-semibold">Feedback Inbox</h1>
          </div>
          <button
            type="button"
            onClick={handleLogout}
            className="flex items-center gap-2 text-muted-foreground hover:text-foreground"
          >
            <LogOut className="w-4 h-4" />
            Log out
          </button>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-6">
        {loading && (
          <p className="text-muted-foreground">Loading feedback…</p>
        )}
        {error && (
          <div className="rounded-lg border border-destructive/50 bg-destructive/10 p-4 text-destructive">
            {error}
          </div>
        )}
        {!loading && !error && feedback.length === 0 && (
          <p className="text-muted-foreground">No feedback yet.</p>
        )}
        {!loading && !error && feedback.length > 0 && (
          <div className="rounded-lg border border-border bg-white overflow-hidden">
            <table className="w-full text-left">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 font-medium text-sm">Date</th>
                  <th className="px-4 py-3 font-medium text-sm">Category</th>
                  <th className="px-4 py-3 font-medium text-sm">Source</th>
                  <th className="px-4 py-3 font-medium text-sm">Email</th>
                  <th className="px-4 py-3 font-medium text-sm">Message</th>
                  <th className="px-4 py-3 font-medium text-sm">Status</th>
                  <th className="px-4 py-3 w-10" />
                </tr>
              </thead>
              <tbody>
                {feedback.map((row) => (
                  <Fragment key={row.id}>
                    <tr
                      key={row.id}
                      className="border-b border-border hover:bg-muted/30"
                    >
                      <td className="px-4 py-2 text-sm text-muted-foreground whitespace-nowrap">
                        {formatDate(row.created_at)}
                      </td>
                      <td className="px-4 py-2 text-sm">{row.category}</td>
                      <td className="px-4 py-2 text-sm">{row.source}</td>
                      <td className="px-4 py-2 text-sm">{row.email ?? '—'}</td>
                      <td className="px-4 py-2 text-sm max-w-[200px] truncate">
                        {truncate(row.message, 60)}
                      </td>
                      <td className="px-4 py-2 text-sm">{row.status}</td>
                      <td className="px-4 py-2">
                        <button
                          type="button"
                          onClick={() =>
                            setExpandedId((id) => (id === row.id ? null : row.id))
                          }
                          className="p-1 text-muted-foreground hover:text-foreground"
                        >
                          {expandedId === row.id ? (
                            <ChevronUp className="w-4 h-4" />
                          ) : (
                            <ChevronDown className="w-4 h-4" />
                          )}
                        </button>
                      </td>
                    </tr>
                    {expandedId === row.id && (
                      <tr key={`${row.id}-detail`} className="bg-muted/20">
                        <td colSpan={7} className="px-4 py-4">
                          <div className="space-y-2 text-sm">
                            {row.message && (
                              <div>
                                <span className="font-medium text-muted-foreground">Message: </span>
                                <span className="whitespace-pre-wrap">{row.message}</span>
                              </div>
                              )}
                            <div>
                              <span className="font-medium text-muted-foreground">Context: </span>
                              <pre className="mt-1 p-3 rounded bg-muted text-xs overflow-auto max-h-64">
                                {JSON.stringify(row.context, null, 2)}
                              </pre>
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </Fragment>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  );
}
