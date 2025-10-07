import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_attendee.dart';
import '../view_models/event_view_model.dart';

class EventAttendeesScreen extends StatefulWidget {
  final Event event;

  const EventAttendeesScreen({super.key, required this.event});

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  List<EventAttendee>? _attendees;
  List<EventAttendee>? _filteredAttendees;
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterAttendees);
    _loadAttendees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    final result = await eventViewModel.getEventAttendees(widget.event.id);

    if (mounted) {
      result.when(
        success: (attendees) {
          setState(() {
            _attendees = attendees;
            _filteredAttendees = attendees;
            _isLoading = false;
          });
        },
        failure: (error) {
          setState(() {
            _error = error.userMessage;
            _isLoading = false;
          });
        },
      );
    }
  }

  void _filterAttendees() {
    if (_attendees == null) return;

    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAttendees = _attendees!.where((attendee) {
        return attendee.fullName.toLowerCase().contains(query) ||
            (attendee.foodPreferences?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendees - ${widget.event.title}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search attendees...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: ArkadColors.arkadTurkos,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: ArkadColors.arkadLightNavy,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadAttendees,
      color: ArkadColors.arkadTurkos,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredAttendees == null || _filteredAttendees!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildAttendeesList();
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading attendees...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Failed to load attendees',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ArkadButton(
                    text: 'Try Again',
                    onPressed: _loadAttendees,
                    icon: Icons.refresh_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isSearching
                          ? Icons.search_off_rounded
                          : Icons.people_outline_rounded,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSearching ? 'No matching attendees' : 'No attendees yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSearching
                        ? 'Try adjusting your search terms'
                        : 'No one has registered for this event yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAttendees!.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader();
        }

        final attendee = _filteredAttendees![index - 1];
        return _buildAttendeeCard(attendee);
      },
    );
  }

  Widget _buildHeader() {
    final totalCount = _attendees?.length ?? 0;
    final filteredCount = _filteredAttendees?.length ?? 0;
    final isFiltered = _searchController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: ArkadColors.arkadLightNavy,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: ArkadColors.arkadTurkos,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFiltered
                          ? '$filteredCount of $totalCount attendees'
                          : '$totalCount attendees',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    if (widget.event.maxParticipants != null)
                      Text(
                        'Capacity: ${widget.event.currentParticipants}/${widget.event.maxParticipants}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeeCard(EventAttendee attendee) {
    return Card(
      color: ArkadColors.arkadLightNavy,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
          child: Text(
            attendee.fullName.isNotEmpty
                ? attendee.fullName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: ArkadColors.arkadTurkos,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          attendee.fullName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        subtitle:
            attendee.foodPreferences != null &&
                attendee.foodPreferences!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        attendee.foodPreferences!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: attendee.hasBeenScanned
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ArkadColors.arkadGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ArkadColors.arkadGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: ArkadColors.arkadGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Checked In',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ArkadColors.arkadGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
