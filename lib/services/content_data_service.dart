import 'package:flutter/foundation.dart';
import 'package:pulpitflow/models/content_item.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';
import 'package:pulpitflow/services/storage_service.dart';

/// Service to handle content items with cloud synchronization
class ContentDataService {
  static const String _contentItemsTable = 'content_items';
  
  /// Add a new content item (both locally and to cloud)
  static Future<void> addContentItem(ContentItem item) async {
    // Always save locally first
    await StorageService.addContentItem(item);
    
    // Save to cloud if user is authenticated
    if (SupabaseAuth.isAuthenticated) {
      await _saveContentItemToCloud(item);
    }
  }
  
  /// Update an existing content item (both locally and in cloud)
  static Future<void> updateContentItem(ContentItem item) async {
    // Update locally
    await StorageService.updateContentItem(item);
    
    // Update in cloud if user is authenticated
    if (SupabaseAuth.isAuthenticated) {
      await _updateContentItemInCloud(item);
    }
  }
  
  /// Delete a content item (both locally and from cloud)
  static Future<void> deleteContentItem(String itemId) async {
    // Delete locally
    await StorageService.deleteContentItem(itemId);
    
    // Delete from cloud if user is authenticated
    if (SupabaseAuth.isAuthenticated) {
      await _deleteContentItemFromCloud(itemId);
    }
  }
  
  /// Get all content items (includes both local and cloud items)
  static Future<List<ContentItem>> getAllContent() async {
    // Get local content
    final localContent = await StorageService.getAllContent();
    
    if (!SupabaseAuth.isAuthenticated) {
      return localContent;
    }
    
    try {
      // Get user's cloud content
      final cloudContent = await _loadContentItemsFromCloud();
      
      // Merge content (avoid duplicates)
      final mergedContent = <String, ContentItem>{};
      
      // Add local content
      for (final item in localContent) {
        mergedContent[item.id] = item;
      }
      
      // Add cloud content (cloud takes precedence for user-created items)
      for (final item in cloudContent) {
        mergedContent[item.id] = item;
      }
      
      return mergedContent.values.toList();
    } catch (e) {
      debugPrint('Error loading cloud content: $e');
      return localContent;
    }
  }
  
  /// Get content by type (includes both local and cloud items)
  static Future<List<ContentItem>> getContentByType(ContentType type) async {
    final allContent = await getAllContent();
    return allContent.where((item) => item.type == type).toList();
  }
  
  /// Search content (includes both local and cloud items)
  static Future<List<ContentItem>> searchContent(String query) async {
    final allContent = await getAllContent();
    final q = query.toLowerCase();
    
    return allContent.where((item) {
      final text = item.text.toLowerCase();
      final translation = item.translation.toLowerCase();
      final keywords = item.keywords.join(' ').toLowerCase();
      return text.contains(q) || translation.contains(q) || keywords.contains(q);
    }).toList();
  }
  
  /// Sync user's content items to cloud
  static Future<void> syncContentToCloud() async {
    if (!SupabaseAuth.isAuthenticated) return;
    
    try {
      final localContent = await StorageService.getAllContent();
      final userId = SupabaseAuth.currentUser!.id;
      
      // Filter out default/sample content (only sync user-created content)
      final userContent = localContent.where((item) => 
        int.tryParse(item.id) == null || // Non-numeric IDs are user-created
        int.parse(item.id) > 100 // IDs > 100 are user-created
      ).toList();
      
      for (final item in userContent) {
        await _saveContentItemToCloud(item);
      }
    } catch (e) {
      debugPrint('Error syncing content to cloud: $e');
    }
  }
  
  /// Load user's content items from cloud
  static Future<List<ContentItem>> _loadContentItemsFromCloud() async {
    if (!SupabaseAuth.isAuthenticated) return [];
    
    try {
      final userId = SupabaseAuth.currentUser!.id;
      final response = await SupabaseService.select(
        _contentItemsTable,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );
      
      return response.map((data) => _contentItemFromCloudData(data)).toList();
    } catch (e) {
      debugPrint('Error loading content items from cloud: $e');
      return [];
    }
  }
  
  /// Save a content item to cloud storage
  static Future<void> _saveContentItemToCloud(ContentItem item) async {
    if (!SupabaseAuth.isAuthenticated) return;
    
    try {
      final userId = SupabaseAuth.currentUser!.id;
      final cloudData = _contentItemToCloudData(item, userId);
      
      // Check if item already exists in cloud
      final existing = await SupabaseService.selectSingle(
        _contentItemsTable,
        filters: {
          'user_id': userId,
          'content_id': item.id,
        },
      );
      
      if (existing != null) {
        // Update existing
        await SupabaseService.update(
          _contentItemsTable,
          cloudData,
          filters: {
            'user_id': userId,
            'content_id': item.id,
          },
        );
      } else {
        // Insert new
        await SupabaseService.insert(_contentItemsTable, cloudData);
      }
    } catch (e) {
      debugPrint('Error saving content item to cloud: $e');
    }
  }
  
  /// Update a content item in cloud storage
  static Future<void> _updateContentItemInCloud(ContentItem item) async {
    await _saveContentItemToCloud(item); // Same as save for now
  }
  
  /// Delete a content item from cloud storage
  static Future<void> _deleteContentItemFromCloud(String itemId) async {
    if (!SupabaseAuth.isAuthenticated) return;
    
    try {
      final userId = SupabaseAuth.currentUser!.id;
      await SupabaseService.delete(
        _contentItemsTable,
        filters: {
          'user_id': userId,
          'content_id': itemId,
        },
      );
    } catch (e) {
      debugPrint('Error deleting content item from cloud: $e');
    }
  }
  
  /// Convert ContentItem to cloud storage format
  static Map<String, dynamic> _contentItemToCloudData(ContentItem item, String userId) {
    return {
      'user_id': userId,
      'content_id': item.id,
      'text': item.text,
      'translation': item.translation,
      'source': item.source,
      'type': item.type.name,
      'authenticity': item.authenticity?.name,
      'surah_name': item.surahName,
      'verse_number': item.verseNumber,
      'keywords': item.keywords.join(','),
      'is_public': false, // User content is private by default
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
  
  /// Convert cloud data to ContentItem
  static ContentItem _contentItemFromCloudData(Map<String, dynamic> data) {
    return ContentItem(
      id: data['content_id'] as String,
      text: data['text'] as String,
      translation: data['translation'] as String,
      source: data['source'] as String,
      type: ContentType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => ContentType.quote,
      ),
      authenticity: data['authenticity'] != null
          ? AuthenticityLevel.values.firstWhere(
              (level) => level.name == data['authenticity'],
              orElse: () => AuthenticityLevel.sahih,
            )
          : null,
      surahName: data['surah_name'] as String?,
      verseNumber: data['verse_number'] as int?,
      keywords: (data['keywords'] as String? ?? '').isEmpty 
          ? <String>[]
          : (data['keywords'] as String).split(',').where((k) => k.trim().isNotEmpty).toList(),
    );
  }
}