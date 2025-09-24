import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/services/student_session_data_service.dart';
import '../../domain/services/student_session_status_service.dart';

/// Modern student session card with status indicators and actions
class StudentSessionCard extends StatelessWidget {
  const StudentSessionCard({
    super.key,
    required this.session,
    this.application,
    this.applicationWithBookingState,
    this.onApply,
    this.onViewTimeslots,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  final StudentSession session;
  final StudentSessionApplication? application;
  final StudentSessionApplicationWithBookingState? applicationWithBookingState;
  final VoidCallback? onApply;
  final VoidCallback? onViewTimeslots;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    // Create unified session with application state for status service
    final sessionWithApp = StudentSessionWithApplicationState(
      session: session,
      applicationWithBookingState: applicationWithBookingState,
    );

    // Get status information using the unified status service
    final statusInfo = StudentSessionStatusService.instance.getStatusInfo(sessionWithApp);
    final actionInfo = StudentSessionStatusService.instance.getActionButtonInfo(sessionWithApp);

    return Container(
      margin: margin,
      child: Card(
        elevation: 2,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, statusInfo),
              const SizedBox(height: 12),
              if (session.description != null) ...[
                _buildDescription(context),
                const SizedBox(height: 12),
              ],
              _buildStatus(context),
              if (actionInfo.action != ActionType.none) ...[
                const SizedBox(height: 16),
                _buildActions(context, actionInfo),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentSessionStatusInfo statusInfo) {
    return Row(
      children: [
        _buildLogo(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.companyName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _buildAvailabilityIndicator(context, statusInfo),
            ],
          ),
        ),
        _buildApplicationStatusBadge(context, statusInfo),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child:
          session.logoUrl != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  session.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          _buildDefaultLogo(context),
                ),
              )
              : _buildDefaultLogo(context),
    );
  }

  Widget _buildDefaultLogo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.business_rounded,
        size: 24,
        color: ArkadColors.arkadTurkos,
      ),
    );
  }

  Widget _buildAvailabilityIndicator(BuildContext context, StudentSessionStatusInfo statusInfo) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusInfo.displayColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          statusInfo.displayText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: statusInfo.displayColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      session.description!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatus(BuildContext context) {
    // Application status is already shown in the top-right badge
    // No need for redundant status display here
    return const SizedBox.shrink();
  }

  Widget _buildApplicationStatusBadge(BuildContext context, StudentSessionStatusInfo statusInfo) {
    if (statusInfo.badgeText == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.badgeColor!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusInfo.badgeText!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: statusInfo.badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ActionButtonInfo actionInfo) {
    VoidCallback? buttonCallback;
    
    switch (actionInfo.action) {
      case ActionType.apply:
        buttonCallback = onApply;
      case ActionType.bookTimeslot:
      case ActionType.manageBooking:
        buttonCallback = onViewTimeslots;
      case ActionType.none:
        buttonCallback = null;
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: actionInfo.isEnabled ? buttonCallback : null,
            icon: Icon(actionInfo.icon, size: 18),
            label: Text(actionInfo.text),
            style: FilledButton.styleFrom(
              backgroundColor: actionInfo.isEnabled ? actionInfo.color : ArkadColors.lightGray,
              foregroundColor: ArkadColors.white,
            ),
          ),
        ),
      ],
    );
  }

}
