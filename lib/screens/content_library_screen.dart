import 'package:flutter/material.dart';
import 'package:pulpitflow/models/content_item.dart';
import 'package:pulpitflow/services/content_data_service.dart';
import 'package:pulpitflow/screens/add_content_screen.dart';

class ContentLibraryScreen extends StatefulWidget {
  final Function(ContentItem)? onContentSelected;
  final bool showAppBar;
  final VoidCallback? onBack;

  const ContentLibraryScreen({
    super.key, 
    this.onContentSelected,
    this.showAppBar = true,
    this.onBack,
  });

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<ContentItem> allContent = [];
  List<ContentItem> quranContent = [];
  List<ContentItem> hadithContent = [];
  List<ContentItem> quotesContent = [];
  List<ContentItem> searchResults = [];
  
  bool isLoading = true;
  bool isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_performSearch);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      // Load content from both local and cloud sources
      final quran = await ContentDataService.getContentByType(ContentType.quran);
      final hadith = await ContentDataService.getContentByType(ContentType.hadith);
      final quotes = await ContentDataService.getContentByType(ContentType.quote);
      
      setState(() {
        quranContent = quran;
        hadithContent = hadith;
        quotesContent = quotes;
        allContent = [...quran, ...hadith, ...quotes];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        isSearchMode = false;
        searchResults.clear();
      } else {
        isSearchMode = true;
        searchResults = allContent.where((item) {
          final searchQuery = query.toLowerCase();
          return item.keywords.any((keyword) => keyword.toLowerCase().contains(searchQuery)) ||
                 item.text.toLowerCase().contains(searchQuery) ||
                 item.translation.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddContent() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddContentScreen(),
      ),
    );
    
    if (result == true) {
      _loadContent(); // Refresh the content
    }
  }

  Future<void> _handleContentAction(String action, ContentItem item) async {
    switch (action) {
      case 'add':
        if (widget.onContentSelected != null) {
          widget.onContentSelected!(item);
        }
        break;
      case 'edit':
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => AddContentScreen(editingItem: item),
          ),
        );
        if (result == true) {
          _loadContent();
        }
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  Future<void> _showDeleteConfirmation(ContentItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete this ${item.type.name}?\n\n"${item.translation.length > 100 ? "${item.translation.substring(0, 100)}..." : item.translation}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await ContentDataService.deleteContentItem(item.id);
        _loadContent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Content deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting content: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStandalone = widget.onContentSelected == null;
    
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Content Library'),
        elevation: 0,
        leading: widget.onBack != null ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddContent,
            tooltip: 'Add Custom Content',
          ),
        ],
        bottom: isSearchMode ? null : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Quran'),
            Tab(text: 'Hadith'),
            Tab(text: 'Quotes'),
          ],
        ),
      ) : null,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isSearchMode
                    ? _buildSearchResults()
                    : _buildTabContent(),
          ),
          // Add bottom padding to prevent FAB from covering content
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddContent,
        icon: const Icon(Icons.add),
        label: const Text('Add Content'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
          hintText: 'Search for topics (e.g., gratitude, patience)...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      isSearchMode = false;
                      searchResults.clear();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return _buildEmptyState('No content found for "${_searchController.text}"');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return _buildContentCard(searchResults[index]);
      },
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildContentList(quranContent, 'No Quran verses available'),
        _buildContentList(hadithContent, 'No Hadith available'),
        _buildContentList(quotesContent, 'No quotes available'),
      ],
    );
  }

  Widget _buildContentList(List<ContentItem> content, String emptyMessage) {
    if (content.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: content.length,
      itemBuilder: (context, index) {
        return _buildContentCard(content[index]);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(ContentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header with type and source
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTypeColor(item.type).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getTypeIcon(item.type),
                  color: _getTypeColor(item.type),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.displaySource,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getTypeColor(item.type),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 40,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) => _handleContentAction(value, item),
                    itemBuilder: (context) => [
                      if (widget.onContentSelected != null)
                        PopupMenuItem(
                          value: 'add',
                          child: ListTile(
                            leading: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                            title: const Text('Add to Khutbah'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Arabic text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              item.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          
          // Translation
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item.translation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          // Keywords
          if (item.keywords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: item.keywords.take(3).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      keyword,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(ContentType type) {
    switch (type) {
      case ContentType.quran:
        return Colors.green;
      case ContentType.hadith:
        return Colors.blue;
      case ContentType.quote:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.quran:
        return Icons.menu_book;
      case ContentType.hadith:
        return Icons.format_quote;
      case ContentType.quote:
        return Icons.lightbulb_outline;
    }
  }
}