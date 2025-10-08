import 'package:pulpitflow/models/template.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';

/// Service class for managing khutbah templates with Supabase
class TemplateService {
  /// Get all available templates (user's own + public + system templates)
  static Future<List<Template>> getAllTemplates() async {
    try {
      final response = await SupabaseService.select(
        'templates',
        orderBy: 'name',
        ascending: true,
      );

      return response.map((json) => Template.fromJson({
        'id': json['id'],
        'name': json['name'],
        'content': json['content'],
        'type': json['type'],
        'description': json['description'],
        'thumbnail': json['thumbnail'],
      })).toList();
    } catch (e) {
      throw 'Failed to load templates: $e';
    }
  }

  /// Get templates by type
  static Future<List<Template>> getTemplatesByType(TemplateType type) async {
    try {
      final response = await SupabaseService.select(
        'templates',
        filters: {'type': type.name},
        orderBy: 'name',
        ascending: true,
      );

      return response.map((json) => Template.fromJson({
        'id': json['id'],
        'name': json['name'],
        'content': json['content'],
        'type': json['type'],
        'description': json['description'],
        'thumbnail': json['thumbnail'],
      })).toList();
    } catch (e) {
      throw 'Failed to load templates: $e';
    }
  }

  /// Get user's personal templates
  static Future<List<Template>> getUserTemplates() async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final response = await SupabaseService.select(
        'templates',
        filters: {'user_id': userId},
        orderBy: 'name',
        ascending: true,
      );

      return response.map((json) => Template.fromJson({
        'id': json['id'],
        'name': json['name'],
        'content': json['content'],
        'type': json['type'],
        'description': json['description'],
        'thumbnail': json['thumbnail'],
      })).toList();
    } catch (e) {
      throw 'Failed to load user templates: $e';
    }
  }

  /// Create a new template
  static Future<Template> createTemplate(Template template) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final response = await SupabaseService.insert('templates', {
        'user_id': userId,
        'name': template.name,
        'content': template.content,
        'type': template.type.name,
        'description': template.description,
        'thumbnail': template.thumbnail,
        'is_public': false, // User templates are private by default
      });

      final created = response.first;
      return Template.fromJson({
        'id': created['id'],
        'name': created['name'],
        'content': created['content'],
        'type': created['type'],
        'description': created['description'],
        'thumbnail': created['thumbnail'],
      });
    } catch (e) {
      throw 'Failed to create template: $e';
    }
  }

  /// Update an existing template
  static Future<Template> updateTemplate(Template template) async {
    try {
      final response = await SupabaseService.update(
        'templates',
        {
          'name': template.name,
          'content': template.content,
          'type': template.type.name,
          'description': template.description,
          'thumbnail': template.thumbnail,
        },
        filters: {'id': template.id},
      );

      final updated = response.first;
      return Template.fromJson({
        'id': updated['id'],
        'name': updated['name'],
        'content': updated['content'],
        'type': updated['type'],
        'description': updated['description'],
        'thumbnail': updated['thumbnail'],
      });
    } catch (e) {
      throw 'Failed to update template: $e';
    }
  }

  /// Delete a template (only user's own templates)
  static Future<void> deleteTemplate(String templateId) async {
    try {
      await SupabaseService.delete('templates', filters: {'id': templateId});
    } catch (e) {
      throw 'Failed to delete template: $e';
    }
  }

  /// Get a single template by ID
  static Future<Template?> getTemplateById(String id) async {
    try {
      final response = await SupabaseService.selectSingle(
        'templates',
        filters: {'id': id},
      );

      if (response == null) return null;

      return Template.fromJson({
        'id': response['id'],
        'name': response['name'],
        'content': response['content'],
        'type': response['type'],
        'description': response['description'],
        'thumbnail': response['thumbnail'],
      });
    } catch (e) {
      throw 'Failed to load template: $e';
    }
  }

  /// Initialize default system templates
  static Future<void> initializeDefaultTemplates() async {
    try {
      // Check if default templates already exist
      final existingTemplates = await SupabaseService.select(
        'templates',
        filters: {'user_id': null}, // System templates have null user_id
      );

      if (existingTemplates.isNotEmpty) return; // Already initialized

      // Insert default templates
      final defaultTemplates = DefaultTemplates.all;
      for (final template in defaultTemplates) {
        await SupabaseService.insert('templates', {
          'id': template.id,
          'user_id': null, // System template
          'name': template.name,
          'content': template.content,
          'type': template.type.name,
          'description': template.description,
          'thumbnail': template.thumbnail,
          'is_public': true,
        });
      }
    } catch (e) {
      throw 'Failed to initialize default templates: $e';
    }
  }
}