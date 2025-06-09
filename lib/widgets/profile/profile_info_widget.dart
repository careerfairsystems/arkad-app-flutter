import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme_config.dart';
import '../../models/user.dart';

class ProfileInfoWidget extends StatelessWidget {
  final User user;

  const ProfileInfoWidget({
    super.key,
    required this.user,
  });

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Widget _buildInfoTile(BuildContext context, String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
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
                  backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                      ? NetworkImage(user.profilePicture!)
                      : null,
                  child: user.profilePicture == null || user.profilePicture!.isEmpty
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
    );
  }
}
