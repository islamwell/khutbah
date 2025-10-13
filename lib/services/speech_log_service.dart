import 'package:pulpitflow/models/speech_log.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';
import 'dart:io';
import 'dart:async';

/// Service class for managing speech log operations with Supabase
class SpeechLogService {
  /// Maximum number of retry attempts for network operations
  static const int _maxRetries = 3;
  
  /// Delay between retry attempts in milliseconds
  static const int _retryDelayMs = 1000;

  /// Retry a network operation with exponential backoff
  static Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        // Check if it's a network error that should be retried
        final shouldRetry = _isRetryableError(e);
        
        if (!shouldRetry || attempts >= maxRetries) {
          rethrow;
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(
          Duration(milliseconds: _retryDelayMs * attempts),
        );
      }
    }
    
    throw Exception('Operation failed after $maxRetries attempts');
  }
  
  /// Check if an error is retryable (network-related)
  static bool _isRetryableError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket');
  }

  /// Get all speech logs for the current user
  static Future<List<SpeechLog>> getUserSpeechLogs() async {
    return _retryOperation(() async {
      try {
        final response = await SupabaseService.select(
          'minbar_speech_logs',
          orderBy: 'delivery_date',
          ascending: false,
        );

        return response.map((json) => SpeechLog.fromJson(json)).toList();
      } catch (e) {
        if (_isRetryableError(e)) {
          throw e; // Let retry mechanism handle it
        }
        throw Exception('Failed to load speech logs: ${_getUserFriendlyError(e)}');
      }
    });
  }

  /// Get speech logs for a specific khutbah
  static Future<List<SpeechLog>> getSpeechLogsByKhutbah(String khutbahId) async {
    return _retryOperation(() async {
      try {
        final response = await SupabaseService.select(
          'minbar_speech_logs',
          filters: {'khutbah_id': khutbahId},
          orderBy: 'delivery_date',
          ascending: false,
        );

        return response.map((json) => SpeechLog.fromJson(json)).toList();
      } catch (e) {
        if (_isRetryableError(e)) {
          throw e; // Let retry mechanism handle it
        }
        throw Exception('Failed to load speech logs: ${_getUserFriendlyError(e)}');
      }
    });
  }

  /// Create a new speech log
  static Future<SpeechLog> createSpeechLog(SpeechLog log) async {
    return _retryOperation(() async {
      try {
        print('\n=== CREATE SPEECH LOG DEBUG ===');
        
        // Step 1: Check authentication
        final userId = SupabaseAuth.currentUser?.id;
        print('Step 1 - User ID: $userId');
        if (userId == null) {
          throw Exception('User not authenticated. Please log in and try again.');
        }

        // Step 2: Validate khutbah_id
        print('Step 2 - Khutbah ID: "${log.khutbahId}"');
        print('Step 2 - Khutbah ID length: ${log.khutbahId.length}');
        print('Step 2 - Khutbah ID isEmpty: ${log.khutbahId.isEmpty}');
        
        if (log.khutbahId.isEmpty) {
          throw Exception('Khutbah ID is required');
        }

        // Step 3: Validate UUID format (basic check)
        final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        final isValidUuid = uuidPattern.hasMatch(log.khutbahId);
        print('Step 3 - Is valid UUID format: $isValidUuid');
        
        if (!isValidUuid) {
          throw Exception('Khutbah ID is not a valid UUID format: "${log.khutbahId}"');
        }

        // Step 4: Prepare insert data
        final now = DateTime.now();
        final insertData = {
          'user_id': userId,
          'khutbah_id': log.khutbahId,
          'khutbah_title': log.khutbahTitle,
          'delivery_date': log.deliveryDate.toIso8601String(),
          'location': log.location,
          'event_type': log.eventType,
          'audience_size': log.audienceSize,
          'audience_demographics': log.audienceDemographics,
          'positive_feedback': log.positiveFeedback,
          'negative_feedback': log.negativeFeedback,
          'general_notes': log.generalNotes,
          'created_at': now.toIso8601String(),
          'modified_at': now.toIso8601String(),
        };

        print('Step 4 - Insert data prepared:');
        print('  - user_id: $userId');
        print('  - khutbah_id: ${log.khutbahId}');
        print('  - khutbah_title: ${log.khutbahTitle}');
        print('  - delivery_date: ${log.deliveryDate.toIso8601String()}');
        print('  - location: ${log.location}');
        print('  - event_type: ${log.eventType}');

        // Step 5: Insert into database
        print('Step 5 - Calling Supabase insert...');
        final response = await SupabaseService.insert('minbar_speech_logs', insertData);

        print('Step 6 - SUCCESS! Speech log created with ID: ${response.first['id']}');
        print('=== END DEBUG ===\n');
        
        return SpeechLog.fromJson(response.first);
      } catch (e) {
        print('ERROR at some step: $e');
        print('ERROR type: ${e.runtimeType}');
        print('ERROR toString: ${e.toString()}');
        print('=== END DEBUG (ERROR) ===\n');
        
        if (_isRetryableError(e)) {
          throw e; // Let retry mechanism handle it
        }
        throw Exception('Failed to create speech log: ${_getUserFriendlyError(e)}');
      }
    });
  }

  /// Update an existing speech log
  static Future<SpeechLog> updateSpeechLog(SpeechLog log) async {
    return _retryOperation(() async {
      try {
        final response = await SupabaseService.update(
          'minbar_speech_logs',
          {
            'khutbah_id': log.khutbahId,
            'khutbah_title': log.khutbahTitle,
            'delivery_date': log.deliveryDate.toIso8601String(),
            'location': log.location,
            'event_type': log.eventType,
            'audience_size': log.audienceSize,
            'audience_demographics': log.audienceDemographics,
            'positive_feedback': log.positiveFeedback,
            'negative_feedback': log.negativeFeedback,
            'general_notes': log.generalNotes,
            'modified_at': DateTime.now().toIso8601String(),
          },
          filters: {'id': log.id},
        );

        return SpeechLog.fromJson(response.first);
      } catch (e) {
        if (_isRetryableError(e)) {
          throw e; // Let retry mechanism handle it
        }
        throw Exception('Failed to update speech log: ${_getUserFriendlyError(e)}');
      }
    });
  }

  /// Delete a speech log
  static Future<void> deleteSpeechLog(String logId) async {
    return _retryOperation(() async {
      try {
        await SupabaseService.delete('minbar_speech_logs', filters: {'id': logId});
      } catch (e) {
        if (_isRetryableError(e)) {
          throw e; // Let retry mechanism handle it
        }
        throw Exception('Failed to delete speech log: ${_getUserFriendlyError(e)}');
      }
    });
  }

  /// Get the count of deliveries for a specific khutbah
  static Future<int> getDeliveryCount(String khutbahId) async {
    return _retryOperation(() async {
      try {
        final response = await SupabaseService.select(
          'minbar_speech_logs',
          filters: {'khutbah_id': khutbahId},
          select: 'id',
        );

        return response.length;
      } catch (e) {
        if (_isRetryableError(e)) {
          throw e; // Let retry mechanism handle it
        }
        throw Exception('Failed to get delivery count: ${_getUserFriendlyError(e)}');
      }
    });
  }

  /// Get filtered speech logs with optional search query
  static Future<List<SpeechLog>> getFilteredSpeechLogs({
    String? khutbahId,
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    String? searchQuery,
  }) async {
    return _retryOperation(() async {
      try {
        final userId = SupabaseAuth.currentUser?.id;
        if (userId == null) {
          throw Exception('User not authenticated. Please log in and try again.');
        }

        // Start with base query
        dynamic query = SupabaseConfig.client
            .from('minbar_speech_logs')
            .select('*')
            .eq('user_id', userId);

        // Apply filters
        if (khutbahId != null && khutbahId.isNotEmpty && khutbahId != 'null') {
          query = query.eq('khutbah_id', khutbahId);
        }

        if (startDate != null) {
          query = query.gte('delivery_date', startDate.toIso8601String());
        }

        if (endDate != null) {
          // Add one day to include the end date
          final endDateInclusive = endDate.add(const Duration(days: 1));
          query = query.lt('delivery_date', endDateInclusive.toIso8601String());
        }

        if (eventType != null && eventType.isNotEmpty) {
          query = query.eq('event_type', eventType);
        }

        // Apply search query (search in location and event_type)
        if (searchQuery != null && searchQuery.isNotEmpty) {
          query = query.or('location.ilike.%$searchQuery%,event_type.ilike.%$searchQuery%');
        }

        // Order by delivery date descending
        query = query.order('delivery_date', ascending: false);

        final response = await query;

        return response.map<SpeechLog>((json) => SpeechLog.fromJson(json)).toList();
      } catch (e) {
        if (_isRetryableError(e)) {
          throw e; // Let retry mechanism handle it
        }
        throw Exception('Failed to filter speech logs: ${_getUserFriendlyError(e)}');
      }
    });
  }
  
  /// Convert technical errors to user-friendly messages
  static String _getUserFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('authentication') || errorString.contains('unauthorized')) {
      return 'Authentication error. Please log in again.';
    }
    
    if (errorString.contains('uuid') || errorString.contains('invalid input syntax')) {
      return 'Invalid data format. Please check your input and try again.';
    }
    
    if (errorString.contains('foreign key') || errorString.contains('reference')) {
      return 'The associated speech may have been deleted.';
    }
    
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'You don\'t have permission to perform this action.';
    }
    
    // Return original error if no specific match
    return error.toString();
  }
}
