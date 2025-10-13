@echo off
echo ============================================================
echo REAL DATABASE INTEGRATION TESTS - PulpitFlow
echo ============================================================
echo.
echo ⚠️  WARNING: These tests will modify your ACTUAL database!
echo.
echo These tests will:
echo   - CREATE real records in your Supabase database
echo   - READ them back to verify
echo   - UPDATE them
echo   - DELETE them
echo   - Verify deletion
echo.
echo Prerequisites:
echo   ✓ Supabase connection configured
echo   ✓ User must be LOGGED IN to the app
echo   ✓ Database write permissions
echo.
echo All test data will be automatically cleaned up.
echo Test records are marked with "TEST" and "DELETE ME" in titles.
echo.
echo ============================================================
echo.
pause
echo.
echo Running real database integration tests...
echo.

flutter test test/database/database_integration_test.dart --reporter expanded

echo.
echo ============================================================
echo Test execution complete!
echo Check the output above for detailed results.
echo ============================================================
pause
