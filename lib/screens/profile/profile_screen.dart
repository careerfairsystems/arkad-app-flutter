import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/login_manager.dart';
import '../../widgets/profile/profile_info_widget.dart';
import '../../widgets/profile/profile_onboarding_widget.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileSchema profile;

  const ProfileScreen({super.key, required this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Add listener registration flag to prevent duplicate listeners
  bool _isUserStateListenerRegistered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        profileProvider.initialize();

        // Register listener for user state changes to keep verification and profile in sync
        if (!_isUserStateListenerRegistered) {
          _isUserStateListenerRegistered = true;
          authProvider.addListener(_syncVerificationWithProfile);
        }
      }
    });
  }

  @override
  void dispose() {
    // Unregister the listener when the widget is disposed
    if (_isUserStateListenerRegistered) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_syncVerificationWithProfile);
      _isUserStateListenerRegistered = false;
    }
    super.dispose();
  }

  // Sync verification status with profile state
  void _syncVerificationWithProfile() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;

    // Immediately update profile state when verification status changes
    if (user != null && user.isVerified) {
      profileProvider.completeOnboarding();
    } else if (user != null) {
      profileProvider.refreshOnboardingState(user);
    }
  }

  Future<void> _onProfileUpdated() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final messenger = ScaffoldMessenger.of(context);

    await authProvider.refreshUserProfile();
    await profileProvider.refreshOnboardingState(authProvider.user);

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  void _navigateToEditProfile() {
    final user =
        Provider.of<AuthProvider>(context, listen: false).user ??
        widget.profile;
    context.push('/profile/edit', extra: user).then((_) => _onProfileUpdated());
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) {
    authProvider.logout();

    LoginManager.clearCredentials();

    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user ?? widget.profile;

    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => authProvider.refreshUserProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show the appropriate screen based on profile completion status
              if (profileProvider.hasIncompleteRequiredFields)
                // Onboarding wizard for incomplete profiles
                ProfileOnboardingWidget(
                  profile: currentUser,
                  onProfileUpdated: _onProfileUpdated,
                )
              else
                // Full profile view for completed profiles
                Column(
                  children: [
                    ProfileInfoWidget(profile: currentUser),

                    const SizedBox(height: 24),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _handleLogout(context, authProvider),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
