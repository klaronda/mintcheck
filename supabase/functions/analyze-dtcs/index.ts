import { serve } from "https://deno.land/std@0.194.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// OpenAI Chat Completions — set OPENAI_API_KEY in Supabase Edge Function secrets
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") || "gpt-4o-mini";
const OPENAI_TIMEOUT_MS = 30_000;

/** Max length for the `summary` string returned to the app (Unicode-safe). */
const SUMMARY_MAX_CHARS = 180;

const VALID_APP_RECOMMENDATIONS = new Set(["safe", "low-data", "caution", "not-recommended"]);

// Request interface (appRecommendation optional; aligns with MintCheck RecommendationType.rawValue)
interface AnalysisRequest {
  dtcs: string[];
  make: string;
  model: string;
  year: number;
  odometerReading?: number;
  askingPrice?: number;
  interiorCondition?: string;
  tireCondition?: string;
  appRecommendation?: string;
}

interface OpenAIChatResponse {
  choices?: Array<{ message?: { content?: string } }>;
  error?: { message?: string };
}

/** Truncate so final length ≤ `max` (Unicode code points), including trailing ellipsis. */
function truncateSummary(text: string, max: number): string {
  const chars = [...text];
  if (chars.length <= max) return text;
  if (max <= 1) return "…".slice(0, max);
  const limit = max - 1; // one code point for ellipsis
  let body = chars.slice(0, limit).join("");
  const lastSpace = body.lastIndexOf(" ");
  if (lastSpace > limit * 0.6) {
    body = body.slice(0, lastSpace).trimEnd();
  } else {
    body = body.trimEnd();
  }
  return body + "…";
}

function buildTierInstruction(appRecommendation: string | undefined): string {
  if (!appRecommendation || !VALID_APP_RECOMMENDATIONS.has(appRecommendation)) {
    return "";
  }
  return `

## MintCheck app tier (tone only — do not repeat the title)
The results screen **already shows a big title** for this tier (e.g. "Not Recommended" / "Proceed with Caution"). The **summary must not restate that title** or spend most of the text on "we recommend/don't recommend."
- **safe**: Explain what we saw; stay reassuring.
- **low-data**: Explain what's missing; suggest a follow-up scan or inspection.
- **caution**: Flag real concerns without sounding like the headline again.
- **not-recommended**: Serious tone is OK in a **short closing phrase**, but most words must explain **what is wrong mechanically** and why it matters — not generic "get an inspection" with no substance.
Do not contradict this tier.`;
}

function buildSharedStyleBlock(): string {
  return `## Writing style (required)
- **Reading level**: 10th grade or below. Short sentences. Simple words. If you use a car term, explain it in plain English.
- **Voice**: MintCheck speaks as "we" — warm, direct, like a trusted friend giving advice.
- **Summary field (body under the tier title)**: Explain **what is going on** — the problem in plain English (e.g. for a lean code: too much air or too little fuel, common causes like vacuum leak, dirty MAF, low fuel pressure). **Lead with the issue**, not with "we recommend." You may add **one short** closing line about next steps (e.g. have a mechanic verify before buying) that fits the tier — but **do not** merely repeat the tier or fill space with vague "professional inspection" language.
- **Summary length (strict)**: **At most ${SUMMARY_MAX_CHARS} characters** (count letters/spaces/punctuation). Shorter is fine. Do not exceed this limit.`;
}

function buildJsonShapeDTC(): string {
  return `Return ONLY one JSON object with this exact shape (keys required). **Do not copy placeholder numbers** — pick realistic US shop dollars for **this** vehicle and **this** code.

{
  "dtcAnalyses": [
    {
      "code": "<string>",
      "name": "<string>",
      "description": "<string — 2–4 sentences: what this code means, common causes, and what often gets replaced or fixed. This is the detailed explanation; the summary stays short.>",
      "repairCostLow": <integer>,
      "repairCostHigh": <integer>,
      "urgency": "low" | "medium" | "high" | "critical",
      "commonForVehicle": <boolean>
    }
  ],
  "totalRepairCostLow": <integer>,
  "totalRepairCostHigh": <integer>,
  "overallUrgency": "low" | "medium" | "high" | "critical",
  "summary": "<string, max ${SUMMARY_MAX_CHARS} characters>",
  "vehicleValuation": {
    "lowEstimate": <integer>,
    "highEstimate": <integer>,
    "reasoning": "<string>"
  }
}`;
}

function buildJsonShapeNoDTC(): string {
  return `Return ONLY one JSON object with this exact shape:

{
  "dtcAnalyses": [],
  "totalRepairCostLow": 0,
  "totalRepairCostHigh": 0,
  "overallUrgency": "low",
  "summary": "<string, max ${SUMMARY_MAX_CHARS} characters>",
  "vehicleValuation": {
    "lowEstimate": <integer>,
    "highEstimate": <integer>,
    "reasoning": "<string>"
  }
}`;
}

async function invokeOpenAI(userPrompt: string): Promise<string | null> {
  if (!OPENAI_API_KEY) {
    console.error("OPENAI_API_KEY not configured");
    return null;
  }

  const body = {
    model: OPENAI_MODEL,
    messages: [
      {
        role: "system",
        content:
          "You are MintCheck's automotive assistant. Respond with a single valid JSON object only, no markdown fences or text outside the JSON. The app already shows a tier title—use the summary to explain what is wrong with the vehicle, not to repeat that title.",
      },
      { role: "user", content: userPrompt },
    ],
    response_format: { type: "json_object" },
    max_tokens: 2000,
    temperature: 0.3,
  };

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);
  try {
    const resp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    clearTimeout(timer);

    const raw = await resp.text();
    if (!resp.ok) {
      console.error("OpenAI API error:", resp.status, raw);
      return null;
    }

    const parsed = JSON.parse(raw) as OpenAIChatResponse;
    if (parsed.error?.message) {
      console.error("OpenAI error field:", parsed.error.message);
      return null;
    }

    const text = parsed.choices?.[0]?.message?.content?.trim();
    if (!text) {
      console.error("Empty OpenAI response:", raw);
      return null;
    }
    return text;
  } catch (err) {
    clearTimeout(timer);
    console.error("OpenAI invoke error:", err);
    return null;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    let requestData: AnalysisRequest;
    try {
      requestData = await req.json();
      console.log("Parsed request data:", JSON.stringify(requestData, null, 2));
    } catch (parseError: unknown) {
      const details = parseError instanceof Error ? parseError.message : String(parseError);
      console.error("JSON parse error:", parseError);
      return new Response(
        JSON.stringify({ error: "Invalid JSON in request body", details }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const {
      dtcs,
      make,
      model,
      year,
      odometerReading,
      askingPrice,
      interiorCondition,
      tireCondition,
      appRecommendation,
    } = requestData;

    if (!make || typeof make !== "string" || make.trim().length === 0) {
      return new Response(JSON.stringify({ error: "Missing or invalid required field: make" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!model || typeof model !== "string" || model.trim().length === 0) {
      return new Response(JSON.stringify({ error: "Missing or invalid required field: model" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!year || typeof year !== "number" || year < 1900 || year > 2100) {
      return new Response(
        JSON.stringify({
          error: "Missing or invalid required field: year (must be a number between 1900-2100)",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (
      appRecommendation !== undefined &&
      appRecommendation !== null &&
      (typeof appRecommendation !== "string" || !VALID_APP_RECOMMENDATIONS.has(appRecommendation))
    ) {
      return new Response(
        JSON.stringify({
          error: "Invalid appRecommendation (use safe | low-data | caution | not-recommended)",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const dtcsArray = Array.isArray(dtcs) ? dtcs : [];

    const vehicleInfo = `${year} ${make} ${model}`;
    const mileageInfo = odometerReading ? ` with ${odometerReading.toLocaleString()} miles` : "";
    const conditionInfo: string[] = [];
    if (interiorCondition) conditionInfo.push(`Interior: ${interiorCondition}`);
    if (tireCondition) conditionInfo.push(`Tires: ${tireCondition}`);
    const conditionText = conditionInfo.length > 0 ? `\nCondition: ${conditionInfo.join(", ")}` : "";
    const askingPriceText = askingPrice ? `\nAsking Price: $${askingPrice.toLocaleString()}` : "";

    const tierBlock = buildTierInstruction(appRecommendation);
    const styleBlock = buildSharedStyleBlock();

    const hasDTCs = dtcsArray.length > 0;

    let prompt: string;
    if (hasDTCs) {
      prompt = `Analyze diagnostic trouble codes (DTCs) for a ${vehicleInfo}${mileageInfo}.${conditionText}${askingPriceText}

DTCs: ${dtcsArray.join(", ")}
${tierBlock}
${styleBlock}

${buildJsonShapeDTC()}

Rules:
- Each DTC entry: accurate **name** and a **rich description** (see JSON shape) so the user understands causes and fixes—not just one vague sentence.
- **repairCostLow / repairCostHigh** (per code): Typical **US shop** range to **diagnose and repair** this code on this vehicle for **common root causes** (e.g. lean codes: cheap fixes like hoses/PCV up through MAF/O2/sensors/intake leaks/fuel pump—use a range wide enough to be honest, often tens to hundreds for simple items up to $800–$1,500+ when major parts fail). **Do not** default to generic "$2,500–$5,000" bands unless the code family truly implies major engine or emissions work. **Do not** reuse the same dollar pair for unrelated codes.
- **totalRepairCostLow / totalRepairCostHigh**: Logical combined range for fixing **all listed codes** (if one repair fixes multiple, totals should reflect that; if independent issues stack, reflect that). Still **code-driven**, not a generic template.
- **vehicleValuation**: US national average market value range in USD; consider age, mileage, condition, reliability; adjust if issues are serious.
- **overallUrgency** should reflect combined risk.
- **summary**: ≤ ${SUMMARY_MAX_CHARS} characters; **issue-first** (see writing style). No tier-title repetition.`;
    } else {
      prompt = `Estimate current market value for a ${vehicleInfo}${mileageInfo}.${conditionText}${askingPriceText}
${tierBlock}
${styleBlock}

${buildJsonShapeNoDTC()}

Rules:
- **summary**: Friendly, 10th-grade reading level; if tier is "safe" or "low-data", explain clearly. Must be ≤ ${SUMMARY_MAX_CHARS} characters (hard cap). Do not repeat the tier title as the whole message.
- **vehicleValuation**: US national average range (USD) and short reasoning.`;
    }

    const responseText = await invokeOpenAI(prompt);

    if (!responseText) {
      return new Response(
        JSON.stringify({ error: "Failed to analyze DTCs - AI service unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    let analysisData: Record<string, unknown>;
    try {
      analysisData = JSON.parse(responseText) as Record<string, unknown>;
    } catch {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        console.error("No JSON found in OpenAI response:", responseText);
        return new Response(JSON.stringify({ error: "Invalid response from AI service" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      try {
        analysisData = JSON.parse(jsonMatch[0]) as Record<string, unknown>;
      } catch (e) {
        console.error("JSON parse failed:", e);
        return new Response(JSON.stringify({ error: "Invalid response from AI service" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const dtcAnalyses = analysisData.dtcAnalyses;
    const rawSummary =
      (analysisData.summary as string) ||
      (hasDTCs ? "" : "No diagnostic trouble codes found. Vehicle appears to be in good condition.");
    const response = {
      analyses: Array.isArray(dtcAnalyses) ? dtcAnalyses : [],
      totalRepairCostLow: Number(analysisData.totalRepairCostLow) || 0,
      totalRepairCostHigh: Number(analysisData.totalRepairCostHigh) || 0,
      overallUrgency: (analysisData.overallUrgency as string) || (hasDTCs ? "medium" : "low"),
      summary: truncateSummary(rawSummary, SUMMARY_MAX_CHARS),
      vehicleValuation: analysisData.vehicleValuation ?? null,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("Error in analyze-dtcs:", error);
    return new Response(JSON.stringify({ error: "Internal server error", message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
