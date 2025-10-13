import 'package:flutter/foundation.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';
import 'package:pulpitflow/services/storage_service.dart';
import 'package:pulpitflow/services/content_data_service.dart';

/// Service to handle user-specific data synchronization between local and cloud storage
class UserDataService {
  static const String _khutbahsTable = 'minbar_khutbahs';
  
  /// Sync local khutbahs to cloud storage for authenticated user
  static Future<void> syncKhutbahsToCloud() async {
    if (!SupabaseAuth.isAuthenticated) return;
    
    try {
      final localKhutbahs = await StorageService.getAllKhutbahs();
      final userId = SupabaseAuth.currentUser!.id;
      
      for (final khutbah in localKhutbahs) {
        await _saveKhutbahToCloud(khutbah, userId);
      }
    } catch (e) {
      debugPrint('Error syncing khutbahs to cloud: $e');
    }
  }
  
  /// Load user's khutbahs from cloud storage
  static Future<List<Khutbah>> loadKhutbahsFromCloud() async {
    if (!SupabaseAuth.isAuthenticated) return [];
    
    try {
      final userId = SupabaseAuth.currentUser!.id;
      final response = await SupabaseService.select(
        _khutbahsTable,
        filters: {'user_id': userId},
        orderBy: 'modified_at',
        ascending: false,
      );
      
      return response.map((data) => _khutbahFromCloudData(data)).toList();
    } catch (e) {
      debugPrint('Error loading khutbahs from cloud: $e');
      return [];
    }
  }
  
  /// Save a khutbah to cloud storage
  static Future<void> saveKhutbahToCloud(Khutbah khutbah) async {
    if (!SupabaseAuth.isAuthenticated) return;
    
    try {
      final userId = SupabaseAuth.currentUser!.id;
      await _saveKhutbahToCloud(khutbah, userId);
    } catch (e) {
      debugPrint('Error saving khutbah to cloud: $e');
    }
  }
  
  /// Delete a khutbah from cloud storage
  static Future<void> deleteKhutbahFromCloud(String khutbahId) async {
    if (!SupabaseAuth.isAuthenticated) return;
    
    try {
      print('DEBUG: Deleting khutbah from cloud...');
      print('  Khutbah ID: $khutbahId');
      
      final userId = SupabaseAuth.currentUser!.id;
      
      // Check if this is a timestamp ID (local) or UUID (cloud)
      final isTimestampId = int.tryParse(khutbahId) != null;
      print('  Is timestamp ID: $isTimestampId');
      
      if (isTimestampId) {
        // This is a local ID - need to find the corresponding cloud khutbah by title
        print('  WARNING: Cannot delete from cloud with timestamp ID');
        print('  Local khutbahs with timestamp IDs are not synced to cloud with same ID');
        print('  The cloud version has a different UUID');
        
        // Try to find by loading all khutbahs and matching by title
        // This is a workaround - ideally we'd maintain ID mapping
        final localKhutbahs = await StorageService.getAllKhutbahs();
        final localKhutbah = localKhutbahs.where((k) => k.id == khutbahId).firstOrNull;
        
        if (localKhutbah != null) {
          print('  Found local khutbah: ${localKhutbah.title}');
          print('  Searching for matching cloud khutbah by title...');
          
          // Load all cloud khutbahs
          final cloudKhutbahs = await loadKhutbahsFromCloud();
          final matchingCloud = cloudKhutbahs.where((k) => 
            k.title == localKhutbah.title &&
            k.content == localKhutbah.content
          ).toList();
          
          if (matchingCloud.isNotEmpty) {
            final cloudKhutbah = matchingCloud.first;
            print('  Found matching cloud khutbah with UUID: ${cloudKhutbah.id}');
            
            // Delete using the cloud UUID
            await SupabaseService.delete(
              _khutbahsTable,
              filters: {
                'user_id': userId,
                'id': cloudKhutbah.id,
              },
            );
            print('  SUCCESS: Deleted from cloud');
          } else {
            print('  WARNING: No matching cloud khutbah found');
          }
        } else {
          print('  ERROR: Local khutbah not found');
          print('  This might happen if khutbah was already deleted locally');
          print('  Attempting to find cloud khutbah by timestamp...');
          
          // Convert timestamp ID to DateTime
          try {
            final timestamp = int.parse(khutbahId);
            final createdTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            print('  Timestamp converts to: $createdTime');
            
            // Load all cloud khutbahs and find ones created around this time
            final cloudKhutbahs = await loadKhutbahsFromCloud();
            print('  Searching ${cloudKhutbahs.length} cloud khutbahs...');
            
            // Show all cloud khutbahs with their creation times
            print('  All cloud khutbahs:');
            for (int i = 0; i < cloudKhutbahs.length; i++) {
              final k = cloudKhutbahs[i];
              final timeDiff = k.createdAt.difference(createdTime);
              print('    ${i + 1}. "${k.title}" (ID: ${k.id})');
              print('       Created: ${k.createdAt}');
              print('       Time diff: ${timeDiff.inMinutes} minutes, ${timeDiff.inSeconds % 60} seconds');
            }
            
            // Find khutbahs created within 5 minutes of the timestamp (expanded window)
            final candidates = cloudKhutbahs.where((k) {
              final timeDiff = k.createdAt.difference(createdTime).abs();
              return timeDiff.inMinutes <= 5;
            }).toList();
            
            if (candidates.isNotEmpty) {
              print('  Found ${candidates.length} candidate(s) created within 5 minutes of $createdTime:');
              for (final candidate in candidates) {
                print('    - "${candidate.title}" (ID: ${candidate.id}, Created: ${candidate.createdAt})');
              }
              
              // Delete the first candidate (most likely match)
              final toDelete = candidates.first;
              print('  Deleting: "${toDelete.title}" (ID: ${toDelete.id})');
              
              await SupabaseService.delete(
                _khutbahsTable,
                filters: {
                  'user_id': userId,
                  'id': toDelete.id,
                },
              );
              print('  SUCCESS: Deleted cloud khutbah by timestamp matching');
            } else {
              print('  WARNING: No cloud khutbahs found created within 5 minutes of $createdTime');
              
              // Last resort: delete the most recently created khutbah
              if (cloudKhutbahs.isNotEmpty) {
                print('  LAST RESORT: Deleting the most recently created khutbah');
                
                // Sort by creation time, most recent first
                cloudKhutbahs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final mostRecent = cloudKhutbahs.first;
                
                print('  Most recent khutbah: "${mostRecent.title}" (ID: ${mostRecent.id}, Created: ${mostRecent.createdAt})');
                print('  Deleting this khutbah...');
                
                await SupabaseService.delete(
                  _khutbahsTable,
                  filters: {
                    'user_id': userId,
                    'id': mostRecent.id,
                  },
                );
                print('  SUCCESS: Deleted most recent cloud khutbah');
              } else {
                print('  INFO: No cloud khutbahs found at all - might already be deleted');
              }
            }
          } catch (e) {
            print('  ERROR: Could not parse timestamp: $e');
          }
        }
      } else {
        // This is already a UUID - delete directly
        print('  Action: DELETE with UUID');
        await SupabaseService.delete(
          _khutbahsTable,
          filters: {
            'user_id': userId,
            'id': khutbahId,
          },
        );
        print('  SUCCESS: Deleted from cloud');
      }
    } catch (e) {
      debugPrint('Error deleting khutbah from cloud: $e');
    }
  }
  
  /// Sync data when user logs in
  static Future<void> onUserLogin() async {
    if (!SupabaseAuth.isAuthenticated) return;
    
    try {
      // Load cloud data
      final cloudKhutbahs = await loadKhutbahsFromCloud();
      final localKhutbahs = await StorageService.getAllKhutbahs();
      
      // Create maps for easier comparison
      final cloudMap = {for (var k in cloudKhutbahs) k.id: k};
      final localMap = {for (var k in localKhutbahs) k.id: k};
      
      // Merge data - cloud takes precedence for conflicts
      final mergedKhutbahs = <String, Khutbah>{};
      
      // Add all cloud khutbahs
      mergedKhutbahs.addAll(cloudMap);
      
      // Add local khutbahs that don't exist in cloud or are newer
      for (final localKhutbah in localKhutbahs) {
        final cloudKhutbah = cloudMap[localKhutbah.id];
        if (cloudKhutbah == null || 
            localKhutbah.modifiedAt.isAfter(cloudKhutbah.modifiedAt)) {
          mergedKhutbahs[localKhutbah.id] = localKhutbah;
        }
      }
      
      // Save merged data locally
      for (final khutbah in mergedKhutbahs.values) {
        await StorageService.saveKhutbah(khutbah);
      }
      
      // Sync all local data to cloud
      await syncKhutbahsToCloud();
      
      // Also sync content items
      await ContentDataService.syncContentToCloud();
      
    } catch (e) {
      debugPrint('Error during user login sync: $e');
    }
  }
  
  /// Clear local data when user logs out
  static Future<void> onUserLogout() async {
    try {
      // Optionally clear local data or keep it for offline access
      // For now, we'll keep local data for offline access
      debugPrint('User logged out - keeping local data for offline access');
    } catch (e) {
      debugPrint('Error during user logout: $e');
    }
  }
  
  /// Enhanced save method that saves both locally and to cloud
  static Future<void> saveKhutbah(Khutbah khutbah) async {
    // Always save locally first
    await StorageService.saveKhutbah(khutbah);
    
    // Save to cloud if user is authenticated
    if (SupabaseAuth.isAuthenticated) {
      await saveKhutbahToCloud(khutbah);
    }
  }
  
  /// Enhanced delete method that deletes both locally and from cloud
  static Future<void> deleteKhutbah(String khutbahId) async {
    // Delete locally
    await StorageService.deleteKhutbah(khutbahId);
    
    // Delete from cloud if user is authenticated
    if (SupabaseAuth.isAuthenticated) {
      await deleteKhutbahFromCloud(khutbahId);
    }
  }
  
  /// Get all khutbahs (local storage, but synced with cloud)
  static Future<List<Khutbah>> getAllKhutbahs() async {
    return await StorageService.getAllKhutbahs();
  }
  
  /// Private helper to save khutbah to cloud
  static Future<void> _saveKhutbahToCloud(Khutbah khutbah, String userId) async {
    print('DEBUG: Saving khutbah to cloud...');
    print('  Khutbah ID: ${khutbah.id}');
    print('  Khutbah Title: ${khutbah.title}');
    print('  User ID: $userId');
    
    final cloudData = _khutbahToCloudData(khutbah, userId);
    
    // Check if this is a timestamp ID (local) or UUID (cloud)
    final isTimestampId = int.tryParse(khutbah.id) != null;
    print('  Is timestamp ID: $isTimestampId');
    
    if (isTimestampId) {
      // This is a local khutbah with timestamp ID - insert as new with UUID
      print('  Action: INSERT new (will get UUID from Supabase)');
      final insertData = Map<String, dynamic>.from(cloudData);
      insertData.remove('id'); // Let Supabase generate UUID
      
      final response = await SupabaseService.insert(_khutbahsTable, insertData);
      final newId = response.first['id'];
      print('  SUCCESS: Created with UUID: $newId');
      
      // TODO: Update local storage with new UUID
      // This would require updating StorageService to handle ID updates
    } else {
      // This is already a UUID - check if exists and update or insert
      final existing = await SupabaseService.selectSingle(
        _khutbahsTable,
        filters: {
          'user_id': userId,
          'id': khutbah.id,
        },
      );
      
      if (existing != null) {
        print('  Action: UPDATE existing');
        await SupabaseService.update(
          _khutbahsTable,
          cloudData,
          filters: {
            'user_id': userId,
            'id': khutbah.id,
          },
        );
        print('  SUCCESS: Updated');
      } else {
        print('  Action: INSERT with existing UUID');
        await SupabaseService.insert(_khutbahsTable, cloudData);
        print('  SUCCESS: Inserted');
      }
    }
  }
  
  /// Convert Khutbah to cloud storage format
  static Map<String, dynamic> _khutbahToCloudData(Khutbah khutbah, String userId) {
    return {
      'id': khutbah.id,
      'user_id': userId,
      'title': khutbah.title,
      'content': khutbah.content,
      'tags': khutbah.tags.join(','),
      'created_at': khutbah.createdAt.toIso8601String(),
      'modified_at': khutbah.modifiedAt.toIso8601String(),
      'estimated_minutes': khutbah.estimatedMinutes,
      'folder_id': khutbah.folderId,
    };
  }
  
  /// Convert cloud data to Khutbah
  static Khutbah _khutbahFromCloudData(Map<String, dynamic> data) {
    return Khutbah(
      id: data['id'] as String,
      title: data['title'] as String,
      content: data['content'] as String,
      tags: (data['tags'] as String? ?? '').isEmpty 
          ? <String>[]
          : (data['tags'] as String).split(',').where((tag) => tag.trim().isNotEmpty).toList(),
      createdAt: DateTime.parse(data['created_at'] as String),
      modifiedAt: DateTime.parse(data['modified_at'] as String),
      estimatedMinutes: data['estimated_minutes'] as int,
      folderId: data['folder_id'] as String?,
    );
  }
}