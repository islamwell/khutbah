import 'package:pulpitflow/models/content_item.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';

/// Service class for managing content items (Quran, Hadith, Quotes) with Supabase
class ContentService {
  /// Get all content items (user's own + public + system content)
  static Future<List<ContentItem>> getAllContentItems() async {
    try {
      final response = await SupabaseService.select(
        'minbar_content_items',
        orderBy: 'created_at',
        ascending: false,
      );

      return response.map((json) => ContentItem.fromJson({
        'id': json['id'],
        'text': json['text'],
        'translation': json['translation'],
        'source': json['source'],
        'type': json['type'],
        'authenticity': json['authenticity'],
        'surahName': json['surah_name'],
        'verseNumber': json['verse_number'],
        'keywords': json['keywords'] ?? '',
      })).toList();
    } catch (e) {
      throw 'Failed to load content items: $e';
    }
  }

  /// Get content items by type
  static Future<List<ContentItem>> getContentItemsByType(ContentType type) async {
    try {
      final response = await SupabaseService.select(
        'minbar_content_items',
        filters: {'type': type.name},
        orderBy: 'created_at',
        ascending: false,
      );

      return response.map((json) => ContentItem.fromJson({
        'id': json['id'],
        'text': json['text'],
        'translation': json['translation'],
        'source': json['source'],
        'type': json['type'],
        'authenticity': json['authenticity'],
        'surahName': json['surah_name'],
        'verseNumber': json['verse_number'],
        'keywords': json['keywords'] ?? '',
      })).toList();
    } catch (e) {
      throw 'Failed to load content items: $e';
    }
  }

  /// Search content items by keywords
  static Future<List<ContentItem>> searchContentItems(String query) async {
    try {
      // Search in text, translation, source, and keywords
      dynamic searchQuery = SupabaseConfig.client
          .from('minbar_content_items')
          .select('*')
          .or('text.ilike.%$query%,translation.ilike.%$query%,source.ilike.%$query%,keywords.ilike.%$query%')
          .order('created_at', ascending: false);

      final response = await searchQuery;

      return response.map<ContentItem>((json) => ContentItem.fromJson({
        'id': json['id'],
        'text': json['text'],
        'translation': json['translation'],
        'source': json['source'],
        'type': json['type'],
        'authenticity': json['authenticity'],
        'surahName': json['surah_name'],
        'verseNumber': json['verse_number'],
        'keywords': json['keywords'] ?? '',
      })).toList();
    } catch (e) {
      throw 'Failed to search content items: $e';
    }
  }

  /// Get content items by keywords
  static Future<List<ContentItem>> getContentItemsByKeywords(List<String> keywords) async {
    try {
      if (keywords.isEmpty) return [];

      // Build search query for multiple keywords
      final keywordQuery = keywords.map((k) => 'keywords.ilike.%$k%').join(',');
      
      dynamic searchQuery = SupabaseConfig.client
          .from('minbar_content_items')
          .select('*')
          .or(keywordQuery)
          .order('created_at', ascending: false);

      final response = await searchQuery;

      return response.map<ContentItem>((json) => ContentItem.fromJson({
        'id': json['id'],
        'text': json['text'],
        'translation': json['translation'],
        'source': json['source'],
        'type': json['type'],
        'authenticity': json['authenticity'],
        'surahName': json['surah_name'],
        'verseNumber': json['verse_number'],
        'keywords': json['keywords'] ?? '',
      })).toList();
    } catch (e) {
      throw 'Failed to load content items by keywords: $e';
    }
  }

  /// Get user's personal content items
  static Future<List<ContentItem>> getUserContentItems() async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final response = await SupabaseService.select(
        'minbar_content_items',
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      return response.map((json) => ContentItem.fromJson({
        'id': json['id'],
        'text': json['text'],
        'translation': json['translation'],
        'source': json['source'],
        'type': json['type'],
        'authenticity': json['authenticity'],
        'surahName': json['surah_name'],
        'verseNumber': json['verse_number'],
        'keywords': json['keywords'] ?? '',
      })).toList();
    } catch (e) {
      throw 'Failed to load user content items: $e';
    }
  }

  /// Create a new content item
  static Future<ContentItem> createContentItem(ContentItem contentItem) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final response = await SupabaseService.insert('minbar_content_items', {
        'user_id': userId,
        'text': contentItem.text,
        'translation': contentItem.translation,
        'source': contentItem.source,
        'type': contentItem.type.name,
        'authenticity': contentItem.authenticity?.name,
        'surah_name': contentItem.surahName,
        'verse_number': contentItem.verseNumber,
        'keywords': contentItem.keywords.join(','),
        'is_public': false, // User content is private by default
      });

      final created = response.first;
      return ContentItem.fromJson({
        'id': created['id'],
        'text': created['text'],
        'translation': created['translation'],
        'source': created['source'],
        'type': created['type'],
        'authenticity': created['authenticity'],
        'surahName': created['surah_name'],
        'verseNumber': created['verse_number'],
        'keywords': created['keywords'] ?? '',
      });
    } catch (e) {
      throw 'Failed to create content item: $e';
    }
  }

  /// Update an existing content item
  static Future<ContentItem> updateContentItem(ContentItem contentItem) async {
    try {
      final response = await SupabaseService.update(
        'minbar_content_items',
        {
          'text': contentItem.text,
          'translation': contentItem.translation,
          'source': contentItem.source,
          'type': contentItem.type.name,
          'authenticity': contentItem.authenticity?.name,
          'surah_name': contentItem.surahName,
          'verse_number': contentItem.verseNumber,
          'keywords': contentItem.keywords.join(','),
        },
        filters: {'id': contentItem.id},
      );

      final updated = response.first;
      return ContentItem.fromJson({
        'id': updated['id'],
        'text': updated['text'],
        'translation': updated['translation'],
        'source': updated['source'],
        'type': updated['type'],
        'authenticity': updated['authenticity'],
        'surahName': updated['surah_name'],
        'verseNumber': updated['verse_number'],
        'keywords': updated['keywords'] ?? '',
      });
    } catch (e) {
      throw 'Failed to update content item: $e';
    }
  }

  /// Delete a content item (only user's own content)
  static Future<void> deleteContentItem(String contentItemId) async {
    try {
      await SupabaseService.delete('minbar_content_items', filters: {'id': contentItemId});
    } catch (e) {
      throw 'Failed to delete content item: $e';
    }
  }

  /// Get a single content item by ID
  static Future<ContentItem?> getContentItemById(String id) async {
    try {
      final response = await SupabaseService.selectSingle(
        'content_items',
        filters: {'id': id},
      );

      if (response == null) return null;

      return ContentItem.fromJson({
        'id': response['id'],
        'text': response['text'],
        'translation': response['translation'],
        'source': response['source'],
        'type': response['type'],
        'authenticity': response['authenticity'],
        'surahName': response['surah_name'],
        'verseNumber': response['verse_number'],
        'keywords': response['keywords'] ?? '',
      });
    } catch (e) {
      throw 'Failed to load content item: $e';
    }
  }

  /// Add to user favorites
  static Future<void> addToFavorites(String contentItemId) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      await SupabaseService.insert('minbar_user_favorites', {
        'user_id': userId,
        'item_type': 'content_item',
        'item_id': contentItemId,
      });
    } catch (e) {
      throw 'Failed to add to favorites: $e';
    }
  }

  /// Remove from user favorites
  static Future<void> removeFromFavorites(String contentItemId) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      await SupabaseService.delete('minbar_user_favorites', filters: {
        'user_id': userId,
        'item_type': 'content_item',
        'item_id': contentItemId,
      });
    } catch (e) {
      throw 'Failed to remove from favorites: $e';
    }
  }

  /// Get user's favorite content items
  static Future<List<ContentItem>> getFavoriteContentItems() async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      // Join user_favorites with minbar_content_items
      dynamic query = SupabaseConfig.client
          .from('minbar_user_favorites')
          .select('minbar_content_items(*)')
          .eq('user_id', userId)
          .eq('item_type', 'content_item');

      final response = await query;

      return response.map<ContentItem>((json) {
        final contentItem = json['content_items'];
        return ContentItem.fromJson({
          'id': contentItem['id'],
          'text': contentItem['text'],
          'translation': contentItem['translation'],
          'source': contentItem['source'],
          'type': contentItem['type'],
          'authenticity': contentItem['authenticity'],
          'surahName': contentItem['surah_name'],
          'verseNumber': contentItem['verse_number'],
          'keywords': contentItem['keywords'] ?? '',
        });
      }).toList();
    } catch (e) {
      throw 'Failed to load favorite content items: $e';
    }
  }
}