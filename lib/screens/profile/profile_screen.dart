import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
import '../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../features/profile/presentation/view_models/profile_view_model.dart';
import '../../features/profile/presentation/widgets/profile_info_widget.dart';
import '../../utils/login_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load profile if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
      if (profileViewModel.currentProfile == null && !profileViewModel.isLoading) {
        profileViewModel.loadProfile();
      }
    });
  }

  void _handleLogout(BuildContext context, AuthViewModel authViewModel) {
    authViewModel.signOut();
    LoginManager.clearCredentials();
    context.go('/auth/login');
  }

  void _navigateToEditProfile() {
    context.push('/profile/edit');
  }

  Widget _buildProfileContent(ProfileViewModel profileViewModel) {
    final profile = profileViewModel.currentProfile;
    final isLoading = profileViewModel.isLoading;
    final error = profileViewModel.error;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: ArkadColors.lightRed, size: 48),
            const SizedBox(height: 16),
            Text(error.userMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => profileViewModel.refreshProfile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (profile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 48),
            SizedBox(height: 16),
            Text('No profile data available'),
          ],
        ),
      );
    }

    // Convert Profile domain entity to ProfileSchema for legacy widget compatibility
    final profileDto = ProfileSchema((b) => b
      ..id = profile.id
      ..email = profile.email
      ..firstName = profile.firstName
      ..lastName = profile.lastName
      ..isStudent = true
      ..isActive = true
      ..isStaff = false
      ..cv = profile.cvUrl
      ..profilePicture = profile.profilePictureUrl
      ..programme = profile.programme?.name
      ..linkedin = profile.linkedin
      ..masterTitle = profile.masterTitle
      ..studyYear = profile.studyYear
      ..foodPreferences = profile.foodPreferences);

    return Column(
      children: [
        ProfileInfoWidget(profile: profileDto),
        const SizedBox(height: 24),
        Consumer<AuthViewModel>(
          builder: (context, authViewModel, _) {
            return TextButton.icon(
              onPressed: () => _handleLogout(context, authViewModel),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: TextButton.styleFrom(
                foregroundColor: ArkadColors.arkadTurkos,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, _) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Profile"),
              elevation: 2,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEditProfile,
                ),
              ],
              bottom: TabBar(
                tabs: const [
                  Tab(text: "Info"),
                  Tab(text: "Events"),
                  Tab(text: "Student Sessions"),
                ],
                labelColor: ArkadColors.white,
                unselectedLabelColor: ArkadColors.white.withValues(alpha: 0.7),
                indicatorColor: ArkadColors.arkadTurkos,
                indicatorWeight: 3,
              ),
            ),
            body: TabBarView(
              children: [
                // Info Tab
                RefreshIndicator(
                  onRefresh: () => profileViewModel.refreshProfile(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: _buildProfileContent(profileViewModel),
                  ),
                ),
                // Events Tab (Placeholder)
                Center(
                  child: Text(
                    'Coming Soon',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ArkadColors.arkadNavy,
                    ),
                  ),
                ),
                // Student Sessions Tab (Placeholder)
                Center(
                  child: Text(
                    'Coming Soon',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ArkadColors.arkadNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}