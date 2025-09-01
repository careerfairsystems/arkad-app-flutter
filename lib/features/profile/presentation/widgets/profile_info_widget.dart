import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';

class ProfileInfoWidget extends StatelessWidget {
  final ProfileSchema profile;

  const ProfileInfoWidget({super.key, required this.profile});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value, {
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isLink ? ArkadColors.arkadTurkos : null,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          _buildInfoTile(context, "Food Preferences", profile.foodPreferences!),

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
    );
  }
}
