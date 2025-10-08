import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pulpitflow/screens/simple_auth_screen.dart';
import 'package:pulpitflow/screens/home_screen.dart';
import 'package:pulpitflow/supabase/supabase_config.dart';
import 'package:pulpitflow/services/user_data_service.dart';

/// Wrapper widget that handles authentication state and shows appropriate screen
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _setupAuthListener();
  }

  void _initializeAuth() {
    final session = SupabaseConfig.client.auth.currentSession;
    setState(() {
      _isAuthenticated = session != null;
      _isLoading = false;
    });

    // If user is authenticated, sync their data
    if (_isAuthenticated) {
      _syncUserData();
    }
  }

  void _setupAuthListener() {
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final isAuthenticated = session != null;

      if (mounted) {
        setState(() {
          _isAuthenticated = isAuthenticated;
        });

        if (isAuthenticated) {
          _syncUserData();
        } else {
          UserDataService.onUserLogout();
        }
      }
    });
  }

  Future<void> _syncUserData() async {
    try {
      await UserDataService.onUserLogin();
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated ? const AuthenticatedApp() : const SimpleAuthScreen();
  }
}

/// Widget that shows the main app with user profile and logout functionality
class AuthenticatedApp extends StatelessWidget {
  const AuthenticatedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreenWithAuth();
  }
}

/// Enhanced home screen with authentication features
class HomeScreenWithAuth extends StatelessWidget {
  const HomeScreenWithAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomeScreen(),
      drawer: _buildUserDrawer(context),
    );
  }

  Widget _buildUserDrawer(BuildContext context) {
    final user = SupabaseAuth.currentUser;
    final userEmail = user?.email ?? '';
    final userName = user?.userMetadata?['full_name'] as String? ?? 
                     userEmail.split('@').first;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Data'),
            subtitle: const Text('Sync your khutbahs with cloud'),
            onTap: () async {
              Navigator.pop(context);
              await _syncData(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Backup Status'),
            subtitle: Text(
              SupabaseAuth.isAuthenticated 
                  ? 'Data is backed up to cloud' 
                  : 'No cloud backup',
            ),
            trailing: Icon(
              SupabaseAuth.isAuthenticated 
                  ? Icons.cloud_done 
                  : Icons.cloud_off,
              color: SupabaseAuth.isAuthenticated 
                  ? Colors.green 
                  : Colors.orange,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Account Settings'),
            onTap: () {
              Navigator.pop(context);
              _showAccountSettings(context);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _syncData(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syncing data...')),
      );
      
      await UserDataService.syncKhutbahsToCloud();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data synced successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showAccountSettings(BuildContext context) {
    final user = SupabaseAuth.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('User ID: ${user?.id ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Account created: ${user?.createdAt ?? 'Unknown'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPassword(context);
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context) async {
    final user = SupabaseAuth.currentUser;
    if (user?.email == null) return;

    try {
      await SupabaseAuth.resetPassword(user!.email!);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset email sent'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseAuth.signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}