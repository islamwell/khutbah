import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';

/// Service class for managing khutbah operations with Supabase
class KhutbahService {
  /// Get all khutbahs for the current user
  static Future<List<Khutbah>> getUserKhutbahs() async {
    try {
      final response = await SupabaseService.select(
        'khutbahs',
        orderBy: 'modified_at',
        ascending: false,
      );

      return response.map((json) => Khutbah.fromJson({
        'id': json['id'],
        'title': json['title'],
        'content': json['content'],
        'tags': json['tags'] ?? '',
        'createdAt': json['created_at'],
        'modifiedAt': json['modified_at'],
        'estimatedMinutes': json['estimated_minutes'],
        'folderId': json['folder_id'],
      })).toList();
    } catch (e) {
      throw 'Failed to load khutbahs: $e';
    }
  }

  /// Get khutbahs by folder
  static Future<List<Khutbah>> getKhutbahsByFolder(String folderId) async {
    try {
      final response = await SupabaseService.select(
        'khutbahs',
        filters: {'folder_id': folderId},
        orderBy: 'modified_at',
        ascending: false,
      );

      return response.map((json) => Khutbah.fromJson({
        'id': json['id'],
        'title': json['title'],
        'content': json['content'],
        'tags': json['tags'] ?? '',
        'createdAt': json['created_at'],
        'modifiedAt': json['modified_at'],
        'estimatedMinutes': json['estimated_minutes'],
        'folderId': json['folder_id'],
      })).toList();
    } catch (e) {
      throw 'Failed to load khutbahs: $e';
    }
  }

  /// Create a new khutbah
  static Future<Khutbah> createKhutbah(Khutbah khutbah) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final response = await SupabaseService.insert('khutbahs', {
        'user_id': userId,
        'title': khutbah.title,
        'content': khutbah.content,
        'tags': khutbah.tags.join(','),
        'estimated_minutes': khutbah.estimatedMinutes,
        'folder_id': khutbah.folderId,
        'created_at': khutbah.createdAt.toIso8601String(),
        'modified_at': khutbah.modifiedAt.toIso8601String(),
      });

      final created = response.first;
      return Khutbah.fromJson({
        'id': created['id'],
        'title': created['title'],
        'content': created['content'],
        'tags': created['tags'] ?? '',
        'createdAt': created['created_at'],
        'modifiedAt': created['modified_at'],
        'estimatedMinutes': created['estimated_minutes'],
        'folderId': created['folder_id'],
      });
    } catch (e) {
      throw 'Failed to create khutbah: $e';
    }
  }

  /// Update an existing khutbah
  static Future<Khutbah> updateKhutbah(Khutbah khutbah) async {
    try {
      final response = await SupabaseService.update(
        'khutbahs',
        {
          'title': khutbah.title,
          'content': khutbah.content,
          'tags': khutbah.tags.join(','),
          'estimated_minutes': khutbah.estimatedMinutes,
          'folder_id': khutbah.folderId,
          'modified_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': khutbah.id},
      );

      final updated = response.first;
      return Khutbah.fromJson({
        'id': updated['id'],
        'title': updated['title'],
        'content': updated['content'],
        'tags': updated['tags'] ?? '',
        'createdAt': updated['created_at'],
        'modifiedAt': updated['modified_at'],
        'estimatedMinutes': updated['estimated_minutes'],
        'folderId': updated['folder_id'],
      });
    } catch (e) {
      throw 'Failed to update khutbah: $e';
    }
  }

  /// Delete a khutbah
  static Future<void> deleteKhutbah(String khutbahId) async {
    try {
      await SupabaseService.delete('khutbahs', filters: {'id': khutbahId});
    } catch (e) {
      throw 'Failed to delete khutbah: $e';
    }
  }

  /// Search khutbahs by title, content, or tags
  static Future<List<Khutbah>> searchKhutbahs(String query) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      // Use Supabase text search functionality
      dynamic searchQuery = SupabaseConfig.client
          .from('khutbahs')
          .select('*')
          .eq('user_id', userId)
          .or('title.ilike.%$query%,content.ilike.%$query%,tags.ilike.%$query%')
          .order('modified_at', ascending: false);

      final response = await searchQuery;

      return response.map<Khutbah>((json) => Khutbah.fromJson({
        'id': json['id'],
        'title': json['title'],
        'content': json['content'],
        'tags': json['tags'] ?? '',
        'createdAt': json['created_at'],
        'modifiedAt': json['modified_at'],
        'estimatedMinutes': json['estimated_minutes'],
        'folderId': json['folder_id'],
      })).toList();
    } catch (e) {
      throw 'Failed to search khutbahs: $e';
    }
  }

  /// Get a single khutbah by ID
  static Future<Khutbah?> getKhutbahById(String id) async {
    try {
      final response = await SupabaseService.selectSingle(
        'khutbahs',
        filters: {'id': id},
      );

      if (response == null) return null;

      return Khutbah.fromJson({
        'id': response['id'],
        'title': response['title'],
        'content': response['content'],
        'tags': response['tags'] ?? '',
        'createdAt': response['created_at'],
        'modifiedAt': response['modified_at'],
        'estimatedMinutes': response['estimated_minutes'],
        'folderId': response['folder_id'],
      });
    } catch (e) {
      throw 'Failed to load khutbah: $e';
    }
  }
}