import 'package:flutter/material.dart';
import 'package:pulpitflow/models/speech_log.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/services/speech_log_service.dart';
import 'package:pulpitflow/services/khutbah_service.dart';
import 'package:pulpitflow/screens/speech_log_form_screen.dart';
import 'package:pulpitflow/screens/speech_log_detail_screen.dart';
import 'package:pulpitflow/utils/page_transitions.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class SpeechLogsScreen extends StatefulWidget {
  const SpeechLogsScreen({super.key});

  @override
  State<SpeechLogsScreen> createState() => _SpeechLogsScreenState();
}

class _SpeechLogsScreenState extends State<SpeechLogsScreen> {
  final SpeechLogService _speechLogService = SpeechLogService();
  List<SpeechLog> _logs = [];
  List<Khutbah> _khutbahs = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter state
  String? _selectedKhutbahId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedEventType;
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  
  // Filter UI state
  bool _showFilters = false;
  
  // Common event types
  final List<String> _eventTypes = [
    'Jummah',
    'Wedding',
    'Conference',
    'Community Gathering',
    'Funeral',
    'Eid',
    'Lecture',
    'Workshop',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadKhutbahs();
    _loadLogs();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadKhutbahs() async {
    try {
      final khutbahs = await KhutbahService.getUserKhutbahs();
      setState(() {
        _khutbahs = khutbahs;
      });
    } catch (e) {
      // Silently fail - filters will just not show khutbahs
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await SpeechLogService.getFilteredSpeechLogs(
        khutbahId: _selectedKhutbahId?.isEmpty == true ? null : _selectedKhutbahId,
        startDate: _startDate,
        endDate: _endDate,
        eventType: _selectedEventType?.isEmpty == true ? null : _selectedEventType,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load speech logs: $e';
        _isLoading = false;
      });
    }
  }
  
  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadLogs();
    });
  }
  
  void _clearFilters() {
    setState(() {
      _selectedKhutbahId = null;
      _startDate = null;
      _endDate = null;
      _selectedEventType = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadLogs();
  }
  
  bool get _hasActiveFilters {
    return _selectedKhutbahId != null ||
        _startDate != null ||
        _endDate != null ||
        _selectedEventType != null ||
        _searchQuery.isNotEmpty;
  }

  Future<void> _onRefresh() async {
    await _loadLogs();
  }

  void _navigateToForm({SpeechLog? log}) async {
    final result = await Navigator.push<bool>(
      context,
      SlidePageRoute(
        page: SpeechLogFormScreen(existingLog: log),
        direction: AxisDirection.left,
      ),
    );

    // Reload logs if form was saved
    if (result == true) {
      _loadLogs();
    }
  }

  void _navigateToDetail(SpeechLog log) async {
    final result = await Navigator.push<bool>(
      context,
      SlidePageRoute(
        page: SpeechLogDetailScreen(log: log),
        direction: AxisDirection.left,
      ),
    );

    // Reload logs if detail screen made changes (edit/delete)
    if (result == true) {
      _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Speech Logs',
          semanticsLabel: 'Speech Logs Screen',
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
            iconSize: 24,
          ),
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear All Filters',
              iconSize: 24,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFilterSection(),
          if (_hasActiveFilters) _buildActiveFiltersChips(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Create new speech log',
        button: true,
        child: FloatingActionButton(
          onPressed: () => _navigateToForm(),
          tooltip: 'Create Speech Log',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Semantics(
        label: 'Search speech logs by location or event type',
        textField: true,
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search by location or event type...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    tooltip: 'Clear search',
                    iconSize: 24,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Speech filter
          DropdownButtonFormField<String>(
            value: _selectedKhutbahId,
            decoration: InputDecoration(
              labelText: 'Speech',
              prefixIcon: const Icon(Icons.article_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Speeches'),
              ),
              ..._khutbahs.map((khutbah) => DropdownMenuItem<String>(
                value: khutbah.id,
                child: Text(
                  khutbah.title,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedKhutbahId = value;
              });
              _loadLogs();
            },
          ),
          const SizedBox(height: 12),
          
          // Event type filter
          DropdownButtonFormField<String>(
            value: _selectedEventType,
            decoration: InputDecoration(
              labelText: 'Event Type',
              prefixIcon: const Icon(Icons.event),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Event Types'),
              ),
              ..._eventTypes.map((type) => DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedEventType = value;
              });
              _loadLogs();
            },
          ),
          const SizedBox(height: 12),
          
          // Date range filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectStartDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _startDate != null
                        ? DateFormat('MMM d, yyyy').format(_startDate!)
                        : 'Start Date',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectEndDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _endDate != null
                        ? DateFormat('MMM d, yyyy').format(_endDate!)
                        : 'End Date',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildActiveFiltersChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedKhutbahId != null)
            _buildFilterChip(
              label: _khutbahs.firstWhere((k) => k.id == _selectedKhutbahId).title,
              onDeleted: () {
                setState(() {
                  _selectedKhutbahId = null;
                });
                _loadLogs();
              },
            ),
          if (_selectedEventType != null)
            _buildFilterChip(
              label: _selectedEventType!,
              onDeleted: () {
                setState(() {
                  _selectedEventType = null;
                });
                _loadLogs();
              },
            ),
          if (_startDate != null)
            _buildFilterChip(
              label: 'From: ${DateFormat('MMM d, yyyy').format(_startDate!)}',
              onDeleted: () {
                setState(() {
                  _startDate = null;
                });
                _loadLogs();
              },
            ),
          if (_endDate != null)
            _buildFilterChip(
              label: 'To: ${DateFormat('MMM d, yyyy').format(_endDate!)}',
              onDeleted: () {
                setState(() {
                  _endDate = null;
                });
                _loadLogs();
              },
            ),
          if (_searchQuery.isNotEmpty)
            _buildFilterChip(
              label: 'Search: $_searchQuery',
              onDeleted: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 12,
      ),
    );
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _loadLogs();
    }
  }
  
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _loadLogs();
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Semantics(
          label: 'Loading speech logs',
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_logs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          return _buildLogListItem(_logs[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Speech Logs Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your speech deliveries by creating your first log',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Create your first speech log',
              button: true,
              child: FilledButton.icon(
                onPressed: () => _navigateToForm(),
                icon: const Icon(Icons.add),
                label: const Text('Create Log'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Retry loading speech logs',
              button: true,
              child: FilledButton.icon(
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogListItem(SpeechLog log) {
    // Truncate very long titles (over 100 characters)
    final displayTitle = log.khutbahTitle.length > 100
        ? '${log.khutbahTitle.substring(0, 100)}...'
        : log.khutbahTitle;
    
    // Truncate very long locations (over 50 characters)
    final displayLocation = log.location.length > 50
        ? '${log.location.substring(0, 50)}...'
        : log.location;
    
    // Truncate very long event types (over 30 characters)
    final displayEventType = log.eventType.length > 30
        ? '${log.eventType.substring(0, 30)}...'
        : log.eventType;
    
    return Semantics(
      label: 'Speech log: $displayTitle, delivered on ${_formatDate(log.deliveryDate)} at $displayLocation',
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _navigateToDetail(log),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
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
              // Title
              SizedBox(
                width: double.infinity,
                child: Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              
              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDate(log.deliveryDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayLocation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Event Type
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayEventType,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }
}
