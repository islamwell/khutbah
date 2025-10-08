import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
    Locale('no'), // Norsk
    Locale('fr'),
  ];

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? result = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Simple key-based translations. For larger apps consider ARB + gen-l10n.
  static final Map<String, Map<String, String>> _values = {
    'en': {
      'app_title': 'NQ Khutbah Companion',
      'tagline': 'Easy way to Create and Give Speeches',
      'bismillah': 'In the name of Allah, Check your intention and ask Allah for Ikhlas',
      'quick_actions': 'Quick Actions',
      'new_khutbah': 'New Khutbah',
      'start_from_scratch': 'Start from scratch',
      'templates': 'Templates',
      'use_template': 'Use a template',
      'my_library': 'My Library',
      'browse_saved': 'Browse saved khutbahs',
      'content_library': 'Content Library',
      'research_verses_hadith': 'Research verses & hadith',
      'recent_khutbahs': 'Recent Khutbahs',
      'view_all': 'View All',
      'no_khutbahs': 'No Khutbahs Yet',
      'create_first': 'Create your first Khutbah to get started',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'min': 'min',
      'settings': 'Settings',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'language': 'Language',
      'english': 'English',
      'urdu': 'Urdu',
      'norsk': 'Norsk',
      'french': 'French',
      // Authentication strings
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'full_name': 'Full Name',
      'forgot_password': 'Forgot Password?',
      'email_required': 'Email is required',
      'email_invalid': 'Please enter a valid email',
      'password_required': 'Password is required',
      'password_min_length': 'Password must be at least 6 characters',
      'confirm_password_required': 'Please confirm your password',
      'passwords_dont_match': 'Passwords do not match',
      'name_required': 'Name is required',
      'check_email_confirmation': 'Please check your email for confirmation',
      'enter_email_reset': 'Please enter your email to reset password',
      'password_reset_sent': 'Password reset email sent',
    },
    'ur': {
      'app_title': 'المنبر',
      'tagline': 'منبر الخطبة - آپ کا خطبہ ساتھی',
      'bismillah': 'اللہ کے نام سے، اپنی نیت درست کریں اور اخلاص کی دعا کریں',
      'quick_actions': 'جلدی عمل',
      'new_khutbah': 'نئی خطبہ',
      'start_from_scratch': 'شروع سے بنائیں',
      'templates': 'سانچے',
      'use_template': 'سانچہ استعمال کریں',
      'my_library': 'میری لائبریری',
      'browse_saved': 'محفوظ خطبات دیکھیں',
      'content_library': 'مواد لائبریری',
      'research_verses_hadith': 'آیات و احادیث کی تلاش',
      'recent_khutbahs': 'حال ہی کے خطبات',
      'view_all': 'سب دیکھیں',
      'no_khutbahs': 'ابھی کوئی خطبہ نہیں',
      'create_first': 'شروع کرنے کے لیے اپنا پہلا خطبہ بنائیں',
      'today': 'آج',
      'yesterday': 'کل',
      'min': 'منٹ',
      'settings': 'ترتیبات',
      'theme': 'تھیم',
      'light': 'ہلکا',
      'dark': 'گہرا',
      'language': 'زبان',
      'english': 'انگریزی',
      'urdu': 'اردو',
      'norsk': 'نارویجن',
      'french': 'فرانسیسی',
      // Authentication strings
      'sign_in': 'داخل ہوں',
      'sign_up': 'رجسٹر کریں',
      'email': 'ای میل',
      'password': 'پاس ورڈ',
      'confirm_password': 'پاس ورڈ کی تصدیق',
      'full_name': 'پورا نام',
      'forgot_password': 'پاس ورڈ بھول گئے؟',
      'email_required': 'ای میل ضروری ہے',
      'email_invalid': 'براہ کرم صحیح ای میل درج کریں',
      'password_required': 'پاس ورڈ ضروری ہے',
      'password_min_length': 'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے',
      'confirm_password_required': 'براہ کرم اپنے پاس ورڈ کی تصدیق کریں',
      'passwords_dont_match': 'پاس ورڈ میل نہیں کھاتے',
      'name_required': 'نام ضروری ہے',
      'check_email_confirmation': 'براہ کرم تصدیق کے لیے اپنا ای میل چیک کریں',
      'enter_email_reset': 'پاس ورڈ ری سیٹ کرنے کے لیے اپنا ای میل درج کریں',
      'password_reset_sent': 'پاس ورڈ ری سیٹ ای میل بھیج دیا گیا',
    },
    'no': {
      'app_title': 'Al-Minbar',
      'tagline': 'Minbar for khutbah – Din khutbah-hjelper',
      'bismillah': 'I Allahs navn, sjekk din intensjon og be om ikhlās',
      'quick_actions': 'Hurtighandlinger',
      'new_khutbah': 'Ny khutbah',
      'start_from_scratch': 'Start fra bunnen',
      'templates': 'Maler',
      'use_template': 'Bruk en mal',
      'my_library': 'Mitt bibliotek',
      'browse_saved': 'Bla gjennom lagrede khutbahs',
      'content_library': 'Innholdsbibliotek',
      'research_verses_hadith': 'Søk i vers og hadith',
      'recent_khutbahs': 'Nylige khutbahs',
      'view_all': 'Se alle',
      'no_khutbahs': 'Ingen khutbahs ennå',
      'create_first': 'Lag din første khutbah for å komme i gang',
      'today': 'I dag',
      'yesterday': 'I går',
      'min': 'min',
      'settings': 'Innstillinger',
      'theme': 'Tema',
      'light': 'Lyst',
      'dark': 'Mørkt',
      'language': 'Språk',
      'english': 'Engelsk',
      'urdu': 'Urdu',
      'norsk': 'Norsk',
      'french': 'Fransk',
      // Authentication strings
      'sign_in': 'Logg inn',
      'sign_up': 'Registrer deg',
      'email': 'E-post',
      'password': 'Passord',
      'confirm_password': 'Bekreft passord',
      'full_name': 'Fullt navn',
      'forgot_password': 'Glemt passord?',
      'email_required': 'E-post er påkrevd',
      'email_invalid': 'Vennligst skriv inn en gyldig e-post',
      'password_required': 'Passord er påkrevd',
      'password_min_length': 'Passord må være minst 6 tegn',
      'confirm_password_required': 'Vennligst bekreft passordet ditt',
      'passwords_dont_match': 'Passordene stemmer ikke overens',
      'name_required': 'Navn er påkrevd',
      'check_email_confirmation': 'Vennligst sjekk e-posten din for bekreftelse',
      'enter_email_reset': 'Vennligst skriv inn e-posten din for å tilbakestille passord',
      'password_reset_sent': 'E-post for tilbakestilling av passord er sendt',
    },
    'fr': {
      'app_title': 'Al-Minbar',
      'tagline': 'Minbar de la khutbah - Votre assistant khutbah',
      'bismillah': 'Au nom d’Allah, vérifiez votre intention et demandez la sincérité (ikhlās)',
      'quick_actions': 'Actions rapides',
      'new_khutbah': 'Nouvelle khutbah',
      'start_from_scratch': 'Commencer de zéro',
      'templates': 'Modèles',
      'use_template': 'Utiliser un modèle',
      'my_library': 'Ma bibliothèque',
      'browse_saved': 'Parcourir les khutbahs enregistrées',
      'content_library': 'Bibliothèque de contenu',
      'research_verses_hadith': 'Rechercher versets et hadiths',
      'recent_khutbahs': 'Khutbahs récentes',
      'view_all': 'Tout voir',
      'no_khutbahs': 'Aucune khutbah pour l’instant',
      'create_first': 'Créez votre première khutbah pour commencer',
      'today': 'Aujourd’hui',
      'yesterday': 'Hier',
      'min': 'min',
      'settings': 'Paramètres',
      'theme': 'Thème',
      'light': 'Clair',
      'dark': 'Sombre',
      'language': 'Langue',
      'english': 'Anglais',
      'urdu': 'Ourdou',
      'norsk': 'Norvégien',
      'french': 'Français',
      // Authentication strings
      'sign_in': 'Se connecter',
      'sign_up': 'S\'inscrire',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'full_name': 'Nom complet',
      'forgot_password': 'Mot de passe oublié ?',
      'email_required': 'L\'e-mail est requis',
      'email_invalid': 'Veuillez saisir un e-mail valide',
      'password_required': 'Le mot de passe est requis',
      'password_min_length': 'Le mot de passe doit contenir au moins 6 caractères',
      'confirm_password_required': 'Veuillez confirmer votre mot de passe',
      'passwords_dont_match': 'Les mots de passe ne correspondent pas',
      'name_required': 'Le nom est requis',
      'check_email_confirmation': 'Veuillez vérifier votre e-mail pour confirmation',
      'enter_email_reset': 'Veuillez saisir votre e-mail pour réinitialiser le mot de passe',
      'password_reset_sent': 'E-mail de réinitialisation du mot de passe envoyé',
    },
  };

  String _lang() => _values.containsKey(locale.languageCode) ? locale.languageCode : 'en';

  String t(String key) {
    final lang = _lang();
    return _values[lang]?[key] ?? _values['en']![key] ?? key;
  }

  // Helper for relative day phrases
  String daysAgo(int days) {
    final lang = _lang();
    switch (lang) {
      case 'ur':
        return '$days دن پہلے';
      case 'no':
        return '$days dager siden';
      case 'fr':
        return 'il y a $days jours';
      default:
        return '$days days ago';
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
