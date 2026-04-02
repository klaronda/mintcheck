import * as Sentry from "https://deno.land/x/sentry/index.mjs";

const SENTRY_DSN = Deno.env.get("SENTRY_DSN");

let _initialized = false;

function ensureInit() {
  if (_initialized) return;
  _initialized = true;

  if (!SENTRY_DSN) {
    console.warn("SENTRY_DSN not set — Sentry disabled for this invocation");
    return;
  }

  Sentry.init({
    dsn: SENTRY_DSN,
    defaultIntegrations: false,
    tracesSampleRate: 1.0,
    environment: Deno.env.get("SENTRY_ENVIRONMENT") || "production",
  });

  Sentry.setTag("region", Deno.env.get("SB_REGION") ?? "unknown");
  Sentry.setTag("execution_id", Deno.env.get("SB_EXECUTION_ID") ?? "unknown");
}

export function captureException(
  err: unknown,
  context?: Record<string, unknown>,
) {
  ensureInit();
  if (!SENTRY_DSN) return;
  Sentry.withScope((scope: { setExtras: (extras: Record<string, unknown>) => void }) => {
    if (context) scope.setExtras(context);
    Sentry.captureException(err);
  });
}

export async function flush(timeoutMs = 2000) {
  if (!SENTRY_DSN) return;
  await Sentry.flush(timeoutMs);
}

export { Sentry };
