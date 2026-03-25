import { useState, useEffect, useCallback, Fragment } from 'react';
import { useNavigate } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { LogOut, RefreshCw, ChevronDown, ChevronUp, Package } from 'lucide-react';
import { AUTH_KEY } from '@/app/contexts/AdminContext';
import { supabase } from '@/lib/supabase';

export interface StarterKitOrderRow {
  id: string;
  user_id: string | null;
  stripe_session_id: string;
  status: string;
  customer_email: string | null;
  customer_name: string | null;
  confirmation_email_sent_at: string | null;
  pass_activated_at: string | null;
  buyer_pass_subscription_id: string | null;
  tracking_carrier: string | null;
  tracking_number: string | null;
  shipped_at: string | null;
  created_at: string;
  updated_at: string;
}

function getApiConfig(): { baseUrl: string; headers: Record<string, string> } | null {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const secret = import.meta.env.VITE_ADMIN_FEEDBACK_SECRET;
  if (!supabaseUrl) return null;
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (secret) headers['x-admin-secret'] = secret;
  return { baseUrl: `${supabaseUrl}/functions/v1/admin-starter-kit-orders`, headers };
}

export default function AdminStarterKitOrders() {
  const navigate = useNavigate();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [orders, setOrders] = useState<StarterKitOrderRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<'all' | 'paid_pending_fulfillment' | 'pass_activated'>('all');
  const [drafts, setDrafts] = useState<
    Record<string, { carrier: string; number: string }>
  >({});
  const [savingId, setSavingId] = useState<string | null>(null);
  const [fulfillingId, setFulfillingId] = useState<string | null>(null);
  const [actionMessage, setActionMessage] = useState<string | null>(null);

  useEffect(() => {
    const auth = localStorage.getItem(AUTH_KEY);
    if (auth !== 'true') {
      navigate('/admin/login');
    } else {
      setIsAuthenticated(true);
    }
  }, [navigate]);

  const loadOrders = useCallback(async () => {
    const cfg = getApiConfig();
    if (!cfg) {
      setError('VITE_SUPABASE_URL is not set.');
      setLoading(false);
      return;
    }
    if (!import.meta.env.VITE_ADMIN_FEEDBACK_SECRET) {
      setError(
        'Set VITE_ADMIN_FEEDBACK_SECRET in .env (same value as ADMIN_FEEDBACK_SECRET on the Edge Function) to load orders locally.'
      );
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const q =
        statusFilter === 'all' ? '' : `?status=${encodeURIComponent(statusFilter)}`;
      const res = await fetch(`${cfg.baseUrl}${q}`, {
        method: 'GET',
        headers: cfg.headers,
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(data?.error ?? `Failed to load orders (${res.status})`);
        setOrders([]);
        return;
      }
      const list = (data.orders ?? []) as StarterKitOrderRow[];
      setOrders(list);
      setDrafts((prev) => {
        const next = { ...prev };
        for (const o of list) {
          if (!next[o.id]) {
            next[o.id] = {
              carrier: o.tracking_carrier ?? '',
              number: o.tracking_number ?? '',
            };
          }
        }
        return next;
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Request failed');
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    if (!isAuthenticated) return;
    void loadOrders();
  }, [isAuthenticated, loadOrders]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    localStorage.removeItem(AUTH_KEY);
    navigate('/admin/login');
  };

  const saveTracking = async (orderId: string) => {
    const cfg = getApiConfig();
    if (!cfg || !import.meta.env.VITE_ADMIN_FEEDBACK_SECRET) return;
    const d = drafts[orderId] ?? { carrier: '', number: '' };
    setSavingId(orderId);
    setActionMessage(null);
    try {
      const res = await fetch(cfg.baseUrl, {
        method: 'PATCH',
        headers: cfg.headers,
        body: JSON.stringify({
          id: orderId,
          tracking_carrier: d.carrier || null,
          tracking_number: d.number || null,
        }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setActionMessage(data?.error ?? `Save failed (${res.status})`);
        return;
      }
      setActionMessage('Tracking saved.');
      await loadOrders();
    } catch (e) {
      setActionMessage(e instanceof Error ? e.message : 'Save failed');
    } finally {
      setSavingId(null);
      setTimeout(() => setActionMessage(null), 4000);
    }
  };

  const fulfillOrder = async (orderId: string) => {
    if (
      !confirm(
        'Activate the 60-day Buyer Pass for this customer now? This starts their entitlement clock (typically when the kit ships).'
      )
    ) {
      return;
    }
    const cfg = getApiConfig();
    if (!cfg || !import.meta.env.VITE_ADMIN_FEEDBACK_SECRET) return;
    setFulfillingId(orderId);
    setActionMessage(null);
    try {
      const res = await fetch(cfg.baseUrl, {
        method: 'POST',
        headers: cfg.headers,
        body: JSON.stringify({ action: 'fulfill', order_id: orderId }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setActionMessage(data?.error ?? data?.detail ?? `Fulfill failed (${res.status})`);
        return;
      }
      setActionMessage(data?.ok ? 'Buyer Pass activated.' : 'Request completed.');
      await loadOrders();
    } catch (e) {
      setActionMessage(e instanceof Error ? e.message : 'Fulfill failed');
    } finally {
      setFulfillingId(null);
      setTimeout(() => setActionMessage(null), 5000);
    }
  };

  const formatDate = (iso: string | null) => {
    if (!iso) return '—';
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

  const copyText = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setActionMessage('Copied to clipboard.');
      setTimeout(() => setActionMessage(null), 2000);
    } catch {
      setActionMessage('Could not copy.');
      setTimeout(() => setActionMessage(null), 2000);
    }
  };

  if (!isAuthenticated) return null;

  return (
    <div className="min-h-screen bg-muted/30">
      <Helmet>
        <title>Starter Kit Orders | MintCheck Admin</title>
        <meta name="robots" content="noindex, nofollow" />
      </Helmet>

      <header className="sticky top-0 z-10 border-b border-border bg-white">
        <div className="max-w-6xl mx-auto px-6 py-4 flex flex-wrap items-center justify-between gap-3">
          <div className="flex flex-wrap items-center gap-4">
            <button
              type="button"
              onClick={() => navigate('/admin/dashboard')}
              className="text-muted-foreground hover:text-foreground"
            >
              ← Dashboard
            </button>
            <h1 className="text-xl font-semibold flex items-center gap-2">
              <Package className="w-5 h-5" />
              Starter Kit Orders
            </h1>
            <button
              type="button"
              onClick={() => loadOrders()}
              disabled={loading}
              className="flex items-center gap-2 text-muted-foreground hover:text-foreground disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              Reload
            </button>
          </div>
          <div className="flex items-center gap-4">
            <a
              href="/admin/feedback"
              className="text-sm text-muted-foreground hover:text-foreground"
            >
              Feedback
            </a>
            <button
              type="button"
              onClick={handleLogout}
              className="flex items-center gap-2 text-muted-foreground hover:text-foreground"
            >
              <LogOut className="w-4 h-4" />
              Log out
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-6 space-y-6">
        <div className="flex flex-wrap gap-2">
          {(
            [
              ['all', 'All'],
              ['paid_pending_fulfillment', 'Pending ship'],
              ['pass_activated', 'Pass active'],
            ] as const
          ).map(([value, label]) => (
            <button
              key={value}
              type="button"
              onClick={() => setStatusFilter(value)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                statusFilter === value
                  ? 'bg-[#3EB489] text-white'
                  : 'border border-border bg-white hover:bg-muted/50'
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        {actionMessage && (
          <div className="rounded-lg border border-border bg-white px-4 py-2 text-sm">{actionMessage}</div>
        )}

        {loading && <p className="text-muted-foreground">Loading orders…</p>}
        {error && (
          <div className="rounded-lg border border-destructive/50 bg-destructive/10 p-4 text-destructive text-sm">
            {error}
          </div>
        )}

        {!loading && !error && orders.length === 0 && (
          <p className="text-muted-foreground">No orders match this filter.</p>
        )}

        {!loading && !error && orders.length > 0 && (
          <div className="space-y-3">
            {orders.map((row) => {
              const expanded = expandedId === row.id;
              const draft = drafts[row.id] ?? { carrier: '', number: '' };
              const canFulfill =
                row.status === 'paid_pending_fulfillment' && Boolean(row.user_id);
              const needsUser = row.status === 'paid_pending_fulfillment' && !row.user_id;

              return (
                <Fragment key={row.id}>
                  <div className="rounded-lg border border-border bg-white overflow-hidden">
                    <button
                      type="button"
                      onClick={() => setExpandedId(expanded ? null : row.id)}
                      className="w-full flex items-center justify-between gap-4 px-4 py-3 text-left hover:bg-muted/30"
                    >
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2 mb-1">
                          <span
                            className={`text-xs px-2 py-0.5 rounded font-medium ${
                              row.status === 'pass_activated'
                                ? 'bg-[#3EB489]/15 text-[#2a8f66]'
                                : row.status === 'canceled'
                                  ? 'bg-gray-100 text-gray-600'
                                  : 'bg-amber-100 text-amber-900'
                            }`}
                          >
                            {row.status}
                          </span>
                          <span className="text-sm text-muted-foreground">
                            {formatDate(row.created_at)}
                          </span>
                        </div>
                        <p className="font-medium truncate">
                          {row.customer_name || '—'} · {row.customer_email || '—'}
                        </p>
                        <p className="text-xs text-muted-foreground font-mono truncate">
                          {truncate(row.stripe_session_id, 48)}
                        </p>
                      </div>
                      {expanded ? (
                        <ChevronUp className="w-5 h-5 shrink-0 text-muted-foreground" />
                      ) : (
                        <ChevronDown className="w-5 h-5 shrink-0 text-muted-foreground" />
                      )}
                    </button>

                    {expanded && (
                      <div className="border-t border-border px-4 py-4 space-y-4 bg-muted/20">
                        <div className="grid sm:grid-cols-2 gap-3 text-sm">
                          <div>
                            <span className="text-muted-foreground">User ID</span>
                            <p className="font-mono text-xs break-all">{row.user_id ?? '—'}</p>
                            {needsUser && (
                              <p className="text-amber-800 text-xs mt-1">
                                No user linked (e.g. guest Payment Link). Set{' '}
                                <code className="bg-white px-1 rounded">user_id</code> in Supabase before fulfilling, or
                                use app checkout.
                              </p>
                            )}
                          </div>
                          <div>
                            <span className="text-muted-foreground">Stripe session</span>
                            <div className="flex items-center gap-2 mt-1">
                              <p className="font-mono text-xs break-all flex-1">{row.stripe_session_id}</p>
                              <button
                                type="button"
                                onClick={() => copyText(row.stripe_session_id)}
                                className="text-xs text-[#3EB489] font-medium shrink-0"
                              >
                                Copy
                              </button>
                            </div>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Confirmation email</span>
                            <p>{formatDate(row.confirmation_email_sent_at)}</p>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Pass activated</span>
                            <p>{formatDate(row.pass_activated_at)}</p>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Shipped at</span>
                            <p>{formatDate(row.shipped_at)}</p>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Buyer Pass subscription</span>
                            <p className="font-mono text-xs break-all">
                              {row.buyer_pass_subscription_id ?? '—'}
                            </p>
                          </div>
                        </div>

                        <div className="grid sm:grid-cols-2 gap-3">
                          <div>
                            <label className="block text-xs font-medium text-muted-foreground mb-1">
                              Carrier
                            </label>
                            <input
                              type="text"
                              value={draft.carrier}
                              onChange={(e) =>
                                setDrafts((prev) => ({
                                  ...prev,
                                  [row.id]: { ...draft, carrier: e.target.value },
                                }))
                              }
                              placeholder="USPS, UPS, FedEx…"
                              className="w-full px-3 py-2 border border-border rounded-lg text-sm"
                            />
                          </div>
                          <div>
                            <label className="block text-xs font-medium text-muted-foreground mb-1">
                              Tracking number
                            </label>
                            <input
                              type="text"
                              value={draft.number}
                              onChange={(e) =>
                                setDrafts((prev) => ({
                                  ...prev,
                                  [row.id]: { ...draft, number: e.target.value },
                                }))
                              }
                              placeholder="Tracking #"
                              className="w-full px-3 py-2 border border-border rounded-lg text-sm"
                            />
                          </div>
                        </div>

                        <div className="flex flex-wrap gap-3">
                          <button
                            type="button"
                            onClick={() => saveTracking(row.id)}
                            disabled={savingId === row.id}
                            className="px-4 py-2 rounded-lg bg-white border border-border text-sm font-medium hover:bg-muted/50 disabled:opacity-50"
                          >
                            {savingId === row.id ? 'Saving…' : 'Save tracking'}
                          </button>
                          <button
                            type="button"
                            onClick={() => fulfillOrder(row.id)}
                            disabled={!canFulfill || fulfillingId === row.id}
                            className="px-4 py-2 rounded-lg bg-[#3EB489] text-white text-sm font-medium hover:bg-[#359e7a] disabled:opacity-50 disabled:cursor-not-allowed"
                          >
                            {fulfillingId === row.id
                              ? 'Activating…'
                              : 'Activate 60-day Buyer Pass'}
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                </Fragment>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}
