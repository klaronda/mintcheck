/**
 * DEPRECATED — shipping email is now handled inline by admin-starter-kit-orders.
 * This stub exists only so the deployed function doesn't crash if something hits it.
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";

serve(() =>
  new Response(
    JSON.stringify({ error: "Deprecated. Use admin-starter-kit-orders PATCH instead." }),
    { status: 410, headers: { "Content-Type": "application/json" } },
  ),
);
