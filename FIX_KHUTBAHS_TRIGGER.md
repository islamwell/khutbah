# Fix Khutbahs Sync Error

## Problem

You're seeing this error when saving khutbahs:
```
Error syncing khutbahs to cloud: Failed to update from minbar_khutbahs: record "new" has no field "updated_at"
```

## Root Cause

The `minbar_khutbahs` table has a column called `modified_at`, but the database trigger is trying to update a field called `updated_at` which doesn't exist.

This happened because:
1. The `khutbahs` table uses `modified_at` for its timestamp field
2. All other tables use `updated_at` for their timestamp field
3. The trigger function `update_updated_at_column()` sets `NEW.updated_at = NOW()`
4. This works for other tables but fails for khutbahs/minbar_khutbahs

## Solution

Run the SQL script to fix the trigger:

### Steps:

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the file `lib/supabase/fix_khutbahs_trigger.sql`
4. Copy the entire contents
5. Paste into the SQL Editor
6. Click **Run**

This will:
- Create a new trigger function `update_modified_at_column()` that sets `modified_at` instead of `updated_at`
- Drop the old incorrect trigger
- Create a new correct trigger on the `minbar_khutbahs` table

### Verify the Fix

After running the SQL, try saving a khutbah again. The error should be gone and your khutbahs should sync to the cloud successfully.

### Alternative: Rename the Column (Not Recommended)

Alternatively, you could rename the `modified_at` column to `updated_at` in the database to match other tables, but this would require updating all the Dart code that references `modified_at`. The trigger fix above is much simpler.

## Files

- `lib/supabase/fix_khutbahs_trigger.sql` - The SQL script to fix the trigger
- `lib/supabase/supabase_tables.sql` - Original schema with the trigger definition
