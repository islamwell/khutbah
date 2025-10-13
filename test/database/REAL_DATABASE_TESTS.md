# Real Database Integration Tests

## ⚠️ WARNING: These tests modify your ACTUAL database!

Unlike the model validation tests, these tests perform **real database operations** on your Supabase instance.

## What These Tests Do

### Khutbah Tests (5 tests)
1. **CREATE** - Inserts a real khutbah into your database
2. **READ** - Fetches it back to verify it exists
3. **UPDATE** - Modifies the khutbah in the database
4. **DELETE** - Removes the khutbah from the database
5. **VERIFY DELETE** - Confirms it's actually gone

### Speech Log Tests (7 tests)
1. **CREATE** - Inserts a real speech log into your database
2. **READ** - Fetches it back to verify it exists
3. **READ BY KHUTBAH** - Queries logs for a specific khutbah
4. **FILTER** - Searches logs with a query
5. **UPDATE** - Modifies the speech log in the database
6. **DELETE** - Removes the speech log from the database
7. **VERIFY DELETE** - Confirms it's actually gone

## Prerequisites

### ✅ Required
1. **Supabase Connection** - Valid URL and anon key configured
2. **User Authentication** - You MUST be logged in to the app
3. **Database Permissions** - User must have write access (RLS policies)

### How to Ensure You're Logged In
Before running these tests:
1. Open the PulpitFlow app
2. Log in with your credentials
3. Keep the app running
4. Then run the tests

## Running the Tests

### Option 1: Use the Batch Script (Windows)
```bash
run_real_database_tests.bat
```

### Option 2: Direct Command
```bash
flutter test test/database/database_integration_test.dart --reporter expanded
```

### Option 3: Run Specific Test Group
```bash
# Test only Khutbah operations
flutter test test/database/database_integration_test.dart --name "Khutbah CRUD"

# Test only Speech Log operations
flutter test test/database/database_integration_test.dart --name "Speech Log CRUD"
```

## Test Output

### Success Example
```
============================================================
REAL DATABASE INTEGRATION TESTS
⚠️  WARNING: These tests will modify your actual database!
============================================================
✓ Supabase initialized successfully
✓ User authenticated
  User ID: abc-123-def-456
  Email: user@example.com
============================================================

📝 Creating test khutbah...
✓ CREATE SUCCESS
  ID: xyz-789-abc-123
  Title: TEST Khutbah 1234567890 - DELETE ME
  Tags: test, automated, delete-me

📖 Reading khutbah from database...
✓ READ SUCCESS
  Found khutbah with ID: xyz-789-abc-123
  Title: TEST Khutbah 1234567890 - DELETE ME
  Content length: 85 characters

✏️  Updating khutbah in database...
✓ UPDATE SUCCESS
  New title: TEST UPDATED Khutbah 1234567890 - DELETE ME
  New estimated minutes: 25
  New tags: test, updated, delete-me

🗑️  Deleting khutbah from database...
✓ DELETE SUCCESS
  Deleted khutbah ID: xyz-789-abc-123

🔍 Verifying deletion...
✓ VERIFICATION SUCCESS
  Confirmed: Khutbah no longer exists in database

============================================================
REAL DATABASE INTEGRATION TEST REPORT
============================================================

✅ All database operations completed successfully!

📊 Operations Tested:
  ✓ Khutbah CREATE - Real database insert
  ✓ Khutbah READ - Real database query
  ✓ Khutbah UPDATE - Real database modification
  ✓ Khutbah DELETE - Real database removal
  ✓ Delete verification - Confirmed removal
  ✓ Speech Log CREATE - Real database insert
  ✓ Speech Log READ - Real database query
  ✓ Speech Log READ BY KHUTBAH - Filtered query
  ✓ Speech Log FILTER - Search query
  ✓ Speech Log UPDATE - Real database modification
  ✓ Speech Log DELETE - Real database removal
  ✓ Delete verification - Confirmed removal

🎯 All test data has been cleaned up from the database
============================================================
```

### If Not Authenticated
```
============================================================
REAL DATABASE INTEGRATION TESTS
⚠️  WARNING: These tests will modify your actual database!
============================================================
✓ Supabase initialized successfully
✗ User not authenticated
⚠️  Tests will be skipped - please log in first
============================================================

⚠️  SKIPPED: Supabase not initialized or user not authenticated
⚠️  SKIPPED: Prerequisites not met
...

============================================================
REAL DATABASE INTEGRATION TEST REPORT
============================================================

❌ Tests could not run: User not authenticated
   Please log in to the app and try again
============================================================
```

## Test Data Cleanup

### Automatic Cleanup
- All test data is automatically deleted after tests complete
- Uses `setUpAll` and `tearDownAll` for proper cleanup
- Even if tests fail, cleanup attempts to run

### Manual Cleanup (if needed)
If tests fail and leave test data behind, you can identify it by:
- Titles containing "TEST" and "DELETE ME"
- Timestamps in the title (e.g., `1234567890`)
- Tags: `test`, `automated`, `delete-me`

Query to find test data in Supabase:
```sql
-- Find test khutbahs
SELECT * FROM khutbahs 
WHERE title LIKE '%TEST%DELETE ME%';

-- Find test speech logs
SELECT * FROM speech_logs 
WHERE location LIKE '%TEST%DELETE ME%';

-- Delete test khutbahs (if needed)
DELETE FROM khutbahs 
WHERE title LIKE '%TEST%DELETE ME%';

-- Delete test speech logs (if needed)
DELETE FROM speech_logs 
WHERE location LIKE '%TEST%DELETE ME%';
```

## What Gets Tested

### Database Operations
- ✅ INSERT with UUID generation
- ✅ SELECT with filters
- ✅ UPDATE with modified_at timestamp
- ✅ DELETE with cascade
- ✅ Foreign key relationships
- ✅ Row Level Security (RLS) policies

### Data Integrity
- ✅ UUIDs are properly generated
- ✅ Timestamps are set correctly
- ✅ Foreign keys are enforced
- ✅ Required fields are validated
- ✅ Optional fields can be null
- ✅ Cascade delete works (deleting khutbah deletes logs)

### Query Operations
- ✅ Fetch all records
- ✅ Filter by foreign key
- ✅ Search with text query
- ✅ Order by date
- ✅ User-scoped queries (RLS)

## Troubleshooting

### "User not authenticated"
**Solution**: Log in to the PulpitFlow app before running tests
1. Open the app
2. Sign in with your credentials
3. Keep the app running
4. Run the tests

### "Supabase initialization failed"
**Solution**: Check your Supabase configuration
1. Verify `supabase_url` in `lib/supabase/supabase_config.dart`
2. Verify `anonKey` is correct
3. Check internet connection
4. Verify Supabase project is active

### "Foreign key constraint violation"
**Solution**: This means the test khutbah wasn't created properly
- Check that user has permission to create khutbahs
- Verify RLS policies allow INSERT
- Check database logs in Supabase dashboard

### "Permission denied"
**Solution**: Check Row Level Security policies
1. Go to Supabase dashboard
2. Check RLS policies for `khutbahs` and `speech_logs` tables
3. Ensure policies allow the authenticated user to INSERT/UPDATE/DELETE

### Tests hang or timeout
**Solution**: 
- Check network connection
- Verify Supabase is responding
- Check for database locks
- Try running tests one at a time

## Safety Features

### Test Data Identification
All test records are clearly marked:
- Titles: `TEST ... DELETE ME`
- Tags: `test`, `automated`, `delete-me`
- Timestamps in titles for uniqueness

### Automatic Cleanup
- Tests clean up after themselves
- Even failed tests attempt cleanup
- Teardown runs regardless of test outcome

### Skipping on Failure
- If Supabase isn't initialized, tests skip
- If user isn't authenticated, tests skip
- No partial operations that leave orphaned data

## Continuous Integration

These tests can be integrated into CI/CD, but require:
1. Test user credentials
2. Supabase connection
3. Proper environment variables

Example GitHub Actions:
```yaml
- name: Run Real Database Tests
  run: flutter test test/database/database_integration_test.dart
  env:
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
    TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
    TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}
```

## Comparison with Model Tests

| Feature | Model Tests | Integration Tests |
|---------|-------------|-------------------|
| Database Connection | ❌ No | ✅ Yes |
| Real Data | ❌ No | ✅ Yes |
| Authentication Required | ❌ No | ✅ Yes |
| Modifies Database | ❌ No | ✅ Yes |
| Tests CRUD | ❌ No | ✅ Yes |
| Tests Serialization | ✅ Yes | ✅ Yes |
| Fast Execution | ✅ Yes | ❌ Slower |
| Safe to Run Anytime | ✅ Yes | ⚠️ Requires auth |

## Best Practices

1. **Run model tests first** - They're faster and don't require auth
2. **Ensure you're logged in** - Check before running
3. **Check test output** - Verify cleanup completed
4. **Run in test environment** - Don't run against production if possible
5. **Monitor database** - Check Supabase dashboard during tests

## Support

If tests consistently fail:
1. Check console output for specific errors
2. Verify authentication status
3. Check Supabase dashboard for errors
4. Verify RLS policies
5. Check database logs
6. Ensure network connectivity

## Summary

These tests provide **real validation** that your database operations work correctly:
- ✅ Actual CREATE operations
- ✅ Actual READ operations
- ✅ Actual UPDATE operations
- ✅ Actual DELETE operations
- ✅ Verification that deletes work

**Answer to "Did it delete correctly?"** - YES! These tests will confirm it! 🎯
