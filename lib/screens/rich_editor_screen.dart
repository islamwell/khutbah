import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/models/content_item.dart';
import 'package:pulpitflow/services/user_data_service.dart';
import 'package:pulpitflow/screens/content_library_screen.dart';
import 'package:pulpitflow/screens/delivery_screen.dart';
import 'package:pulpitflow/widgets/export_bottom_sheet.dart';
import 'package:pulpitflow/utils/pdf_generator.dart';
import 'package:pulpitflow/utils/html_generator.dart';
import 'package:flutter/services.dart';

class RichEditorScreen extends StatefulWidget {
  final Khutbah? existingKhutbah;

  const RichEditorScreen({super.key, this.existingKhutbah});

  @override
  State<RichEditorScreen> createState() => _RichEditorScreenState();
}

class _RichEditorScreenState extends State<RichEditorScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late FocusNode _titleFocusNode;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  late String khutbahId;
  
  bool _isSaving = false;
  bool _showContentLibrary = false;
  int _estimatedMinutes = 15;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
    // Request focus after the frame is built to show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _initializeEditor() {
    khutbahId = widget.existingKhutbah?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Initialize controllers and nodes
    _titleFocusNode = FocusNode();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    
    // Initialize title
    _titleController = TextEditingController(
      text: widget.existingKhutbah?.title ?? 'New Khutbah'
    );
    
    // Initialize Quill controller
    final initialText = widget.existingKhutbah?.content ?? '';
    Document document;
    
    try {
      if (initialText.isNotEmpty && initialText.startsWith('[')) {
        // Existing Quill document
        final json = jsonDecode(initialText);
        document = Document.fromJson(json);
      } else {
        // Plain text - convert to Quill document
        document = Document()..insert(0, initialText);
      }
    } catch (e) {
      // Fallback to plain text
      document = Document()..insert(0, initialText);
    }
    
    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    
    _quillController.addListener(_updateEstimatedTime);
    _updateEstimatedTime();
  }

  void _updateEstimatedTime() {
    final plain = _quillController.document.toPlainText();
    final wordCount = plain.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    setState(() {
      _estimatedMinutes = (wordCount / 150).ceil().clamp(1, 60);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showContentLibrary) {
      return _buildContentLibraryFullScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: IntrinsicWidth(
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.light 
                  ? Colors.black 
                  : Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Khutbah Title',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: _titleController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear, 
                        color: Theme.of(context).brightness == Brightness.light 
                            ? Colors.black 
                            : Colors.white, 
                        size: 20,
                      ),
                      tooltip: 'Clear title',
                      onPressed: () {
                        setState(() {
                          _titleController.clear();
                        });
                        _titleFocusNode.requestFocus();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {}); // Update to show/hide clear button
            },
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'library',
                child: ListTile(
                  leading: Icon(Icons.library_books),
                  title: Text('Content Library'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Export'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: _showContentLibrary ? 3 : 1,
            child: _buildEditor(),
          ),
          if (_showContentLibrary)
            Container(
              width: 400,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: ContentLibraryScreen(
                onContentSelected: _insertContent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        _buildFormattingToolbar(),
        Expanded(child: _buildContentEditor()),
        _buildBottomBar(),
      ],
    );
  }



  Widget _buildFormattingToolbar() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120), // Limit toolbar height
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: QuillSimpleToolbar(
                controller: _quillController,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Reading time: $_estimatedMinutes min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: QuillEditor.basic(
        controller: _quillController,
        scrollController: _scrollController,
        focusNode: _focusNode,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Words: ${_quillController.document.toPlainText().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          if (_quillController.document.toPlainText().trim().isNotEmpty) ...[
            FilledButton.icon(
              onPressed: _openDeliveryMode,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Deliver'),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _saveKhutbah,
            icon: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _insertContent(ContentItem item) {
    String formattedContent;
    if (item.type == ContentType.quran) {
      formattedContent = '''

${item.text}

"${item.translation}"
— ${item.displaySource}

''';
    } else if (item.type == ContentType.hadith) {
      formattedContent = '''

${item.text}

"${item.translation}"
— ${item.displaySource}

''';
    } else { // quote
      formattedContent = '''

"${item.translation}"
— ${item.source}

''';
    }

    final index = _quillController.selection.baseOffset;
    _quillController.document.insert(index, formattedContent);
    
    // Move cursor to end of inserted content
    _quillController.updateSelection(
      TextSelection.collapsed(offset: index + formattedContent.length),
      ChangeSource.local,
    );

    setState(() {
      _showContentLibrary = false;
    });
  }

  Future<void> _saveKhutbah() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final khutbah = Khutbah(
        id: khutbahId,
        title: _titleController.text.trim(),
        // Save as JSON to preserve formatting
        content: jsonEncode(_quillController.document.toDelta().toJson()),
        tags: widget.existingKhutbah?.tags ?? [],
        createdAt: widget.existingKhutbah?.createdAt ?? DateTime.now(),
        modifiedAt: DateTime.now(),
        estimatedMinutes: _estimatedMinutes,
        folderId: widget.existingKhutbah?.folderId,
      );

      await UserDataService.saveKhutbah(khutbah);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khutbah saved successfully'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving khutbah: $e'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildContentLibraryFullScreen() {
    return Scaffold(
      body: ContentLibraryScreen(
        onContentSelected: _insertContent,
        showAppBar: true,
        onBack: () {
          setState(() {
            _showContentLibrary = false;
          });
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'library':
        setState(() {
          _showContentLibrary = true;
        });
        break;
      case 'export':
        _showExportOptions();
        break;
    }
  }

  // Removed rename dialog - now using inline editing in AppBar
  // void _showRenameDialog() {
  //   ... dialog code removed ...
  // }

  void _showExportOptions() {
    final title = _titleController.text.trim();
    final content = _quillController.document.toPlainText();
    
    if (title.isEmpty || content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a title and content before exporting'),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }
    
    ExportBottomSheet.show(
      context,
      title: title,
      content: content,
      onOptionSelected: _handleExportOption,
    );
  }

  Future<void> _handleExportOption(ExportOption option) async {
    final title = _titleController.text.trim();
    final content = _quillController.document.toPlainText();
    
    try {
      switch (option) {
        // case ExportOption.savePDFWithPicker: // Commented out for next version
        //   await _savePDFWithPicker(title, content);
        //   break;
        // case ExportOption.printPDF: // Commented out for next version
        //   await _printPDF(title, content);
        //   break;
        case ExportOption.sharePDF:
          await _sharePDF(title, content);
          break;
        case ExportOption.shareHTML:
          await _shareHTML(title, content);
          break;
        case ExportOption.copyPlainText:
          await _copyPlainText(content);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  // Commented out - Save to Downloads not working properly on Android
  // Future<void> _savePDF(String title, String content) async {
  //   final filePath = await PDFGenerator.savePDFFromDocument(title, _quillController.document);
  //   if (mounted) {
  //     if (filePath != null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('PDF saved to Downloads: ${filePath.split('/').last}'),
  //           action: SnackBarAction(
  //             label: 'Open Folder',
  //             onPressed: () {
  //               // Could implement opening file manager here
  //             },
  //           ),
  //         ),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Failed to save PDF to Downloads. Check storage permissions.'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  Future<void> _savePDFWithPicker(String title, String content) async {
    final filePath = await PDFGenerator.savePDFWithPickerFromDocument(title, _quillController.document);
    if (mounted) {
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: ${filePath.split('/').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save cancelled or failed'),
            backgroundColor: Colors.orange,
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  Future<void> _printPDF(String title, String content) async {
    final success = await PDFGenerator.printPDFFromDocument(title, _quillController.document);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print dialog opened'),
            duration: Duration(milliseconds: 800),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open print dialog'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  Future<void> _sharePDF(String title, String content) async {
    final success = await PDFGenerator.sharePDFFromDocument(title, _quillController.document);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF shared successfully'),
            duration: Duration(milliseconds: 800),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share PDF'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  // Commented out - Save HTML not working properly, use Share HTML instead
  // Future<void> _saveHTML(String title, String content) async {
  //   try {
  //     final filePath = await HTMLGenerator.saveHTML(title, _quillController.document);
  //     if (filePath != null && mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('HTML saved successfully'),
  //           action: SnackBarAction(
  //             label: 'View',
  //             onPressed: () {
  //               // Could open file manager or show file location
  //               print('HTML file saved at: $filePath');
  //             },
  //           ),
  //         ),
  //       );
  //     } else if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to save HTML file')),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error saving HTML: $e')),
  //       );
  //     }
  //   }
  // }

  Future<void> _shareHTML(String title, String content) async {
    try {
      final success = await HTMLGenerator.shareHTML(title, _quillController.document);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HTML shared successfully'),
            duration: Duration(milliseconds: 800),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share HTML'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing HTML: $e'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  Future<void> _copyPlainText(String content) async {
    try {
      // Trim whitespace and ensure we have content to copy
      final textToCopy = content.trim();
      
      if (textToCopy.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No content to copy'),
              duration: Duration(milliseconds: 800),
            ),
          );
        }
        return;
      }
      
      await Clipboard.setData(ClipboardData(text: textToCopy));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text copied to clipboard'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy text: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }



  void _openDeliveryMode() async {
    await _saveKhutbah();
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryScreen(
            title: _titleController.text,
            content: _quillController.document.toPlainText(),
            estimatedMinutes: _estimatedMinutes,
          ),
        ),
      );
    }
  }
}