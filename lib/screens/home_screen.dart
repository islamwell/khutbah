import 'package:flutter/material.dart';
import 'package:pulpitflow/screens/rich_editor_screen.dart';
import 'package:pulpitflow/screens/library_screen.dart';
import 'package:pulpitflow/screens/templates_screen.dart';
import 'package:pulpitflow/screens/content_library_screen.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/services/user_data_service.dart';
import 'package:pulpitflow/l10n/app_localizations.dart';
import 'package:pulpitflow/utils/app_settings.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Khutbah> recentKhutbahs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentKhutbahs();
  }

  Future<void> _loadRecentKhutbahs() async {
    try {
      final allKhutbahs = await UserDataService.getAllKhutbahs();
      setState(() {
        recentKhutbahs = allKhutbahs.take(3).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l),
              const SizedBox(height: 32),
              _buildQuickActions(l),
              const SizedBox(height: 32),
              _buildRecentKhutbahs(l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('app_title'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l.t('tagline'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l.t('bismillah'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: l.t('settings'),
          onPressed: _openSettingsSheet,
          icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildQuickActions(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.t('quick_actions'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: l.t('new_khutbah'),
                subtitle: l.t('start_from_scratch'),
                onTap: () => _navigateToEditor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.description_outlined,
                title: l.t('templates'),
                subtitle: l.t('use_template'),
                onTap: () => _navigateToTemplates(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.library_books_outlined,
                title: l.t('my_library'),
                subtitle: l.t('browse_saved'),
                onTap: () => _navigateToLibrary(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.search,
                title: l.t('content_library'),
                subtitle: l.t('research_verses_hadith'),
                onTap: () => _navigateToEditor(showContentLibrary: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.event_note_outlined,
                title: 'Speech Logs',
                subtitle: 'Track your deliveries',
                onTap: () => _navigateToSpeechLogs(),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()), // Empty space for symmetry
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentKhutbahs(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.t('recent_khutbahs'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (recentKhutbahs.isNotEmpty)
              TextButton(
                onPressed: _navigateToLibrary,
                child: Text(
                  l.t('view_all'),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (recentKhutbahs.isEmpty)
          _buildEmptyState(l)
        else
          ...recentKhutbahs.map((khutbah) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildKhutbahCard(khutbah, l),
              )),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            l.t('no_khutbahs'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l.t('create_first'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKhutbahCard(Khutbah khutbah, AppLocalizations l) {
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
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    khutbah.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(khutbah.modifiedAt, l),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l) {
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

  void _navigateToEditor({bool showContentLibrary = false}) {
    if (showContentLibrary) {
      // Navigate directly to content library
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContentLibraryScreen(
            showAppBar: true,
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RichEditorScreen(),
        ),
      ).then((_) => _loadRecentKhutbahs());
    }
  }

  void _navigateToTemplates() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TemplatesScreen()),
    ).then((_) => _loadRecentKhutbahs());
  }

  void _navigateToLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LibraryScreen()),
    ).then((_) => _loadRecentKhutbahs());
  }

  void _navigateToSpeechLogs() {
    Navigator.pushNamed(context, '/speech-logs');
  }

  void _editKhutbah(Khutbah khutbah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RichEditorScreen(existingKhutbah: khutbah),
      ),
    ).then((_) => _loadRecentKhutbahs());
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _SettingsModal(onLogout: _logout),
    );
  }

  Future<void> _logout() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      if (mounted) {
        // Navigate to login screen
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SettingsModal extends StatefulWidget {
  final Future<void> Function() onLogout;

  const _SettingsModal({required this.onLogout});

  @override
  State<_SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<_SettingsModal> {
  late ThemeMode currentTheme;
  late Locale currentLocale;

  @override
  void initState() {
    super.initState();
    currentTheme = AppSettings.instance.themeMode;
    currentLocale = AppSettings.instance.locale;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    
    // Get user email from Supabase
    final userEmail = SupabaseConfig.client.auth.currentUser?.email ?? 'User';
    final userName = userEmail.split('@').first;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting with logout icon (right-justified)
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assalamo alaykum',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.onLogout();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red, size: 24),
                  tooltip: 'Logout',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l.t('theme'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: Text(l.t('light')),
                  selected: currentTheme == ThemeMode.light,
                  onSelected: (_) {
                    setState(() {
                      currentTheme = ThemeMode.light;
                    });
                    AppSettings.instance.setThemeMode(ThemeMode.light);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l.t('dark')),
                  selected: currentTheme == ThemeMode.dark,
                  onSelected: (_) {
                    setState(() {
                      currentTheme = ThemeMode.dark;
                    });
                    AppSettings.instance.setThemeMode(ThemeMode.dark);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l.t('language'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LangChip(
                  code: 'en', 
                  label: l.t('english'), 
                  selected: currentLocale.languageCode == 'en',
                  onSelected: () {
                    setState(() {
                      currentLocale = const Locale('en');
                    });
                    AppSettings.instance.setLocale(const Locale('en'));
                  },
                ),
                _LangChip(
                  code: 'ur', 
                  label: l.t('urdu'), 
                  selected: currentLocale.languageCode == 'ur',
                  onSelected: () {
                    setState(() {
                      currentLocale = const Locale('ur');
                    });
                    AppSettings.instance.setLocale(const Locale('ur'));
                  },
                ),
                _LangChip(
                  code: 'no', 
                  label: l.t('norsk'), 
                  selected: currentLocale.languageCode == 'no',
                  onSelected: () {
                    setState(() {
                      currentLocale = const Locale('no');
                    });
                    AppSettings.instance.setLocale(const Locale('no'));
                  },
                ),
                _LangChip(
                  code: 'fr', 
                  label: l.t('french'), 
                  selected: currentLocale.languageCode == 'fr',
                  onSelected: () {
                    setState(() {
                      currentLocale = const Locale('fr');
                    });
                    AppSettings.instance.setLocale(const Locale('fr'));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _LangChip({
    required this.code, 
    required this.label, 
    required this.selected,
    required this.onSelected,
  });

  // Map language codes to flag emojis
  String _getFlagEmoji(String code) {
    switch (code) {
      case 'en':
        return '🇬🇧';
      case 'ur':
        return '🇵🇰';
      case 'no':
        return '🇳🇴';
      case 'fr':
        return '🇫🇷';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final flag = _getFlagEmoji(code);
    return ChoiceChip(
      label: Text('$flag $label'),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
