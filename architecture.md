# Al-Minbar: Islamic Khutbah Preparation App Architecture

## Project Overview
Al-Minbar is a comprehensive Islamic Khutbah (sermon) preparation app that combines research, writing, and delivery into one seamless workflow. It features a rich-text editor, content library, templates, delivery mode, and personal organization system.

## Core Architecture

### 1. Technical Requirements
- **Platform**: Flutter cross-platform (iOS, Android, potentially Desktop)
- **Storage**: Local SQLite database with JSON import/export for sync
- **Text Processing**: Rich text editing with RTL support for Arabic
- **Fonts**: Amiri for Arabic text, Inter for UI elements
- **Theme**: Professional, calm design with deep green/blue accents

### 2. Feature Breakdown

#### Feature 1: Khutbah Builder (Rich Text Editor)
- **Components**: Custom rich text editor with toolbar
- **Functionality**: Bold, italics, bullets, numbered lists, RTL toggle
- **Structure**: Visual separators for First/Second parts with jalsah break
- **Files**: `editor_screen.dart`, `rich_text_toolbar.dart`, `text_formatting.dart`

#### Feature 2: Content Library (Research Engine)
- **Components**: Searchable database with categorized content
- **Categories**: Quran verses, Hadith with authenticity, Scholarly quotes
- **Functionality**: Search by topic, one-click insert into editor
- **Files**: `content_library_screen.dart`, `search_widget.dart`, `content_models.dart`

#### Feature 3: Khutbah Templates
- **Components**: Pre-built sermon structures
- **Templates**: Standard template with Arabic openings/closings, Thematic templates
- **Files**: `templates_screen.dart`, `template_models.dart`

#### Feature 4: Delivery Mode (Teleprompter)
- **Components**: Full-screen teleprompter with auto-scroll
- **Features**: Adjustable speed, pause/play, progress tracking, time estimation
- **Files**: `delivery_screen.dart`, `teleprompter_controls.dart`

#### Feature 5: Personal Library & Organization
- **Components**: Saved Khutbahs with folders, tags, search
- **Features**: Auto-save, export/import, cross-device sync preparation
- **Files**: `library_screen.dart`, `khutbah_models.dart`, `storage_service.dart`

### 3. Data Models
```dart
// Core data structures
class Khutbah {
  String id, title, content, tags;
  DateTime createdAt, modifiedAt;
  int estimatedMinutes;
}

class ContentItem {
  String id, text, translation, source;
  ContentType type; // Quran, Hadith, Quote
  String? authenticity; // For Hadith
}

class Template {
  String id, name, content;
  TemplateType type;
}
```

### 4. File Structure
```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── khutbah.dart
│   ├── content_item.dart
│   └── template.dart
├── screens/
│   ├── home_screen.dart
│   ├── editor_screen.dart
│   ├── content_library_screen.dart
│   ├── templates_screen.dart
│   ├── delivery_screen.dart
│   └── library_screen.dart
├── widgets/
│   ├── rich_text_toolbar.dart
│   ├── content_search.dart
│   └── khutbah_card.dart
├── services/
│   ├── storage_service.dart
│   └── content_service.dart
└── utils/
    ├── text_formatting.dart
    └── constants.dart
```

### 5. Implementation Steps

1. **Setup Phase**
   - Update theme with Islamic-appropriate colors (deep green/teal)
   - Add required dependencies (sqflite, path_provider, etc.)
   - Create data models and services

2. **Core Editor Phase**
   - Implement rich text editor with formatting toolbar
   - Add RTL support and Arabic text handling
   - Create visual separators for Khutbah structure

3. **Content Library Phase**
   - Build searchable content database with sample data
   - Implement categorized content display (Quran, Hadith, Quotes)
   - Add one-click insert functionality

4. **Templates Phase**
   - Create template system with standard Islamic Khutbah structure
   - Add Arabic openings (Khutbat al-Hajah) and closings
   - Implement template selection and customization

5. **Delivery Mode Phase**
   - Build full-screen teleprompter interface
   - Add auto-scroll with speed controls
   - Implement progress tracking and time estimation

6. **Library & Organization Phase**
   - Create personal library with search and filtering
   - Add folder/tag organization system
   - Implement export/import functionality

7. **Polish Phase**
   - Add animations and transitions
   - Optimize for tablet and phone layouts
   - Test and debug all features

### 6. Key Technical Considerations
- **RTL Text Support**: Proper handling of Arabic text direction
- **Font Loading**: Amiri font for Arabic, Inter for UI
- **Storage**: Local SQLite with JSON export for cross-device sync
- **Performance**: Efficient text editing for long documents
- **Accessibility**: High contrast delivery mode, readable fonts

### 7. MVP Scope
Focus on core workflow: New Khutbah → Template Selection → Content Research → Writing → Delivery → Save. Additional features like advanced organization and sync can be added in future iterations.

This architecture provides a solid foundation for building a professional Islamic Khutbah preparation app with all requested features while maintaining clean, maintainable code structure.