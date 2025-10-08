# Implementation Plan

- [x] 1. Remove Fleather completely from the application





  - Delete fleather_editor_screen.dart file
  - Remove fleather dependency from pubspec.yaml
  - Remove all Fleather imports from any remaining files
  - Update navigation references to use only RichEditorScreen
  - _Requirements: All (prerequisite for other tasks)_

- [x] 2. Fix keyboard persistence in Quill editor





  - Modify QuillEditor widget to set `autoFocus: true`
  - Ensure FocusNode is properly initialized and retained
  - Add keyboard dismiss behavior configuration to prevent auto-dismiss
  - Test keyboard stays visible while typing
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 3. Redesign settings modal layout





  - Remove "Settings" title and icon line from modal
  - Restructure user greeting section with logout icon
  - Add red logout icon next to username (right-justified)
  - Wrap content in SingleChildScrollView to prevent overflow
  - Set isScrollControlled: true for modal bottom sheet
  - Adjust padding and spacing for compact layout
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 4. Add flag icons to language selection





  - Add Unicode flag emojis to language chip labels
  - Map language codes to flags: en→🇬🇧, ur→🇵🇰, no→🇳🇴, fr→🇫🇷
  - Modify _LangChip widget to display flag before language name
  - Ensure flags render correctly on all platforms
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 5. Fix template loading functionality





  - Modify _useTemplate method to create Khutbah from template
  - Pass template content and name to RichEditorScreen
  - Ensure template content loads into Quill editor
  - Verify title field is populated with template name
  - Test user can immediately edit loaded template
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 6. Create export bottom sheet widget





  - Create new ExportBottomSheet widget
  - Add all export options: Save PDF, Print PDF, Share PDF
  - Add divider separator
  - Add HTML options: Save HTML, Share HTML
  - Add divider separator
  - Add Copy Plain Text option
  - Style with proper icons and labels
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10_

- [x] 7. Implement PDF export with Arabic font support





  - Add google_fonts dependency to pubspec.yaml
  - Create PDFGenerator utility class
  - Implement Arabic text detection using regex
  - Load Noto Naskh Arabic font from Google Fonts
  - Apply Arabic font and RTL direction for Arabic text
  - Implement Save PDF functionality
  - Implement Print PDF functionality
  - Implement Share PDF functionality
  - Test with Arabic content to verify characters render correctly
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 8. Implement HTML export functionality





  - Convert Quill document to HTML format
  - Implement Save as HTML with proper encoding
  - Implement Share as HTML functionality
  - Ensure Arabic text is properly encoded in HTML
  - Add proper HTML metadata and lang attributes
  - _Requirements: 5.6, 5.7_

- [x] 9. Implement copy plain text functionality




  - Add clipboard dependency if needed
  - Extract plain text from Quill document
  - Copy text to system clipboard
  - Show confirmation snackbar
  - _Requirements: 5.9_

- [ ] 10. Integrate export bottom sheet into editor
  - Replace existing export menu in RichEditorScreen
  - Add export button/menu item that shows bottom sheet
  - Wire up all export options to their respective handlers
  - Test all export flows end-to-end
  - _Requirements: 5.1, 5.10_

- [ ] 11. Update navigation and references
  - Update all navigation calls to use RichEditorScreen only
  - Remove any Fleather-related navigation logic
  - Update home screen quick actions
  - Update library screen editor navigation
  - Verify no broken navigation paths remain
  - _Requirements: All_

- [ ]* 12. Add error handling and user feedback
  - Add try-catch blocks for all export operations
  - Show loading indicators during PDF generation
  - Display error messages for failed exports
  - Add permission request handling for file saves
  - Show success messages after successful exports
  - _Requirements: All_

- [ ]* 13. Test on physical devices
  - Test keyboard persistence on Android device
  - Test keyboard persistence on iOS device
  - Test settings modal on various screen sizes
  - Test all export options on physical device
  - Verify Arabic PDF renders correctly on device
  - Test template loading on device
  - _Requirements: All_
