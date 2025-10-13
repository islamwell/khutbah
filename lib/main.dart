import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pulpitflow/theme.dart';
import 'package:pulpitflow/widgets/auth_wrapper.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';
import 'package:pulpitflow/utils/app_settings.dart';
import 'package:pulpitflow/l10n/app_localizations.dart';
import 'package:pulpitflow/screens/home_screen.dart';
import 'package:pulpitflow/screens/speech_logs_screen.dart';
import 'package:pulpitflow/screens/speech_log_detail_screen.dart';
import 'package:pulpitflow/screens/speech_log_form_screen.dart';
import 'package:pulpitflow/screens/filtered_speech_logs_screen.dart';
import 'package:pulpitflow/models/speech_log.dart';
import 'package:pulpitflow/services/storage_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Supabase with error handling
    try {
      await SupabaseConfig.initialize();
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
      // Continue without Supabase for now
    }

    // Load persisted app settings (theme, locale) with error handling
    try {
      await AppSettings.instance.load();
    } catch (e) {
      debugPrint('App settings load error: $e');
      // Continue with default settings
    }

    // Update content library with new Quran ayats
    try {
      await StorageService.updateContentLibrary();
    } catch (e) {
      debugPrint('Content library update error: $e');
      // Continue without content update
    }
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Main initialization error: $e');
    // Run a fallback app
    runApp(const FallbackApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Al-Minbar',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: AppSettings.instance.themeMode,
          locale: AppSettings.instance.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          home: const AuthWrapper(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/speech-logs': (context) => const SpeechLogsScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle routes with parameters
            if (settings.name == '/speech-log-detail') {
              final log = settings.arguments as SpeechLog;
              return MaterialPageRoute(
                builder: (context) => SpeechLogDetailScreen(log: log),
              );
            }
            if (settings.name == '/speech-log-form') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => SpeechLogFormScreen(
                  existingLog: args?['existingLog'] as SpeechLog?,
                  preselectedKhutbahId: args?['preselectedKhutbahId'] as String?,
                  preselectedKhutbahTitle: args?['preselectedKhutbahTitle'] as String?,
                ),
              );
            }
            if (settings.name == '/filtered-speech-logs') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => FilteredSpeechLogsScreen(
                  khutbahId: args['khutbahId'] as String,
                  khutbahTitle: args['khutbahTitle'] as String,
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-Minbar',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Al-Minbar'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Al-Minbar',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Initialization Error',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              SizedBox(height: 16),
              Text(
                'Please check the logs for more details.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
