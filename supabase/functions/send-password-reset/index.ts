/**
 * Send Password Reset Edge Function
 * 
 * This function provides server-side rate limiting for password reset requests.
 * It prevents abuse by limiting requests per IP address and email hash.
 * 
 * Rate limits:
 * - Per IP: 5 requests per 15 minutes
 * - Per email hash: 3 requests per 15 minutes
 * 
 * The response is always neutral to prevent account enumeration.
 */

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Request limits / timeouts
const MAX_BODY_BYTES = 16 * 1024; // 16 KB
const REQUEST_TIMEOUT_MS = 10_000; // 10 seconds

// Rate limit configuration
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes
const MAX_REQUESTS_PER_IP = 5;
const MAX_REQUESTS_PER_EMAIL = 3;

// In-memory rate limit store (resets on function cold start)
// For production at scale, consider using Redis or a database table
interface RateLimitEntry {
  count: number;
  windowStart: number;
}

const ipRateLimits = new Map<string, RateLimitEntry>();
const emailRateLimits = new Map<string, RateLimitEntry>();

function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("Request timed out")), timeoutMs);
    promise
      .then((value) => {
        clearTimeout(timer);
        resolve(value);
      })
      .catch((error) => {
        clearTimeout(timer);
        reject(error);
      });
  });
}

async function parseJsonBody(req: Request): Promise<{ ok: true; data: any } | { ok: false; response: Response }> {
  const contentLength = req.headers.get("content-length");
  if (contentLength && Number(contentLength) > MAX_BODY_BYTES) {
    return {
      ok: false,
      response: new Response(JSON.stringify({ error: "Payload too large" }), {
        status: 413,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }

  const bodyBuffer = await req.arrayBuffer();
  if (bodyBuffer.byteLength > MAX_BODY_BYTES) {
    return {
      ok: false,
      response: new Response(JSON.stringify({ error: "Payload too large" }), {
        status: 413,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }

  if (bodyBuffer.byteLength === 0) {
    return { ok: true, data: {} };
  }

  try {
    const text = new TextDecoder().decode(bodyBuffer);
    return { ok: true, data: JSON.parse(text) };
  } catch {
    return {
      ok: false,
      response: new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }
}

// Structured logging
function log(level: "info" | "warn" | "error", event: string, details?: Record<string, unknown>): void {
  console.log(JSON.stringify({ timestamp: new Date().toISOString(), level, event, ...details }));
}

// Hash email for privacy in logs and rate limiting
async function hashEmail(email: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(email.toLowerCase().trim());
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.slice(0, 8).map(b => b.toString(16).padStart(2, "0")).join("");
}

// Check and update rate limit
function checkRateLimit(
  store: Map<string, RateLimitEntry>,
  key: string,
  maxRequests: number
): { allowed: boolean; remaining: number; resetIn: number } {
  const now = Date.now();
  const entry = store.get(key);

  if (!entry || now - entry.windowStart > RATE_LIMIT_WINDOW_MS) {
    // New window
    store.set(key, { count: 1, windowStart: now });
    return { allowed: true, remaining: maxRequests - 1, resetIn: RATE_LIMIT_WINDOW_MS };
  }

  if (entry.count >= maxRequests) {
    const resetIn = RATE_LIMIT_WINDOW_MS - (now - entry.windowStart);
    return { allowed: false, remaining: 0, resetIn };
  }

  entry.count++;
  store.set(key, entry);
  const resetIn = RATE_LIMIT_WINDOW_MS - (now - entry.windowStart);
  return { allowed: true, remaining: maxRequests - entry.count, resetIn };
}

// Get client IP from request headers
function getClientIP(req: Request): string {
  // Check common proxy headers
  const forwardedFor = req.headers.get("x-forwarded-for");
  if (forwardedFor) {
    return forwardedFor.split(",")[0].trim();
  }
  
  const realIP = req.headers.get("x-real-ip");
  if (realIP) {
    return realIP;
  }

  const cfConnectingIP = req.headers.get("cf-connecting-ip");
  if (cfConnectingIP) {
    return cfConnectingIP;
  }

  return "unknown";
}

// Validate email format
function isValidEmail(email: string): boolean {
  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
  return emailRegex.test(email);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!supabaseUrl || !serviceRoleKey) {
    log("error", "config_error", { message: "Missing environment variables" });
    return new Response(JSON.stringify({ error: "Server configuration error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Parse request body
  let email: string;
  let redirectTo: string | undefined;

  const bodyResult = await parseJsonBody(req);
  if (!bodyResult.ok) {
    return bodyResult.response;
  }

  const body = bodyResult.data ?? {};
  email = body.email;
  redirectTo = body.redirect_to;

  if (!email || typeof email !== "string") {
    return new Response(JSON.stringify({ error: "Email is required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Validate email format
  if (!isValidEmail(email)) {
    return new Response(JSON.stringify({ error: "Invalid email format" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const normalizedEmail = email.toLowerCase().trim();
  const emailHash = await hashEmail(normalizedEmail);
  const clientIP = getClientIP(req);

  // Check IP rate limit
  const ipLimit = checkRateLimit(ipRateLimits, clientIP, MAX_REQUESTS_PER_IP);
  if (!ipLimit.allowed) {
    const retryAfter = Math.ceil(ipLimit.resetIn / 1000);
    log("warn", "rate_limit_ip", { ip: clientIP, retry_after: retryAfter });
    return new Response(JSON.stringify({ 
      error: "Too many requests",
      retry_after: retryAfter,
    }), {
      status: 429,
      headers: { 
        ...corsHeaders, 
        "Content-Type": "application/json",
        "Retry-After": String(retryAfter),
      },
    });
  }

  // Check email rate limit
  const emailLimit = checkRateLimit(emailRateLimits, emailHash, MAX_REQUESTS_PER_EMAIL);
  if (!emailLimit.allowed) {
    const retryAfter = Math.ceil(emailLimit.resetIn / 1000);
    log("warn", "rate_limit_email", { email_hash: emailHash, retry_after: retryAfter });
    return new Response(JSON.stringify({ 
      error: "Too many requests for this email",
      retry_after: retryAfter,
    }), {
      status: 429,
      headers: { 
        ...corsHeaders, 
        "Content-Type": "application/json",
        "Retry-After": String(retryAfter),
      },
    });
  }

  // Create admin client to send reset email
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    // Send password reset email
    const { error } = await withTimeout(
      adminClient.auth.resetPasswordForEmail(normalizedEmail, {
        redirectTo: redirectTo || undefined,
      }),
      REQUEST_TIMEOUT_MS
    );

    if (error) {
      // Log the error but return neutral response
      log("warn", "reset_email_error", { email_hash: emailHash, error: error.message });
    } else {
      log("info", "reset_email_sent", { email_hash: emailHash, ip: clientIP });
    }

    // Always return success to prevent account enumeration
    // The neutral message doesn't reveal whether the account exists
    return new Response(JSON.stringify({ 
      success: true,
      message: "If an account exists for this email, a reset link will be sent.",
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    log("error", "reset_email_exception", { email_hash: emailHash, error: errorMessage });

    // Still return neutral response
    return new Response(JSON.stringify({ 
      success: true,
      message: "If an account exists for this email, a reset link will be sent.",
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
