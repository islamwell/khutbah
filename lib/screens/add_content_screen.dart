import 'package:flutter/material.dart';
import 'package:pulpitflow/models/content_item.dart';
import 'package:pulpitflow/services/content_data_service.dart';

class AddContentScreen extends StatefulWidget {
  final ContentItem? editingItem;

  const AddContentScreen({super.key, this.editingItem});

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _translationController = TextEditingController();
  final _sourceController = TextEditingController();
  final _surahController = TextEditingController();
  final _verseController = TextEditingController();
  final _keywordsController = TextEditingController();

  ContentType _selectedType = ContentType.quote;
  AuthenticityLevel? _selectedAuthenticity;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      _populateFields(widget.editingItem!);
    }
  }

  void _populateFields(ContentItem item) {
    _textController.text = item.text;
    _translationController.text = item.translation;
    _sourceController.text = item.source;
    _surahController.text = item.surahName ?? '';
    _verseController.text = item.verseNumber?.toString() ?? '';
    _keywordsController.text = item.keywords.join(', ');
    _selectedType = item.type;
    _selectedAuthenticity = item.authenticity;
  }

  @override
  void dispose() {
    _textController.dispose();
    _translationController.dispose();
    _sourceController.dispose();
    _surahController.dispose();
    _verseController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final keywords = _keywordsController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      final contentItem = ContentItem(
        id: widget.editingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        text: _textController.text.trim(),
        translation: _translationController.text.trim(),
        source: _sourceController.text.trim(),
        type: _selectedType,
        authenticity: _selectedAuthenticity,
        surahName: _selectedType == ContentType.quran && _surahController.text.trim().isNotEmpty
            ? _surahController.text.trim()
            : null,
        verseNumber: _selectedType == ContentType.quran && _verseController.text.trim().isNotEmpty
            ? int.tryParse(_verseController.text.trim())
            : null,
        keywords: keywords,
      );

      if (widget.editingItem != null) {
        await ContentDataService.updateContentItem(contentItem);
      } else {
        await ContentDataService.addContentItem(contentItem);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingItem != null 
                ? 'Content updated successfully' 
                : 'Content added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving content: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingItem != null ? 'Edit Content' : 'Add Custom Content'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveContent,
              child: Text(
                widget.editingItem != null ? 'UPDATE' : 'SAVE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildTextFields(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: ContentType.values.map((type) {
              return RadioListTile<ContentType>(
                title: Text(_getTypeDisplayName(type)),
                subtitle: Text(
                  _getTypeDescription(type),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                value: type,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    if (value != ContentType.hadith) {
                      _selectedAuthenticity = null;
                    }
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _textController,
          label: 'Arabic Text',
          hint: 'Enter the Arabic text...',
          maxLines: 3,
          textDirection: TextDirection.rtl,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _translationController,
          label: 'English Translation',
          hint: 'Enter the English translation...',
          maxLines: 3,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _sourceController,
          label: 'Source',
          hint: _getSourceHint(),
          required: true,
        ),
        if (_selectedType == ContentType.quran) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _surahController,
                  label: 'Surah Name',
                  hint: 'e.g., Al-Baqarah',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _verseController,
                  label: 'Verse Number',
                  hint: 'e.g., 255',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
        if (_selectedType == ContentType.hadith) ...[
          const SizedBox(height: 16),
          _buildAuthenticitySelector(),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: _keywordsController,
          label: 'Keywords',
          hint: 'patience, gratitude, charity (comma-separated)',
          required: true,
        ),
        const SizedBox(height: 32),
        Center(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _saveContent,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(widget.editingItem != null ? 'Update Content' : 'Save Content'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextDirection? textDirection,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: textDirection,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      style: textDirection == TextDirection.rtl
          ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16)
          : null,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildAuthenticitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authenticity Level',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AuthenticityLevel>(
          value: _selectedAuthenticity,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          hint: const Text('Select authenticity level'),
          items: AuthenticityLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAuthenticity = value;
            });
          },
        ),
      ],
    );
  }

  String _getTypeDisplayName(ContentType type) {
    switch (type) {
      case ContentType.quran:
        return 'Quran Verse';
      case ContentType.hadith:
        return 'Hadith';
      case ContentType.quote:
        return 'Quote/Saying';
    }
  }

  String _getTypeDescription(ContentType type) {
    switch (type) {
      case ContentType.quran:
        return 'Verse from the Holy Quran';
      case ContentType.hadith:
        return 'Saying or tradition of Prophet Muhammad ﷺ';
      case ContentType.quote:
        return 'Quote from scholars, companions, or wise sayings';
    }
  }

  String _getSourceHint() {
    switch (_selectedType) {
      case ContentType.quran:
        return 'e.g., Surah Al-Baqarah';
      case ContentType.hadith:
        return 'Bukhari, Muslim, and Sanad Abu Hurairah';
      case ContentType.quote:
        return 'e.g., Ali ibn Abi Talib, Ibn Qayyium';
    }
  }
}