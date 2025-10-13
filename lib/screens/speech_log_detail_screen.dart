import 'package:flutter/material.dart';
import 'package:pulpitflow/models/speech_log.dart';
import 'package:pulpitflow/services/speech_log_service.dart';
import 'package:pulpitflow/screens/speech_log_form_screen.dart';
import 'package:pulpitflow/utils/page_transitions.dart';

class SpeechLogDetailScreen extends StatefulWidget {
  final SpeechLog log;

  const SpeechLogDetailScreen({super.key, required this.log});

  @override
  State<SpeechLogDetailScreen> createState() => _SpeechLogDetailScreenState();
}

class _SpeechLogDetailScreenState extends State<SpeechLogDetailScreen> {
  bool _isDeleting = false;

  Future<void> _editLog() async {
    final result = await Navigator.push<bool>(
      context,
      SlidePageRoute(
        page: SpeechLogFormScreen(existingLog: widget.log),
        direction: AxisDirection.left,
      ),
    );

    if (result == true && mounted) {
      // Log was updated, navigate back to refresh the list
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteLog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Speech Log'),
        content: const Text(
          'Are you sure you want to delete this speech log? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await SpeechLogService.deleteSpeechLog(widget.log.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech log deleted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete speech log: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Speech Log Details',
          semanticsLabel: 'Speech Log Details Screen',
        ),
        actions: [
          Semantics(
            label: 'Edit speech log',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _isDeleting ? null : _editLog,
              tooltip: 'Edit',
              iconSize: 24,
            ),
          ),
          Semantics(
            label: _isDeleting ? 'Deleting speech log' : 'Delete speech log',
            button: true,
            child: IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : _deleteLog,
              tooltip: 'Delete',
              iconSize: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpeechTitleSection(),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            if (widget.log.audienceSize != null || 
                (widget.log.audienceDemographics?.isNotEmpty ?? false))
              ...[
                _buildAudienceSection(),
                const SizedBox(height: 24),
              ],
            if (widget.log.positiveFeedback.isNotEmpty)
              ...[
                _buildPositiveFeedbackSection(),
                const SizedBox(height: 24),
              ],
            if (widget.log.negativeFeedback.isNotEmpty)
              ...[
                _buildNegativeFeedbackSection(),
                const SizedBox(height: 24),
              ],
            if (widget.log.generalNotes.isNotEmpty)
              ...[
                _buildGeneralNotesSection(),
                const SizedBox(height: 24),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechTitleSection() {
    // Check if this is an archived log (khutbah might be deleted)
    final isArchived = widget.log.khutbahTitle.startsWith('[Archived]');
    
    return Card(
      elevation: 0,
      color: isArchived 
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isArchived ? Icons.archive_outlined : Icons.article_outlined,
                  color: isArchived
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isArchived ? 'Archived Speech' : 'Speech',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isArchived
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.log.khutbahTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isArchived
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (isArchived) ...[
              const SizedBox(height: 8),
              Text(
                'The original speech has been deleted',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'View full speech details',
                button: true,
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: Navigate to khutbah detail/editor screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigation to speech details coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View Speech'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Delivery Date',
              _formatDate(widget.log.deliveryDate),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Location',
              widget.log.location,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.event_outlined,
              'Event Type',
              widget.log.eventType,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audience Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            if (widget.log.audienceSize != null)
              ...[
                _buildInfoRow(
                  Icons.people_outline,
                  'Audience Size',
                  '${widget.log.audienceSize} attendees',
                ),
                if (widget.log.audienceDemographics?.isNotEmpty ?? false)
                  const SizedBox(height: 12),
              ],
            if (widget.log.audienceDemographics?.isNotEmpty ?? false)
              _buildInfoRow(
                Icons.groups_outlined,
                'Demographics',
                widget.log.audienceDemographics!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositiveFeedbackSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.thumb_up,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Positive Feedback',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.log.positiveFeedback,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNegativeFeedbackSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.thumb_down,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Areas for Improvement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.log.negativeFeedback,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralNotesSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'General Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.log.generalNotes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;

    return '$weekday, $month $day, $year';
  }
}
