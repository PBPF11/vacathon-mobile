import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
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
  EventsResponse? _eventsResponse;
  bool _isLoading = true;
  String _errorMessage = '';
  late ApiService _apiService;

  // Filter states
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCity;
  double? _selectedDistance;
  bool _showFilters = false;

  // Available filter options
  List<String> _availableCities = [];
  List<double> _availableDistances = [];
  final List<String> _statusOptions = ['upcoming', 'ongoing', 'completed'];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _apiService = ApiService.instance;
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    print('[DEBUG] Loading events...');
    try {
      final filters = <String, String>{};
      if (_searchController.text.isNotEmpty) {
        filters['search'] = _searchController.text;
      }
      if (_selectedStatus != null) {
        filters['status'] = _selectedStatus!;
      }
      if (_selectedCity != null) {
        filters['city'] = _selectedCity!;
      }
      if (_selectedDistance != null) {
        filters['distance'] = _selectedDistance!.toString();
      }

      print('[DEBUG] Filters: $filters');
      if (DummyDataService.USE_DUMMY_DATA) {
        print('[DEBUG] Using dummy data');
        _eventsResponse = await DummyDataService.getEvents(filters: filters);
        print('[DEBUG] Dummy data loaded: ${_eventsResponse?.events.length} events');
      } else {
        print('[DEBUG] Calling API');
        _eventsResponse = await _apiService.getEvents(filters: filters);
        print('[DEBUG] API data loaded: ${_eventsResponse?.events.length} events');
      }
      _deriveFilterOptions();
      print('[DEBUG] Events loaded successfully');
    } catch (e) {
      _errorMessage = 'Failed to load events: $e';
      print('[DEBUG] Error loading events: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedCity = null;
      _selectedDistance = null;
    });
    _loadEvents();
  }

  void _deriveFilterOptions() {
    final events = _eventsResponse?.events ?? [];
    _availableCities = events.map((event) => event.city).toSet().toList()..sort();

    final distanceSet = <double>{};
    for (final event in events) {
      for (final category in event.categories) {
        distanceSet.add(category.distanceKm);
      }
    }
    _availableDistances = distanceSet.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar - matches .layout-section.layout-section--compact
          Container(
            padding: const EdgeInsets.all(16),
            color: whiteColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadEvents();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: darkColor.withOpacity(0.2)),
                ),
                filled: true,
                fillColor: bgColor,
              ),
              onSubmitted: (_) => _loadEvents(),
            ),
          ),

          // Filters - expandable section
          if (_showFilters) _buildFilters(),

          // Events list
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: whiteColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status filter
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
              _loadEvents();
            },
          ),

          const SizedBox(height: 12),

          // City filter
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
            items: _availableCities.map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
              });
              _loadEvents();
            },
          ),

          const SizedBox(height: 12),

          // Distance filter
          DropdownButtonFormField<double>(
            value: _selectedDistance,
            decoration: const InputDecoration(
              labelText: 'Distance (KM)',
              border: OutlineInputBorder(),
            ),
            items: _availableDistances.map((distance) {
              return DropdownMenuItem(
                value: distance,
                child: Text('${distance}K'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDistance = value;
              });
              _loadEvents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_eventsResponse == null || _eventsResponse!.events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventsResponse!.events.length + (_eventsResponse!.pagination.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _eventsResponse!.events.length) {
          // Load more button
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Load next page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('Load More'),
              ),
            ),
          );
        }

        final event = _eventsResponse!.events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          print('[NAV] Navigate to event detail: ${event.id}');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image
              if (event.bannerImage != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(event.bannerImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Title and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(event.status),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Location and date
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${event.city}, ${event.country}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    event.formattedDateRange,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Categories
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: event.categories.take(3).map((category) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
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

              const SizedBox(height: 12),

              // Registration info
              Text(
                '${event.registeredCount}/${event.participantLimit} registered',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
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
    _searchController.dispose();
    super.dispose();
  }

}
