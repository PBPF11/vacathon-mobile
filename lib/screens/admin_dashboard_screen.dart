import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _totalParticipants = 0;
  int _totalEvents = 0;
  int _activeEvents = 0;
  int _completedEvents = 0;
  List<_ParticipantSummary> _participantSummary = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService.instance;
      final totalEventsResponse = await api.getAdminEvents(page: 1);
      final activeEventsResponse = await api.getAdminEvents(
        page: 1,
        filters: {'status': 'upcoming'},
      );
      final completedEventsResponse = await api.getAdminEvents(
        page: 1,
        filters: {'status': 'completed'},
      );

      final firstRegistrations = await api.getAdminRegistrations(page: 1);
      final registrations = await _collectRegistrations(firstRegistrations);

      final summary = _summarizeRegistrations(registrations);

      if (!mounted) return;
      setState(() {
        _totalEvents = totalEventsResponse.pagination.total;
        _activeEvents = activeEventsResponse.pagination.total;
        _completedEvents = completedEventsResponse.pagination.total;
        _totalParticipants = firstRegistrations.total;
        _participantSummary = summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load admin dashboard: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<EventRegistration>> _collectRegistrations(
    RegistrationsResponse firstPage,
  ) async {
    final registrations = <EventRegistration>[...firstPage.registrations];
    var hasNext = firstPage.hasNext;
    var page = 2;
    var guard = 0;

    while (hasNext && guard < 50) {
      final response =
          await ApiService.instance.getAdminRegistrations(page: page);
      registrations.addAll(response.registrations);
      hasNext = response.hasNext;
      page += 1;
      guard += 1;
    }

    return registrations;
  }

  List<_ParticipantSummary> _summarizeRegistrations(
    List<EventRegistration> registrations,
  ) {
    final counts = <String, int>{};
    for (final registration in registrations) {
      final title = registration.event.title.trim();
      if (title.isEmpty) continue;
      counts[title] = (counts[title] ?? 0) + 1;
    }
    final summary = counts.entries
        .map((entry) => _ParticipantSummary(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return summary;
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
          title: const Text('Admin Dashboard'),
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
        title: const Text('Admin Dashboard'),
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
          else if (_errorMessage != null)
            Center(
              child: _buildSurfaceCard(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          else
            RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 16),
                  _buildAdminActions(),
                  const SizedBox(height: 16),
                  _buildParticipantSummary(),
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
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Overview of all marathon events and participants.',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem('Total Participants', _totalParticipants),
      _StatItem('Total Events', _totalEvents),
      _StatItem('Active Events', _activeEvents),
      _StatItem('Completed Events', _completedEvents),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: width >= 900 ? 2.8 : 2.4,
          children: stats
              .map(
                (stat) => _buildSurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        stat.value.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildAdminActions() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/admin/events'),
                  icon: const Icon(Icons.event),
                  label: const Text('Manage Events'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/admin/participants'),
                  icon: const Icon(Icons.people),
                  label: const Text('Manage Participants'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Forum moderation is available on the web.'),
                ),
              );
            },
            icon: const Icon(Icons.gavel),
            label: const Text('Moderate Forum'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantSummary() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participants per Event Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          if (_participantSummary.isEmpty)
            Text(
              'No registration data available.',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                if (isWide) {
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Event')),
                      DataColumn(label: Text('Participants')),
                    ],
                    rows: _participantSummary
                        .map(
                          (item) => DataRow(
                            cells: [
                              DataCell(Text(item.eventTitle)),
                              DataCell(Text(item.count.toString())),
                            ],
                          ),
                        )
                        .toList(),
                  );
                }

                return Column(
                  children: _participantSummary
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.eventTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                item.count.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
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

class _StatItem {
  final String label;
  final int value;

  _StatItem(this.label, this.value);
}

class _ParticipantSummary {
  final String eventTitle;
  final int count;

  _ParticipantSummary(this.eventTitle, this.count);
}
