-- Migration: Account Deletion RPC
-- Description: Creates an RPC function to delete all user data for account deletion

-- RPC function to delete user account and all associated data
-- This function is called by the server-side deletion flow to clean up user data
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get the current authenticated user's ID
    current_user_id := auth.uid();
    
    -- Ensure user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Delete from all user-related tables
    -- Order matters due to foreign key constraints
    
    -- Delete chat messages first (references chat_sessions)
    DELETE FROM public.chat_messages WHERE user_id = current_user_id;
    
    -- Delete chat sessions
    DELETE FROM public.chat_sessions WHERE user_id = current_user_id;
    
    -- Delete recipe feedback
    DELETE FROM public.recipe_feedback WHERE user_id = current_user_id;
    
    -- Delete recipe history
    DELETE FROM public.recipe_history WHERE user_id = current_user_id;
    
    -- Delete saved recipes (favorites)
    DELETE FROM public.saved_recipes WHERE user_id = current_user_id;
    
    -- Delete recipes created by user
    DELETE FROM public.recipes WHERE user_id = current_user_id;
    
    -- Delete daily macro logs
    DELETE FROM public.daily_macro_logs WHERE user_id = current_user_id;
    
    -- Delete activity feed
    DELETE FROM public.activity_feed WHERE user_id = current_user_id;
    
    -- Delete fridge items
    DELETE FROM public.fridge_items WHERE user_id = current_user_id;
    
    -- Delete pantry items
    DELETE FROM public.pantry_items WHERE user_id = current_user_id;
    
    -- Delete user preferences
    DELETE FROM public.user_preferences WHERE user_id = current_user_id;
    
    -- Delete profile (this should cascade but being explicit)
    DELETE FROM public.profiles WHERE id = current_user_id;
    
    -- Note: Deletion from auth.users and storage objects is handled separately
    -- via a server-side Admin API call (e.g., Edge Function).
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- Explicitly revoke from anonymous and public roles
REVOKE ALL ON FUNCTION public.delete_user_account() FROM anon;
REVOKE ALL ON FUNCTION public.delete_user_account() FROM public;

-- Add comment for documentation
COMMENT ON FUNCTION public.delete_user_account() IS 'Deletes all data associated with the current authenticated user. Called during account deletion flow.';
