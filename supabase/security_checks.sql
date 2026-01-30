-- Security verification checks (manual)
-- Run in Supabase SQL editor with request.jwt.claims set.

-- 1) Verify profiles are only readable by the owner
SET request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000001"}';
SELECT id, name, email FROM public.profiles;

-- 2) Verify user_preferences are scoped
SELECT * FROM public.user_preferences;

-- 3) Verify delete_user_account RPC requires auth
RESET request.jwt.claims;
SELECT public.delete_user_account(); -- should error

-- 4) Verify authenticated RPC scope
SET request.jwt.claims = '{"sub": "00000000-0000-0000-0000-000000000001"}';
SELECT public.delete_user_account();
