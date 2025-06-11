import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme_config.dart';

/// A reusable widget for displaying user profile information
/// This can be used in both full profile view
class ProfileInfoWidget extends StatelessWidget {
  final ProfileSchema profile;
  final bool showFullDetails;
  final VoidCallback? onEditPressed;

  const ProfileInfoWidget({
    super.key,
    required this.profile,
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
                      profile.profilePicture != null &&
                              profile.profilePicture!.isNotEmpty
                          ? NetworkImage(profile.profilePicture!)
                          : null,
                  child:
                      profile.profilePicture == null ||
                              profile.profilePicture!.isEmpty
                          ? const Icon(Icons.person, size: 60)
                          : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${profile.firstName} ${profile.lastName}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                profile.email,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (profile.programme != null &&
                  profile.programme!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  profile.programme!,
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
          _buildInfoTile(context, "Email", profile.email),

          // LinkedIn info with clickable link
          if (profile.linkedin != null && profile.linkedin!.isNotEmpty)
            InkWell(
              onTap: () => _launchUrl(context, profile.linkedin!),
              child: _buildInfoTile(
                context,
                "LinkedIn",
                profile.linkedin!,
                isLink: true,
              ),
            ),

          // Education information
          if (profile.studyYear != null)
            _buildInfoTile(context, "Study Year", "Year ${profile.studyYear}"),

          if (profile.masterTitle != null && profile.masterTitle!.isNotEmpty)
            _buildInfoTile(context, "Master Title", profile.masterTitle!),

          // Preference information
          if (profile.foodPreferences != null &&
              profile.foodPreferences!.isNotEmpty)
            _buildInfoTile(
              context,
              "Food Preferences",
              profile.foodPreferences!,
            ),

          // CV display and link
          if (profile.cv != null && profile.cv!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchUrl(context, profile.cv!),
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
