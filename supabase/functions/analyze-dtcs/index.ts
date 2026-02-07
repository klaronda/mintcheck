import { serve } from "https://deno.land/std@0.194.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// AWS Bedrock configuration
const AWS_REGION = Deno.env.get('AWS_REGION') || 'us-east-1';
const AWS_ACCESS_KEY_ID = Deno.env.get('AWS_ACCESS_KEY_ID');
const AWS_SECRET_ACCESS_KEY = Deno.env.get('AWS_SECRET_ACCESS_KEY');
const AWS_SESSION_TOKEN = Deno.env.get('AWS_SESSION_TOKEN');
const BEDROCK_MODEL_ID = Deno.env.get('BEDROCK_MODEL_ID') || 'anthropic.claude-3-5-sonnet-20241022-v2:0';
const BEDROCK_TIMEOUT_MS = 5000; // 5 second timeout

// Request interface
interface AnalysisRequest {
  dtcs: string[];
  make: string;
  model: string;
  year: number;
  odometerReading?: number;
  askingPrice?: number;
  interiorCondition?: string;
  tireCondition?: string;
}

// SigV4 signing helpers
async function sha256(message: string | Uint8Array): Promise<Uint8Array> {
  const data = typeof message === 'string' ? new TextEncoder().encode(message) : message;
  return new Uint8Array(await crypto.subtle.digest('SHA-256', data));
}

function toHex(arrayBuffer: Uint8Array): string {
  return Array.from(arrayBuffer).map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function hmac(key: Uint8Array, data: string): Promise<Uint8Array> {
  const cryptoKey = await crypto.subtle.importKey('raw', key, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const signature = await crypto.subtle.sign('HMAC', cryptoKey, new TextEncoder().encode(data));
  return new Uint8Array(signature);
}

async function getSignatureKey(key: string, dateStamp: string, region: string, service: string): Promise<Uint8Array> {
  const kDate = await hmac(new TextEncoder().encode('AWS4' + key), dateStamp);
  const kRegion = await hmac(kDate, region);
  const kService = await hmac(kRegion, service);
  const kSigning = await hmac(kService, 'aws4_request');
  return kSigning;
}

function isoDate(date: Date): string {
  return date.toISOString().replace(/[:-]|\.\d{3}/g, '');
}

async function signBedrockRequest(
  method: 'POST',
  url: URL,
  body: string,
  region: string,
  accessKey: string,
  secretKey: string,
  sessionToken?: string
): Promise<Record<string, string>> {
  const service = 'bedrock';
  const amzDate = isoDate(new Date());
  const dateStamp = amzDate.slice(0, 8);
  const canonicalUri = url.pathname;
  const canonicalQuerystring = '';
  const payloadHash = toHex(await sha256(body));

  const canonicalHeaders = `content-type:application/json\nhost:${url.host}\nx-amz-date:${amzDate}\n`;
  const signedHeaders = 'content-type;host;x-amz-date';
  const canonicalRequest = `${method}\n${canonicalUri}\n${canonicalQuerystring}\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;

  const algorithm = 'AWS4-HMAC-SHA256';
  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
  const stringToSign = `${algorithm}\n${amzDate}\n${credentialScope}\n${toHex(await sha256(canonicalRequest))}`;

  const signingKey = await getSignatureKey(secretKey, dateStamp, region, service);
  const signature = toHex(await hmac(signingKey, stringToSign));

  const authorizationHeader = `${algorithm} Credential=${accessKey}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'X-Amz-Date': amzDate,
    Authorization: authorizationHeader,
  };
  if (sessionToken) {
    headers['X-Amz-Security-Token'] = sessionToken;
  }
  return headers;
}

async function invokeBedrock(body: Record<string, unknown>): Promise<any | null> {
  if (!AWS_ACCESS_KEY_ID || !AWS_SECRET_ACCESS_KEY || !AWS_REGION) {
    console.error('AWS credentials not configured');
    return null;
  }

  const url = new URL(`https://bedrock-runtime.${AWS_REGION}.amazonaws.com/model/${BEDROCK_MODEL_ID}/invoke`);
  const bodyString = JSON.stringify(body);
  const headers = await signBedrockRequest('POST', url, bodyString, AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN);

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), BEDROCK_TIMEOUT_MS);
  try {
    const resp = await fetch(url.toString(), {
      method: 'POST',
      headers,
      body: bodyString,
      signal: controller.signal,
    });
    clearTimeout(timer);
    if (!resp.ok) {
      const errorText = await resp.text();
      console.error('Bedrock API error:', resp.status, errorText);
      return null;
    }
    return await resp.json();
  } catch (err) {
    clearTimeout(timer);
    console.error('Bedrock invoke error:', err);
    return null;
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Parse request body
    let requestData: AnalysisRequest;
    try {
      requestData = await req.json();
      console.log('Parsed request data:', JSON.stringify(requestData, null, 2));
    } catch (parseError) {
      console.error('JSON parse error:', parseError);
      return new Response(
        JSON.stringify({ error: 'Invalid JSON in request body', details: parseError.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { dtcs, make, model, year, odometerReading, askingPrice, interiorCondition, tireCondition } = requestData;

    // Validate required fields
    if (!make || typeof make !== 'string' || make.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid required field: make' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!model || typeof model !== 'string' || model.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid required field: model' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!year || typeof year !== 'number' || year < 1900 || year > 2100) {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid required field: year (must be a number between 1900-2100)' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Ensure dtcs is an array (default to empty if missing)
    const dtcsArray = Array.isArray(dtcs) ? dtcs : [];

    // Build prompt for Bedrock
    const vehicleInfo = `${year} ${make} ${model}`;
    const mileageInfo = odometerReading ? ` with ${odometerReading.toLocaleString()} miles` : '';
    const conditionInfo = [];
    if (interiorCondition) conditionInfo.push(`Interior: ${interiorCondition}`);
    if (tireCondition) conditionInfo.push(`Tires: ${tireCondition}`);
    const conditionText = conditionInfo.length > 0 ? `\nCondition: ${conditionInfo.join(', ')}` : '';
    const askingPriceText = askingPrice ? `\nAsking Price: $${askingPrice.toLocaleString()}` : '';

    const hasDTCs = dtcsArray && dtcsArray.length > 0;

    // Build prompt conditionally based on whether DTCs exist
    let prompt: string;
    if (hasDTCs) {
      // Include both DTC analysis and valuation
      prompt = `You are an automotive diagnostic expert. Analyze the following diagnostic trouble codes (DTCs) for a ${vehicleInfo}${mileageInfo}.${conditionText}${askingPriceText}

DTCs to analyze: ${dtcsArray.join(', ')}

Provide a comprehensive analysis in JSON format with the following structure:

{
  "dtcAnalyses": [
    {
      "code": "P0420",
      "name": "Catalytic Converter Efficiency Below Threshold",
      "description": "Clear explanation of what this code means in simple terms",
      "repairCostLow": 500,
      "repairCostHigh": 2500,
      "urgency": "high",
      "commonForVehicle": true
    }
  ],
  "totalRepairCostLow": 500,
  "totalRepairCostHigh": 2500,
  "overallUrgency": "high",
  "summary": "Overall summary of the issues found and their impact",
  "vehicleValuation": {
    "lowEstimate": 18400,
    "highEstimate": 20680,
    "reasoning": "Brief explanation of the US national average valuation based on age, mileage, condition, and current market conditions"
  }
}

For each DTC:
- Provide a clear, simple description that a non-mechanic can understand
- Estimate realistic repair costs (low and high range)
- Assess urgency: "low", "medium", "high", or "critical"
- Indicate if this is common for this make/model

For vehicle valuation:
- Estimate current US national average market value range (low and high) in USD
- Base the estimate on nationwide market data, not regional prices
- Consider: vehicle age, mileage, condition, make/model reliability, current market trends
- Account for any issues found in the DTC analysis
- Provide brief reasoning for the estimate

Return ONLY valid JSON, no other text.`;
    } else {
      // Only request vehicle valuation (no DTCs to analyze)
      prompt = `You are an automotive valuation expert. Estimate the current market value for a ${vehicleInfo}${mileageInfo}.${conditionText}${askingPriceText}

Provide a vehicle valuation in JSON format with the following structure:

{
  "dtcAnalyses": [],
  "totalRepairCostLow": 0,
  "totalRepairCostHigh": 0,
  "overallUrgency": "low",
  "summary": "No diagnostic trouble codes found. Vehicle appears to be in good condition based on the scan.",
  "vehicleValuation": {
    "lowEstimate": 18400,
    "highEstimate": 20680,
    "reasoning": "Brief explanation of the US national average valuation based on age, mileage, condition, make/model reliability, and current market trends"
  }
}

For vehicle valuation:
- Estimate current US national average market value range (low and high) in USD
- Base the estimate on nationwide market data, not regional prices
- Consider: vehicle age, mileage, condition, make/model reliability, current market trends
- If asking price is provided, note whether it's above, below, or within the estimated range
- Provide brief reasoning for the estimate

Return ONLY valid JSON, no other text.`;
    }

    // Call Bedrock
    const bedrockBody = {
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 2000,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ]
    };

    const bedrockResponse = await invokeBedrock(bedrockBody);

    if (!bedrockResponse) {
      return new Response(
        JSON.stringify({ error: 'Failed to analyze DTCs - AI service unavailable' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse response
    const responseText = bedrockResponse.content?.[0]?.text || '';
    
    // Extract JSON from response
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      console.error('No JSON found in Bedrock response:', responseText);
      return new Response(
        JSON.stringify({ error: 'Invalid response from AI service' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const analysisData = JSON.parse(jsonMatch[0]);

    // Format response to match expected structure
    const response = {
      analyses: analysisData.dtcAnalyses || [],
      totalRepairCostLow: analysisData.totalRepairCostLow || 0,
      totalRepairCostHigh: analysisData.totalRepairCostHigh || 0,
      overallUrgency: analysisData.overallUrgency || (hasDTCs ? 'medium' : 'low'),
      summary: analysisData.summary || (hasDTCs ? '' : 'No diagnostic trouble codes found. Vehicle appears to be in good condition.'),
      vehicleValuation: analysisData.vehicleValuation || null
    };

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in analyze-dtcs:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
