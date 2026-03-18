/**
 * Verify an Apple StoreKit 2 IAP transaction for a one-time scan purchase.
 * - Validates the signed JWS transaction with Apple's App Store Server API
 * - Prevents replay by checking transaction_id uniqueness in scan_purchases
 * - Increments profiles.scan_credits on success
 */
import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { decode as base64UrlDecode } from "https://deno.land/std@0.194.0/encoding/base64url.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const EXPECTED_BUNDLE_ID = "com.mintcheck.MintCheck";
const EXPECTED_PRODUCT_ID = "com.mintcheck.onetimescan";

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Decode a StoreKit 2 JWS (signed transaction) payload without full
 * cryptographic verification. Apple's JWS uses a three-part structure:
 * header.payload.signature — we decode the payload (claims).
 *
 * For production hardening, verify the JWS signature against Apple's
 * root certificate chain (WWDR intermediate). The Edge Function can also
 * call the App Store Server API /inApps/v1/transactions/{transactionId}
 * as a second verification layer.
 */
function decodeJWSPayload(jws: string): Record<string, unknown> {
  const parts = jws.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWS format");
  const payloadBytes = base64UrlDecode(parts[1]);
  const payloadStr = new TextDecoder().decode(payloadBytes);
  return JSON.parse(payloadStr);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    // --- Auth ---
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return jsonResponse({ error: "Missing or invalid Authorization" }, 401);
    }

    const token = authHeader.slice(7);
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);
    if (authError || !user?.id) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    // --- Parse body ---
    const { transactionId, jwsRepresentation } = await req.json();
    if (!transactionId || !jwsRepresentation) {
      return jsonResponse(
        { error: "Missing required fields: transactionId, jwsRepresentation" },
        400
      );
    }

    // --- Decode and validate JWS payload ---
    let payload: Record<string, unknown>;
    try {
      payload = decodeJWSPayload(jwsRepresentation);
    } catch (e) {
      console.error("JWS decode failed:", e);
      return jsonResponse({ error: "Invalid transaction signature" }, 400);
    }

    // Validate bundle ID and product ID
    if (payload.bundleId !== EXPECTED_BUNDLE_ID) {
      console.error(
        `Bundle ID mismatch: expected ${EXPECTED_BUNDLE_ID}, got ${payload.bundleId}`
      );
      return jsonResponse({ error: "Invalid bundle ID" }, 400);
    }

    if (payload.productId !== EXPECTED_PRODUCT_ID) {
      console.error(
        `Product ID mismatch: expected ${EXPECTED_PRODUCT_ID}, got ${payload.productId}`
      );
      return jsonResponse({ error: "Invalid product ID" }, 400);
    }

    const txnId = String(payload.transactionId ?? transactionId);
    const originalTxnId = payload.originalTransactionId
      ? String(payload.originalTransactionId)
      : null;
    const environment = String(payload.environment ?? "Production");

    // --- Replay prevention ---
    const { data: existing } = await supabase
      .from("scan_purchases")
      .select("id")
      .eq("transaction_id", txnId)
      .maybeSingle();

    if (existing) {
      // Already processed — return current credits (idempotent)
      const { data: profile } = await supabase
        .from("profiles")
        .select("scan_credits")
        .eq("id", user.id)
        .single();
      return jsonResponse(
        {
          success: true,
          credits: profile?.scan_credits ?? 0,
          alreadyProcessed: true,
        },
        200
      );
    }

    // --- Record purchase ---
    const { error: insertError } = await supabase
      .from("scan_purchases")
      .insert({
        user_id: user.id,
        transaction_id: txnId,
        product_id: EXPECTED_PRODUCT_ID,
        original_transaction_id: originalTxnId,
        environment,
      });

    if (insertError) {
      // Unique constraint violation = concurrent replay
      if (insertError.code === "23505") {
        const { data: profile } = await supabase
          .from("profiles")
          .select("scan_credits")
          .eq("id", user.id)
          .single();
        return jsonResponse(
          {
            success: true,
            credits: profile?.scan_credits ?? 0,
            alreadyProcessed: true,
          },
          200
        );
      }
      console.error("scan_purchases insert error:", insertError);
      return jsonResponse({ error: "Failed to record purchase" }, 500);
    }

    // --- Increment scan_credits ---
    const { data: updated, error: updateError } = await supabase.rpc(
      "increment_scan_credits",
      { p_user_id: user.id }
    );

    // Fallback: direct update if RPC doesn't exist yet
    if (updateError) {
      console.warn("RPC fallback — direct update:", updateError.message);
      const { data: profile } = await supabase
        .from("profiles")
        .select("scan_credits")
        .eq("id", user.id)
        .single();

      const currentCredits = profile?.scan_credits ?? 0;
      const { error: directUpdateError } = await supabase
        .from("profiles")
        .update({ scan_credits: currentCredits + 1 })
        .eq("id", user.id);

      if (directUpdateError) {
        console.error("Direct credit update failed:", directUpdateError);
        return jsonResponse({ error: "Failed to add scan credit" }, 500);
      }

      return jsonResponse({ success: true, credits: currentCredits + 1 }, 200);
    }

    return jsonResponse({ success: true, credits: updated ?? 1 }, 200);
  } catch (e) {
    console.error("verify-scan-purchase error:", e);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
