import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
import '../../utils/login_manager.dart';
import '../../view_models/auth_model.dart';
import '../../widgets/profile/profile_info_widget.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileSchema profile;

  const ProfileScreen({super.key, required this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _handleLogout(BuildContext context, AuthModel authProvider) {
    authProvider.logout();

    LoginManager.clearCredentials();

    context.go('/auth/login');
  }

  void _navigateToEditProfile() {
    final authProvider = Provider.of<AuthModel>(context, listen: false);
    final user = authProvider.user ?? widget.profile;
    context.push('/profile/edit', extra: user);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthModel>(context);
    final currentUser = authProvider.user ?? widget.profile;

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
              onRefresh: () => authProvider.refreshUserProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ProfileInfoWidget(profile: currentUser),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _handleLogout(context, authProvider),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: TextButton.styleFrom(
                          foregroundColor: ArkadColors.arkadTurkos,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Events Tab (Placeholder)
            Center(
              child: Text(
                'Coming Soon',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: ArkadColors.arkadNavy),
              ),
            ),
            // Student Sessions Tab (Placeholder)
            Center(
              child: Text(
                'Coming Soon',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: ArkadColors.arkadNavy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
