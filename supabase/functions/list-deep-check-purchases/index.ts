import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.slice(7);
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user?.id) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Join deep_check_reports for year_make_model and report_emailed_at (one report per purchase when report_ready)
    // Only show purchases that have moved past "pending" status (exclude incomplete/failed checkouts)
    const { data: rows, error } = await supabase
      .from("deep_check_purchases")
      .select("id, vin, status, report_url, report_error, recommendation_status, created_at, deep_check_reports(year_make_model, report_emailed_at)")
      .eq("user_id", user.id)
      .neq("status", "pending")
      .order("created_at", { ascending: false })
      .limit(50);

    if (error) {
      console.error("list-deep-check-purchases error:", error);
      return new Response(JSON.stringify({ error: "Failed to load" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const purchases = (rows ?? []).map((row) => {
      const reports = (row as { deep_check_reports?: { year_make_model?: string | null; report_emailed_at?: string | null } | Array<{ year_make_model?: string | null; report_emailed_at?: string | null }> }).deep_check_reports;
      const first = Array.isArray(reports) ? reports[0] : reports;
      const yearMakeModel = first?.year_make_model ?? null;
      const reportEmailedAt = first?.report_emailed_at ?? null;
      return {
        id: row.id,
        vin: row.vin,
        status: row.status,
        report_url: row.report_url ?? null,
        report_error: row.report_error ?? null,
        recommendation_status: row.recommendation_status ?? null,
        year_make_model: yearMakeModel ?? null,
        report_emailed_at: reportEmailedAt ?? null,
        created_at: row.created_at,
      };
    });

    return new Response(
      JSON.stringify({ purchases }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("list-deep-check-purchases error:", e);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
