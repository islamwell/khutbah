# Database CRUD Tests

Comprehensive automated tests for all database operations across all tables.

## Overview

These tests verify complete CRUD (Create, Read, Update, Delete) operations for:
- **Khutbahs table** (8 fields)
- **Speech Logs table** (14 fields)
- **Authentication** (user verification)

## Test Coverage

### ✅ Operations Tested
- **CREATE**: Insert new records
- **READ**: Fetch single and multiple records
- **UPDATE**: Modify existing records
- **DELETE**: Remove records
- **SEARCH**: Query with search terms
- **FILTER**: Filter by date, type, and relationships

### ✅ Tables & Fields Tested

#### Khutbahs Table
- `id` (UUID, auto-generated)
- `user_id` (UUID, foreign key)
- `title` (TEXT)
- `content` (TEXT)
- `tags` (TEXT[])
- `estimated_minutes` (INTEGER)
- `created_at` (TIMESTAMP)
- `modified_at` (TIMESTAMP)

#### Speech Logs Table
- `id` (UUID, auto-generated)
- `user_id` (UUID, foreign key)
- `khutbah_id` (UUID, foreign key)
- `khutbah_title` (TEXT)
- `delivery_date` (TIMESTAMP)
- `location` (TEXT)
- `event_type` (TEXT)
- `audience_size` (INTEGER, optional)
- `audience_demographics` (TEXT, optional)
- `positive_feedback` (TEXT)
- `negative_feedback` (TEXT)
- `general_notes` (TEXT)
- `created_at` (TIMESTAMP)
- `modified_at` (TIMESTAMP)

### ✅ Constraints Tested
- Foreign key relationships
- Cascade delete operations
- Row Level Security (RLS) policies
- UUID validation
- Required vs optional fields

## Prerequisites

1. **Supabase Connection**: Valid Supabase URL and anon key configured
2. **Authentication**: User must be logged in
3. **Database Access**: User must have proper RLS permissions

## Running the Tests

### Run All Database Tests
```bash
flutter test test/database/database_crud_test.dart
```

### Run with Verbose Output
```bash
flutter test test/database/database_crud_test.dart --reporter expanded
```

### Run Specific Test Group
```bash
# Test only khutbahs
flutter test test/database/database_crud_test.dart --name "Khutbahs Table"

# Test only speech logs
flutter test test/database/database_crud_test.dart --name "Speech Logs Table"

# Test only authentication
flutter test test/database/database_crud_test.dart --name "Authentication"
```

## Test Output

The tests provide detailed console output including:

### Success Indicators
```
✓ CREATE khutbah: Success (ID: abc-123)
✓ READ khutbahs: Success (Found 5 khutbahs)
✓ UPDATE khutbah: Success
✓ DELETE khutbah: Success
```

### Failure Indicators
```
✗ CREATE khutbah: Failed - Error message
✗ READ khutbahs: Failed - Error message
```

### Warning Indicators
```
⚠ SKIP: No test khutbah ID available
⚠ Warning: Tests require authentication
```

## Test Report

After running all tests, a comprehensive report is generated:

```
============================================================
DATABASE CRUD TEST REPORT
============================================================

📊 Test Coverage:
  ✓ Authentication verification
  ✓ Khutbahs table: CREATE, READ, UPDATE, DELETE
  ✓ Speech Logs table: CREATE, READ, UPDATE, DELETE
  ✓ Filtered queries and search
  ✓ Field validation
  ✓ Foreign key constraints
  ✓ Row level security policies

📝 Tables Tested:
  1. khutbahs (8 fields)
  2. speech_logs (14 fields)
  3. auth.users (via authentication)

🎯 Operations Tested:
  - CREATE (INSERT)
  - READ (SELECT, SELECT with filters)
  - UPDATE (MODIFY)
  - DELETE (REMOVE)
  - SEARCH (with query)
  - FILTER (by date, type, khutbah)
============================================================
```

## Troubleshooting

### Authentication Errors
If you see authentication errors:
1. Ensure you're logged in to the app
2. Check that Supabase is properly initialized
3. Verify your Supabase credentials

### Foreign Key Errors
If you see foreign key constraint errors:
1. Ensure the referenced khutbah exists
2. Check that the khutbah_id is a valid UUID
3. Verify the khutbah belongs to the current user

### Permission Errors
If you see permission denied errors:
1. Check Row Level Security policies in Supabase
2. Verify the user has proper permissions
3. Ensure the user_id matches the authenticated user

### UUID Format Errors
If you see "invalid input syntax for type uuid":
1. Check that IDs are valid UUIDs (not timestamps or empty strings)
2. Verify the khutbah exists in the database
3. Ensure foreign key references are correct

## Test Data Cleanup

The tests automatically clean up test data:
- Test khutbahs are deleted after tests complete
- Test speech logs are deleted after tests complete
- Uses `setUpAll` and `tearDownAll` for proper cleanup

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Database Tests
  run: flutter test test/database/database_crud_test.dart
  env:
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

## Notes

- Tests create temporary data with timestamps to avoid conflicts
- All test data is prefixed with "Test" for easy identification
- Tests verify both success and failure scenarios
- Foreign key relationships are tested through cascade deletes
- RLS policies are implicitly tested through user-scoped operations

## Support

If tests fail consistently:
1. Check the console output for specific error messages
2. Verify database schema matches expectations
3. Ensure Supabase connection is stable
4. Check that RLS policies are correctly configured
