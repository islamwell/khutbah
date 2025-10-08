import 'package:flutter/material.dart';
import 'package:pulpitflow/models/content_item.dart';
import 'package:pulpitflow/utils/constants.dart';

class ContentSearchWidget extends StatefulWidget {
  final Function(List<ContentItem>) onSearchResults;
  final Function(String) onSearchQuery;

  const ContentSearchWidget({
    super.key,
    required this.onSearchResults,
    required this.onSearchQuery,
  });

  @override
  State<ContentSearchWidget> createState() => _ContentSearchWidgetState();
}

class _ContentSearchWidgetState extends State<ContentSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(),
        const SizedBox(height: 16),
        _buildQuickTopics(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: (query) {
          widget.onSearchQuery(query);
        },
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            _performSearch(query.trim());
          }
        },
        decoration: InputDecoration(
          hintText: 'Search Quran, Hadith, or Quotes...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
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

  Widget _buildQuickTopics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Topics',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: AppConstants.commonTopics.take(6).map((topic) {
            return GestureDetector(
              onTap: () => _selectTopic(topic),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  topic,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _selectTopic(String topic) {
    _searchController.text = topic.split('(').first.trim().toLowerCase();
    _focusNode.unfocus();
    _performSearch(_searchController.text);
  }

  void _performSearch(String query) {
    // This would typically call the storage service to search content
    // For now, we'll just notify the parent widget
    widget.onSearchQuery(query);
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchQuery('');
    widget.onSearchResults([]);
  }
}