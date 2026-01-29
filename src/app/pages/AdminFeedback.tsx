import { useState, useEffect, Fragment, useCallback } from 'react';
import { useNavigate } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { LogOut, ChevronDown, ChevronUp, RefreshCw } from 'lucide-react';
import { AUTH_KEY } from '@/app/contexts/AdminContext';
import { supabase } from '@/lib/supabase';

const STATUS_OPTIONS = ['Received', 'Responded', 'Resolved', 'Open', 'Closed'] as const;

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

function getFetchConfig(): { url: string; headers: Record<string, string> } | null {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const secret = import.meta.env.VITE_ADMIN_FEEDBACK_SECRET;
  if (!supabaseUrl) return null;
  const url = `${supabaseUrl}/functions/v1/list-feedback?limit=100`;
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (secret) headers['x-admin-secret'] = secret;
  return { url, headers };
}

function getUpdateConfig(): { url: string; headers: Record<string, string> } | null {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const secret = import.meta.env.VITE_ADMIN_FEEDBACK_SECRET;
  if (!supabaseUrl) return null;
  const url = `${supabaseUrl}/functions/v1/update-feedback`;
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (secret) headers['x-admin-secret'] = secret;
  return { url, headers };
}

function getNotifyConfig(): { url: string; headers: Record<string, string> } | null {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  if (!supabaseUrl || !anonKey) return null;
  const url = `${supabaseUrl}/functions/v1/notify-feedback`;
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'apikey': anonKey,
    'Authorization': `Bearer ${anonKey}`,
  };
  return { url, headers };
}

export default function AdminFeedback() {
  const navigate = useNavigate();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [feedback, setFeedback] = useState<FeedbackRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [updatingId, setUpdatingId] = useState<string | null>(null);
  const [resendStatus, setResendStatus] = useState<{ id: string; ok: boolean; message: string } | null>(null);

  useEffect(() => {
    const auth = localStorage.getItem(AUTH_KEY);
    if (auth !== 'true') {
      navigate('/admin/login');
    } else {
      setIsAuthenticated(true);
    }
  }, [navigate]);

  const loadFeedback = useCallback(async () => {
    const cfg = getFetchConfig();
    if (!cfg) {
      setError('VITE_SUPABASE_URL not set');
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(cfg.url, { headers: cfg.headers });
      if (!res.ok) {
        if (res.status === 401) throw new Error('Unauthorized. Set VITE_ADMIN_FEEDBACK_SECRET and ADMIN_FEEDBACK_SECRET in Supabase.');
        throw new Error(`Failed to load feedback: ${res.status}`);
      }
      const data = await res.json();
      setFeedback(data.feedback ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!isAuthenticated) return;
    loadFeedback();
  }, [isAuthenticated, loadFeedback]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    localStorage.removeItem(AUTH_KEY);
    navigate('/admin/login');
  };

  const updateStatus = async (rowId: string, newStatus: string) => {
    const cfg = getUpdateConfig();
    if (!cfg) return;
    const prev = feedback.find((r) => r.id === rowId)?.status;
    setUpdatingId(rowId);
    setFeedback((f) => f.map((r) => (r.id === rowId ? { ...r, status: newStatus } : r)));
    try {
      const res = await fetch(cfg.url, {
        method: 'POST',
        headers: cfg.headers,
        body: JSON.stringify({ id: rowId, status: newStatus }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setFeedback((f) => f.map((r) => (r.id === rowId && prev != null ? { ...r, status: prev } : r)));
        setError(data?.error ?? `Failed to update status: ${res.status}`);
      }
    } catch (e) {
      setFeedback((f) => f.map((r) => (r.id === rowId && prev != null ? { ...r, status: prev } : r)));
      setError(e instanceof Error ? e.message : 'Failed to update status');
    } finally {
      setUpdatingId(null);
    }
  };

  const resendEmail = async (rowId: string) => {
    const cfg = getNotifyConfig();
    if (!cfg) {
      setResendStatus({ id: rowId, ok: false, message: 'Missing Supabase config' });
      return;
    }
    setResendStatus(null);
    try {
      const res = await fetch(cfg.url, {
        method: 'POST',
        headers: cfg.headers,
        body: JSON.stringify({ feedbackId: rowId }),
      });
      const data = await res.json().catch(() => ({}));
      if (res.ok && data?.error == null) {
        setResendStatus({ id: rowId, ok: true, message: 'Email sent' });
      } else {
        setResendStatus({ id: rowId, ok: false, message: data?.error ?? `Failed: ${res.status}` });
      }
    } catch (e) {
      setResendStatus({ id: rowId, ok: false, message: e instanceof Error ? e.message : 'Request failed' });
    }
    setTimeout(() => setResendStatus(null), 4000);
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
            <button
              type="button"
              onClick={() => loadFeedback()}
              disabled={loading}
              className="flex items-center gap-2 text-muted-foreground hover:text-foreground disabled:opacity-50"
              title="Reload"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              Reload
            </button>
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
                      <td className="px-4 py-2 text-sm">
                        <select
                          value={row.status || 'Received'}
                          onChange={(e) => {
                            const v = e.target.value;
                            if (v) updateStatus(row.id, v);
                          }}
                          disabled={updatingId === row.id}
                          className="rounded border border-border bg-background px-2 py-1 text-sm disabled:opacity-50"
                        >
                          {!STATUS_OPTIONS.includes(row.status as (typeof STATUS_OPTIONS)[number]) && row.status && (
                            <option value={row.status}>{row.status}</option>
                          )}
                          {STATUS_OPTIONS.map((s) => (
                            <option key={s} value={s}>
                              {s}
                            </option>
                          ))}
                        </select>
                      </td>
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
                            <div className="flex flex-wrap items-center gap-2">
                              <button
                                type="button"
                                onClick={() => resendEmail(row.id)}
                                className="rounded border border-border bg-background px-3 py-1.5 text-sm hover:bg-muted/50"
                              >
                                Resend email
                              </button>
                              {resendStatus?.id === row.id && (
                                <span
                                  className={
                                    resendStatus.ok
                                      ? 'text-green-600'
                                      : 'text-destructive'
                                  }
                                >
                                  {resendStatus.message}
                                </span>
                              )}
                            </div>
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
