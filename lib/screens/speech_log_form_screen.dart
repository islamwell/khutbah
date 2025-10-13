import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulpitflow/models/speech_log.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/services/speech_log_service.dart';
import 'package:pulpitflow/services/khutbah_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SpeechLogFormScreen extends StatefulWidget {
  final SpeechLog? existingLog;
  final String? preselectedKhutbahId;
  final String? preselectedKhutbahTitle;

  const SpeechLogFormScreen({
    super.key,
    this.existingLog,
    this.preselectedKhutbahId,
    this.preselectedKhutbahTitle,
  });

  @override
  State<SpeechLogFormScreen> createState() => _SpeechLogFormScreenState();
}

class _SpeechLogFormScreenState extends State<SpeechLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _eventTypeController = TextEditingController();
  final _audienceSizeController = TextEditingController();
  final _audienceDemographicsController = TextEditingController();
  final _positiveFeedbackController = TextEditingController();
  final _negativeFeedbackController = TextEditingController();
  final _generalNotesController = TextEditingController();

  List<Khutbah> _khutbahs = [];
  Khutbah? _selectedKhutbah;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLoadingKhutbahs = true;
  bool _hasUnsavedChanges = false;

  // Common event types for suggestions
  final List<String> _eventTypeSuggestions = [
    'Jummah',
    'Wedding',
    'Conference',
    'Community Gathering',
    'Eid',
    'Funeral',
    'Workshop',
    'Seminar',
    'Youth Event',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadKhutbahs();
    _initializeForm();
    _setupChangeListeners();
    _loadCachedFormData();
  }

  void _setupChangeListeners() {
    _locationController.addListener(_markAsChanged);
    _eventTypeController.addListener(_markAsChanged);
    _audienceSizeController.addListener(_markAsChanged);
    _audienceDemographicsController.addListener(_markAsChanged);
    _positiveFeedbackController.addListener(_markAsChanged);
    _negativeFeedbackController.addListener(_markAsChanged);
    _generalNotesController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
    
    // Save to cache when form changes (only for new logs)
    if (widget.existingLog == null) {
      _saveFormCache();
    }
  }

  Future<void> _loadKhutbahs() async {
    try {
      print('DEBUG: Loading khutbahs from Supabase...');
      
      // Load from Supabase (has proper UUIDs) instead of local storage (has timestamps)
      final khutbahs = await KhutbahService.getUserKhutbahs();
      
      print('DEBUG: Loaded ${khutbahs.length} khutbahs');
      if (khutbahs.isNotEmpty) {
        print('DEBUG: First khutbah ID: ${khutbahs.first.id}');
        print('DEBUG: First khutbah title: ${khutbahs.first.title}');
      }
      
      setState(() {
        _khutbahs = khutbahs;
        _isLoadingKhutbahs = false;
        
        // Set preselected khutbah if provided
        if (widget.preselectedKhutbahId != null && widget.existingLog == null) {
          _selectedKhutbah = khutbahs.firstWhere(
            (k) => k.id == widget.preselectedKhutbahId,
            orElse: () {
              print('WARNING: Preselected khutbah not found: ${widget.preselectedKhutbahId}');
              // Return first khutbah if available, otherwise create dummy
              return khutbahs.isNotEmpty ? khutbahs.first : Khutbah(
                id: widget.preselectedKhutbahId!,
                title: widget.preselectedKhutbahTitle ?? 'Unknown',
                content: '',
                tags: [],
                createdAt: DateTime.now(),
                modifiedAt: DateTime.now(),
                estimatedMinutes: 0,
              );
            },
          );
          print('DEBUG: Selected khutbah ID: ${_selectedKhutbah?.id}');
        }
      });
    } catch (e) {
      print('ERROR: Failed to load khutbahs: $e');
      setState(() {
        _isLoadingKhutbahs = false;
      });
      if (mounted) {
        _showSnackBar('Failed to load speeches: $e', isError: true);
      }
    }
  }

  void _initializeForm() {
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _locationController.text = log.location;
      _eventTypeController.text = log.eventType;
      _audienceSizeController.text = log.audienceSize?.toString() ?? '';
      _audienceDemographicsController.text = log.audienceDemographics ?? '';
      _positiveFeedbackController.text = log.positiveFeedback;
      _negativeFeedbackController.text = log.negativeFeedback;
      _generalNotesController.text = log.generalNotes;
      _selectedDate = log.deliveryDate;
      
      // Find and set the selected khutbah
      _selectedKhutbah = _khutbahs.firstWhere(
        (k) => k.id == log.khutbahId,
        orElse: () => Khutbah(
          id: log.khutbahId,
          title: log.khutbahTitle,
          content: '',
          tags: [],
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          estimatedMinutes: 0,
        ),
      );
      
      _hasUnsavedChanges = false;
    }
  }
  
  /// Load cached form data to prevent data loss
  Future<void> _loadCachedFormData() async {
    // Only load cache for new logs, not when editing
    if (widget.existingLog != null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('speech_log_form_cache');
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        
        // Check if cache is recent (within last 24 hours)
        final cacheTime = DateTime.parse(data['cached_at'] as String);
        final now = DateTime.now();
        if (now.difference(cacheTime).inHours > 24) {
          // Cache is too old, clear it
          await _clearFormCache();
          return;
        }
        
        // Restore form data
        setState(() {
          _locationController.text = data['location'] ?? '';
          _eventTypeController.text = data['event_type'] ?? '';
          _audienceSizeController.text = data['audience_size'] ?? '';
          _audienceDemographicsController.text = data['audience_demographics'] ?? '';
          _positiveFeedbackController.text = data['positive_feedback'] ?? '';
          _negativeFeedbackController.text = data['negative_feedback'] ?? '';
          _generalNotesController.text = data['general_notes'] ?? '';
          
          if (data['delivery_date'] != null) {
            _selectedDate = DateTime.parse(data['delivery_date'] as String);
          }
          
          if (data['khutbah_id'] != null) {
            _selectedKhutbah = _khutbahs.firstWhere(
              (k) => k.id == data['khutbah_id'],
              orElse: () => _khutbahs.isNotEmpty ? _khutbahs.first : _selectedKhutbah!,
            );
          }
        });
        
        // Show snackbar to inform user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restored unsaved form data'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail - caching is a nice-to-have feature
      debugPrint('Failed to load cached form data: $e');
    }
  }
  
  /// Save form data to cache
  Future<void> _saveFormCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'khutbah_id': _selectedKhutbah?.id,
        'delivery_date': _selectedDate?.toIso8601String(),
        'location': _locationController.text,
        'event_type': _eventTypeController.text,
        'audience_size': _audienceSizeController.text,
        'audience_demographics': _audienceDemographicsController.text,
        'positive_feedback': _positiveFeedbackController.text,
        'negative_feedback': _negativeFeedbackController.text,
        'general_notes': _generalNotesController.text,
        'cached_at': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString('speech_log_form_cache', jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save form cache: $e');
    }
  }
  
  /// Clear form cache
  Future<void> _clearFormCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('speech_log_form_cache');
    } catch (e) {
      debugPrint('Failed to clear form cache: $e');
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _eventTypeController.dispose();
    _audienceSizeController.dispose();
    _audienceDemographicsController.dispose();
    _positiveFeedbackController.dispose();
    _negativeFeedbackController.dispose();
    _generalNotesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Select Delivery Date',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors in the form', isError: true);
      return;
    }

    if (_selectedKhutbah == null) {
      _showSnackBar('Please select a speech', isError: true);
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Please select a delivery date', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== FORM SAVE DEBUG ===');
      print('Selected Khutbah ID: ${_selectedKhutbah!.id}');
      print('Selected Khutbah Title: ${_selectedKhutbah!.title}');
      print('Selected Date: $_selectedDate');
      print('Location: ${_locationController.text.trim()}');
      print('Event Type: ${_eventTypeController.text.trim()}');
      
      final audienceSize = _audienceSizeController.text.trim().isEmpty
          ? null
          : int.tryParse(_audienceSizeController.text.trim());

      final log = SpeechLog(
        id: widget.existingLog?.id ?? '', // Empty string for new logs - Supabase will generate UUID
        khutbahId: _selectedKhutbah!.id,
        khutbahTitle: _selectedKhutbah!.title,
        deliveryDate: _selectedDate!,
        location: _locationController.text.trim(),
        eventType: _eventTypeController.text.trim(),
        audienceSize: audienceSize,
        audienceDemographics: _audienceDemographicsController.text.trim().isEmpty
            ? null
            : _audienceDemographicsController.text.trim(),
        positiveFeedback: _positiveFeedbackController.text.trim(),
        negativeFeedback: _negativeFeedbackController.text.trim(),
        generalNotes: _generalNotesController.text.trim(),
        createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      print('SpeechLog object created with khutbahId: ${log.khutbahId}');
      print('=== END FORM DEBUG ===\n');

      if (widget.existingLog != null) {
        await SpeechLogService.updateSpeechLog(log);
        _showSnackBar('Speech log updated successfully');
      } else {
        await SpeechLogService.createSpeechLog(log);
        _showSnackBar('Speech log created successfully');
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      // Clear cache after successful save
      await _clearFormCache();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Failed to save speech log: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingLog != null ? 'Edit Speech Log' : 'New Speech Log',
            semanticsLabel: widget.existingLog != null 
                ? 'Edit Speech Log Form' 
                : 'New Speech Log Form',
          ),
          actions: [
            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Semantics(
                    label: 'Saving speech log',
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              )
            else
              Semantics(
                label: 'Save speech log',
                button: true,
                child: TextButton(
                  onPressed: _saveLog,
                  child: const Text('Save'),
                ),
              ),
          ],
        ),
        body: _isLoadingKhutbahs
            ? Center(
                child: Semantics(
                  label: 'Loading speeches',
                  child: const CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Speech Details'),
                      const SizedBox(height: 12),
                      _buildSpeechSelector(),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Event Information'),
                      const SizedBox(height: 12),
                      _buildLocationField(),
                      const SizedBox(height: 16),
                      _buildEventTypeField(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Audience Details (Optional)'),
                      const SizedBox(height: 12),
                      _buildAudienceSizeField(),
                      const SizedBox(height: 16),
                      _buildAudienceDemographicsField(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Feedback & Reflections'),
                      const SizedBox(height: 12),
                      _buildPositiveFeedbackField(),
                      const SizedBox(height: 16),
                      _buildNegativeFeedbackField(),
                      const SizedBox(height: 16),
                      _buildGeneralNotesField(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildSpeechSelector() {
    return Semantics(
      label: 'Select speech or khutbah, required field',
      child: DropdownButtonFormField<Khutbah>(
        value: _selectedKhutbah,
        decoration: InputDecoration(
          labelText: 'Speech / Khutbah *',
          hintText: 'Select a speech',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: const Icon(Icons.article_outlined),
        ),
        items: _khutbahs.map((khutbah) {
          return DropdownMenuItem(
            value: khutbah,
            child: Text(
              khutbah.title,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: _isLoading
            ? null
            : (value) {
                setState(() {
                  _selectedKhutbah = value;
                  _hasUnsavedChanges = true;
                });
              },
        validator: (value) {
          if (value == null) {
            return 'Please select a speech';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return Semantics(
      label: 'Select delivery date, required field. ${_selectedDate != null ? "Currently selected: ${_formatDate(_selectedDate!)}" : "No date selected"}',
      button: true,
      child: InkWell(
        onTap: _isLoading ? null : _selectDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Delivery Date *',
            hintText: 'Select date',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.calendar_today),
            errorText: _selectedDate == null && _hasUnsavedChanges
                ? 'Please select a delivery date'
                : null,
          ),
          child: Text(
            _selectedDate != null
                ? _formatDate(_selectedDate!)
                : 'Tap to select date',
            style: TextStyle(
              color: _selectedDate != null
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Location *',
        hintText: 'e.g., Main Street Masjid',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.location_on_outlined),
      ),
      enabled: !_isLoading,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a location';
        }
        return null;
      },
    );
  }

  Widget _buildEventTypeField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _eventTypeController.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _eventTypeSuggestions;
        }
        return _eventTypeSuggestions.where((option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (value) {
        _eventTypeController.text = value;
        _hasUnsavedChanges = true;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Sync with our main controller
        if (controller.text != _eventTypeController.text) {
          controller.text = _eventTypeController.text;
        }
        controller.addListener(() {
          if (_eventTypeController.text != controller.text) {
            _eventTypeController.text = controller.text;
          }
        });

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Event Type *',
            hintText: 'e.g., Jummah, Wedding, Conference',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.event_outlined),
          ),
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an event type';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildAudienceSizeField() {
    return TextFormField(
      controller: _audienceSizeController,
      decoration: InputDecoration(
        labelText: 'Audience Size',
        hintText: 'Estimated number of attendees',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.people_outline),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      enabled: !_isLoading,
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final number = int.tryParse(value.trim());
          if (number == null || number <= 0) {
            return 'Please enter a valid positive number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildAudienceDemographicsField() {
    return TextFormField(
      controller: _audienceDemographicsController,
      decoration: InputDecoration(
        labelText: 'Audience Demographics',
        hintText: 'e.g., Mostly youth, Mixed ages, Families',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.groups_outlined),
      ),
      maxLines: 2,
      enabled: !_isLoading,
    );
  }

  Widget _buildPositiveFeedbackField() {
    return TextFormField(
      controller: _positiveFeedbackController,
      decoration: InputDecoration(
        labelText: 'Positive Feedback',
        hintText: 'What went well? What resonated with the audience?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.thumb_up_outlined),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      enabled: !_isLoading,
    );
  }

  Widget _buildNegativeFeedbackField() {
    return TextFormField(
      controller: _negativeFeedbackController,
      decoration: InputDecoration(
        labelText: 'Areas for Improvement',
        hintText: 'What could be improved? What didn\'t work as expected?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.thumb_down_outlined),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      enabled: !_isLoading,
    );
  }

  Widget _buildGeneralNotesField() {
    return TextFormField(
      controller: _generalNotesController,
      decoration: InputDecoration(
        labelText: 'General Notes',
        hintText: 'Any other observations or reflections...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.notes_outlined),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      enabled: !_isLoading,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Cancel and discard changes',
            button: true,
            child: OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_hasUnsavedChanges) {
                        final shouldLeave = await _onWillPop();
                        if (shouldLeave && mounted) {
                          Navigator.pop(context);
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            label: _isLoading ? 'Saving speech log' : 'Save speech log',
            button: true,
            child: FilledButton(
              onPressed: _isLoading ? null : _saveLog,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Log'),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;

    return '$weekday, $month $day, $year';
  }
}
