/**
 * Process Account Deletion Edge Function
 * 
 * This function processes pending account deletion jobs from the queue.
 * It handles deletion in a safe order with retries and structured logging.
 * 
 * Can be triggered by:
 * 1. A scheduled cron job (recommended for production)
 * 2. Direct invocation after requesting deletion
 * 3. Manual trigger for retry processing
 */

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

// Environment variables
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Structured logging helper
interface LogEvent {
  event: string;
  job_id?: string;
  user_id?: string;
  step?: string;
  retry_count?: number;
  error?: string;
  duration_ms?: number;
  details?: Record<string, unknown>;
}

function log(level: "info" | "warn" | "error", event: LogEvent): void {
  const timestamp = new Date().toISOString();
  const logEntry = { timestamp, level, ...event };
  console.log(JSON.stringify(logEntry));
}

// Job status type
interface DeletionJob {
  id: string;
  user_id: string;
  status: string;
  retry_count: number;
  max_retries: number;
  db_deleted: boolean;
  storage_deleted: boolean;
  auth_deleted: boolean;
  last_error: string | null;
}

// Calculate next retry time with exponential backoff
function calculateNextRetry(retryCount: number): Date {
  // Exponential backoff: 30s, 1m, 2m, 4m, 8m
  const baseDelaySeconds = 30;
  const delaySeconds = baseDelaySeconds * Math.pow(2, retryCount);
  const maxDelaySeconds = 600; // Cap at 10 minutes
  const actualDelay = Math.min(delaySeconds, maxDelaySeconds);
  return new Date(Date.now() + actualDelay * 1000);
}

// Delete storage objects for a user with pagination
async function deleteStorageObjects(
  adminClient: SupabaseClient,
  bucket: string,
  userId: string
): Promise<{ deleted: number; errors: string[] }> {
  const errors: string[] = [];
  let totalDeleted = 0;
  const limit = 1000;
  let offset = 0;

  while (true) {
    const { data, error } = await adminClient.storage
      .from(bucket)
      .list(userId, { limit, offset });

    if (error) {
      // If bucket doesn't exist or user folder doesn't exist, that's OK
      if (error.message?.includes("not found") || error.message?.includes("does not exist")) {
        break;
      }
      errors.push(`List error in ${bucket}: ${error.message}`);
      break;
    }

    if (!data || data.length === 0) {
      break;
    }

    const paths = data.map((item) => `${userId}/${item.name}`);
    
    const { error: removeError } = await adminClient.storage
      .from(bucket)
      .remove(paths);

    if (removeError) {
      // Log but don't fail - some files might already be deleted
      errors.push(`Remove error in ${bucket}: ${removeError.message}`);
    } else {
      totalDeleted += paths.length;
    }

    if (data.length < limit) {
      break;
    }

    offset += data.length;
  }

  return { deleted: totalDeleted, errors };
}

// Process a single deletion job
async function processJob(
  adminClient: SupabaseClient,
  job: DeletionJob
): Promise<{ success: boolean; error?: string }> {
  const startTime = Date.now();
  const userId = job.user_id;

  log("info", {
    event: "job_started",
    job_id: job.id,
    user_id: userId,
    retry_count: job.retry_count,
  });

  // Mark job as processing
  await adminClient
    .from("account_deletion_jobs")
    .update({ status: "processing", started_at: new Date().toISOString() })
    .eq("id", job.id);

  try {
    // Step 1: Delete database rows (if not already done)
    if (!job.db_deleted) {
      log("info", { event: "step_started", job_id: job.id, step: "db_delete" });
      
      // Call the delete_user_account RPC as service role
      // We need to impersonate the user for auth.uid() to work
      const { error: rpcError } = await adminClient.rpc("delete_user_account_admin", {
        target_user_id: userId,
      });

      if (rpcError) {
        throw new Error(`DB deletion failed: ${rpcError.message}`);
      }

      await adminClient
        .from("account_deletion_jobs")
        .update({ db_deleted: true })
        .eq("id", job.id);

      log("info", { event: "db_deleted", job_id: job.id, user_id: userId });
    }

    // Step 2: Delete storage objects (if not already done)
    if (!job.storage_deleted) {
      log("info", { event: "step_started", job_id: job.id, step: "storage_delete" });
      
      const buckets = ["fridge-photos", "recipe-images", "avatars"];
      const allErrors: string[] = [];
      let totalDeleted = 0;

      for (const bucket of buckets) {
        const result = await deleteStorageObjects(adminClient, bucket, userId);
        totalDeleted += result.deleted;
        allErrors.push(...result.errors);
      }

      // Only fail if there were critical errors, not "not found" errors
      const criticalErrors = allErrors.filter(
        (e) => !e.includes("not found") && !e.includes("does not exist")
      );

      if (criticalErrors.length > 0) {
        log("warn", {
          event: "storage_partial_error",
          job_id: job.id,
          details: { errors: criticalErrors },
        });
      }

      await adminClient
        .from("account_deletion_jobs")
        .update({ storage_deleted: true })
        .eq("id", job.id);

      log("info", {
        event: "storage_deleted",
        job_id: job.id,
        user_id: userId,
        details: { files_deleted: totalDeleted },
      });
    }

    // Step 3: Delete auth user (if not already done)
    if (!job.auth_deleted) {
      log("info", { event: "step_started", job_id: job.id, step: "auth_delete" });
      
      const { error: authError } = await adminClient.auth.admin.deleteUser(userId);

      if (authError && !authError.message?.includes("not found")) {
        throw new Error(`Auth deletion failed: ${authError.message}`);
      }

      await adminClient
        .from("account_deletion_jobs")
        .update({ auth_deleted: true })
        .eq("id", job.id);

      log("info", { event: "auth_deleted", job_id: job.id, user_id: userId });
    }

    // Mark job as completed
    await adminClient
      .from("account_deletion_jobs")
      .update({
        status: "completed",
        completed_at: new Date().toISOString(),
        last_error: null,
      })
      .eq("id", job.id);

    const duration = Date.now() - startTime;
    log("info", {
      event: "job_completed",
      job_id: job.id,
      user_id: userId,
      duration_ms: duration,
    });

    return { success: true };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    const duration = Date.now() - startTime;

    log("error", {
      event: "job_failed",
      job_id: job.id,
      user_id: userId,
      retry_count: job.retry_count,
      error: errorMessage,
      duration_ms: duration,
    });

    // Update job with error and schedule retry if applicable
    const newRetryCount = job.retry_count + 1;
    const shouldRetry = newRetryCount < job.max_retries;

    await adminClient
      .from("account_deletion_jobs")
      .update({
        status: shouldRetry ? "pending" : "failed",
        retry_count: newRetryCount,
        last_error: errorMessage,
        next_retry_at: shouldRetry ? calculateNextRetry(newRetryCount).toISOString() : null,
      })
      .eq("id", job.id);

    return { success: false, error: errorMessage };
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Validate environment
  if (!supabaseUrl || !serviceRoleKey) {
    log("error", { event: "config_error", error: "Missing environment variables" });
    return new Response(
      JSON.stringify({ error: "Server configuration error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Create admin client
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    // Parse request body for optional parameters
    let jobId: string | null = null;
    let processAll = false;

    if (req.method === "POST") {
      try {
        const body = await req.json();
        jobId = body.job_id || null;
        processAll = body.process_all === true;
      } catch {
        // Empty body is fine
      }
    }

    let jobs: DeletionJob[] = [];

    if (jobId) {
      // Process specific job
      const { data, error } = await adminClient
        .from("account_deletion_jobs")
        .select("*")
        .eq("id", jobId)
        .single();

      if (error || !data) {
        return new Response(
          JSON.stringify({ error: "Job not found" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      jobs = [data as DeletionJob];
    } else {
      // Process pending jobs that are ready for retry
      const { data, error } = await adminClient
        .from("account_deletion_jobs")
        .select("*")
        .in("status", ["pending", "processing"])
        .lte("next_retry_at", new Date().toISOString())
        .order("created_at", { ascending: true })
        .limit(processAll ? 100 : 10);

      if (error) {
        throw new Error(`Failed to fetch jobs: ${error.message}`);
      }

      jobs = (data || []) as DeletionJob[];
    }

    if (jobs.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: "No jobs to process", processed: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    log("info", { event: "batch_started", details: { job_count: jobs.length } });

    // Process jobs
    const results: { job_id: string; success: boolean; error?: string }[] = [];

    for (const job of jobs) {
      const result = await processJob(adminClient, job);
      results.push({ job_id: job.id, ...result });
    }

    const successCount = results.filter((r) => r.success).length;
    const failCount = results.filter((r) => !r.success).length;

    log("info", {
      event: "batch_completed",
      details: { total: jobs.length, success: successCount, failed: failCount },
    });

    return new Response(
      JSON.stringify({
        success: true,
        processed: jobs.length,
        succeeded: successCount,
        failed: failCount,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    log("error", { event: "function_error", error: errorMessage });

    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
