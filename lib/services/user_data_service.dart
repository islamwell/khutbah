import 'package:flutter/foundation.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';
import 'package:pulpitflow/services/storage_service.dart';
import 'package:pulpitflow/services/content_data_service.dart';

/// Service to handle user-specific data synchronization between local and cloud storage
class UserDataService {
  static const String _khutbahsTable = 'khutbahs';
  
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
      final userId = SupabaseAuth.currentUser!.id;
      await SupabaseService.delete(
        _khutbahsTable,
        filters: {
          'user_id': userId,
          'id': khutbahId,
        },
      );
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
    final cloudData = _khutbahToCloudData(khutbah, userId);
    
    // Check if khutbah already exists in cloud
    final existing = await SupabaseService.selectSingle(
      _khutbahsTable,
      filters: {
        'user_id': userId,
        'id': khutbah.id,
      },
    );
    
    if (existing != null) {
      // Update existing
      await SupabaseService.update(
        _khutbahsTable,
        cloudData,
        filters: {
          'user_id': userId,
          'id': khutbah.id,
        },
      );
    } else {
      // Insert new - let Supabase generate UUID if needed
      final insertData = Map<String, dynamic>.from(cloudData);
      // Remove id to let Supabase auto-generate UUID
      insertData.remove('id');
      await SupabaseService.insert(_khutbahsTable, insertData);
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