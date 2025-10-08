import 'package:flutter/material.dart';

class RichTextToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onBulletList;
  final VoidCallback onNumberedList;
  final VoidCallback onToggleRtl;
  final bool isRtlMode;
  final int estimatedMinutes;

  const RichTextToolbar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onBulletList,
    required this.onNumberedList,
    required this.onToggleRtl,
    required this.isRtlMode,
    required this.estimatedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            context,
            Icons.format_bold,
            'Bold',
            onBold,
          ),
          _buildToolbarButton(
            context,
            Icons.format_italic,
            'Italic',
            onItalic,
          ),
          _buildDivider(context),
          _buildToolbarButton(
            context,
            Icons.format_list_bulleted,
            'Bullet List',
            onBulletList,
          ),
          _buildToolbarButton(
            context,
            Icons.format_list_numbered,
            'Numbered List',
            onNumberedList,
          ),
          _buildDivider(context),
          _buildToolbarButton(
            context,
            isRtlMode ? Icons.format_textdirection_l_to_r : Icons.format_textdirection_r_to_l,
            isRtlMode ? 'Switch to LTR' : 'Switch to RTL',
            onToggleRtl,
            isActive: isRtlMode,
          ),
          const Spacer(),
          _buildEstimatedTime(context),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: isActive
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.all(6),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
    );
  }

  Widget _buildEstimatedTime(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '$estimatedMinutes min',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class FormattingHelper {
  static String applyBold(String text, TextSelection selection) {
    return _applyFormatting(text, selection, '**', '**');
  }

  static String applyItalic(String text, TextSelection selection) {
    return _applyFormatting(text, selection, '*', '*');
  }

  static String addBulletPoint(String text, int position) {
    return _insertAtPosition(text, position, '• ');
  }

  static String addNumberedPoint(String text, int position) {
    return _insertAtPosition(text, position, '1. ');
  }

  static String _applyFormatting(
    String text,
    TextSelection selection,
    String prefix,
    String suffix,
  ) {
    if (!selection.isValid || selection.isCollapsed) {
      return text;
    }

    final selectedText = text.substring(selection.start, selection.end);
    final formattedText = '$prefix$selectedText$suffix';
    
    return text.replaceRange(selection.start, selection.end, formattedText);
  }

  static String _insertAtPosition(String text, int position, String insertion) {
    return text.substring(0, position) + insertion + text.substring(position);
  }

  static int estimateReadingTime(String text) {
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    
    // Average reading speed: 150 words per minute
    // Minimum 5 minutes, maximum 60 minutes
    return (wordCount / 150).ceil().clamp(5, 60);
  }
}