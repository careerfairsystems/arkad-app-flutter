import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme_config.dart';
import '../../models/user.dart';

/// A reusable widget for displaying user profile information
/// This can be used in both full profile view
class ProfileInfoWidget extends StatelessWidget {
  final User user;
  final bool showFullDetails;
  final VoidCallback? onEditPressed;

  const ProfileInfoWidget({
    super.key,
    required this.user,
    this.showFullDetails = true,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile header with image and name
        Center(
          child: Column(
            children: [
              Hero(
                tag: 'profilePicture',
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      user.profilePicture != null &&
                              user.profilePicture!.isNotEmpty
                          ? NetworkImage(user.profilePicture!)
                          : null,
                  child:
                      user.profilePicture == null ||
                              user.profilePicture!.isEmpty
                          ? const Icon(Icons.person, size: 60)
                          : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${user.firstName ?? 'No'} ${user.lastName ?? 'Name'}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(user.email, style: Theme.of(context).textTheme.titleSmall),
              if (user.programme != null && user.programme!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  user.programme!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),

        if (showFullDetails) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Basic information section
          _buildInfoTile(context, "Email", user.email),

          // LinkedIn info with clickable link
          if (user.linkedin != null && user.linkedin!.isNotEmpty)
            InkWell(
              onTap: () => _launchUrl(context, user.linkedin!),
              child: _buildInfoTile(
                context,
                "LinkedIn",
                user.linkedin!,
                isLink: true,
              ),
            ),

          // Education information
          if (user.studyYear != null)
            _buildInfoTile(context, "Study Year", "Year ${user.studyYear}"),

          if (user.masterTitle != null && user.masterTitle!.isNotEmpty)
            _buildInfoTile(context, "Master Title", user.masterTitle!),

          // Preference information
          if (user.foodPreferences != null && user.foodPreferences!.isNotEmpty)
            _buildInfoTile(context, "Food Preferences", user.foodPreferences!),

          // CV display and link
          if (user.cv != null && user.cv!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchUrl(context, user.cv!),
              icon: const Icon(Icons.description),
              label: const Text("View CV"),
            ),
          ],
        ],

        // Edit button if provided
        if (onEditPressed != null) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                foregroundColor: ArkadColors.arkadTurkos,
                backgroundColor: Colors.white,
                side: BorderSide(color: ArkadColors.arkadTurkos),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Helper method to build an information tile
  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value, {
    bool isLink = false,
  }) {
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

  /// Helper method to launch URLs safely
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
}
