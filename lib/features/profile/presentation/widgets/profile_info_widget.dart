import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/domain/validation_service.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/programme.dart';

class ProfileInfoWidget extends StatelessWidget {
  final Profile profile;

  const ProfileInfoWidget({super.key, required this.profile});

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open $url')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid URL format')));
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
              ).textTheme.titleSmall?.copyWith(color: ArkadColors.gray),
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
        // Profile header with image and name only
        Center(
          child: Column(
            children: [
              Hero(
                tag: 'profilePicture',
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      profile.profilePictureUrl != null &&
                          profile.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(profile.profilePictureUrl!)
                      : null,
                  child:
                      profile.profilePictureUrl == null ||
                          profile.profilePictureUrl!.isEmpty
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${profile.firstName} ${profile.lastName}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Basic information section
        _buildInfoTile(context, "Email", profile.email),

        // Programme information
        if (profile.programme != null) ...[
          Builder(
            builder: (context) {
              final programmeLabel = ProgrammeUtils.programmeToLabel(
                profile.programme!,
              );
              if (programmeLabel != null && programmeLabel.isNotEmpty) {
                return _buildInfoTile(context, "Programme", programmeLabel);
              }
              return const SizedBox.shrink();
            },
          ),
        ],

        // LinkedIn info with clickable link
        if (profile.linkedin != null && profile.linkedin!.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final linkedInUrl = ValidationService.buildLinkedInUrl(
                profile.linkedin!,
              );
              return InkWell(
                onTap: () => _launchUrl(context, linkedInUrl),
                child: _buildInfoTile(
                  context,
                  "LinkedIn",
                  linkedInUrl,
                  isLink: true,
                ),
              );
            },
          ),
        ],

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
        if (profile.cvUrl != null && profile.cvUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _launchUrl(context, profile.cvUrl!),
            icon: const Icon(Icons.description, color: ArkadColors.white),
            label: const Text("View CV"),
          ),
        ],
      ],
    );
  }
}
