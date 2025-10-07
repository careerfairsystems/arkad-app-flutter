import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
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
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: ArkadColors.arkadTurkos),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'MyriadProCondensed',
                        color: ArkadColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'MyriadProCondensed',
                        color: isLink
                            ? ArkadColors.arkadTurkos
                            : Colors.white, // Back to white
                        fontWeight: FontWeight.w500,
                        decoration: isLink ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLink) ...[
                const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: ArkadColors.arkadTurkos,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ArkadColors.arkadLightNavy,
      elevation: 2,
      surfaceTintColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header with image, name and email
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'profilePicture',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: ArkadColors.arkadTurkos.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage:
                          profile.profilePictureUrl != null &&
                              profile.profilePictureUrl!.isNotEmpty
                          ? NetworkImage(profile.profilePictureUrl!)
                          : null,
                      child:
                          profile.profilePictureUrl == null ||
                              profile.profilePictureUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: ArkadColors.arkadTurkos,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        "${profile.firstName} ${profile.lastName}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontFamily: 'MyriadProCondensed',
                          fontWeight: FontWeight.w600,
                          color: ArkadColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'MyriadProCondensed',
                          color: ArkadColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: ArkadColors.gray.withValues(alpha: 0.2)),
            const SizedBox(height: 12),

            // Information section with icons (email removed from tiles since it's in header)
            // Programme information first since email is now in header
            if (profile.programme != null) ...[
              Builder(
                builder: (context) {
                  final programmeLabel = ProgrammeUtils.programmeToLabel(
                    profile.programme!,
                  );
                  if (programmeLabel != null && programmeLabel.isNotEmpty) {
                    return _buildInfoTile(
                      context,
                      Icons.school,
                      "Programme",
                      programmeLabel,
                    );
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
                  return _buildInfoTile(
                    context,
                    Icons.link,
                    "LinkedIn",
                    linkedInUrl,
                    isLink: true,
                    onTap: () => _launchUrl(context, linkedInUrl),
                  );
                },
              ),
            ],

            // Education information
            if (profile.studyYear != null)
              _buildInfoTile(
                context,
                Icons.calendar_today,
                "Study Year",
                "Year ${profile.studyYear}",
              ),

            if (profile.masterTitle != null && profile.masterTitle!.isNotEmpty)
              _buildInfoTile(
                context,
                Icons.school,
                "Master",
                profile.masterTitle!,
              ),

            // Preference information
            if (profile.foodPreferences != null &&
                profile.foodPreferences!.isNotEmpty)
              _buildInfoTile(
                context,
                Icons.restaurant,
                "Food Preferences",
                profile.foodPreferences!,
              ),

            // CV display and link
            if (profile.cvUrl != null && profile.cvUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ArkadButton(
                  text: "View CV",
                  onPressed: () => _launchUrl(context, profile.cvUrl!),
                  variant: ArkadButtonVariant.secondary,
                  size: ArkadButtonSize.small,
                  icon: Icons.description,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
