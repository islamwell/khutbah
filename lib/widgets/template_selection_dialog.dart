import 'package:flutter/material.dart';
import 'package:pulpitflow/services/khutbah_templates_service.dart';

class TemplateSelectionDialog extends StatefulWidget {
  const TemplateSelectionDialog({super.key});

  @override
  State<TemplateSelectionDialog> createState() => _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends State<TemplateSelectionDialog> {
  String? selectedTemplateId;
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = KhutbahTemplatesService.getAllTemplates();

    return AlertDialog(
      title: const Text('Choose a Template'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a khutbah template to get started:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      value: template.id,
                      groupValue: selectedTemplateId,
                      onChanged: (value) {
                        setState(() {
                          selectedTemplateId = value;
                        });
                      },
                      title: Text(
                        template.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  );
                },
              ),
            ),
            if (selectedTemplateId != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Custom Title (Optional)',
                  hintText: 'Leave empty to use template title',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: selectedTemplateId != null ? _createFromTemplate : null,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createFromTemplate() async {
    if (selectedTemplateId == null) return;

    try {
      final khutbah = await KhutbahTemplatesService.createFromTemplate(
        selectedTemplateId!,
        customTitle: _titleController.text.trim().isNotEmpty 
            ? _titleController.text.trim() 
            : null,
      );
      
      if (mounted) {
        Navigator.of(context).pop(khutbah);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create from template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}