# BiteWise Supabase Backend

This directory contains the complete Supabase database schema for BiteWise.

## Directory Structure

```
supabase/
├── README.md           # This file
└── migrations/         # SQL migration files
    ├── 00001_foundation_tables.sql     # profiles, user_preferences, user_settings
    ├── 00002_inventory_tables.sql      # ingredients, fridge_scans, fridge_items, pantry_items
    ├── 00003_recipe_tables.sql         # recipes, saved_recipes, recipe_history, recipe_feedback
    ├── 00004_chat_tables.sql           # chat_sessions, chat_messages
    ├── 00005_tracking_tables.sql       # daily_macro_logs, activity_feed
    ├── 00006_rls_policies.sql          # Row Level Security policies
    ├── 00007_clear_functions.sql       # Clear data RPCs with timestamp updates
    ├── 00008_cleanup_functions.sql     # Auto-delete expired data functions
    ├── 00009_storage_buckets.sql       # Storage buckets and policies
    └── 00010_seed_ingredients.sql      # Seed data for ingredients catalog
```

## Database Schema Overview

### Core Tables

| Table | Description |
|-------|-------------|
| `profiles` | User profiles (extends auth.users) |
| `user_preferences` | Dietary preferences, allergies, macro goals |
| `user_settings` | App settings, retention policies, clear timestamps |
| `ingredients` | Shared ingredient catalog for normalization |
| `fridge_scans` | Fridge photo scan records |
| `fridge_items` | User's fridge inventory |
| `pantry_items` | User's pantry staples |
| `recipes` | Recipe storage (user, AI, or system) |
| `saved_recipes` | User's favorite/bookmarked recipes |
| `recipe_history` | Log of cooked recipes |
| `recipe_feedback` | Detailed recipe feedback |
| `chat_sessions` | Chat conversation sessions |
| `chat_messages` | Individual chat messages |
| `daily_macro_logs` | Daily nutrition tracking |
| `activity_feed` | Recent user activity |

### Storage Buckets

| Bucket | Public | Purpose |
|--------|--------|---------|
| `fridge-photos` | No | User's fridge scan images |
| `recipe-images` | Yes | Recipe photos |
| `avatars` | Yes | User profile pictures |

## Setup Instructions

### Option 1: Supabase Dashboard (Recommended for first-time setup)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Run each migration file in order (00001 → 00010)
4. Verify tables in **Table Editor**

### Option 2: Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Push migrations
supabase db push
```

### Option 3: Direct psql

```bash
psql "postgres://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  -f supabase/migrations/00001_foundation_tables.sql
# ... repeat for each migration
```

## Key Features

### Auto-Delete with User Settings

Users can configure retention periods in `user_settings`:
- `fridge_auto_expire_enabled` / `fridge_auto_expire_days`
- `chat_auto_expire_enabled` / `general_chat_expire_days`
- `keep_recipe_chats_longer` / `recipe_chat_expire_days`

### Clear Functions with Timestamps

When users clear data, timestamps are updated automatically:

```sql
-- Clear fridge items
SELECT clear_fridge_items();
-- Updates: last_fridge_clear_at

-- Clear pantry items
SELECT clear_pantry_items();
-- Updates: last_pantry_clear_at

-- Clear chat history
SELECT clear_chat_history();
-- Updates: last_chat_clear_at
```

### Daily Cleanup

Schedule `run_daily_cleanup()` via pg_cron or Edge Function:

```sql
-- If using pg_cron:
SELECT cron.schedule('daily-cleanup', '0 3 * * *', 'SELECT run_daily_cleanup()');
```

## iOS Integration

### Swift Model Mapping

| Swift Model | Supabase Table |
|-------------|----------------|
| `UserProfile` | `profiles` + `user_preferences` |
| `AppSettings` | `user_settings` (partial) |
| `FridgeItem` | `fridge_items` |
| `Ingredient` | `pantry_items` |
| `Recipe` | `recipes` |
| `ChatSession` | `chat_sessions` |
| `ChatMessage` | `chat_messages` |
| `DailyMacroLog` | `daily_macro_logs` |
| `RecipeFeedback` | `recipe_feedback` |
| `ActivityItem` | `activity_feed` |

### Example: Clear Fridge from iOS

```swift
// Using Supabase Swift SDK
try await supabase.rpc("clear_fridge_items").execute()

// Read the clear timestamp
let settings: UserSettings = try await supabase
    .from("user_settings")
    .select("last_fridge_clear_at")
    .single()
    .execute()
    .value
```

## RLS Policies Summary

- **User-owned data**: Users can only access their own data
- **Public recipes**: `is_public = true` recipes readable by all
- **Ingredients catalog**: Readable by all authenticated users
- **Storage**: Users can only upload to their own folders

## Troubleshooting

### Migration Order

Always run migrations in numerical order. Each migration may depend on tables created in previous migrations.

### RLS Testing

To test RLS policies in SQL Editor:

```sql
-- Test as authenticated user
SET request.jwt.claims = '{"sub": "user-uuid-here"}';
SELECT * FROM profiles;
```

### Resetting a User's Data

```sql
SELECT clear_all_user_data();
```

## Environment Variables (iOS)

Add to your Xcode project:

```swift
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://YOUR_PROJECT.supabase.co")!,
    supabaseKey: "YOUR_ANON_KEY"
)
```
