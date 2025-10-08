import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/models/content_item.dart';
import 'package:pulpitflow/services/user_data_service.dart';
import 'package:pulpitflow/screens/content_library_screen.dart';
import 'package:pulpitflow/screens/delivery_screen.dart';

class SimpleRichEditorScreen extends StatefulWidget {
  final Khutbah? existingKhutbah;

  const SimpleRichEditorScreen({super.key, this.existingKhutbah});

  @override
  State<SimpleRichEditorScreen> createState() => _SimpleRichEditorScreenState();
}

class _SimpleRichEditorScreenState extends State<SimpleRichEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String khutbahId;
  
  bool _isSaving = false;
  bool _showContentLibrary = false;
  int _estimatedMinutes = 15;
  
  // Simple formatting state
  bool _isBold = false;
  bool _isItalic = false;
  double _fontSize = 16;
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.transparent;
  TextAlign _textAlign = TextAlign.left;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    khutbahId = widget.existingKhutbah?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Initialize title
    _titleController = TextEditingController(
      text: widget.existingKhutbah?.title ?? 'New Khutbah'
    );
    
    // Initialize content - extract plain text from JSON if needed
    String initialText = widget.existingKhutbah?.content ?? '';
    if (initialText.isNotEmpty && initialText.startsWith('[')) {
      try {
        // Try to extract plain text from Quill JSON
        final json = jsonDecode(initialText);
        if (json is List && json.isNotEmpty) {
          final StringBuffer buffer = StringBuffer();
          for (final op in json) {
            if (op is Map && op.containsKey('insert')) {
              buffer.write(op['insert'].toString());
            }
          }
          initialText = buffer.toString();
        }
      } catch (e) {
        // Keep original text if parsing fails
      }
    }
    
    _contentController = TextEditingController(text: initialText);
    _contentController.addListener(_updateEstimatedTime);
    _updateEstimatedTime();
  }

  void _updateEstimatedTime() {
    final plain = _contentController.text;
    final wordCount = plain.split(RegExp(r'\\s+')).where((word) => word.isNotEmpty).length;
    setState(() {
      _estimatedMinutes = (wordCount / 150).ceil().clamp(5, 60);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleController.text.isEmpty ? 'New Khutbah' : _titleController.text),
        actions: [
          IconButton(
            icon: Icon(_showContentLibrary ? Icons.close : Icons.library_books),
            onPressed: () {
              setState(() {
                _showContentLibrary = !_showContentLibrary;
              });
            },
            tooltip: _showContentLibrary ? 'Close Library' : 'Open Content Library',
          ),
          if (_contentController.text.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _openDeliveryMode,
              tooltip: 'Deliver Khutbah',
            ),
          IconButton(
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveKhutbah,
            tooltip: 'Save',
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
            Expanded(
              flex: 2,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
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
            ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        _buildTitleSection(),
        _buildSimpleToolbar(),
        Expanded(child: _buildContentEditor()),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: TextField(
        controller: _titleController,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'Enter khutbah title...',
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSimpleToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarButton(
                  Icons.format_bold,
                  'Bold',
                  _isBold,
                  () => setState(() => _isBold = !_isBold),
                ),
                _buildToolbarButton(
                  Icons.format_italic,
                  'Italic',
                  _isItalic,
                  () => setState(() => _isItalic = !_isItalic),
                ),
                const SizedBox(width: 8),
                _buildFontSizeSelector(),
                const SizedBox(width: 8),
                _buildColorSelector(),
                const SizedBox(width: 8),
                _buildAlignmentSelector(),
                const SizedBox(width: 16),
                Text(
                  'Reading: $_estimatedMinutes min',
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

  Widget _buildToolbarButton(IconData icon, String tooltip, bool isActive, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: isActive 
            ? Theme.of(context).colorScheme.primaryContainer 
            : null,
      ),
    );
  }

  Widget _buildFontSizeSelector() {
    return PopupMenuButton<double>(
      tooltip: 'Font Size',
      icon: Icon(
        Icons.format_size,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 12, child: Text('Small (12)')),
        const PopupMenuItem(value: 14, child: Text('Normal (14)')),
        const PopupMenuItem(value: 16, child: Text('Medium (16)')),
        const PopupMenuItem(value: 18, child: Text('Large (18)')),
        const PopupMenuItem(value: 20, child: Text('Extra Large (20)')),
        const PopupMenuItem(value: 24, child: Text('Huge (24)')),
      ],
      onSelected: (size) => setState(() => _fontSize = size),
    );
  }

  Widget _buildColorSelector() {
    return PopupMenuButton<Color>(
      tooltip: 'Text Color',
      icon: Icon(
        Icons.format_color_text,
        size: 20,
        color: _textColor == Colors.black 
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
            : _textColor,
      ),
      itemBuilder: (context) => [
        _buildColorMenuItem(Colors.black, 'Black'),
        _buildColorMenuItem(Colors.red, 'Red'),
        _buildColorMenuItem(Colors.blue, 'Blue'),
        _buildColorMenuItem(Colors.green, 'Green'),
        _buildColorMenuItem(Colors.orange, 'Orange'),
        _buildColorMenuItem(Colors.purple, 'Purple'),
      ],
      onSelected: (color) => setState(() => _textColor = color),
    );
  }

  PopupMenuItem<Color> _buildColorMenuItem(Color color, String name) {
    return PopupMenuItem<Color>(
      value: color,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }

  Widget _buildAlignmentSelector() {
    return PopupMenuButton<TextAlign>(
      tooltip: 'Text Alignment',
      icon: Icon(
        _textAlign == TextAlign.left ? Icons.format_align_left :
        _textAlign == TextAlign.center ? Icons.format_align_center :
        Icons.format_align_right,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: TextAlign.left,
          child: Row(
            children: [Icon(Icons.format_align_left), SizedBox(width: 8), Text('Left')],
          ),
        ),
        const PopupMenuItem(
          value: TextAlign.center,
          child: Row(
            children: [Icon(Icons.format_align_center), SizedBox(width: 8), Text('Center')],
          ),
        ),
        const PopupMenuItem(
          value: TextAlign.right,
          child: Row(
            children: [Icon(Icons.format_align_right), SizedBox(width: 8), Text('Right')],
          ),
        ),
      ],
      onSelected: (align) => setState(() => _textAlign = align),
    );
  }

  Widget _buildContentEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        textAlign: _textAlign,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
          color: _textColor,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          hintText: 'Start writing your khutbah...\\n\\nTip: Use the Content Library to insert Quranic verses and Hadith.',
          border: InputBorder.none,
        ),
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
            'Words: ${_contentController.text.split(RegExp(r'\\s+')).where((word) => word.isNotEmpty).length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          if (_contentController.text.trim().isNotEmpty) ...[
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

    final currentPosition = _contentController.selection.baseOffset;
    final text = _contentController.text;

    final newText = text.substring(0, currentPosition) +
        formattedContent +
        text.substring(currentPosition);

    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: currentPosition + formattedContent.length,
    );

    setState(() {
      _showContentLibrary = false;
    });
  }

  void _openDeliveryMode() async {
    await _saveKhutbah();
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryScreen(
            title: _titleController.text,
            content: _contentController.text,
            estimatedMinutes: _estimatedMinutes,
          ),
        ),
      );
    }
  }

  Future<void> _saveKhutbah() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
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
        // Save as plain text for now - simpler and more reliable
        content: _contentController.text,
        tags: widget.existingKhutbah?.tags ?? [],
        createdAt: widget.existingKhutbah?.createdAt ?? DateTime.now(),
        modifiedAt: DateTime.now(),
        estimatedMinutes: _estimatedMinutes,
        folderId: widget.existingKhutbah?.folderId,
      );

      await UserDataService.saveKhutbah(khutbah);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khutbah saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving khutbah: $e')),
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
}