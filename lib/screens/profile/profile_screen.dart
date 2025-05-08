import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme_config.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_onboarding_provider.dart';
import '../../utils/login_manager.dart';
import '../../widgets/profile_onboarding_widget.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

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
        final onboardingProvider = Provider.of<ProfileOnboardingProvider>(
          context,
          listen: false,
        );
        onboardingProvider.initialize(user);

        // Register listener for user state changes to keep verification and onboarding in sync
        if (!_isUserStateListenerRegistered) {
          _isUserStateListenerRegistered = true;
          authProvider.addListener(_syncVerificationWithOnboarding);
        }
      }
    });
  }

  @override
  void dispose() {
    // Unregister the listener when the widget is disposed
    if (_isUserStateListenerRegistered) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_syncVerificationWithOnboarding);
      _isUserStateListenerRegistered = false;
    }
    super.dispose();
  }

  // Sync verification status with onboarding state
  void _syncVerificationWithOnboarding() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider = Provider.of<ProfileOnboardingProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;

    // Immediately update onboarding state when verification status changes
    if (user != null && user.isVerified) {
      onboardingProvider.completeOnboarding();
    } else if (user != null) {
      onboardingProvider.refreshOnboardingState(user);
    }
  }

  Future<void> _onProfileUpdated() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider = Provider.of<ProfileOnboardingProvider>(
      context,
      listen: false,
    );
    final messenger = ScaffoldMessenger.of(context);

    await authProvider.refreshUserProfile();
    await onboardingProvider.refreshOnboardingState(authProvider.user);

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user ?? widget.user;

    // Access the onboarding provider to check profile completion status
    final onboardingProvider = Provider.of<ProfileOnboardingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: currentUser),
                ),
              ).then((_) => _onProfileUpdated());
            },
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
              if (!currentUser.isVerified &&
                  onboardingProvider.hasIncompleteRequiredFields)
                ProfileOnboardingWidget(
                  user: currentUser,
                  onProfileUpdated: _onProfileUpdated,
                )
              else if (currentUser.isVerified &&
                  !onboardingProvider.hasIncompleteRequiredFields)
                Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Hero(
                            tag: 'profilePicture',
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  currentUser.profilePicture != null
                                      ? NetworkImage(
                                        currentUser.profilePicture!,
                                      )
                                      : null,
                              child:
                                  currentUser.profilePicture == null
                                      ? const Icon(Icons.person, size: 60)
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${currentUser.firstName ?? 'No'} ${currentUser.lastName ?? 'Name'}",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            currentUser.email,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (currentUser.programme != null &&
                              currentUser.programme!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              currentUser.programme!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Profile information
                    _buildInfoTile("Email", currentUser.email),

                    if (currentUser.linkedin != null &&
                        currentUser.linkedin!.isNotEmpty)
                      InkWell(
                        onTap: () => _launchUrl(context, currentUser.linkedin!),
                        child: _buildInfoTile(
                          "LinkedIn",
                          currentUser.linkedin!,
                          isLink: true,
                        ),
                      ),

                    if (currentUser.studyYear != null)
                      _buildInfoTile(
                        "Study Year",
                        "Year ${currentUser.studyYear}",
                      ),

                    if (currentUser.masterTitle != null &&
                        currentUser.masterTitle!.isNotEmpty)
                      _buildInfoTile("Master Title", currentUser.masterTitle!),

                    if (currentUser.foodPreferences != null &&
                        currentUser.foodPreferences!.isNotEmpty)
                      _buildInfoTile(
                        "Food Preferences",
                        currentUser.foodPreferences!,
                      ),

                    if (currentUser.cv != null &&
                        currentUser.cv!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(context, currentUser.cv!),
                        icon: const Icon(Icons.description),
                        label: const Text("View CV"),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _handleLogout(context, authProvider),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                      ),
                    ),
                  ],
                )
              else if (!onboardingProvider.hasIncompleteRequiredFields &&
                  onboardingProvider.optionalFields.length >
                      onboardingProvider.completedOptionalFields.length)
                _buildOptionalFieldsCard(context, onboardingProvider),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to show optional fields completion card
  Widget _buildOptionalFieldsCard(
    BuildContext context,
    ProfileOnboardingProvider provider,
  ) {
    double completionPercentage =
        provider.completedOptionalFields.length /
        provider.optionalFields.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ArkadColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile completion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(completionPercentage * 100).toInt()}%',
                  style: TextStyle(
                    color: ArkadColors.arkadTurkos,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionPercentage,
                backgroundColor: ArkadColors.lightGray,
                color: ArkadColors.arkadTurkos,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your profile to make it more effective!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ArkadColors.arkadTurkos,
                side: BorderSide(color: ArkadColors.arkadTurkos),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: widget.user),
                  ),
                ).then((_) => _onProfileUpdated());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    // Ensure URL has proper scheme
    String fixedUrl = urlString;
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      fixedUrl = 'https://$urlString';
    }

    try {
      // Parse the URL with fixed scheme
      final Uri uri = Uri.parse(fixedUrl);

      // Check if the URL can be launched
      if (await canLaunchUrl(uri)) {
        // Launch URL in external browser
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Show error if URL can't be launched
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open: $urlString')));
        }
      }
    } catch (e) {
      // Show error on exception (e.g., malformed URL)
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid URL: $urlString')));
      }
    }
  }

  // Helper method to handle logout
  void _handleLogout(BuildContext context, AuthProvider authProvider) {
    // Clear auth data
    authProvider.logout();

    // Clear text field values
    LoginManager.clearCredentials();

    // Navigate to login screen
    context.go('/auth/login');
  }

  Widget _buildInfoTile(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              decoration: isLink ? TextDecoration.underline : null,
              color: isLink ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }
}
