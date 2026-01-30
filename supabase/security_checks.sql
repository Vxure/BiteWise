-- ============================================================================
-- Security Verification Checks (Manual)
-- Run in Supabase SQL editor to verify security policies
-- ============================================================================

-- ============================================================================
-- 1. RLS POLICY VERIFICATION
-- ============================================================================

-- 1a) Verify profiles are only readable by the owner
SET request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000001"}';
SELECT id, name, email FROM public.profiles;
-- Expected: Only rows where id = '00000000-0000-0000-0000-000000000001'

-- 1b) Verify user_preferences are scoped
SELECT * FROM public.user_preferences;
-- Expected: Only rows where user_id = '00000000-0000-0000-0000-000000000001'

-- 1c) Verify deletion jobs are scoped
SELECT * FROM public.account_deletion_jobs;
-- Expected: Only rows where user_id = '00000000-0000-0000-0000-000000000001'

-- ============================================================================
-- 2. RPC FUNCTION SECURITY
-- ============================================================================

-- 2a) Verify delete_user_account RPC requires auth
RESET request.jwt.claims;
SELECT public.delete_user_account(); 
-- Expected: ERROR 'Not authenticated'

-- 2b) Verify request_account_deletion RPC requires auth
SELECT public.request_account_deletion();
-- Expected: ERROR 'Not authenticated'

-- 2c) Verify get_deletion_job_status RPC requires auth
SELECT public.get_deletion_job_status();
-- Expected: ERROR 'Not authenticated'

-- 2d) Verify admin function is not callable by authenticated users
SET request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000001"}';
SELECT public.delete_user_account_admin('00000000-0000-0000-0000-000000000002');
-- Expected: ERROR (permission denied)

-- ============================================================================
-- 3. AUTHENTICATED USER TESTS
-- ============================================================================

-- 3a) Verify authenticated delete_user_account works (returns JSON)
SET request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000001"}';
SELECT public.delete_user_account();
-- Expected: JSON with success: true and deleted counts

-- 3b) Verify request_account_deletion creates job
SELECT public.request_account_deletion();
-- Expected: JSON with success: true, job_id, status

-- 3c) Verify get_deletion_job_status returns job info
SELECT public.get_deletion_job_status();
-- Expected: JSON with job details or has_job: false

-- ============================================================================
-- 4. POLICY EXISTENCE VERIFICATION
-- ============================================================================

-- 4a) Verify no global profile read policy exists
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'profiles'
  AND policyname LIKE '%all profiles%';
-- Expected: No rows

-- 4b) Verify own-profile policy exists
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'profiles'
  AND policyname = 'Users can view own profile';
-- Expected: 1 row with USING (auth.uid() = id)

-- 4c) List all profile policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'profiles';
-- Expected: Only own-profile read and update policies

-- ============================================================================
-- 5. DELETION JOB TABLE VERIFICATION
-- ============================================================================

-- 5a) Verify job table exists with correct columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'account_deletion_jobs'
ORDER BY ordinal_position;

-- 5b) Verify RLS is enabled on job table
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname = 'account_deletion_jobs';
-- Expected: relrowsecurity = true

RESET request.jwt.claims;
