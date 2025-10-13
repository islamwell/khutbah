@echo off
echo ============================================================
echo DATABASE CRUD TESTS - PulpitFlow
echo ============================================================
echo.
echo Running comprehensive database tests...
echo This will test all CRUD operations on all tables.
echo.
echo Prerequisites:
echo   - Supabase connection configured
echo   - User authenticated
echo   - Database access permissions
echo.
echo ============================================================
echo.

flutter test test/database/database_crud_test.dart --reporter expanded

echo.
echo ============================================================
echo Test execution complete!
echo Check the output above for detailed results.
echo ============================================================
pause
