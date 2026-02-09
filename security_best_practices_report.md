# BiteWise Security Best Practices Report

## Executive Summary
This review covers the iOS Swift client, Supabase Edge Functions, and Supabase SQL/RLS policies. The most significant risks are **exposed secrets** (local config + client‑side API key usage) and **unauthenticated job processing** in the account deletion worker. Key rotation is explicitly **deferred** per request. Several defense‑in‑depth improvements were implemented (request size limits/timeouts, Keychain storage for user profile, stricter error logging, and main‑thread enforcement for shared state).

## Scope
- iOS Swift client (`BiteWise/`)
- Supabase Edge Functions (`supabase/functions/`)
- Supabase SQL/RLS policies (`supabase/migrations/`)

## Severity Definitions
- **CRITICAL:** Exposed secrets, auth bypass, SQL injection, unauthorized data access.
- **HIGH:** Missing/incorrect RLS, unvalidated inputs leading to leakage, insecure auth/session handling.
- **MEDIUM:** Thread safety issues, error handling gaps, rate limiting weaknesses.
- **LOW:** Logging/observability improvements, minor hardening.

## Findings

### CRITICAL‑1: Secrets present in local config (rotation deferred)
**Evidence**: `Secrets.xcconfig:6-10` contains live Supabase and Gemini keys. Even though the file is not in git history, it is still a local secret that could be accidentally shared.
- `Secrets.xcconfig:6-7` (Supabase URL + anon key)
- `Secrets.xcconfig:10` (Gemini API key)

**Impact**: If this file is shared or leaked, an attacker can use the keys to access backend resources or consume API quota.

**Status**: **Deferred** — rotation and cleanup will be done later as requested.

**Recommendation**: Rotate keys before production or any repo sharing. Consider `.gitignore` enforcement and pre‑commit secret scanning.

### HIGH‑1: Client‑side Gemini API key exposure
**Evidence**:
- API key loaded from Info.plist: `BiteWise/Services/APIConfiguration.swift:14-24`
- Key placed directly into network request: `BiteWise/Services/GeminiService.swift:423-432`

**Impact**: Client‑side API keys are extractable from the app bundle, enabling unauthorized API usage and quota abuse.

**Recommendation**: Proxy Gemini requests through a server/Edge Function and keep the key server‑side only.

### MEDIUM‑1: Account deletion worker lacks authentication
**Status**: **Resolved** — `process-account-deletion` now validates `Authorization: Bearer <serviceRoleKey>` before processing.

**Evidence**: Authorization check added in handler (`supabase/functions/process-account-deletion/index.ts:320-334`).

**Impact (previous)**: Any caller could trigger job processing, which could lead to unintended load or premature processing of queued deletions.

**Recommendation (if re-opened)**: Require an internal secret header or service‑role token for invocation, or restrict via network policy.

### MEDIUM‑2: Rate limiting is in‑memory only (cold‑start reset)
**Evidence**: In‑memory maps for IP/email rate limits are used in `send-password-reset` and reset on cold start (`supabase/functions/send-password-reset/index.ts:34-42`).

**Impact**: Attackers can bypass limits by forcing cold starts or spreading load across instances.

**Recommendation**: Persist limits in a shared store (e.g., Deno KV or database table) for production.

### LOW‑1: Wildcard CORS on Edge Functions
**Evidence**: CORS allows `*` origin in Edge Functions (e.g., `supabase/functions/send-password-reset/index.ts:20-23`).

**Impact**: Increases exposure surface and can allow cross‑site invocation from untrusted origins.

**Recommendation**: Restrict to known app/web origins where possible.

## Hardening Implemented in This Change
- **Main‑thread safety**: `DataManager` and `SessionContext` are now `@MainActor` (`BiteWise/Models/DataManager.swift:6-7`, `BiteWise/Services/SessionContext.swift:34-37`).
- **Error handling**: Replaced silent persistence failures with `do/catch` + `Logger` helpers (`BiteWise/Models/DataManager.swift:99-119`).
- **Data versioning**: Added a non‑destructive `dataVersion` check that logs and bumps versions (`BiteWise/Models/DataManager.swift:91-97`).
- **Sensitive data storage**: `UserProfile` now stored in Keychain with migration from UserDefaults (`BiteWise/Services/KeychainService.swift:8-78`, `BiteWise/Models/DataManager.swift:121-160`).
- **Edge Function guardrails**: Added request size limits and timeouts (`supabase/functions/send-password-reset/index.ts:25-98`, `supabase/functions/delete-user-account/index.ts:25-78`, `supabase/functions/process-account-deletion/index.ts:20-87`).
- **Memory considerations**: Recipe history cleanup already addressed by migration `00015_cleanup_recipe_history.sql` (`supabase/migrations/00015_cleanup_recipe_history.sql:10-90`).

## Deferred Items
- **Key rotation** for Supabase + Gemini keys (explicitly deferred). A rotation playbook should be executed before production or repo sharing.
