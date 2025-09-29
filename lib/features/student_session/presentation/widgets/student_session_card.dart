import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/optimized_image.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/services/student_session_data_service.dart';
import '../../domain/services/student_session_status_service.dart';
import '../mappers/student_session_status_mapper.dart';

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

    // Get domain status information using the unified status service
    final domainStatusInfo = StudentSessionStatusService.instance.getStatusInfo(
      sessionWithApp,
    );
    final domainActionInfo = StudentSessionStatusService.instance
        .getActionButtonInfo(sessionWithApp);

    // Convert domain info to UI info using the presentation mapper
    final statusInfo = StudentSessionStatusMapper.instance.mapStatusInfo(
      domainStatusInfo,
    );
    final actionInfo = StudentSessionStatusMapper.instance.mapActionInfo(
      domainActionInfo,
    );

    return Card(
      margin: margin,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: actionInfo.action != ActionType.none && actionInfo.isEnabled
            ? () {
                switch (actionInfo.action) {
                  case ActionType.apply:
                    onApply?.call();
                  case ActionType.bookTimeslot:
                  case ActionType.manageBooking:
                    onViewTimeslots?.call();
                  case ActionType.none:
                    break;
                }
              }
            : null,
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

  Widget _buildHeader(
    BuildContext context,
    StudentSessionUIStatusInfo statusInfo,
  ) {
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
    return OptimizedImage(
      imageUrl: session.logoUrl,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
      fallbackWidget: _buildDefaultLogo(context),
    );
  }

  Widget _buildDefaultLogo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
      ),
      child: const Icon(
        Icons.business_rounded,
        size: 24,
        color: ArkadColors.arkadTurkos,
      ),
    );
  }

  Widget _buildAvailabilityIndicator(
    BuildContext context,
    StudentSessionUIStatusInfo statusInfo,
  ) {
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

  Widget _buildApplicationStatusBadge(
    BuildContext context,
    StudentSessionUIStatusInfo statusInfo,
  ) {
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

  Widget _buildActions(
    BuildContext context,
    StudentSessionUIActionInfo actionInfo,
  ) {
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
              backgroundColor: actionInfo.isEnabled
                  ? actionInfo.color
                  : ArkadColors.lightGray,
              foregroundColor: ArkadColors.white,
            ),
          ),
        ),
      ],
    );
  }
}
