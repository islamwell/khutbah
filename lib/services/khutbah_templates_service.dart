import 'dart:io';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/services/html_import_service.dart';

class KhutbahTemplate {
  final String id;
  final String title;
  final String description;
  final String fileName;

  const KhutbahTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
  });
}

class KhutbahTemplatesService {
  static const List<KhutbahTemplate> _templates = [
    KhutbahTemplate(
      id: 'salaam_basic',
      title: 'Assalamo Alaykum (Basic)',
      description: 'A comprehensive khutbah about the importance of greeting with Salaam - plain text format',
      fileName: 'salaam template.html',
    ),
    KhutbahTemplate(
      id: 'salaam_formatted',
      title: 'Assalamo Alaykum (Classic)',
      description: 'A beautifully formatted khutbah about spreading peace with traditional green styling',
      fileName: 'Salaam3 template.html',
    ),
    KhutbahTemplate(
      id: 'salaam_modern',
      title: 'Assalamo Alaykum (Modern)',
      description: 'A contemporary take on the salaam khutbah with modern styling and digital age applications',
      fileName: 'Salaam Modern template.html',
    ),
  ];

  /// Get all available khutbah templates
  static List<KhutbahTemplate> getAllTemplates() {
    return _templates;
  }

  /// Load a template and convert it to a Khutbah
  static Future<Khutbah> loadTemplate(String templateId) async {
    final template = _templates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found: $templateId'),
    );

    try {
      // Read the HTML file from the root directory
      final file = File(template.fileName);
      final htmlString = await file.readAsString();
      
      // Parse HTML to Khutbah
      final khutbah = HtmlImportService.parseHtmlToKhutbah(htmlString);
      
      // Update the title to indicate it's from a template
      final now = DateTime.now();
      return khutbah.copyWith(
        id: now.millisecondsSinceEpoch.toString(),
        title: '${khutbah.title} (Template)',
        tags: [...khutbah.tags, 'template'],
        createdAt: now,
        modifiedAt: now,
      );
    } catch (e) {
      throw Exception('Failed to load template: $e');
    }
  }

  /// Create a new khutbah from a template
  static Future<Khutbah> createFromTemplate(String templateId, {String? customTitle}) async {
    final khutbah = await loadTemplate(templateId);
    
    if (customTitle != null && customTitle.trim().isNotEmpty) {
      return khutbah.copyWith(title: customTitle.trim());
    }
    
    return khutbah;
  }
}