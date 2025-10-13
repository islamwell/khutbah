import 'package:flutter/material.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/services/user_data_service.dart';
import 'package:pulpitflow/screens/rich_editor_screen.dart';
import 'package:pulpitflow/screens/templates_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pulpitflow/services/html_import_service.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:pulpitflow/services/speech_log_service.dart';
import 'package:intl/intl.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Khutbah> khutbahs = [];
  List<Khutbah> filteredKhutbahs = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Map<String, int> deliveryCounts = {};
  Map<String, DateTime?> mostRecentDeliveries = {};

  @override
  void initState() {
    super.initState();
    _loadKhutbahs();
    _searchController.addListener(_filterKhutbahs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKhutbahs() async {
    try {
      final loadedKhutbahs = await UserDataService.getAllKhutbahs();
      
      // Load delivery counts and most recent delivery dates for all khutbahs
      await _loadDeliveryData(loadedKhutbahs);
      
      setState(() {
        khutbahs = loadedKhutbahs;
        filteredKhutbahs = loadedKhutbahs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDeliveryData(List<Khutbah> khutbahs) async {
    final counts = <String, int>{};
    final recentDates = <String, DateTime?>{};
    
    for (final khutbah in khutbahs) {
      try {
        // Get delivery count
        final count = await SpeechLogService.getDeliveryCount(khutbah.id);
        counts[khutbah.id] = count;
        
        // Get most recent delivery date if there are any deliveries
        if (count > 0) {
          final logs = await SpeechLogService.getSpeechLogsByKhutbah(khutbah.id);
          if (logs.isNotEmpty) {
            recentDates[khutbah.id] = logs.first.deliveryDate;
          }
        }
      } catch (e) {
        // If there's an error, just set count to 0
        counts[khutbah.id] = 0;
      }
    }
    
    deliveryCounts = counts;
    mostRecentDeliveries = recentDates;
  }

  void _filterKhutbahs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredKhutbahs = khutbahs;
      } else {
        filteredKhutbahs = khutbahs.where((khutbah) {
          // Get plain text content for search
          String searchableContent;
          try {
            if (khutbah.content.startsWith('[') || khutbah.content.startsWith('{')) {
              final json = jsonDecode(khutbah.content);
              final document = Document.fromJson(json);
              searchableContent = document.toPlainText().toLowerCase();
            } else {
              searchableContent = khutbah.content.toLowerCase();
            }
          } catch (e) {
            searchableContent = khutbah.content.toLowerCase();
          }
          
          return khutbah.title.toLowerCase().contains(query) ||
                 searchableContent.contains(query) ||
                 khutbah.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: 'Create New',
            onSelected: (value) {
              switch (value) {
                case 'blank':
                  _navigateToEditor();
                  break;
                case 'template':
                  _showTemplateDialog();
                  break;
                case 'import':
                  _importHtml();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'blank',
                child: ListTile(
                  leading: Icon(Icons.edit_note),
                  title: Text('Blank Khutbah'),
                  subtitle: Text('Start from scratch'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'template',
                child: ListTile(
                  leading: Icon(Icons.article_outlined),
                  title: Text('From Template'),
                  subtitle: Text('Use a pre-made template'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text('Import HTML'),
                  subtitle: Text('Import from HTML file'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredKhutbahs.isEmpty
                    ? _buildEmptyState()
                    : _buildKhutbahsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search khutbahs...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.library_books_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No Results Found' : 'No Khutbahs Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch 
                  ? 'Try a different search term'
                  : 'Create your first Khutbah to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _navigateToEditor,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Blank'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _showTemplateDialog,
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Template'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKhutbahsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredKhutbahs.length,
      itemBuilder: (context, index) {
        final khutbah = filteredKhutbahs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildKhutbahCard(khutbah),
        );
      },
    );
  }

  Widget _buildKhutbahCard(Khutbah khutbah) {
    final deliveryCount = deliveryCounts[khutbah.id] ?? 0;
    final mostRecentDelivery = mostRecentDeliveries[khutbah.id];
    
    return GestureDetector(
      onTap: () => _editKhutbah(khutbah),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    khutbah.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Delivery count badge
                if (deliveryCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$deliveryCount',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, khutbah),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy_outlined),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getContentPreview(khutbah.content),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(khutbah.modifiedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (khutbah.tags.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      khutbah.tags.first,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            // Most recent delivery date
            if (mostRecentDelivery != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last delivered: ${_formatShortDate(mostRecentDelivery)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            // Quick actions
            const SizedBox(height: 12),
            Row(
              children: [
                // Log Delivery button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _logDelivery(khutbah),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Log Delivery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                // View Delivery History button (only show if there are deliveries)
                if (deliveryCount > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewDeliveryHistory(khutbah),
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('History'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    try {
      // Try to parse as Quill Delta JSON first
      if (content.startsWith('[') || content.startsWith('{')) {
        final json = jsonDecode(content);
        final document = Document.fromJson(json);
        final plainText = document.toPlainText();
        
        // Get first few lines for preview, excluding common Arabic openings
        final lines = plainText.split('\n')
            .where((line) => line.trim().isNotEmpty)
            .where((line) => !line.trim().startsWith('بِسْمِ') && !line.trim().startsWith('الْحَمْدُ'))
            .take(2);
        
        final preview = lines.join(' ').trim();
        return preview.length > 100 ? '${preview.substring(0, 100)}...' : preview;
      }
    } catch (e) {
      // If parsing fails, treat as plain text
    }
    
    // Fallback to plain text processing
    final lines = content.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .where((line) => !line.trim().startsWith('بِسْمِ') && !line.trim().startsWith('الْحَمْدُ'))
        .take(2);
    
    final preview = lines.join(' ').trim();
    return preview.length > 100 ? '${preview.substring(0, 100)}...' : preview;
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    // Format hour to 12-hour format
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$weekday $month $day, $year ${displayHour}:${minute}$period';
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _logDelivery(Khutbah khutbah) async {
    final result = await Navigator.pushNamed(
      context,
      '/speech-log-form',
      arguments: {
        'preselectedKhutbahId': khutbah.id,
        'preselectedKhutbahTitle': khutbah.title,
      },
    );

    // Reload khutbahs if log was saved
    if (result == true) {
      _loadKhutbahs();
    }
  }

  void _viewDeliveryHistory(Khutbah khutbah) {
    Navigator.pushNamed(
      context,
      '/filtered-speech-logs',
      arguments: {
        'khutbahId': khutbah.id,
        'khutbahTitle': khutbah.title,
      },
    ).then((_) => _loadKhutbahs());
  }

  void _handleMenuAction(String action, Khutbah khutbah) async {
    switch (action) {
      case 'edit':
        _editKhutbah(khutbah);
        break;
      case 'duplicate':
        final duplicatedKhutbah = khutbah.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '${khutbah.title} (Copy)',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
        await UserDataService.saveKhutbah(duplicatedKhutbah);
        _loadKhutbahs();
        break;
      case 'delete':
        _showDeleteDialog(khutbah);
        break;
    }
  }

  void _showDeleteDialog(Khutbah khutbah) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Khutbah'),
        content: Text('Are you sure you want to delete "${khutbah.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await UserDataService.deleteKhutbah(khutbah.id);
              _loadKhutbahs();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RichEditorScreen()),
    ).then((_) => _loadKhutbahs());
  }

  void _editKhutbah(Khutbah khutbah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RichEditorScreen(existingKhutbah: khutbah),
      ),
    ).then((_) => _loadKhutbahs());
  }

  Future<void> _importHtml() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['html', 'htm'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final data = file.bytes;
      if (data == null) {
        _showSnack('Failed to read the selected file');
        return;
      }
      final htmlString = String.fromCharCodes(data);
      final khutbah = HtmlImportService.parseHtmlToKhutbah(htmlString);
      await UserDataService.saveKhutbah(khutbah);
      _showSnack('Imported "${khutbah.title}"');
      await _loadKhutbahs();
    } catch (e) {
      _showSnack('Import failed: $e');
    }
  }

  void _showTemplateDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TemplatesScreen()),
    ).then((_) => _loadKhutbahs());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
