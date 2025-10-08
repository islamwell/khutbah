# Al-Minbar (PulpitFlow)

A comprehensive Islamic Khutbah preparation app that combines research, writing, and delivery into one seamless workflow.

## Features

### 🎯 Core Features
- **Rich Text Editor**: Advanced Quill-based editor with Arabic and English support
- **Khutbah Templates**: 3 pre-designed templates (Basic, Classic, Modern)
- **Content Library**: Organize Quran verses, Hadith, and quotes
- **Cloud Sync**: Supabase integration for cross-device synchronization
- **Export Options**: PDF generation and HTML sharing
- **Delivery Mode**: Presentation-friendly interface for khutbah delivery

### 📱 Template System
1. **Basic Template**: Plain text format for simple khutbahs
2. **Classic Template**: Traditional green styling with Islamic aesthetics
3. **Modern Template**: Contemporary design with gradient colors and digital-age content

### 🔧 Technical Features
- **SDK 36 Support**: Latest Android compatibility
- **Multi-language**: Arabic and English support with RTL text handling
- **Offline Capability**: Local storage with cloud synchronization
- **Cross-platform**: Android, iOS, and Web support

## Getting Started

### Prerequisites
- Flutter SDK 3.24.0 or higher
- Dart SDK 3.6.0 or higher
- Android SDK 36 (for Android builds)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/islamwell/khutbah.git
cd khutbah
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Release

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
├── services/                 # Business logic and API services
├── utils/                    # Utility functions
├── widgets/                  # Reusable UI components
└── supabase/                # Database schema and configuration

android/                      # Android-specific configuration
web/                         # Web-specific files
assets/                      # App assets and templates
```

## Key Components

### Services
- **KhutbahTemplatesService**: Manages khutbah templates
- **UserDataService**: Handles user data and cloud sync
- **HTMLGenerator**: Converts content to HTML format
- **PDFGenerator**: Creates PDF exports

### Screens
- **LibraryScreen**: Main khutbah management interface
- **RichEditorScreen**: Advanced text editing
- **DeliveryScreen**: Presentation mode for khutbahs
- **HomeScreen**: Dashboard and navigation

## Configuration

### Supabase Setup
1. Create a Supabase project
2. Update `lib/supabase/supabase_config.dart` with your credentials
3. Run the SQL scripts in `lib/supabase/` to set up the database

### Android Configuration
- Minimum SDK: 21
- Target SDK: 36
- Compile SDK: 36

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Version History

- **v1.0.6**: Added template system, SDK 36 support, enhanced UI
- **v1.0.5**: Initial release with basic khutbah management

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue on GitHub.

---

**Built with ❤️ for the Muslim community**