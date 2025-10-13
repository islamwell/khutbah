import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/services/user_data_service.dart';
import 'package:pulpitflow/services/html_to_quill_converter.dart';
import 'package:pulpitflow/widgets/export_bottom_sheet.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class HtmlTemplateViewer extends StatefulWidget {
  final String htmlContent;
  final String title;

  const HtmlTemplateViewer({
    super.key,
    required this.htmlContent,
    required this.title,
  });

  @override
  State<HtmlTemplateViewer> createState() => _HtmlTemplateViewerState();
}

class _HtmlTemplateViewerState extends State<HtmlTemplateViewer> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    
    // Convert HTML to Quill document
    final quillDocument = HtmlToQuillConverter.convertHtmlToQuill(widget.htmlContent);
    _quillController = QuillController(
      document: quillDocument,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Khutbah Title',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareHtml,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportHtml,
            tooltip: 'Export',
          ),
          IconButton(
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAsKhutbah,
            tooltip: 'Save as Khutbah',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildHtmlPreview(),
        ),
      ),
    );
  }

  Widget _buildHtmlPreview() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: QuillEditor.basic(
        controller: _quillController,
        configurations: QuillEditorConfigurations(
          readOnly: true,
          showCursor: false,
          padding: EdgeInsets.zero,
          customStyles: DefaultStyles(
            h1: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c5f2d),
                height: 1.4,
              ),
              const VerticalSpacing(16, 8),
              const VerticalSpacing(0, 0),
              null,
            ),
            h2: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c5f2d),
                height: 1.4,
              ),
              const VerticalSpacing(14, 6),
              const VerticalSpacing(0, 0),
              null,
            ),
            h3: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a4d1a),
                height: 1.4,
              ),
              const VerticalSpacing(12, 4),
              const VerticalSpacing(0, 0),
              null,
            ),
            paragraph: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
              const VerticalSpacing(0, 8),
              const VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAsKhutbah() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      final khutbah = Khutbah(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _quillController.document.toDelta().toJson(),
        tags: ['template', 'salaam', 'converted'],
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        estimatedMinutes: 20,
      );
      
      await UserDataService.saveKhutbah(khutbah);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khutbah saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareHtml() async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = '${_titleController.text.trim().replaceAll(RegExp(r'[^\w\s-]'), '')}.html';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(widget.htmlContent);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sharing: ${_titleController.text.trim()}',
        subject: _titleController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportHtml() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_titleController.text.trim().replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(widget.htmlContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
