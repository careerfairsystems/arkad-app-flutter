import 'package:arkad/features/event/presentation/screens/booked_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../services/service_locator.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../../notifications/data/services/fcm_service.dart';
import '../../../student_session/presentation/widgets/profile_student_sessions_tab.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/profile_info_widget.dart';

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

  Future<void> _sendTestNotification() async {
    final fcmService = serviceLocator<FcmService>();
    final localNotifications = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'arkad_notifications',
      'Arkad Notifications',
      channelDescription: 'Important notifications from Arkad',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Test Notification',
      'This is a test notification from Arkad!',
      details,
      payload: '{"link": "https://app.arkadtlth.se/companies"}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildProfileContent(ProfileViewModel profileViewModel) {
    final profile = profileViewModel.currentProfile;
    final isLoading = profileViewModel.isLoading;
    final error = profileViewModel.error;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuthFormWidgets.buildErrorMessage(
              error,
              onDismiss: () => profileViewModel.clearError(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: profileViewModel.canRetry
                  ? () => profileViewModel.retryLastOperation()
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArkadColors.arkadTurkos,
                foregroundColor: ArkadColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: ArkadColors.arkadLightNavy,
                disabledForegroundColor: ArkadColors.lightGray,
              ),
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
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: ArkadButton(
            text: "Test Notification",
            onPressed: _sendTestNotification,
            variant: ArkadButtonVariant.secondary,
            size: ArkadButtonSize.medium,
            icon: Icons.notifications,
            fullWidth: true,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<AuthViewModel>(
          builder: (context, authViewModel, _) {
            return Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: ArkadButton(
                  text: "Log Out",
                  onPressed: () => _handleLogout(context, authViewModel),
                  variant: ArkadButtonVariant.danger,
                  size: ArkadButtonSize.medium,
                  icon: Icons.logout,
                  fullWidth: true,
                ),
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
        const tabCount = 3;

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
                tabs: const [
                  Tab(text: "Info"),
                  Tab(text: "Events"),
                  Tab(text: "Sessions"),
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
                const Center(child: BookedEventsScreen()),
                // Student Sessions Tab
                const ProfileStudentSessionsTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}
