# Authentication Setup Guide

This guide explains how to set up the authentication system for Al-Minbar (PulpitFlow) with Supabase.

## Features Added

✅ **Login/Signup Screen** - Complete authentication UI with email/password
✅ **User Data Persistence** - Khutbahs are saved both locally and in the cloud
✅ **Data Synchronization** - Automatic sync between local and cloud storage
✅ **Multi-language Support** - Authentication UI supports English, Urdu, Norwegian, and French
✅ **Offline Support** - App works offline with local storage, syncs when online
✅ **User Profile Management** - User drawer with account settings and logout

## Database Setup

1. **Run the SQL Migration**
   - Copy the contents of `supabase_migration.sql`
   - Go to your Supabase project dashboard
   - Navigate to SQL Editor
   - Paste and run the migration script

2. **Verify Tables Created**
   - `user_khutbahs` - Stores user-specific khutbah data
   - `users` - Stores user profile information
   - Row Level Security (RLS) is enabled for data privacy

## How It Works

### Authentication Flow
1. App starts with `AuthWrapper` checking authentication status
2. If not authenticated → Shows `AuthScreen` (login/signup)
3. If authenticated → Shows `HomeScreenWithAuth` with user drawer

### Data Persistence
- **Local Storage**: Uses SQLite (mobile) or SharedPreferences (web)
- **Cloud Storage**: Uses Supabase with user-specific tables
- **Sync Strategy**: 
  - Always save locally first (for offline support)
  - Sync to cloud if user is authenticated
  - On login: merge local and cloud data (cloud takes precedence for conflicts)

### User Experience
- **Offline First**: App works without internet connection
- **Seamless Sync**: Data automatically syncs when user logs in
- **Data Safety**: Local data is preserved even when logged out
- **Multi-device**: Same account can be used across multiple devices

## Key Files Added/Modified

### New Files
- `lib/screens/auth_screen.dart` - Login/signup UI
- `lib/widgets/auth_wrapper.dart` - Authentication state management
- `lib/services/user_data_service.dart` - User data sync service
- `supabase_migration.sql` - Database schema

### Modified Files
- `lib/main.dart` - Uses AuthWrapper instead of direct HomeScreen
- `lib/screens/home_screen.dart` - Added drawer button, uses UserDataService
- `lib/screens/library_screen.dart` - Uses UserDataService for khutbahs
- `lib/screens/editor_screen.dart` - Uses UserDataService for saving
- `lib/l10n/app_localizations.dart` - Added authentication strings

## User Interface Features

### Authentication Screen
- Tab-based UI (Sign In / Sign Up)
- Form validation with error messages
- Password visibility toggle
- Forgot password functionality
- Multi-language support

### User Drawer (when authenticated)
- User profile display
- Manual sync option
- Backup status indicator
- Account settings
- Sign out functionality

## Security Features

- **Row Level Security**: Users can only access their own data
- **Automatic User Profiles**: Created on signup via database trigger
- **Password Reset**: Email-based password recovery
- **Data Isolation**: Each user's khutbahs are completely separate

## Usage

1. **First Time Users**: Sign up with email and password
2. **Existing Users**: Sign in with credentials
3. **Offline Usage**: Create and edit khutbahs without internet
4. **Sync Data**: Manual sync via user drawer or automatic on login
5. **Multi-device**: Login on another device to access your khutbahs

## Technical Notes

- Uses Supabase Auth for user management
- Implements optimistic UI updates (save locally first)
- Handles network failures gracefully
- Maintains data consistency across devices
- Supports both web and mobile platforms