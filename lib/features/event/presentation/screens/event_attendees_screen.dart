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
      _filteredAttendees =
          _attendees!.where((attendee) {
            return attendee.fullName.toLowerCase().contains(query) ||
                (attendee.foodPreferences?.toLowerCase().contains(query) ??
                    false);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendees - ${widget.event.title}'),
        backgroundColor: ArkadColors.arkadTurkos,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [_buildSearchBar(), Expanded(child: _buildBody())],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search attendees...',
          prefixIcon: const Icon(Icons.search, color: ArkadColors.arkadTurkos),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ArkadColors.arkadTurkos),
          ),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: ArkadColors.arkadTurkos),
          SizedBox(height: 16),
          Text('Loading attendees...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ArkadColors.lightRed),
            const SizedBox(height: 16),
            Text(
              'Failed to load attendees',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ArkadButton(
              text: 'Try Again',
              onPressed: _loadAttendees,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ArkadColors.arkadTurkos.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.people_outline,
                size: 64,
                color: ArkadColors.arkadTurkos,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? 'No matching attendees' : 'No attendees yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try adjusting your search terms'
                  : 'No one has registered for this event yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeesList() {
    return RefreshIndicator(
      onRefresh: _loadAttendees,
      color: ArkadColors.arkadTurkos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAttendees!.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }

          final attendee = _filteredAttendees![index - 1];
          return _buildAttendeeCard(attendee);
        },
      ),
    );
  }

  Widget _buildHeader() {
    final totalCount = _attendees?.length ?? 0;
    final filteredCount = _filteredAttendees?.length ?? 0;
    final isFiltered = _searchController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArkadColors.arkadTurkos.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people, color: ArkadColors.arkadTurkos),
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
                        color: ArkadColors.arkadNavy,
                      ),
                    ),
                    if (widget.event.maxParticipants != null)
                      Text(
                        'Capacity: ${widget.event.currentParticipants}/${widget.event.maxParticipants}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ArkadColors.arkadNavy.withValues(alpha: 0.7),
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
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: ArkadColors.arkadTurkos.withOpacity(0.1),
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
            color: ArkadColors.arkadNavy,
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
                        Icons.restaurant,
                        size: 16,
                        color: ArkadColors.arkadNavy.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          attendee.foodPreferences!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: ArkadColors.arkadNavy.withValues(alpha: 0.7),
                          ),
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
