import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';
import 'event_detail_screen.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Event> _events = [];
  EventPagination? _pagination;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;

  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedCity;
  double? _selectedDistance;

  List<String> _availableCities = [];
  List<double> _availableDistances = [];

  late ApiService _apiService;

  static const List<String> _statusOptions = [
    'upcoming',
    'ongoing',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService.instance;
    _loadEvents(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _isAdminUser() {
    final profile = Provider.of<AuthProvider>(context, listen: false).userProfile;
    return profile?.isSuperuser == true || profile?.isStaff == true;
  }

  Map<String, String> _buildFilters() {
    final filters = <String, String>{};
    if (_searchQuery.trim().isNotEmpty) {
      filters['search'] = _searchQuery.trim();
      filters['q'] = _searchQuery.trim();
    }
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filters['status'] = _selectedStatus!;
    }
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filters['city'] = _selectedCity!;
    }
    if (_selectedDistance != null) {
      filters['distance'] = _selectedDistance!.toString();
    }
    return filters;
  }

  Future<EventsResponse> _fetchEvents({required int page}) async {
    final filters = _buildFilters();
    final isAdmin = _isAdminUser();

    if (DummyDataService.USE_DUMMY_DATA) {
      return isAdmin
          ? DummyDataService.getAdminEvents(page: page, filters: filters)
          : DummyDataService.getEvents(page: page, filters: filters);
    }

    if (isAdmin) {
      try {
        return await _apiService.getAdminEvents(page: page, filters: filters);
      } catch (e) {
        print('[WARN] Admin events failed, fallback to user events: $e');
        return await _apiService.getEvents(page: page, filters: filters);
      }
    }

    return await _apiService.getEvents(page: page, filters: filters);
  }

  Future<void> _loadEvents({required bool reset}) async {
    if (!mounted) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      if (_isLoadingMore || _pagination?.hasNext != true) {
        return;
      }
      setState(() {
        _isLoadingMore = true;
        _errorMessage = null;
      });
    }

    final targetPage = reset ? 1 : _currentPage + 1;

    try {
      final response = await _fetchEvents(page: targetPage);
      final updatedEvents = reset
          ? response.events
          : [..._events, ...response.events];
      final updatedCities = _deriveCities(updatedEvents);
      final updatedDistances = _deriveDistances(updatedEvents);

      if (!mounted) return;
      setState(() {
        _currentPage = targetPage;
        _events = updatedEvents;
        _pagination = response.pagination;
        if (updatedEvents.isNotEmpty) {
          _availableCities = updatedCities;
          _availableDistances = updatedDistances;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load events: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  List<String> _deriveCities(List<Event> events) {
    final cities = events
        .map((event) => event.city.trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList();
    cities.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cities;
  }

  List<double> _deriveDistances(List<Event> events) {
    final distances = <double>{};
    for (final event in events) {
      for (final category in event.categories) {
        distances.add(category.distanceKm);
      }
    }
    final list = distances.toList()..sort();
    return list;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
      });
      _loadEvents(reset: true);
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStatus = null;
      _selectedCity = null;
      _selectedDistance = null;
    });
    _loadEvents(reset: true);
  }

  List<String> _getCityOptions() {
    if (DummyDataService.USE_DUMMY_DATA) {
      final cities = DummyDataService.getUniqueCities();
      cities.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return cities;
    }
    return _availableCities;
  }

  List<double> _getDistanceOptions() {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getUniqueDistances();
    }
    return _availableDistances;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin =
        authProvider.userProfile?.isSuperuser == true ||
        authProvider.userProfile?.isStaff == true;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (_errorMessage != null) _buildErrorBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildEventsList(isAdmin),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/admin/events'),
              backgroundColor: primaryColor,
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Manage'),
            )
          : null,
    );
  }

  Widget _buildFilterBar() {
    final cities = _getCityOptions();
    final distances = _getDistanceOptions();
    final selectedStatus =
        _statusOptions.contains(_selectedStatus) ? _selectedStatus : null;
    final selectedCity =
        cities.contains(_selectedCity) ? _selectedCity : null;
    final selectedDistance =
        distances.contains(_selectedDistance) ? _selectedDistance : null;

    return Container(
      color: whiteColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: (value) {
              _debounce?.cancel();
              setState(() {
                _searchQuery = value;
              });
              _loadEvents(reset: true);
            },
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String?>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ..._statusOptions.map(
                      (status) => DropdownMenuItem<String?>(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    _loadEvents(reset: true);
                  },
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String?>(
                  value: selectedCity,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All cities'),
                    ),
                    ...cities.map(
                      (city) => DropdownMenuItem<String?>(
                        value: city,
                        child: Text(city),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                    _loadEvents(reset: true);
                  },
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<double?>(
                  value: selectedDistance,
                  decoration: InputDecoration(
                    labelText: 'Distance',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<double?>(
                      value: null,
                      child: Text('All distances'),
                    ),
                    ...distances.map(
                      (distance) => DropdownMenuItem<double?>(
                        value: distance,
                        child: Text('${distance.toStringAsFixed(1)} km'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDistance = value;
                    });
                    _loadEvents(reset: true);
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Failed to load events.',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton(
            onPressed: () => _loadEvents(reset: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(bool isAdmin) {
    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadEvents(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length + (_pagination?.hasNext == true ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _events.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator()
                    : TextButton.icon(
                        onPressed: () => _loadEvents(reset: false),
                        icon: const Icon(Icons.more_horiz),
                        label: const Text('Load more'),
                      ),
              ),
            );
          }

          final event = _events[index];
          return _buildEventCard(event, isAdmin: isAdmin);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or refresh.',
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _loadEvents(reset: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event, {required bool isAdmin}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _openEventDetail(event),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.bannerImage != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  event.bannerImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(event.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel(event.status).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${event.city}, ${event.country}',
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedDateRange,
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (event.categories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: event.categories
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        "${event.registeredCount}/${event.participantLimit == 0 ? 'Unlimited' : event.participantLimit} registered",
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _openEventDetail(event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isAdmin ? 'View event' : 'View details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'upcoming':
        return 'Upcoming';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
