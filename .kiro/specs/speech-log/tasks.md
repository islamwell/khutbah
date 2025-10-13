# Implementation Plan

- [x] 1. Create data model and database schema





  - Create SpeechLog model class with all required fields and JSON serialization
  - Write factory constructor for creating SpeechLog from JSON
  - Implement copyWith method for immutable updates
  - Create SQL migration file for speech_logs table with indexes and RLS policies
  - _Requirements: 1.1, 1.3, 1.4, 1.5, 2.4, 5.3, 6.1, 6.2, 6.3, 6.4_

- [x] 2. Implement SpeechLogService for data operations





  - Create SpeechLogService class with Supabase integration
  - Implement getUserSpeechLogs() method to fetch all logs for current user
  - Implement getSpeechLogsByKhutbah() method to fetch logs for specific speech
  - Implement createSpeechLog() method with proper error handling
  - Implement updateSpeechLog() method with modified_at timestamp update
  - Implement deleteSpeechLog() method with confirmation
  - Implement getDeliveryCount() method for counting speech deliveries
  - Add proper error handling and user-friendly error messages
  - _Requirements: 1.3, 1.5, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ]* 2.1 Write unit tests for SpeechLogService
  - Create mock Supabase client for testing
  - Write tests for all CRUD operations
  - Test error handling scenarios
  - _Requirements: 1.3, 1.5, 2.4, 5.3_

- [x] 3. Build SpeechLogFormScreen for creating and editing logs





  - Create form screen with all required input fields
  - Implement speech selector dropdown using existing khutbahs
  - Add date picker for delivery date with validation (not in future)
  - Add text fields for location and event type with validation
  - Add optional numeric input for audience size
  - Add optional text field for audience demographics
  - Add multi-line text fields for positive feedback, negative feedback, and general notes
  - Implement form validation logic for required fields
  - Add save button with loading state and success feedback
  - Add cancel button with unsaved changes warning
  - Handle create vs edit mode based on passed SpeechLog parameter
  - _Requirements: 1.1, 1.2, 1.4, 2.1, 2.2, 2.3, 5.1, 5.2, 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ]* 3.1 Write widget tests for SpeechLogFormScreen
  - Test form validation for required fields
  - Test date picker validation
  - Test save button state changes
  - Test cancel button with unsaved changes
  - _Requirements: 1.4, 5.2_

- [x] 4. Create SpeechLogsScreen for viewing all logs





  - Create main screen with app bar and floating action button
  - Implement ListView.builder for efficient rendering of log entries
  - Create log list item widget showing title, date, location, event type
  - Add sorting by delivery date (most recent first)
  - Implement empty state when no logs exist
  - Add pull-to-refresh functionality
  - Implement navigation to detail screen on tap
  - Add navigation to form screen from FAB
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 5. Build SpeechLogDetailScreen for viewing full log details





  - Create detail screen with organized sections for all log information
  - Display speech title with link to view associated khutbah
  - Show delivery date, location, event type, audience info in info section
  - Display positive feedback in visually distinct section
  - Display negative feedback in visually distinct section
  - Display general notes section
  - Add edit button in app bar that navigates to form screen
  - Add delete button with confirmation dialog
  - Implement delete functionality with success/error feedback
  - Handle navigation back to list after delete
  - _Requirements: 2.5, 3.4, 5.1, 5.4, 5.5, 5.6_

- [x] 6. Create reusable SpeechLogListWidget for khutbah-specific logs




  - Create widget that accepts khutbahId parameter
  - Fetch and display logs for specific speech
  - Show condensed view with date, location, event type
  - Implement tap navigation to detail screen
  - Handle empty state when speech has no logs
  - Add loading indicator while fetching data
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3_

- [x] 7. Enhance library screen with delivery tracking






  - Add delivery count badge to KhutbahCard widget
  - Fetch delivery counts when loading khutbahs
  - Display most recent delivery date on card if available
  - Add "View Delivery History" icon button on cards
  - Implement navigation to filtered logs view for specific khutbah
  - Update UI to show "Log Delivery" quick action
  - _Requirements: 3.1, 3.2, 4.1, 4.2, 4.3_


- [x] 8. Add navigation and routing






  - Add route for SpeechLogsScreen in main app routes
  - Add route for SpeechLogDetailScreen with log ID parameter
  - Add route for SpeechLogFormScreen with optional log parameter
  - Update navigation drawer or bottom nav to include speech logs
  - Implement deep linking support for log screens
  - _Requirements: 3.1, 3.4_

-

- [x] 9. Implement filtering and search functionality





  - Add filter UI to SpeechLogsScreen (by speech, date range, event type)
  - Implement filter logic in SpeechLogService
  - Add search bar for searching by location or event type
  - Implement debounced search to reduce queries
  - Update list view based on active filters
  - Add clear filters button

  - _Requirements: 3.1, 3.2, 6.5_
- [x] 10. Add error handling and edge cases




- [ ] 10. Add error handling and edge cases


  - Implement network error handling with retry mechanism
  - Add error state UI for failed data loads
  - Handle case where associated khutbah is deleted (show archived log)
  - Implement form data caching to prevent data loss
  - Add validation error messages for all form fields
  - Handle very large text inputs with truncation in list views



  - Add confirmation dialogs for destructive actions
  - _Requirements: 1.4, 5.6_
-

- [x] 10.1 Write integration tests for complete flows








  - Test create → view → edit → delete flow
  - Test filtering and searching
  - Test navigation between screens
  - Test data persistence

  - _Requirements: 1.5, 2.4, 3.5, 5.3_
-

- [x] 11. Polish UI and accessibility





  - Apply consistent Al-Minbar theme colors and typography
  - Ensure RTL support for Arabic text in all screens
  - Add proper semantic labels for screen readers
  - Verify touch targets meet minimum size requirements
  - Add loading indicators for all async operations
  - Implement success snackbars after save operations
  - Add smooth transitions between screens
  - Test and fix any UI overflow issues
  - _Requirements: 1.1, 2.1, 3.1, 5.1_
