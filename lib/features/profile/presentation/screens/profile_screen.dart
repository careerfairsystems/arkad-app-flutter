import 'package:arkad/features/event/presentation/screens/booked_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/profile_info_widget.dart';
import 'staff_actions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileViewModel = Provider.of<ProfileViewModel>(
        context,
        listen: false,
      );

      // Reset all command states to prevent stale errors/states
      profileViewModel.getProfileCommand.reset();
      profileViewModel.updateProfileCommand.reset();
      profileViewModel.uploadCVCommand.reset();
      profileViewModel.uploadProfilePictureCommand.reset();

      if (profileViewModel.currentProfile == null &&
          !profileViewModel.isLoading) {
        profileViewModel.loadProfile();
      }
    });
  }

  void _handleLogout(BuildContext context, AuthViewModel authViewModel) {
    authViewModel.signOut();
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

    return Column(
      children: [
        ProfileInfoWidget(profile: profile),
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
    return Consumer2<ProfileViewModel, AuthViewModel>(
      builder: (context, profileViewModel, authViewModel, _) {
        final isStaff = authViewModel.currentUser?.isStaff ?? false;
        final tabCount = isStaff ? 4 : 3;

        return DefaultTabController(
          length: tabCount,
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
                tabs: [
                  const Tab(text: "Info"),
                  const Tab(text: "Events"),
                  const Tab(text: "Student Sessions"),
                  if (isStaff) const Tab(text: "Coordinator"),
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
                // Events Tab
                Center(child: BookedEventsScreen()),
                // Student Sessions Tab
                Center(
                  child: Text(
                    'Coming Soon',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ArkadColors.arkadNavy,
                    ),
                  ),
                ),
                // Coordinator Tab (only shown for staff)
                if (isStaff) const StaffActionsScreen(),
              ],
            ),
          ),
        );
      },
    );
  }
}
