import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/dummy_data_service.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  EventDetail? _eventDetail;
  bool _isLoadingDetail = true;
  bool _isRegistered = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    // Register the HTML view for the map
    ui_web.platformViewRegistry.registerViewFactory(
      'map-view',
      (int viewId) => html.IFrameElement()
        ..src = _eventDetail?.mapUrl ?? 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3966.521260322283!2d106.816666!3d-6.2!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zNsKwMTInMDAuMCJTIDEwNsKwNDknMDAuMCJF!5e0!3m2!1sen!2sid!4v1638360000000!5m2!1sen!2sid'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _apiService = ApiService.instance;
    await _loadEventDetail();
    await _checkRegistrationStatus();
  }

  Future<void> _loadEventDetail() async {
    setState(() {
      _isLoadingDetail = true;
    });

    print('[DEBUG] Loading event detail for ${widget.event.slug}...');
    try {
      // GUNAKAN REAL API
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Gunakan SLUG, bukan ID
      _eventDetail = await ApiService.instance.getEventDetail(
        widget.event.slug,
      );
      print('[DEBUG] Event detail loaded');
    } catch (e) {
      print('[DEBUG] Error loading event detail: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat detail: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    }
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      final profile = await _apiService.getProfile();
      final isRegistered = profile.history.any((hist) => hist.event.slug == widget.event.slug && hist.status == 'registered');
      setState(() {
        _isRegistered = isRegistered;
      });
      print('[DEBUG] Registration status checked: $_isRegistered');
    } catch (e) {
      print('[DEBUG] Error checking registration status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: widget.event.bannerImage != null
                  ? Image.network(widget.event.bannerImage!, fit: BoxFit.cover)
                  : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.event, size: 80, color: Colors.white),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  print('[ACTION] Share event: ${widget.event.id}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality coming soon'),
                    ),
                  );
                },
              ),
            ],
          ),

          // Event Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildEventInfoCard(),
            ),
          ),

          // Tab Content - Only Overview
          SliverFillRemaining(
            child: _buildOverviewTab(),
          ),
        ],
      ),

      // Floating Action Button for Registration
      floatingActionButton: (widget.event.isRegistrationOpen && !_isRegistered)
          ? FloatingActionButton.extended(
        onPressed: () {
          print('[ACTION] Register for event: ${widget.event.id}');
          _showRegistrationDialog();
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.assignment),
        label: const Text('Register'),
      )
          : _isRegistered ? FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.check),
        label: const Text('Registered'),
      ) : null,
    );
  }

  Widget _buildEventInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Registration Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.event.status,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.event.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(widget.event.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${widget.event.registeredCount}/${widget.event.participantLimit} registered',
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Location and Date
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.event.city}, ${widget.event.country}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  widget.event.formattedDateRange,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            if (widget.event.venue != null &&
                widget.event.venue!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    widget.event.venue!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Description
            const Text(
              'About this event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.event.description,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // Categories
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.event.categories.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: darkColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Distance',
                    '${widget.event.categories.firstOrNull?.distanceKm ?? 0} KM',
                  ),
                  _buildStatItem(
                    'Duration',
                    widget.event.durationDays != null
                        ? '${widget.event.durationDays} days'
                        : '1 day',
                  ),
                  _buildStatItem(
                    'Popularity',
                    widget.event.popularityScore.toString(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Registration Status
          const Text(
            'Registration Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.registrationStatusMessage,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: darkColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.event.capacityRatio / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryColor, accentColor],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.event.remainingSlots != null)
                        Text(
                          '${widget.event.remainingSlots} slots remaining',
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      Text(
                        '${widget.event.capacityRatio.toStringAsFixed(0)}% capacity',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (widget.event.registrationOpenDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Opened: ${_formatDate(widget.event.registrationOpenDate!)}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  Text(
                    'Deadline: ${_formatDate(widget.event.registrationDeadline)}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (widget.event.isRegistrationOpen && !_isRegistered)
                        ? () => _showRegistrationDialog()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRegistered ? primaryColor : primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_isRegistered ? 'I\'ve Registered' : 'Proceed to Registration'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Event Location Map
          const Text(
            'Event Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: kIsWeb
                ? HtmlElementView(viewType: 'map-view')
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 48, color: primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.event.city}, ${widget.event.country}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            // Open Google Maps directions
                            final url =
                                'https://www.google.com/maps/dir/?api=1&destination=${widget.event.city}+${widget.event.country}';
                            print('[ACTION] Open Google Maps: $url');
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open Google Maps'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          child: const Text('Get Directions'),
                        ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 24),

          // Registration Info
          const Text(
            'Registration Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Registration Opens',
                    widget.event.registrationOpenDate != null
                        ? _formatDate(widget.event.registrationOpenDate!)
                        : 'TBD',
                  ),
                  _buildInfoRow(
                    'Registration Deadline',
                    _formatDate(widget.event.registrationDeadline),
                  ),
                  _buildInfoRow(
                    'Participant Limit',
                    widget.event.participantLimit == 0
                        ? 'Unlimited'
                        : widget.event.participantLimit.toString(),
                  ),
                  _buildInfoRow(
                    'Current Registrations',
                    widget.event.registeredCount.toString(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (_isLoadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final schedules = _eventDetail?.schedules ?? [];

    return schedules.isEmpty
        ? const Center(child: Text('No schedule information available'))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  schedule.formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            title: Text(
              schedule.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle:
            schedule.description != null &&
                schedule.description!.isNotEmpty
                ? Text(schedule.description!)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildRouteTab() {
    if (_isLoadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final aidStations = _eventDetail?.aidStations ?? [];
    final routeSegments = _eventDetail?.routeSegments ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aid Stations
          if (aidStations.isNotEmpty) ...[
            const Text(
              'Aid Stations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...aidStations.map(
                  (station) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: station.isMedical
                          ? Colors.red.withOpacity(0.2)
                          : accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      station.isMedical
                          ? Icons.local_hospital
                          : Icons.restaurant,
                      color: station.isMedical ? Colors.red : darkColor,
                    ),
                  ),
                  title: Text(station.name),
                  subtitle: Text(
                    '${station.kilometerMarker} KM - ${station.supplies}',
                  ),
                  trailing: station.isMedical
                      ? const Icon(Icons.local_hospital, color: Colors.red)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Route Segments
          if (routeSegments.isNotEmpty) ...[
            const Text(
              'Route Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...routeSegments.map(
                  (segment) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Segment ${segment.order}: ${segment.title}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${segment.distanceKm} KM',
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (segment.elevationGain > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Elevation Gain: ${segment.elevationGain}m',
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        segment.description,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    if (_isLoadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final documents = _eventDetail?.documents ?? [];

    return documents.isEmpty
        ? const Center(child: Text('No resources available'))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description, color: primaryColor),
            ),
            title: Text(document.title),
            subtitle: Text(
              '${document.documentTypeDisplay} • ${document.uploadedBy}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                print(
                  '[ACTION] Download document: ${document.documentUrl}',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download functionality coming soon'),
                  ),
                );
              },
            ),
            onTap: () {
              print('[ACTION] View document: ${document.documentUrl}');
              // TODO: Open document
            },
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor.withOpacity(0.7))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => RegistrationDialog(event: widget.event),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class RegistrationDialog extends StatefulWidget {
  final Event event;

  const RegistrationDialog({super.key, required this.event});

  @override
  State<RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<RegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  final _distanceLabelController = TextEditingController();

  int? _selectedCategoryId;
  bool _acceptTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _medicalNotesController.dispose();
    _distanceLabelController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    // Fallback: if emergency phone empty, reuse main phone number to unblock submission.
    final emergencyPhone = _emergencyPhoneController.text.trim().isEmpty
        ? _phoneController.text.trim()
        : _emergencyPhoneController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare registration data
      final Map<String, dynamic> registrationData = {
        'phone_number': _phoneController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': emergencyPhone,
        'medical_notes': _medicalNotesController.text.trim(),
      };

      // Debug logs
      print('[DEBUG] Event categories: ${widget.event.categories}');
      print('[DEBUG] Selected category: $_selectedCategoryId');

      // Add category if selected
      if (_selectedCategoryId != null) {
        registrationData['category'] = _selectedCategoryId;
      }

      // Add distance label for open events
      if (widget.event.categories.isEmpty) {
        if (_distanceLabelController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please specify your target distance'),
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
        registrationData['distance_label'] = _distanceLabelController.text
            .trim();
      }

      // Add terms acceptance
      registrationData['accept_terms'] = _acceptTerms;

      print('[DEBUG] Registration data: $registrationData');

      print(
        '[ACTION] Submit registration for event ${widget.event.id}: $registrationData',
      );

      // AKSES API LEWAT PROVIDER
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // PANGGIL API REGISTER
      // Pastikan method registerForEvent di ApiService sudah diupdate menerima (String slug, int catId, map data)
      final registration = await ApiService.instance.registerForEvent(
        widget.event.slug, // Gunakan Slug
        _selectedCategoryId ??
            0, // Kirim ID Kategori (pastikan handle null/jarak manual jika perlu)
        registrationData,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully registered! Ref: ${registration.referenceCode}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Registration failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment, color: primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Event Registration',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            widget.event.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Distance/Category Selection
                if (widget.event.categories.isNotEmpty) ...[
                  const Text(
                    'Select Distance Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: widget.event.categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a distance category';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  const Text(
                    'Preferred Distance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _distanceLabelController,
                    decoration: InputDecoration(
                      hintText: 'e.g., 10K, Half Marathon, Ultra',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please specify your target distance';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 20),

                // Contact Information
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+62-812-3456-7890',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Emergency Contact
                const Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emergencyNameController,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact Name',
                    hintText: 'Full name of emergency contact',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter emergency contact name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _emergencyPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    hintText: '+62-811-9876-5432',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                ),
                keyboardType: TextInputType.phone,
                  validator: (value) {
                    // Allow empty input in dummy mode; it will reuse main phone.
                    return null;
                  },
              ),

                const SizedBox(height: 20),

                // Medical Notes
                const Text(
                  'Medical Information (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _medicalNotesController,
                  decoration: InputDecoration(
                    hintText:
                    'Any medical conditions, allergies, or medications we should be aware of...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'I agree to the event terms and conditions',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: whiteColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : const Text(
                          'Register',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
