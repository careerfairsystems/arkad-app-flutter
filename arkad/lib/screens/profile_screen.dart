import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/profile_completion_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _checkedProfileCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
    });
  }

  Future<void> _checkProfileCompletion() async {
    if (_checkedProfileCompletion) return;

    // Show profile completion dialog as a suggestion, not a requirement
    // This will now show for all new users without checking for required fields
    _showProfileCompletionDialog();

    setState(() {
      _checkedProfileCompletion = true;
    });
  }

  Future<void> _showProfileCompletionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow users to dismiss by tapping outside
      builder: (BuildContext context) {
        return const ProfileCompletionDialog();
      },
    );

    // If dialog was completed successfully, refresh the profile
    if (result == true) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshUserProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user ?? widget.user;

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
              );
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
              Center(
                child: Column(
                  children: [
                    Hero(
                      tag: 'profilePicture',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: currentUser.profilePicture != null
                            ? NetworkImage(currentUser.profilePicture!)
                            : null,
                        child: currentUser.profilePicture == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${currentUser.firstName} ${currentUser.lastName}",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      currentUser.email,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
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
                  child: _buildInfoTile("LinkedIn", currentUser.linkedin!,
                      isLink: true),
                ),

              if (currentUser.studyYear != null)
                _buildInfoTile("Study Year", "Year ${currentUser.studyYear}"),

              if (currentUser.masterTitle != null &&
                  currentUser.masterTitle!.isNotEmpty)
                _buildInfoTile("Master Title", currentUser.masterTitle!),

              if (currentUser.foodPreferences != null &&
                  currentUser.foodPreferences!.isNotEmpty)
                _buildInfoTile(
                    "Food Preferences", currentUser.foodPreferences!),

              if (currentUser.cv != null && currentUser.cv!.isNotEmpty) ...[
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
          ),
        ),
      ),
      // Add floating action button to trigger profile completion manually
      floatingActionButton: FloatingActionButton(
        onPressed: _showProfileCompletionDialog,
        child: const Icon(Icons.person_add),
        tooltip: 'Complete Profile',
      ),
    );
  }

  // Helper method to handle URL launching
  void _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Using a synchronous call after async to check if context is still valid
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  // Helper method to handle logout
  void _handleLogout(BuildContext context, AuthProvider authProvider) {
    // First handle the synchronous part
    authProvider.logout();

    // Then navigate - no async gap here
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Widget _buildInfoTile(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              decoration: isLink ? TextDecoration.underline : null,
              color: isLink ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }
}
