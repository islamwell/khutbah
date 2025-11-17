# Delete Account Feature Setup

This document explains how to set up the delete account feature in your Supabase project.

## Overview

The delete account feature allows users to permanently delete their account and all associated data from the app. This includes:

- User profile
- All khutbahs
- All saved content items
- All templates
- All folders
- Search history
- User favorites

## Database Setup

### Step 1: Run the SQL Function

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the file `lib/supabase/delete_user_function.sql`
4. Copy the entire contents of the file
5. Paste it into the SQL Editor
6. Click **Run** to execute the SQL

This will create a PostgreSQL function called `delete_user_account()` that users can call to delete their own account.

### Step 2: Verify the Function

Run this query in the SQL Editor to verify the function was created:

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_name = 'delete_user_account';
```

You should see one row with `routine_name = 'delete_user_account'` and `routine_type = 'FUNCTION'`.

## How It Works

### Database Level

The database is already configured with `ON DELETE CASCADE` constraints. When a user is deleted from `auth.users`, all their related data in the following tables is automatically deleted:

- `users` (profile table)
- `user_khutbahs` (or `minbar_khutbahs`)
- `content_items`
- `templates`
- `folders`
- `user_favorites`
- `search_history`

### Application Level

1. **User Action**: User taps "Account Settings" in the app drawer
2. **Delete Button**: User taps the "Delete Account" button (shown in red)
3. **Confirmation Dialog**: User sees a warning dialog explaining what will be deleted
4. **Deletion Process**:
   - If user confirms, the app calls `SupabaseAuth.deleteAccount()`
   - This calls the `delete_user_account()` RPC function in Supabase
   - The function deletes the user from `auth.users`
   - All related data is cascade-deleted automatically
   - The user is signed out
   - User is redirected to the authentication screen

### Code Files Modified

- `lib/supabase/supabase_config.dart` - Added `deleteAccount()` method to `SupabaseAuth` class
- `lib/widgets/auth_wrapper.dart` - Added delete account button and confirmation dialog
- `lib/supabase/delete_user_function.sql` - Database function for account deletion

## Security

- The `delete_user_account()` function uses `SECURITY DEFINER` to run with elevated privileges
- It verifies the user is authenticated before allowing deletion
- Only the authenticated user can delete their own account (users cannot delete other accounts)
- The function uses `auth.uid()` to ensure users can only delete themselves

## Testing

To test the delete account feature:

1. Create a test account in the app
2. Add some data (khutbahs, templates, etc.)
3. Go to Account Settings
4. Tap "Delete Account"
5. Confirm the deletion
6. Verify:
   - User is signed out
   - User cannot sign in with the deleted credentials
   - All data is removed from the database

**IMPORTANT**: Do not test with a real account as the deletion is permanent and cannot be undone!

## Troubleshooting

### Error: "Function delete_user_account does not exist"

**Solution**: Make sure you ran the SQL function creation script in Step 1.

### Error: "Not authenticated"

**Solution**: User must be signed in to delete their account. Check that `SupabaseAuth.isAuthenticated` returns `true`.

### Error: "Permission denied"

**Solution**: Verify that the function grants execute permission to authenticated users:

```sql
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;
```

## Notes

- Account deletion is **permanent** and **cannot be undone**
- All user data is deleted immediately and cannot be recovered
- Users will need to create a new account if they want to use the app again
- Consider adding a cooldown period or email confirmation for additional security (optional enhancement)
