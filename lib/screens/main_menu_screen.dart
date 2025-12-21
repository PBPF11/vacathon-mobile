import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';
import 'event_detail_screen.dart';

// CSS Variables from reference - exact matches
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class MainMenuScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const MainMenuScreen({super.key, required this.onNavigate});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  static const String _newsVideoId = 'aZ9HQJoMPWc';
  static const String _newsVideoUrl =
      'https://www.youtube.com/watch?v=aZ9HQJoMPWc';

  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  bool _isLoading = true;
  String? _errorMessage;
  Event? _highlightEvent;
  String _highlightSummary = '';
  List<Event> _upcomingEvents = [];
  List<HomeStat> _stats = [];
  List<HighlightReason>? _highlightReasons;
  String? _mapUrl;

  final List<NewsItem> _newsItems = const [
    NewsItem(
      title: 'Jakarta Marathon opens registration for 2025',
      source: 'Vacathon News',
      url: 'https://muhammad-rafi419-vacathon.pbp.cs.ui.ac.id/',
    ),
    NewsItem(
      title: 'Trail running destinations gaining momentum',
      source: 'Vacathon Community',
      url: 'https://muhammad-rafi419-vacathon.pbp.cs.ui.ac.id/',
    ),
    NewsItem(
      title: 'Training plans to get marathon-ready in 12 weeks',
      source: 'Vacathon Insights',
      url: 'https://muhammad-rafi419-vacathon.pbp.cs.ui.ac.id/',
    ),
  ];

  final List<ExternalLink> _externalLinks = const [
    ExternalLink(
      label: 'Vacathon Web',
      icon: Icons.travel_explore,
      url: 'https://muhammad-rafi419-vacathon.pbp.cs.ui.ac.id/',
    ),
    ExternalLink(
      label: 'YouTube',
      icon: Icons.play_circle_fill,
      url: 'https://www.youtube.com/',
    ),
    ExternalLink(
      label: 'Instagram',
      icon: Icons.camera_alt,
      url: 'https://www.instagram.com/',
    ),
    ExternalLink(
      label: 'Strava',
      icon: Icons.directions_run,
      url: 'https://www.strava.com/',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await _fetchEvents();
      _highlightEvent = _pickHighlightEvent(events);
      _highlightSummary = _buildHighlightSummary(_highlightEvent);
      _upcomingEvents = _pickUpcomingEvents(events, _highlightEvent);
      _stats = _buildStats(events);
      _highlightReasons = _buildHighlightReasons(_highlightEvent);
      _mapUrl = _buildMapUrl(_highlightEvent);
    } catch (e) {
      _errorMessage = 'Failed to load home data: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Event>> _fetchEvents() async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getAllEvents();
    }

    final List<Event> events = [];
    var page = 1;
    while (true) {
      final response = await ApiService.instance.getEvents(page: page);
      events.addAll(response.events);
      if (!response.pagination.hasNext) {
        break;
      }
      page += 1;
    }
    return events;
  }

  Event? _pickHighlightEvent(List<Event> events) {
    if (events.isEmpty) {
      return null;
    }

    final upcoming = events
        .where((event) =>
            event.status == 'upcoming' || event.status == 'ongoing')
        .toList()
      ..sort((a, b) {
        final dateCompare = a.startDate.compareTo(b.startDate);
        if (dateCompare != 0) return dateCompare;
        return b.popularityScore.compareTo(a.popularityScore);
      });

    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }

    final today = DateTime.now();
    final fallback = events
        .where((event) => event.startDate.isBefore(today))
        .toList()
      ..sort((a, b) {
        final dateCompare = b.startDate.compareTo(a.startDate);
        if (dateCompare != 0) return dateCompare;
        return b.popularityScore.compareTo(a.popularityScore);
      });

    return fallback.isNotEmpty ? fallback.first : events.first;
  }

  List<Event> _pickUpcomingEvents(List<Event> events, Event? highlight) {
    final highlightId = highlight?.id;
    final prioritized = events
        .where((event) =>
            event.status == 'upcoming' || event.status == 'ongoing')
        .where((event) => event.id != highlightId)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (prioritized.length >= 3) {
      return prioritized.take(3).toList();
    }

    final remaining = events
        .where((event) => event.id != highlightId)
        .where((event) => !prioritized.contains(event))
        .toList();

    return [...prioritized, ...remaining.take(3 - prioritized.length)];
  }

  List<HomeStat> _buildStats(List<Event> events) {
    final totalEvents = events.length;
    final totalRunners =
        events.fold<int>(0, (sum, event) => sum + event.registeredCount);
    final activeCities = events
        .map((event) => event.city.trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .length;

    return [
      HomeStat(
        label: 'Events',
        value: totalEvents.toString(),
        icon: Icons.event,
      ),
      HomeStat(
        label: 'Registered Runners',
        value: _numberFormat.format(totalRunners),
        icon: Icons.directions_run,
      ),
      HomeStat(
        label: 'Active Cities',
        value: activeCities.toString(),
        icon: Icons.location_on,
      ),
      const HomeStat(
        label: 'Partners and Sponsors',
        value: '14',
        icon: Icons.handshake,
      ),
    ];
  }

  String _buildHighlightSummary(Event? event) {
    if (event == null || event.description.trim().isEmpty) {
      return 'Vacathon curates remarkable running getaways so you can chase '
          'every finish line with confidence, community, and adventure.';
    }
    return _truncateWords(event.description, 40);
  }

  String _truncateWords(String text, int maxWords) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= maxWords) {
      return text;
    }
    return '${words.take(maxWords).join(' ')}...';
  }

  List<HighlightReason> _buildHighlightReasons(Event? event) {
    final reasons = [
      const HighlightReason(
        icon: '2',
        title: 'Two race days.',
        description:
            'A two-day schedule welcomes more runners and gives you flexibility '
            'to choose the race that fits your plan.',
      ),
      const HighlightReason(
        icon: '*',
        title: 'Inclusive for every runner.',
        description:
            'Certified routes and multiple categories support both first-timers '
            'and seasoned athletes to perform their best.',
      ),
      const HighlightReason(
        icon: '!',
        title: 'Strict marathon regulation.',
        description:
            'Safety-first cut-offs and climate-aware planning deliver a '
            'comfortable, well-managed race experience.',
      ),
    ];

    final durationDays = event?.durationDays;
    if (durationDays != null && durationDays > 1) {
      reasons[0] = HighlightReason(
        icon: '2',
        title: 'Two race days.',
        description:
            '${event!.title} unfolds across $durationDays days, giving you '
            'even more chances to join the excitement.',
      );
    }

    final participantLimit = event?.participantLimit;
    if (participantLimit != null && participantLimit > 0) {
      reasons[1] = HighlightReason(
        icon: '*',
        title: 'Inclusive for every runner.',
        description:
            'With capacity for ${_numberFormat.format(participantLimit)} runners, '
            'everyone from newcomers to elite racers has room to shine.',
      );
    }

    return reasons;
  }

  String _buildMapUrl(Event? event) {
    final parts = <String>[];
    if (event != null) {
      if (event.city.trim().isNotEmpty) {
        parts.add(event.city.trim());
      }
      if (event.country.trim().isNotEmpty) {
        parts.add(event.country.trim());
      }
    }
    final query = parts.isNotEmpty
        ? '${parts.join(' ')} marathon'
        : 'marathon race';
    return 'https://www.google.com/maps?q=${Uri.encodeComponent(query)}';
  }

  void _openEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;
    final isAdmin = profile?.isStaff == true || profile?.isSuperuser == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _contentMaxWidth(constraints.maxWidth);
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('Vacathon'),
            backgroundColor: primaryColor,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (isAdmin)
                IconButton(
                  tooltip: 'Admin Dashboard',
                  onPressed: () => Navigator.of(context).pushNamed('/admin'),
                  icon: const Icon(Icons.admin_panel_settings),
                ),
            ],
          ),
          body: Stack(
            children: [
              _buildBackdrop(),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              else if (_errorMessage != null)
                _buildErrorState()
              else
                RefreshIndicator(
                  onRefresh: _loadHome,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildWhyRunSection()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.2),
                              const SizedBox(height: 24),
                              _buildHighlightBanner()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.2, delay: 60.ms),
                              const SizedBox(height: 20),
                              _buildQuickNav(isAdmin)
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, delay: 100.ms),
                              const SizedBox(height: 24),
                              _buildMapSection()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, delay: 140.ms),
                              const SizedBox(height: 24),
                              _buildVideoSection()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, delay: 180.ms),
                              const SizedBox(height: 24),
                              _buildStatsSection()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, delay: 220.ms),
                              const SizedBox(height: 24),
                              _buildNewsSection()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, delay: 260.ms),
                              const SizedBox(height: 24),
                              _buildUpcomingEvents()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, delay: 300.ms),
                              const SizedBox(height: 24),
                              _buildCommunityCTA()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, delay: 340.ms),
                              const SizedBox(height: 24),
                              _buildExternalLinks()
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, delay: 380.ms),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _contentMaxWidth(double width) {
    if (width >= 1200) {
      return 1000;
    }
    if (width >= 900) {
      return 860;
    }
    return width;
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
                size: 220,
                color: primaryColor.withOpacity(0.12),
              ),
              _buildBubble(
                top: 180,
                left: -80,
                size: 180,
                color: accentColor.withOpacity(0.2),
              ),
              _buildBubble(
                bottom: 120,
                right: -70,
                size: 200,
                color: primaryColor.withOpacity(0.1),
              ),
              _buildBubble(
                bottom: -60,
                left: 40,
                size: 140,
                color: accentColor.withOpacity(0.18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unable to load home data.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHome,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightBanner() {
    final event = _highlightEvent;
    final bannerImage = event?.bannerImage;
    final ctaEnabled = event != null;
    final ctaLabel = event != null && event.isRegistrationOpen
        ? 'Daftar Sekarang'
        : 'Lihat Detail';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
        image: bannerImage != null && bannerImage.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(bannerImage),
                fit: BoxFit.cover,
              )
            : null,
        gradient: bannerImage == null
            ? LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                  darkColor.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: darkColor.withOpacity(0.55),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event != null ? 'Highlight Event' : 'Find Your Next Marathon',
              style: const TextStyle(
                color: whiteColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event?.title ?? 'Discover the race that fits your goals',
              style: const TextStyle(
                color: whiteColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _highlightSummary,
              style: TextStyle(
                color: whiteColor.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (event != null)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildMetaChip(
                    'Location',
                    '${event.city}, ${event.country}',
                  ),
                  _buildMetaChip(
                    'Race Day',
                    DateFormat('d MMM yyyy').format(event.startDate),
                  ),
                  _buildMetaChip(
                    'Register By',
                    DateFormat('d MMM yyyy').format(event.registrationDeadline),
                  ),
                ],
              ),
            if (event != null && event.categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: event.categories
                    .take(4)
                    .map(
                      (category) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: whiteColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: whiteColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          category.displayName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: whiteColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: ctaEnabled ? () => _openEventDetail(event!) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: darkColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    ctaLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: ctaEnabled ? () => _openEventDetail(event!) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: whiteColor,
                    side: const BorderSide(color: whiteColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Lihat Event'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _surfaceDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? whiteColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: primaryColor.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: darkColor.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  Widget _buildSurfaceCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? color,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: _surfaceDecoration(color: color),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWhyRunSection() {
    const leadText =
        'Vacathon curates destination-worthy races, organizes community support, '
        'and streamlines your travel so you can focus on the miles ahead.';

    final reasonsSeed = _highlightReasons ?? const <HighlightReason>[];
    final reasons = reasonsSeed.isNotEmpty
        ? reasonsSeed
        : _buildHighlightReasons(_highlightEvent);

    return _buildSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final reasonWidgets = reasons
              .map((reason) => _buildReasonCard(reason))
              .toList();

          final lead = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why run with Vacathon?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: darkColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                leadText,
                style: TextStyle(
                  color: textColor.withOpacity(0.75),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _PillTag(label: 'Community Driven'),
                  _PillTag(label: 'Verified Routes'),
                  _PillTag(label: 'Travel Ready'),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => widget.onNavigate(1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withOpacity(0.6)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Explore events',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: lead),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: reasonWidgets
                        .map(
                          (widget) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: widget,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              lead,
              const SizedBox(height: 20),
              ...reasonWidgets
                  .map(
                    (widget) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: widget,
                    ),
                  )
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReasonCard(HighlightReason reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(
                reason.icon,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason.description,
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    final event = _highlightEvent;
    final location = [
      if (event != null && event.city.trim().isNotEmpty) event.city.trim(),
      if (event != null && event.country.trim().isNotEmpty)
        event.country.trim(),
    ].join(', ');
    final mapLabel = location.isNotEmpty ? location : 'Global marathon routes';
    final mapUrl = _mapUrl ?? _buildMapUrl(event);

    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Featured Marathon Route',
            'Preview the surrounding area and start planning your travel logistics.',
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _openUrl(mapUrl),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.15),
                    accentColor.withOpacity(0.35),
                    primaryColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.18,
                      child: Center(
                        child: Icon(
                          Icons.map,
                          size: 180,
                          color: darkColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: whiteColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: darkColor.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place, color: primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mapLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: darkColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openUrl(mapUrl),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text(
                              'Open map',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCTA() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.85),
            accentColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect with fellow runners',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: whiteColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Join the Vacathon forum to share training tips, swap stories, '
            'and meet your next race crew.',
            style: TextStyle(
              color: whiteColor.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => widget.onNavigate(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: whiteColor,
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Visit the forum',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: whiteColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: whiteColor.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: whiteColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNav(bool isAdmin) {
    Future<void> _handleLogout() async {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }

    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Main Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 900
                  ? 4
                  : width >= 640
                      ? 3
                      : 2;
              final childAspectRatio = width >= 900
                  ? 3.1
                  : width >= 640
                      ? 2.8
                      : 2.5;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                children: [
                  _buildNavCard(
                    label: 'Daftar Marathon',
                    icon: Icons.flag,
                    onTap: () => widget.onNavigate(1),
                  ),
                  _buildNavCard(
                    label: 'Forum Diskusi',
                    icon: Icons.forum,
                    onTap: () => widget.onNavigate(3),
                  ),
                  _buildNavCard(
                    label: 'Akun Saya',
                    icon: Icons.person,
                    onTap: () => widget.onNavigate(2),
                  ),
                  _buildNavCard(
                    label: 'Notifikasi',
                    icon: Icons.notifications,
                    onTap: () => widget.onNavigate(4),
                  ),
                  _buildNavCard(
                    label: 'Logout',
                    icon: Icons.logout,
                    onTap: _handleLogout,
                  ),
                  if (isAdmin)
                    _buildNavCard(
                      label: 'Admin Dashboard',
                      icon: Icons.admin_panel_settings,
                      onTap: () => Navigator.of(context).pushNamed('/admin'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: darkColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.18),
                    accentColor.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vacathon Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 900 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _stats
                    .map(
                      (stat) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: darkColor.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(stat.icon, color: primaryColor),
                            const SizedBox(height: 12),
                            Text(
                              stat.value,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stat.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.7),
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

  Widget _buildVideoSection() {
    final thumbnailUrl =
        'https://img.youtube.com/vi/$_newsVideoId/hqdefault.jpg';
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Latest Marathon News',
            'Stay inspired with coverage from the running world.',
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _openUrl(_newsVideoUrl),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(thumbnailUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: darkColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: whiteColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.play_arrow, color: primaryColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Marathon News',
            'Stories, tips, and updates curated by the Vacathon team.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children:
                      _newsItems.map((item) => _buildNewsCard(item)).toList(),
                );
              }

              return SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newsItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _buildNewsCard(_newsItems[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsItem item) {
    return InkWell(
      onTap: () => _openUrl(item.url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: darkColor.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.source,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'Read more',
              style: TextStyle(
                fontSize: 12,
                color: primaryColor.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Other Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(1),
                child: const Text(
                  'See all events',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_upcomingEvents.isEmpty)
            Text(
              'No additional events to show just yet.',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.7,
                    children: _upcomingEvents
                        .map((event) => _buildUpcomingEventCard(event))
                        .toList(),
                  );
                }

                return Column(
                  children: _upcomingEvents
                      .map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildUpcomingEventCard(event),
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

  Widget _buildUpcomingEventCard(Event event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${event.city}, ${event.country} - ${DateFormat('d MMM yyyy').format(event.startDate)}',
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: event.categories
                .take(3)
                .map(
                  (category) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      category.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: darkColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _openEventDetail(event),
              child: const Text(
                'View details',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalLinks() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect with other platforms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Link your running journey across the apps you already love.',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 900
                  ? 4
                  : width >= 640
                      ? 3
                      : 2;
              final childAspectRatio = width >= 900
                  ? 3.2
                  : width >= 640
                      ? 2.8
                      : 2.5;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                children: _externalLinks
                    .map(
                      (link) => InkWell(
                        onTap: () => _openUrl(link.url),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(link.icon, color: primaryColor, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  link.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}

class HomeStat {
  final String label;
  final String value;
  final IconData icon;

  const HomeStat({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _PillTag extends StatelessWidget {
  final String label;

  const _PillTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }
}

class HighlightReason {
  final String icon;
  final String title;
  final String description;

  const HighlightReason({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class NewsItem {
  final String title;
  final String source;
  final String url;

  const NewsItem({
    required this.title,
    required this.source,
    required this.url,
  });
}

class ExternalLink {
  final String label;
  final IconData icon;
  final String url;

  const ExternalLink({
    required this.label,
    required this.icon,
    required this.url,
  });
}
