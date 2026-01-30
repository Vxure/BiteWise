/**
 * Delete User Account Edge Function
 * 
 * This function handles account deletion requests from the client.
 * It creates a deletion job and optionally processes it immediately.
 * 
 * The job queue approach ensures:
 * - Idempotency (safe to call multiple times)
 * - Retry capability for partial failures
 * - Audit trail of deletion status
 */

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Structured logging
function log(level: "info" | "warn" | "error", event: string, details?: Record<string, unknown>): void {
  console.log(JSON.stringify({ timestamp: new Date().toISOString(), level, event, ...details }));
}

// Delete storage objects with pagination and graceful error handling
async function deleteBucketObjects(
  adminClient: SupabaseClient,
  bucket: string,
  userId: string,
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
      // Gracefully handle "not found" errors
      if (error.message?.includes("not found") || error.message?.includes("does not exist")) {
        break;
      }
      errors.push(`${bucket}: ${error.message}`);
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
      errors.push(`${bucket} remove: ${removeError.message}`);
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

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    log("error", "config_error", { message: "Missing environment variables" });
    return new Response(JSON.stringify({ error: "Server configuration error." }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized." }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Parse request body for options
  let useJobQueue = true; // Default to job queue for robustness
  let waitForCompletion = true; // Default to waiting for immediate processing
  
  try {
    const body = await req.json();
    if (body.use_job_queue === false) useJobQueue = false;
    if (body.wait_for_completion === false) waitForCompletion = false;
  } catch {
    // Empty body is fine, use defaults
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized." }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const userId = user.id;
  log("info", "deletion_requested", { user_id: userId, use_job_queue: useJobQueue });

  if (useJobQueue) {
    // Create a deletion job via RPC
    const { data: jobResult, error: jobError } = await userClient.rpc("request_account_deletion");
    
    if (jobError) {
      log("error", "job_creation_failed", { user_id: userId, error: jobError.message });
      return new Response(JSON.stringify({ error: "Failed to create deletion job." }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const jobData = jobResult as { success: boolean; job_id: string; status: string; message: string };
    log("info", "job_created", { user_id: userId, job_id: jobData.job_id, status: jobData.status });

    if (waitForCompletion && jobData.status === "pending") {
      // Process the job immediately
      try {
        const processResponse = await fetch(`${supabaseUrl}/functions/v1/process-account-deletion`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${serviceRoleKey}`,
          },
          body: JSON.stringify({ job_id: jobData.job_id }),
        });

        if (!processResponse.ok) {
          const errorText = await processResponse.text();
          log("warn", "immediate_processing_failed", { job_id: jobData.job_id, error: errorText });
          // Job is queued, will be processed later
          return new Response(JSON.stringify({
            success: true,
            job_id: jobData.job_id,
            status: "queued",
            message: "Deletion queued for processing",
          }), {
            status: 202,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const processResult = await processResponse.json();
        log("info", "immediate_processing_complete", { job_id: jobData.job_id, result: processResult });

        return new Response(JSON.stringify({
          success: true,
          job_id: jobData.job_id,
          status: "completed",
          message: "Account deleted successfully",
        }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } catch (processError) {
        log("warn", "immediate_processing_error", { 
          job_id: jobData.job_id, 
          error: processError instanceof Error ? processError.message : String(processError) 
        });
        // Job is queued, will be processed later
        return new Response(JSON.stringify({
          success: true,
          job_id: jobData.job_id,
          status: "queued",
          message: "Deletion queued for processing",
        }), {
          status: 202,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    return new Response(JSON.stringify({
      success: true,
      job_id: jobData.job_id,
      status: jobData.status,
      message: jobData.message,
    }), {
      status: jobData.status === "completed" ? 200 : 202,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Legacy direct deletion path (for backwards compatibility)
  // This path is less robust but faster for simple cases
  log("info", "direct_deletion_started", { user_id: userId });

  try {
    // Step 1: Delete user-scoped database rows via RPC
    const { data: rpcResult, error: rpcError } = await userClient.rpc("delete_user_account");
    if (rpcError) {
      throw new Error(`DB deletion failed: ${rpcError.message}`);
    }
    log("info", "db_deleted", { user_id: userId, result: rpcResult });

    // Step 2: Delete storage objects
    const buckets = ["fridge-photos", "recipe-images", "avatars"];
    for (const bucket of buckets) {
      const result = await deleteBucketObjects(adminClient, bucket, userId);
      if (result.errors.length > 0) {
        log("warn", "storage_partial_error", { user_id: userId, bucket, errors: result.errors });
      }
    }
    log("info", "storage_deleted", { user_id: userId });

    // Step 3: Delete auth user
    const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(userId);
    if (deleteUserError && !deleteUserError.message?.includes("not found")) {
      throw new Error(`Auth deletion failed: ${deleteUserError.message}`);
    }
    log("info", "auth_deleted", { user_id: userId });

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    log("error", "direct_deletion_failed", { user_id: userId, error: errorMessage });
    return new Response(JSON.stringify({ error: "Failed to delete account." }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
