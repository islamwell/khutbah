import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulpitflow/models/template.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/screens/rich_editor_screen.dart';
import 'package:pulpitflow/services/html_to_quill_converter_simple.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khutbah Templates'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a template to start your Khutbah',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: DefaultTemplates.all.length,
                itemBuilder: (context, index) {
                  final template = DefaultTemplates.all[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildTemplateCard(context, template),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, Template template) {
    return GestureDetector(
      onTap: () => _useTemplate(context, template),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTemplateIcon(template.type),
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTemplateTypeLabel(template.type),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              template.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getTemplatePreview(template),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontFamily: 'monospace',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTemplateIcon(TemplateType type) {
    switch (type) {
      case TemplateType.standard:
        return Icons.article_outlined;
      case TemplateType.eid:
        return Icons.celebration_outlined;
      case TemplateType.social:
        return Icons.people_outline;
      case TemplateType.youth:
        return Icons.school_outlined;
      case TemplateType.general:
        return Icons.topic_outlined;
    }
  }

  String _getTemplateTypeLabel(TemplateType type) {
    switch (type) {
      case TemplateType.standard:
        return 'STANDARD';
      case TemplateType.eid:
        return 'EID SPECIAL';
      case TemplateType.social:
        return 'SOCIAL ISSUES';
      case TemplateType.youth:
        return 'YOUTH FOCUSED';
      case TemplateType.general:
        return 'GENERAL';
    }
  }

  String _getTemplatePreview(Template template) {
    final lines = template.content.split('\n');
    final previewLines = lines.take(3).map((line) => line.trim()).where((line) => line.isNotEmpty);
    return previewLines.join('\n');
  }

  Future<void> _useTemplate(BuildContext context, Template template) async {
    // Check if this is an HTML template
    if (template.content.startsWith('HTML:')) {
      // Extract the file path
      final htmlPath = template.content.substring(5);
      
      try {
        // Read the HTML file
        final htmlFile = await rootBundle.loadString(htmlPath);
        
        // Convert HTML to Quill format
        final quillDocument = HtmlToQuillConverterSimple.convertHtmlToQuill(htmlFile);
        final quillJson = jsonEncode(quillDocument.toDelta().toJson());
        
        print('Converted HTML to Quill. Document length: ${quillDocument.length}');
        print('Plain text preview: ${quillDocument.toPlainText().substring(0, quillDocument.toPlainText().length > 100 ? 100 : quillDocument.toPlainText().length)}');
        
        // Create a Khutbah with converted Quill content
        final khutbah = Khutbah(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: template.name,
          content: quillJson,
          tags: ['template', 'converted'],
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          estimatedMinutes: 20,
        );
        
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RichEditorScreen(existingKhutbah: khutbah),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load template: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Create a Khutbah from template (plain text)
      final khutbah = Khutbah(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: template.name,
        content: template.content,
        tags: [],
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        estimatedMinutes: 15,
      );
      
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RichEditorScreen(existingKhutbah: khutbah),
          ),
        );
      }
    }
  }
}