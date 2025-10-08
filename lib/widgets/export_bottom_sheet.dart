import 'package:flutter/material.dart';

enum ExportOption {
  // savePDFWithPicker, // Commented out for next version
  // printPDF, // Commented out for next version
  sharePDF,
  shareHTML,
  copyPlainText,
}

class ExportBottomSheet extends StatelessWidget {
  final String title;
  final String content;
  final Function(ExportOption) onOptionSelected;

  const ExportBottomSheet({
    Key? key,
    required this.title,
    required this.content,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Export Options',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // PDF Options
          // Commented out for next version - file picker issues
          // _buildExportOption(
          //   context,
          //   icon: Icons.picture_as_pdf,
          //   title: 'Save PDF',
          //   subtitle: 'Choose location and save as PDF',
          //   onTap: () => _handleOptionTap(context, ExportOption.savePDFWithPicker),
          // ),
          
          // _buildExportOption(
          //   context,
          //   icon: Icons.print,
          //   title: 'Print PDF',
          //   subtitle: 'Print document directly',
          //   onTap: () => _handleOptionTap(context, ExportOption.printPDF),
          // ),
          
          _buildExportOption(
            context,
            icon: Icons.share,
            title: 'Share PDF',
            subtitle: 'Share PDF with others',
            onTap: () => _handleOptionTap(context, ExportOption.sharePDF),
          ),

          // Divider
          const Divider(height: 1, thickness: 1),

          // HTML Options
          _buildExportOption(
            context,
            icon: Icons.share_outlined,
            title: 'Share HTML',
            subtitle: 'Share as web page format',
            onTap: () => _handleOptionTap(context, ExportOption.shareHTML),
          ),

          // Divider
          const Divider(height: 1, thickness: 1),

          // Plain Text Option
          _buildExportOption(
            context,
            icon: Icons.content_copy,
            title: 'Copy Plain Text',
            subtitle: 'Copy text to clipboard',
            onTap: () => _handleOptionTap(context, ExportOption.copyPlainText),
          ),

          // Bottom padding for safe area
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _handleOptionTap(BuildContext context, ExportOption option) {
    Navigator.pop(context);
    onOptionSelected(option);
  }

  /// Static method to show the export bottom sheet
  static void show(
    BuildContext context, {
    required String title,
    required String content,
    required Function(ExportOption) onOptionSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportBottomSheet(
        title: title,
        content: content,
        onOptionSelected: onOptionSelected,
      ),
    );
  }
}