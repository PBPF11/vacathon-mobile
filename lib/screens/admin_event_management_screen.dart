import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'admin_event_form_screen.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class AdminEventManagementScreen extends StatefulWidget {
  const AdminEventManagementScreen({super.key});

  @override
  State<AdminEventManagementScreen> createState() =>
      _AdminEventManagementScreenState();
}

class _AdminEventManagementScreenState
    extends State<AdminEventManagementScreen> {
  EventsResponse? _eventsResponse;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;

  List<Event> get _events => _eventsResponse?.events ?? [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents({bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await ApiService.instance.getAdminEvents(
        page: _currentPage,
      );
      if (!mounted) return;
      setState(() {
        if (reset || _eventsResponse == null) {
          _eventsResponse = response;
        } else {
          _eventsResponse = EventsResponse(
            events: [..._events, ...response.events],
            pagination: response.pagination,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load events: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openEventForm({Event? event}) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.9;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: AdminEventFormContent(
                event: event,
                showClose: true,
                inDialog: true,
              ),
            ),
          ),
        );
      },
    );

    if (result == 'created' || result == 'updated') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'created'
                ? 'Event created successfully.'
                : 'Event updated successfully.',
          ),
        ),
      );
      _loadEvents(reset: true);
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text('Delete "${event.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.instance.deleteEvent(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully.')),
      );
      _loadEvents(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $e')),
      );
    }
  }

  void _loadMore() {
    if (_eventsResponse?.pagination.hasNext != true || _isLoadingMore) return;
    _currentPage += 1;
    _loadEvents(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;
    final isAdmin = profile?.isStaff == true || profile?.isSuperuser == true;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Event Management'),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: _buildSurfaceCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: primaryColor, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Admin access only',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You do not have permission to view this page.',
                  style: TextStyle(color: textColor.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Event Management'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          else
            RefreshIndicator(
              onRefresh: () => _loadEvents(reset: true),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildActions(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorCard(_errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  if (_events.isEmpty)
                    _buildEmptyState()
                  else
                    _buildEventGrid(),
                  if (_eventsResponse?.pagination.hasNext == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                        onPressed: _isLoadingMore ? null : _loadMore,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _isLoadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              )
                            : const Text('Load more events'),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Events',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage all marathon events below.',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _openEventForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: whiteColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Add New Event',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 980
            ? 3
            : width >= 640
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width >= 980 ? 1.4 : 1.25,
          ),
          itemCount: _events.length,
          itemBuilder: (context, index) {
            final event = _events[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Event event) {
    final formatter = DateFormat('d MMM yyyy');
    final statusLabel = _statusLabel(event.status);
    final statusColor = _statusColor(event.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: whiteColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'City: ${event.city}',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            'Start Date: ${formatter.format(event.startDate)}',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          if (event.categories.isEmpty)
            Text(
              '-',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: event.categories
                  .map(
                    (category) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category.displayName,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const Spacer(),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _openEventForm(event: event),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _deleteEvent(event),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      case 'upcoming':
      default:
        return 'Upcoming';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ongoing':
        return primaryColor;
      case 'completed':
        return Colors.grey;
      case 'upcoming':
      default:
        return accentColor.withOpacity(0.9);
    }
  }

  Widget _buildEmptyState() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.event_note,
            size: 40,
            color: textColor.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No events found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first event to get started.',
            style: TextStyle(color: textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildSurfaceCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bgColor,
                bgColor.withOpacity(0.9),
                whiteColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              _buildBubble(
                top: -60,
                right: -40,
                size: 200,
                color: primaryColor.withOpacity(0.12),
              ),
              _buildBubble(
                bottom: -80,
                left: -60,
                size: 260,
                color: accentColor.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
