import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

if (!supabaseUrl || !anonKey || !serviceRoleKey) {
  console.error("Missing required environment variables for Supabase clients.");
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
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

  // Step 1: Delete user-scoped database rows via RPC (uses auth.uid())
  const { error: rpcError } = await userClient.rpc("delete_user_account");
  if (rpcError) {
    console.error("RPC delete_user_account failed:", rpcError.message);
    return new Response(JSON.stringify({ error: "Failed to delete account data." }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Step 2: Delete storage objects owned by the user
  try {
    await deleteBucketObjects(adminClient, "fridge-photos", userId);
    await deleteBucketObjects(adminClient, "recipe-images", userId);
    await deleteBucketObjects(adminClient, "avatars", userId);
  } catch (storageError) {
    console.error("Storage deletion failed:", storageError);
    return new Response(JSON.stringify({ error: "Failed to delete storage assets." }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Step 3: Delete auth user
  const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(userId);
  if (deleteUserError && deleteUserError.message !== "User not found") {
    console.error("Auth user deletion failed:", deleteUserError.message);
    return new Response(JSON.stringify({ error: "Failed to delete auth user." }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

async function deleteBucketObjects(
  adminClient: ReturnType<typeof createClient>,
  bucket: string,
  userId: string,
) {
  const paths: string[] = [];
  const limit = 1000;
  let offset = 0;

  while (true) {
    const { data, error } = await adminClient.storage
      .from(bucket)
      .list(userId, { limit, offset });

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) {
      break;
    }

    for (const item of data) {
      paths.push(`${userId}/${item.name}`);
    }

    if (data.length < limit) {
      break;
    }

    offset += data.length;
  }

  if (paths.length > 0) {
    const { error: removeError } = await adminClient.storage
      .from(bucket)
      .remove(paths);
    if (removeError) {
      throw removeError;
    }
  }
}
