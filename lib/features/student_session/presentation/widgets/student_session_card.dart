import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';

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
              _buildHeader(context),
              const SizedBox(height: 12),
              if (session.description != null) ...[
                _buildDescription(context),
                const SizedBox(height: 12),
              ],
              _buildStatus(context),
              if (_shouldShowActions()) ...[
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              _buildAvailabilityIndicator(context),
            ],
          ),
        ),
        _buildApplicationStatusBadge(context),
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

  Widget _buildAvailabilityIndicator(BuildContext context) {
    // Determine status based on user's application state
    String statusText;
    Color statusColor;
    
    if (!session.isAvailable) {
      statusText = 'Not available';
      statusColor = Theme.of(context).colorScheme.outline;
    } else if (session.userStatus == null) {
      // No application made yet
      statusText = 'Available';
      statusColor = ArkadColors.arkadGreen;
    } else {
      // User has applied, show application status
      switch (session.userStatus!) {
        case StudentSessionStatus.pending:
          statusText = 'Pending';
          statusColor = Colors.orange;
        case StudentSessionStatus.accepted:
          statusText = 'Accepted';
          statusColor = ArkadColors.arkadGreen;
        case StudentSessionStatus.rejected:
          statusText = 'Rejected';
          statusColor = ArkadColors.lightRed;
      }
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: statusColor,
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

  Widget _buildApplicationStatusBadge(BuildContext context) {
    final currentApplication = applicationWithBookingState?.application ?? application;
    if (currentApplication == null) return const SizedBox.shrink();

    final status = currentApplication.status;
    Color badgeColor;

    switch (status) {
      case ApplicationStatus.pending:
        badgeColor = Colors.orange;
      case ApplicationStatus.accepted:
        badgeColor = ArkadColors.arkadGreen;
      case ApplicationStatus.rejected:
        badgeColor = ArkadColors.lightRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (_shouldShowApplyButton()) ...[
          Expanded(
            child: FilledButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Apply'),
              style: FilledButton.styleFrom(
                backgroundColor: ArkadColors.arkadTurkos,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else if (_shouldShowBookingButton()) ...[
          Expanded(
            child: FilledButton.icon(
              onPressed: onViewTimeslots,
              icon: Icon(_getBookingButtonIcon(), size: 18),
              label: Text(_getBookingButtonText()),
              style: FilledButton.styleFrom(
                backgroundColor: ArkadColors.arkadTurkos,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _shouldShowActions() {
    return _shouldShowApplyButton() || _shouldShowBookingButton();
  }

  bool _shouldShowApplyButton() {
    if (!session.isAvailable) return false;
    
    // Check if user has already applied (use enhanced booking state if available)
    final currentApplication = applicationWithBookingState?.application ?? application;
    if (currentApplication != null) return false; // Already applied

    // Check if we're in application period
    final status = TimelineValidationService.checkApplicationPeriod();
    return status.canApply;
  }

  bool _shouldShowBookingButton() {
    // Use enhanced booking state if available, otherwise fall back to regular application
    final currentApplication = applicationWithBookingState?.application ?? application;
    if (currentApplication?.status != ApplicationStatus.accepted) return false;

    // Check if we're in booking period
    final status = TimelineValidationService.checkBookingPeriod();
    return status.canBook;
  }

  String _getBookingButtonText() {
    // Use enhanced booking state to determine if user has existing booking
    final hasBooking = applicationWithBookingState?.hasBooking ?? false;
    return hasBooking ? 'Manage Booking' : 'Book Timeslot';
  }

  IconData _getBookingButtonIcon() {
    // Use enhanced booking state to determine if user has existing booking
    final hasBooking = applicationWithBookingState?.hasBooking ?? false;
    return hasBooking ? Icons.edit_calendar_rounded : Icons.schedule_rounded;
  }
}
