# Speech Log Feature Design Document

## Overview

The Speech Log feature enables speakers to track and analyze their speech deliveries over time. This system allows users to record when and where they delivered each speech, capture audience feedback, and identify patterns for continuous improvement. The feature integrates seamlessly with the existing Khutbah library, allowing speakers to associate multiple delivery instances with a single speech/template.

## Architecture

### Data Flow
1. User selects a speech from their library or creates a new log entry
2. User fills in delivery details (date, location, event type, audience info)
3. User records feedback (positive, negative, general notes)
4. System saves the log entry to Supabase with user_id and khutbah_id associations
5. User can view all log entries for a specific speech or browse all logs
6. User can edit or delete existing log entries

### Integration Points
- **Khutbah Library**: Speech logs link to existing Khutbah records via foreign key
- **Supabase Database**: New `speech_logs` table with RLS policies
- **Library Screen**: Enhanced to show delivery count and access to logs
- **Navigation**: New screen accessible from library or main navigation

## Components and Interfaces

### 1. Data Model

#### SpeechLog Model (`lib/models/speech_log.dart`)
```dart
class SpeechLog {
  final String id;
  final String khutbahId;           // Foreign key to khutbahs table
  final String khutbahTitle;        // Denormalized for display
  final DateTime deliveryDate;
  final String location;
  final String eventType;           // e.g., "Jummah", "Wedding", "Conference"
  final int? audienceSize;
  final String? audienceDemographics;
  final String positiveFeedback;
  final String negativeFeedback;
  final String generalNotes;
  final DateTime createdAt;
  final DateTime modifiedAt;
}
```

### 2. Service Layer

#### SpeechLogService (`lib/services/speech_log_service.dart`)
Handles all CRUD operations for speech logs using Supabase:
- `getUserSpeechLogs()` - Get all logs for current user
- `getSpeechLogsByKhutbah(String khutbahId)` - Get logs for specific speech
- `createSpeechLog(SpeechLog log)` - Create new log entry
- `updateSpeechLog(SpeechLog log)` - Update existing log
- `deleteSpeechLog(String logId)` - Delete log entry
- `getDeliveryCount(String khutbahId)` - Get count of deliveries for a speech

### 3. UI Components

#### SpeechLogsScreen (`lib/screens/speech_logs_screen.dart`)
Main screen showing all speech logs:
- List view of all log entries sorted by delivery date (most recent first)
- Filter options: by speech, by date range, by event type
- Search functionality
- Floating action button to create new log
- Each list item shows: speech title, delivery date, location, event type
- Tap to view full details

#### SpeechLogDetailScreen (`lib/screens/speech_log_detail_screen.dart`)
Detailed view of a single log entry:
- Display all log information in organized sections
- Edit and delete buttons
- Visual separation of positive/negative feedback
- Link to view the associated speech

#### SpeechLogFormScreen (`lib/screens/speech_log_form_screen.dart`)
Form for creating/editing log entries:
- Speech selector (dropdown or search from user's library)
- Date picker for delivery date
- Text fields for location, event type
- Optional numeric input for audience size
- Optional text field for audience demographics
- Multi-line text fields for positive feedback, negative feedback, general notes
- Save and cancel buttons
- Form validation

#### SpeechLogListWidget (`lib/widgets/speech_log_list_widget.dart`)
Reusable widget for displaying logs for a specific speech:
- Used in Khutbah detail view
- Shows condensed list of deliveries
- Tap to view full log details

### 4. UI Enhancements to Existing Screens

#### Library Screen Updates
- Add delivery count badge to each Khutbah card
- Add "View Delivery History" button/icon on Khutbah cards
- Show most recent delivery date on card

#### Khutbah Detail/Editor Screen Updates
- Add "Log Delivery" quick action button
- Show delivery history section at bottom
- Display summary stats (total deliveries, average feedback)

## Data Models

### Database Schema

#### speech_logs Table (Supabase)
```sql
CREATE TABLE speech_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  khutbah_id UUID NOT NULL REFERENCES khutbahs(id) ON DELETE CASCADE,
  khutbah_title TEXT NOT NULL,
  delivery_date TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT NOT NULL,
  event_type TEXT NOT NULL,
  audience_size INTEGER,
  audience_demographics TEXT,
  positive_feedback TEXT NOT NULL DEFAULT '',
  negative_feedback TEXT NOT NULL DEFAULT '',
  general_notes TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  modified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_speech_logs_user_id ON speech_logs(user_id);
CREATE INDEX idx_speech_logs_khutbah_id ON speech_logs(khutbah_id);
CREATE INDEX idx_speech_logs_delivery_date ON speech_logs(delivery_date DESC);

-- Row Level Security
ALTER TABLE speech_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own speech logs"
  ON speech_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own speech logs"
  ON speech_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own speech logs"
  ON speech_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own speech logs"
  ON speech_logs FOR DELETE
  USING (auth.uid() = user_id);
```

### Field Constraints
- `delivery_date`: Required, cannot be in the future
- `location`: Required, min 1 character
- `event_type`: Required, suggested values but allows custom input
- `audience_size`: Optional, must be positive integer if provided
- `positive_feedback`, `negative_feedback`, `general_notes`: Optional text fields

## Error Handling

### Validation Errors
- Display inline validation messages for required fields
- Show snackbar for form-level errors
- Prevent submission until all required fields are valid

### Network Errors
- Show user-friendly error messages for network failures
- Implement retry mechanism for failed operations
- Cache form data locally to prevent data loss

### Database Errors
- Handle foreign key violations (deleted khutbah)
- Handle duplicate entries gracefully
- Log errors for debugging while showing user-friendly messages

### Edge Cases
- Handle case where associated khutbah is deleted (show archived log with title)
- Handle empty states (no logs yet)
- Handle very large text inputs (truncate in list view)

## Testing Strategy

### Unit Tests
- Test SpeechLog model serialization/deserialization
- Test SpeechLogService CRUD operations with mock Supabase client
- Test date validation logic
- Test form validation logic

### Widget Tests
- Test SpeechLogFormScreen form validation
- Test SpeechLogListWidget rendering with various data states
- Test empty state displays
- Test error state displays

### Integration Tests
- Test complete flow: create log → view log → edit log → delete log
- Test filtering and searching functionality
- Test navigation between screens
- Test data persistence across app restarts

### Manual Testing Checklist
- Create log for existing speech
- Create log with all optional fields
- Create log with minimal required fields
- Edit existing log
- Delete log
- View logs filtered by speech
- View logs filtered by date range
- Search logs by location or event type
- Verify delivery count updates on library screen
- Test with no internet connection
- Test with slow internet connection

## UI/UX Considerations

### Design Principles
- Consistent with existing Al-Minbar design language
- Use existing theme colors and typography
- Follow Material Design guidelines for forms and lists
- Maintain RTL support for Arabic text

### User Experience
- Quick access to log creation from library
- Minimal required fields to reduce friction
- Auto-save drafts to prevent data loss
- Confirmation dialogs for destructive actions (delete)
- Loading indicators for async operations
- Success feedback after save operations

### Accessibility
- Proper semantic labels for screen readers
- Sufficient color contrast for all text
- Touch targets meet minimum size requirements
- Keyboard navigation support

## Performance Considerations

### Data Loading
- Lazy load logs (paginate if user has many entries)
- Cache recently viewed logs
- Prefetch delivery counts for library screen

### Database Queries
- Use indexes for common queries (user_id, khutbah_id, delivery_date)
- Limit initial query results
- Implement pagination for large datasets

### UI Performance
- Use ListView.builder for efficient list rendering
- Implement pull-to-refresh for data updates
- Debounce search input to reduce queries

## Future Enhancements (Out of Scope for MVP)

- Analytics dashboard showing delivery patterns over time
- Export logs to CSV or PDF
- Attach photos or audio recordings to logs
- Share logs with mentors or peers
- Reminder system for follow-up improvements
- AI-powered insights based on feedback patterns
- Comparison view for same speech across different deliveries
- Rating system (1-5 stars) for quick feedback
- Tags for categorizing feedback themes
