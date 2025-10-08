# Requirements Document

## Introduction

This feature addresses critical usability issues in the PulpitFlow Flutter application affecting the text editor, settings screen, template loading, and export functionality. The fixes will improve user experience by ensuring the keyboard remains visible during editing, fixing UI overflow issues in settings, adding visual language indicators, enabling proper template loading, and implementing a comprehensive export system with proper Arabic font support.

## Requirements

### Requirement 1: Fix Text Editor Keyboard Persistence

**User Story:** As a user writing a khutbah, I want the keyboard to remain visible while I'm editing text, so that I can continuously type without interruption.

#### Acceptance Criteria

1. WHEN the user taps on the text editor THEN the keyboard SHALL appear and remain visible
2. WHEN the user is typing in the editor THEN the keyboard SHALL NOT automatically dismiss
3. WHEN the user explicitly dismisses the keyboard (back button or swipe) THEN the keyboard SHALL close
4. IF the user switches focus to another input field THEN the keyboard SHALL remain visible for the new field
5. app will not use fleather as the editor.  it will use the flutter_quill package instead.  please make changes throughtout the app.

### Requirement 2: Redesign Settings Screen Layout

**User Story:** As a user accessing settings, I want a clean, non-overflowing interface with easy logout access, so that I can quickly adjust preferences and sign out when needed.

#### Acceptance Criteria

1. WHEN the settings screen is displayed THEN all content SHALL be visible without overflow
2. WHEN the settings screen is displayed THEN a RED logout icon SHALL appear next to the username on the right side
3. WHEN the settings screen is displayed THEN the "Settings" title and icon line SHALL be removed
4. WHEN the user views the settings THEN the logout icon SHALL be right-justified next to the user greeting
5. WHEN the user taps the logout icon THEN the logout process SHALL initiate
6. WHEN the settings modal is displayed THEN it SHALL use proper scrolling if content exceeds screen height

### Requirement 3: Add Language Flag Icons

**User Story:** As a multilingual user, I want to see country flags in each language selection box, so that I can quickly identify and select my preferred language visually.

#### Acceptance Criteria

1. WHEN the language selection is displayed THEN each language option SHALL show a small country flag icon
2. WHEN English is displayed THEN it SHALL show the US flag
3. WHEN Urdu is displayed THEN it SHALL show the Pakistan flag
4. WHEN Norsk is displayed THEN it SHALL show the Norway flag
5. WHEN French is displayed THEN it SHALL show the France flag
6. WHEN a language chip is rendered THEN the flag SHALL be positioned before the language name

### Requirement 4: Fix Template Loading Functionality

**User Story:** As a user selecting a template, I want the template content to load into the editor, so that I can start writing based on the template structure.

#### Acceptance Criteria

1. WHEN the user selects a template THEN the template content SHALL be loaded into the editor
2. WHEN the template is loaded THEN the editor SHALL display the template's text content
3. WHEN the template is loaded THEN the title field SHALL be populated with the template name
4. WHEN the template is loaded THEN the user SHALL be able to immediately edit the content
5. IF the template contains formatting THEN the formatting SHALL be preserved in the editor

### Requirement 5: Implement Comprehensive Export System

**User Story:** As a user completing a khutbah, I want multiple export options presented in a bottom sheet, so that I can easily share or save my work in different formats.

#### Acceptance Criteria

1. WHEN the user taps export THEN a bottom sheet SHALL appear with export options
2. WHEN the bottom sheet is displayed THEN it SHALL show "Save as PDF" option
3. WHEN the bottom sheet is displayed THEN it SHALL show "Print PDF" option
4. WHEN the bottom sheet is displayed THEN it SHALL show "Share PDF" option
5. WHEN the bottom sheet is displayed THEN it SHALL show a separator line
6. WHEN the bottom sheet is displayed THEN it SHALL show "Save as HTML" option - HTML should be properly formatted.
7. WHEN the bottom sheet is displayed THEN it SHALL show "Share as HTML" option
8. WHEN the bottom sheet is displayed THEN it SHALL show a separator line
9. WHEN the bottom sheet is displayed THEN it SHALL show "Copy Plain Text" option
10. WHEN the user selects any export option THEN the corresponding action SHALL execute

### Requirement 6: Fix Arabic Font Support in PDF Export

**User Story:** As a user writing khutbahs in Arabic, I want Arabic characters to display correctly in exported PDFs, so that my content is readable and properly formatted.

#### Acceptance Criteria

1. WHEN a PDF is generated with Arabic text THEN Arabic characters SHALL render correctly
2. WHEN a PDF is generated with Arabic text THEN characters SHALL NOT appear as boxes
3. WHEN a PDF is generated THEN it SHALL use a Unicode-compatible Arabic font
4. WHEN a PDF is generated with mixed languages THEN all characters SHALL render correctly
5. IF the PDF library requires font embedding THEN an appropriate Arabic font SHALL be embedded
6. WHEN Arabic text is rendered THEN it SHALL display right-to-left correctly
