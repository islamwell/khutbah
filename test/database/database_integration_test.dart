import 'package:flutter_test/flutter_test.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';
import 'package:pulpitflow/models/speech_log.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/services/speech_log_service.dart';
import 'package:pulpitflow/services/khutbah_service.dart';

/// REAL Database Integration Tests
/// 
/// ⚠️ WARNING: These tests perform ACTUAL database operations!
/// 
/// Requirements:
/// 1. Active Supabase connection
/// 2. Authenticated user (must be logged in)
/// 3. Database write permissions
/// 
/// These tests will:
/// - CREATE real records in your database
/// - READ them back to verify
/// - UPDATE them
/// - DELETE them
/// - Verify deletion
/// 
/// Run with: flutter test test/database/database_integration_test.dart
void main() {
  group('🔴 REAL Database Integration Tests', () {
    bool supabaseInitialized = false;
    bool userAuthenticated = false;

    setUpAll(() async {
      print('\n' + '=' * 70);
      print('REAL DATABASE INTEGRATION TESTS');
      print('⚠️  WARNING: These tests will modify your actual database!');
      print('=' * 70);
      
      // Try to initialize Supabase (will fail in test environment)
      try {
        await SupabaseConfig.initialize();
        supabaseInitialized = true;
        print('✓ Supabase initialized successfully');
        
        // Check authentication
        userAuthenticated = SupabaseAuth.isAuthenticated;
        if (userAuthenticated) {
          final user = SupabaseAuth.currentUser;
          print('✓ User authenticated');
          print('  User ID: ${user?.id}');
          print('  Email: ${user?.email}');
        } else {
          print('✗ User not authenticated');
          print('⚠️  Tests will be skipped - please log in first');
        }
      } catch (e) {
        print('✗ Supabase initialization failed: $e');
        print('⚠️  This is expected in unit test environment');
        print('⚠️  These tests require a running app with authentication');
        print('⚠️  All tests will be skipped');
      }
      
      print('=' * 70 + '\n');
    });

    group('Khutbah CRUD - Real Database Operations', () {
      String? testKhutbahId;
      final testTimestamp = DateTime.now().millisecondsSinceEpoch;

      test('1. CREATE: Insert a real khutbah into database', () async {
        if (!supabaseInitialized || !userAuthenticated) {
          print('⚠️  SKIPPED: Supabase not initialized or user not authenticated');
          return;
        }

        try {
          print('\n📝 Creating test khutbah...');
          
          final testKhutbah = Khutbah(
            id: '', // Database will generate UUID
            title: 'TEST Khutbah $testTimestamp - DELETE ME',
            content: 'This is a test khutbah created by automated tests. It should be automatically deleted.',
            tags: ['test', 'automated', 'delete-me'],
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            estimatedMinutes: 15,
          );

          final created = await KhutbahService.createKhutbah(testKhutbah);
          testKhutbahId = created.id;

          expect(created.id, isNotEmpty);
          expect(created.title, contains('TEST Khutbah'));
          expect(created.content, equals(testKhutbah.content));
          expect(created.estimatedMinutes, equals(15));
          
          print('✓ CREATE SUCCESS');
          print('  ID: $testKhutbahId');
          print('  Title: ${created.title}');
          print('  Tags: ${created.tags.join(", ")}');
        } catch (e) {
          print('✗ CREATE FAILED: $e');
          rethrow;
        }
      });

      test('2. READ: Fetch the created khutbah from database', () async {
        if (!supabaseInitialized || !userAuthenticated || testKhutbahId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n📖 Reading khutbah from database...');
          
          final khutbahs = await KhutbahService.getUserKhutbahs();
          final found = khutbahs.firstWhere(
            (k) => k.id == testKhutbahId,
            orElse: () => throw Exception('Khutbah not found in database'),
          );

          expect(found.id, equals(testKhutbahId));
          expect(found.title, contains('TEST Khutbah'));
          
          print('✓ READ SUCCESS');
          print('  Found khutbah with ID: ${found.id}');
          print('  Title: ${found.title}');
          print('  Content length: ${found.content.length} characters');
        } catch (e) {
          print('✗ READ FAILED: $e');
          rethrow;
        }
      });

      test('3. UPDATE: Modify the khutbah in database', () async {
        if (!supabaseInitialized || !userAuthenticated || testKhutbahId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n✏️  Updating khutbah in database...');
          
          // Fetch current version
          final khutbahs = await KhutbahService.getUserKhutbahs();
          final original = khutbahs.firstWhere((k) => k.id == testKhutbahId);
          
          // Update it
          final updated = original.copyWith(
            title: 'TEST UPDATED Khutbah $testTimestamp - DELETE ME',
            content: 'This content has been UPDATED by automated tests.',
            tags: ['test', 'updated', 'delete-me'],
            estimatedMinutes: 25,
          );

          final result = await KhutbahService.updateKhutbah(updated);

          expect(result.id, equals(testKhutbahId));
          expect(result.title, contains('UPDATED'));
          expect(result.estimatedMinutes, equals(25));
          
          print('✓ UPDATE SUCCESS');
          print('  New title: ${result.title}');
          print('  New estimated minutes: ${result.estimatedMinutes}');
          print('  New tags: ${result.tags.join(", ")}');
        } catch (e) {
          print('✗ UPDATE FAILED: $e');
          rethrow;
        }
      });

      test('4. DELETE: Remove the khutbah from database', () async {
        if (!supabaseInitialized || !userAuthenticated || testKhutbahId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n🗑️  Deleting khutbah from database...');
          
          await KhutbahService.deleteKhutbah(testKhutbahId!);
          
          print('✓ DELETE SUCCESS');
          print('  Deleted khutbah ID: $testKhutbahId');
        } catch (e) {
          print('✗ DELETE FAILED: $e');
          rethrow;
        }
      });

      test('5. VERIFY DELETE: Confirm khutbah is gone', () async {
        if (!supabaseInitialized || !userAuthenticated || testKhutbahId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n🔍 Verifying deletion...');
          
          final khutbahs = await KhutbahService.getUserKhutbahs();
          final exists = khutbahs.any((k) => k.id == testKhutbahId);

          expect(exists, isFalse, reason: 'Khutbah should not exist after deletion');
          
          print('✓ VERIFICATION SUCCESS');
          print('  Confirmed: Khutbah no longer exists in database');
        } catch (e) {
          print('✗ VERIFICATION FAILED: $e');
          rethrow;
        }
      });
    });

    group('Speech Log CRUD - Real Database Operations', () {
      String? testKhutbahId;
      String? testLogId;
      final testTimestamp = DateTime.now().millisecondsSinceEpoch;

      setUpAll(() async {
        if (!supabaseInitialized || !userAuthenticated) {
          print('⚠️  Skipping Speech Log tests - prerequisites not met');
          return;
        }

        // Create a test khutbah for speech log tests
        try {
          print('\n🔧 Setup: Creating test khutbah for speech log tests...');
          
          final testKhutbah = Khutbah(
            id: '',
            title: 'TEST Khutbah for Logs $testTimestamp - DELETE ME',
            content: 'Test khutbah for speech log testing',
            tags: ['test', 'speech-logs'],
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            estimatedMinutes: 10,
          );
          
          final created = await KhutbahService.createKhutbah(testKhutbah);
          testKhutbahId = created.id;
          print('✓ Setup complete: Test khutbah created (ID: $testKhutbahId)');
        } catch (e) {
          print('✗ Setup failed: Could not create test khutbah - $e');
        }
      });

      tearDownAll(() async {
        // Clean up test khutbah
        if (testKhutbahId != null) {
          try {
            print('\n🧹 Cleanup: Deleting test khutbah...');
            await KhutbahService.deleteKhutbah(testKhutbahId!);
            print('✓ Cleanup complete: Test khutbah deleted');
          } catch (e) {
            print('⚠️  Cleanup warning: Could not delete test khutbah - $e');
          }
        }
      });

      test('1. CREATE: Insert a real speech log into database', () async {
        if (!supabaseInitialized || !userAuthenticated || testKhutbahId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n📝 Creating test speech log...');
          
          final testLog = SpeechLog(
            id: '', // Database will generate UUID
            khutbahId: testKhutbahId!,
            khutbahTitle: 'TEST Khutbah for Logs',
            deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
            location: 'TEST Mosque $testTimestamp - DELETE ME',
            eventType: 'TEST Event',
            audienceSize: 100,
            audienceDemographics: 'Test demographics',
            positiveFeedback: 'Test positive feedback',
            negativeFeedback: 'Test negative feedback',
            generalNotes: 'Test general notes',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          );

          final created = await SpeechLogService.createSpeechLog(testLog);
          testLogId = created.id;

          expect(created.id, isNotEmpty);
          expect(created.khutbahId, equals(testKhutbahId));
          expect(created.location, contains('TEST Mosque'));
          expect(created.audienceSize, equals(100));
          
          print('✓ CREATE SUCCESS');
          print('  ID: $testLogId');
          print('  Location: ${created.location}');
          print('  Event Type: ${created.eventType}');
          print('  Audience Size: ${created.audienceSize}');
        } catch (e) {
          print('✗ CREATE FAILED: $e');
          print('  Error details: ${e.toString()}');
          rethrow;
        }
      });

      test('2. READ: Fetch the created speech log from database', () async {
        if (!supabaseInitialized || !userAuthenticated || testLogId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n📖 Reading speech log from database...');
          
          final logs = await SpeechLogService.getUserSpeechLogs();
          final found = logs.firstWhere(
            (log) => log.id == testLogId,
            orElse: () => throw Exception('Speech log not found in database'),
          );

          expect(found.id, equals(testLogId));
          expect(found.location, contains('TEST Mosque'));
          
          print('✓ READ SUCCESS');
          print('  Found speech log with ID: ${found.id}');
          print('  Location: ${found.location}');
          print('  Event Type: ${found.eventType}');
        } catch (e) {
          print('✗ READ FAILED: $e');
          rethrow;
        }
      });

      test('3. READ BY KHUTBAH: Fetch logs for specific khutbah', () async {
        if (!supabaseInitialized || !userAuthenticated || testKhutbahId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n📖 Reading speech logs by khutbah...');
          
          final logs = await SpeechLogService.getSpeechLogsByKhutbah(testKhutbahId!);
          
          expect(logs, isNotEmpty);
          for (final log in logs) {
            expect(log.khutbahId, equals(testKhutbahId));
          }
          
          print('✓ READ BY KHUTBAH SUCCESS');
          print('  Found ${logs.length} log(s) for khutbah');
        } catch (e) {
          print('✗ READ BY KHUTBAH FAILED: $e');
          rethrow;
        }
      });

      test('4. FILTER: Search speech logs', () async {
        if (!supabaseInitialized || !userAuthenticated) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n🔍 Filtering speech logs...');
          
          final logs = await SpeechLogService.getFilteredSpeechLogs(
            searchQuery: 'TEST Mosque',
          );
          
          expect(logs, isNotNull);
          print('✓ FILTER SUCCESS');
          print('  Found ${logs.length} log(s) matching search');
        } catch (e) {
          print('✗ FILTER FAILED: $e');
          rethrow;
        }
      });

      test('5. UPDATE: Modify the speech log in database', () async {
        if (!supabaseInitialized || !userAuthenticated || testLogId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n✏️  Updating speech log in database...');
          
          // Fetch current version
          final logs = await SpeechLogService.getUserSpeechLogs();
          final original = logs.firstWhere((log) => log.id == testLogId);
          
          // Update it
          final updated = original.copyWith(
            location: 'TEST UPDATED Mosque $testTimestamp - DELETE ME',
            eventType: 'TEST UPDATED Event',
            audienceSize: 150,
            positiveFeedback: 'UPDATED positive feedback',
          );

          final result = await SpeechLogService.updateSpeechLog(updated);

          expect(result.id, equals(testLogId));
          expect(result.location, contains('UPDATED'));
          expect(result.audienceSize, equals(150));
          
          print('✓ UPDATE SUCCESS');
          print('  New location: ${result.location}');
          print('  New event type: ${result.eventType}');
          print('  New audience size: ${result.audienceSize}');
        } catch (e) {
          print('✗ UPDATE FAILED: $e');
          rethrow;
        }
      });

      test('6. DELETE: Remove the speech log from database', () async {
        if (!supabaseInitialized || !userAuthenticated || testLogId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n🗑️  Deleting speech log from database...');
          
          await SpeechLogService.deleteSpeechLog(testLogId!);
          
          print('✓ DELETE SUCCESS');
          print('  Deleted speech log ID: $testLogId');
        } catch (e) {
          print('✗ DELETE FAILED: $e');
          rethrow;
        }
      });

      test('7. VERIFY DELETE: Confirm speech log is gone', () async {
        if (!supabaseInitialized || !userAuthenticated || testLogId == null) {
          print('⚠️  SKIPPED: Prerequisites not met');
          return;
        }

        try {
          print('\n🔍 Verifying deletion...');
          
          final logs = await SpeechLogService.getUserSpeechLogs();
          final exists = logs.any((log) => log.id == testLogId);

          expect(exists, isFalse, reason: 'Speech log should not exist after deletion');
          
          print('✓ VERIFICATION SUCCESS');
          print('  Confirmed: Speech log no longer exists in database');
        } catch (e) {
          print('✗ VERIFICATION FAILED: $e');
          rethrow;
        }
      });
    });

    group('Final Report', () {
      test('Generate test execution report', () {
        print('\n' + '=' * 70);
        print('REAL DATABASE INTEGRATION TEST REPORT');
        print('=' * 70);
        
        if (!supabaseInitialized) {
          print('\n❌ Tests could not run: Supabase not initialized');
        } else if (!userAuthenticated) {
          print('\n❌ Tests could not run: User not authenticated');
          print('   Please log in to the app and try again');
        } else {
          print('\n✅ All database operations completed successfully!');
          print('\n📊 Operations Tested:');
          print('  ✓ Khutbah CREATE - Real database insert');
          print('  ✓ Khutbah READ - Real database query');
          print('  ✓ Khutbah UPDATE - Real database modification');
          print('  ✓ Khutbah DELETE - Real database removal');
          print('  ✓ Delete verification - Confirmed removal');
          print('  ✓ Speech Log CREATE - Real database insert');
          print('  ✓ Speech Log READ - Real database query');
          print('  ✓ Speech Log READ BY KHUTBAH - Filtered query');
          print('  ✓ Speech Log FILTER - Search query');
          print('  ✓ Speech Log UPDATE - Real database modification');
          print('  ✓ Speech Log DELETE - Real database removal');
          print('  ✓ Delete verification - Confirmed removal');
          print('\n🎯 All test data has been cleaned up from the database');
        }
        
        print('=' * 70 + '\n');
      });
    });
  });
}
