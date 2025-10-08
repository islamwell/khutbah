# Design Document

## Overview

This design addresses six critical issues in the PulpitFlow application:
1. Text editor keyboard persistence
2. Settings screen overflow and layout redesign
3. Language selection with flag icons
4. Template loading functionality
5. Comprehensive export system with bottom sheet
6. Arabic font support in PDF exports

The solution involves modifications to the editor screens (both Fleather and Quill), settings modal, templates screen, and export functionality with proper font embedding for Arabic text.

## Architecture

### Component Structure

```
lib/
├── screens/
│   ├── rich_editor_screen.dart (modify keyboard handling + export)
│   ├── home_screen.dart (redesign settings modal)
│   └── templates_screen.dart (fix template loading)
├── widgets/
│   ├── export_bottom_sheet.dart (new)
│   └── language_chip.dart (modify with flags)
└── utils/
    └── pdf_generator.dart (new - with Arabic font support)
```

**IMPORTANT**: Remove all Fleather dependencies and references. Use ONLY Quill editor throughout the application.

### Key Changes

1. **Editor Screen**: Add focus management and keyboard persistence (Quill only)
2. **Settings Modal**: Restructure layout, remove overflow, add logout icon
3. **Language Selection**: Add flag emoji/icons to language chips
4. **Templates**: Pass template content to editor on selection
5. **Export System**: Create reusable bottom sheet with multiple export options
6. **PDF Generation**: Implement Arabic font embedding using Google Fonts or bundled fonts
7. **Remove Fleather**: Delete fleather_editor_screen.dart and all Fleather imports

## Components and Interfaces

### 1. Keyboard Persistence Fix

**Problem**: Keyboard dismisses immediately after appearing in text editor.

**Solution**: 
- Ensure `FocusNode` is properly managed and retained
- Use `autofocus: true` or request focus explicitly when editor loads
- Wrap editor in `GestureDetector` to prevent unintended focus loss
- Add `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual` to scrollable areas
- For Quill editor, ensure `readOnly: false` and `autoFocus: true` are set

**Implementation Points**:
- `RichEditorScreen`: Modify `_buildContentEditor()` to manage focus properly
- Ensure `FocusNode` is initialized and disposed correctly
- Set `autoFocus: true` in `QuillEditor` widget
- Verify `ScrollController` doesn't interfere with keyboard

### 2. Settings Screen Redesign

**Current Issues**:
- Content overflow
- Redundant "Settings" header
- Logout button at bottom (hard to reach)

**New Design**:
```
┌─────────────────────────────────────┐
│  [Person Icon] Assalamo alaykum     │
│                Username      [🔴 ⎋] │ <- Red logout icon, right-aligned
├─────────────────────────────────────┤
│  Theme                              │
│  ○ Light  ● Dark                    │
├─────────────────────────────────────┤
│  Language                           │
│  [🇬🇧 English] [🇵🇰 Urdu]           │
│  [🇳🇴 Norsk]   [🇫🇷 French]         │
└─────────────────────────────────────┘
```

**Changes**:
- Remove "Settings" title and icon line
- Move logout to icon next to username (red color, right-justified)
- Use `SingleChildScrollView` to prevent overflow
- Reduce padding and spacing for compact layout
- Keep drag handle for modal

### 3. Language Flag Icons

**Implementation**:
- Use Unicode flag emojis (🇬🇧, 🇵🇰, 🇳🇴, 🇫🇷)
- Alternative: Use `country_flags` package or custom SVG assets
- Modify `_LangChip` widget to include flag before label

**Flag Mapping**:
- English (en): 🇬🇧 or 🇺🇸
- Urdu (ur): 🇵🇰
- Norsk (no): 🇳🇴
- French (fr): 🇫🇷

### 4. Template Loading Fix

**Current Issue**: `_useTemplate()` navigates to editor without passing template data.

**Solution**:
```dart
void _useTemplate(BuildContext context, Template template) {
  // Create a Khutbah from template
  final khutbah = Khutbah(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: template.name,
    content: template.content,
    tags: [],
    createdAt: DateTime.now(),
    modifiedAt: DateTime.now(),
    estimatedMinutes: 15,
  );
  
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => RichEditorScreen(existingKhutbah: khutbah),
    ),
  );
}
```

### 5. Export Bottom Sheet

**New Widget**: `ExportBottomSheet`

**Options**:
1. Save as PDF
2. Print PDF
3. Share PDF
4. --- (divider)
5. Save as HTML
6. Share as HTML
7. --- (divider)
8. Copy Plain Text

**Interface**:
```dart
class ExportBottomSheet extends StatelessWidget {
  final String title;
  final String content;
  
  void showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ExportBottomSheet(
        title: title,
        content: content,
      ),
    );
  }
}
```

**Actions**:
- **Save as PDF**: Generate PDF and save to device storage
- **Print PDF**: Open system print dialog
- **Share PDF**: Generate PDF and share via system share sheet
- **Save as HTML**: Convert content to HTML and save
- **Share as HTML**: Convert to HTML and share
- **Copy Plain Text**: Copy plain text to clipboard

### 6. Arabic Font Support in PDF

**Problem**: Arabic characters render as boxes (□) in PDF.

**Root Cause**: Default PDF fonts don't support Arabic Unicode characters.

**Solution Options**:

**Option A: Use Google Fonts (Recommended)**
```dart
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;

final arabicFont = await GoogleFonts.notoNaskhArabicRegular();
final ttf = pw.Font.ttf(arabicFont);

pdf.addPage(
  pw.Page(
    build: (context) => pw.Text(
      arabicText,
      style: pw.TextStyle(font: ttf),
      textDirection: pw.TextDirection.rtl,
    ),
  ),
);
```

**Option B: Bundle Custom Font**
- Add Amiri, Scheherazade, or Noto Naskh Arabic to `assets/fonts/`
- Load font in PDF generation
- Set `textDirection: pw.TextDirection.rtl` for Arabic text

**Recommended Font**: Noto Naskh Arabic (comprehensive Unicode support, open source)

**Implementation**:
- Create `PDFGenerator` utility class
- Detect Arabic text using regex: `[\u0600-\u06FF]`
- Apply Arabic font and RTL direction when Arabic detected
- Use default font for non-Arabic text

## Data Models

### ExportOptions Enum
```dart
enum ExportOption {
  savePDF,
  printPDF,
  sharePDF,
  saveHTML,
  shareHTML,
  copyPlainText,
}
```

### ExportService Interface
```dart
class ExportService {
  static Future<void> exportAsPDF(String title, String content, {bool save = false, bool print = false, bool share = false});
  static Future<void> exportAsHTML(String title, String content, {bool save = false, bool share = false});
  static Future<void> copyPlainText(String content);
}
```

## Error Handling

### Keyboard Focus Issues
- **Error**: Focus lost unexpectedly
- **Handling**: Implement focus retention logic, log focus changes for debugging

### Settings Overflow
- **Error**: Content exceeds screen height
- **Handling**: Wrap in `SingleChildScrollView`, set `isScrollControlled: true` for modal

### Template Loading
- **Error**: Template content is null or empty
- **Handling**: Validate template before navigation, show error snackbar if invalid

### PDF Export with Arabic
- **Error**: Font loading fails
- **Handling**: Fallback to bundled font, show error message if both fail
- **Error**: Arabic text still shows boxes
- **Handling**: Verify font supports Arabic range, check RTL direction is set

### Export Failures
- **Error**: Permission denied for file save
- **Handling**: Request storage permissions, show permission dialog
- **Error**: Share fails
- **Handling**: Show error snackbar with retry option

## Testing Strategy

### Unit Tests
1. Test `ExportService` methods with sample content
2. Test Arabic text detection regex
3. Test template-to-khutbah conversion

### Widget Tests
1. Test `ExportBottomSheet` renders all options
2. Test language chips display flags correctly
3. Test settings modal layout without overflow
4. Test keyboard focus retention in editors

### Integration Tests
1. Test template selection → editor with content loaded
2. Test export flow: select option → generate → share/save
3. Test Arabic PDF generation end-to-end
4. Test settings changes persist correctly

### Manual Testing
1. Verify keyboard stays up while typing in editor
2. Verify settings modal displays correctly on various screen sizes
3. Verify all export options work on physical device
4. Verify Arabic text renders correctly in PDF on device
5. Test logout icon functionality

## Implementation Notes

### Dependencies
- Existing: `pdf`, `printing`, `share_plus`, `flutter_quill`
- Remove: `fleather` (completely remove from pubspec.yaml)
- May need: `google_fonts` (for Arabic font), `clipboard` (for copy text)

### Platform Considerations
- **Android**: Request storage permissions for save operations
- **iOS**: Configure Info.plist for photo library access if saving PDFs
- **Web**: Use download API for file saves

### Performance
- Load Arabic font once and cache for multiple PDF generations
- Generate PDFs asynchronously to avoid UI blocking
- Use `compute()` for large document PDF generation

### Accessibility
- Ensure export options have proper semantic labels
- Logout icon should have tooltip
- Language flags should have accessible labels

### Localization
- Export option labels should use localization strings
- PDF metadata should respect current locale
- HTML export should include proper lang attribute
