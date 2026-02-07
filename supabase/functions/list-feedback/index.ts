import { serve } from "https://deno.land/std@0.194.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-admin-secret",
};

type FeedbackRow = {
  id: string;
  created_at: string;
  user_id: string | null;
  category: string;
  message: string | null;
  email: string | null;
  context: Record<string, unknown>;
  status: string;
  source: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Allow access via x-admin-secret OR JWT with profiles.role = 'admin'
    const adminSecret = Deno.env.get("ADMIN_FEEDBACK_SECRET");
    const providedSecret = req.headers.get("x-admin-secret");
    const authHeader = req.headers.get("Authorization");

    let allowed = false;
    if (adminSecret && providedSecret === adminSecret) {
      allowed = true;
    } else if (authHeader?.startsWith("Bearer ")) {
      const token = authHeader.slice(7);
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);
      if (!authError && user?.id) {
        const { data: profile } = await supabase
          .from("profiles")
          .select("role")
          .eq("id", user.id)
          .single();
        if (profile?.role === "admin") allowed = true;
      }
    }

    if (!allowed) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const url = new URL(req.url);
    const limitParam = url.searchParams.get("limit");
    const limit = Math.min(limitParam ? parseInt(limitParam, 10) : 100, 200) || 100;
    const { data, error } = await supabase
      .from("feedback")
      .select("id, created_at, user_id, category, message, email, context, status, source")
      .order("created_at", { ascending: false })
      .limit(limit)
      .returns<FeedbackRow[]>();

    if (error) {
      console.error("list-feedback error:", error);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ feedback: data ?? [] }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("list-feedback error:", e);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
