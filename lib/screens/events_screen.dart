import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  EventsResponse? _eventsResponse;
  bool _isLoading = false;
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
    // Load events will be called in build method based on user role
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    print('[DEBUG] Loading admin events...');
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
      // Use regular events API for admin (admin endpoints don't exist yet)
      _eventsResponse = await _apiService.getEvents(filters: filters);
      print('[DEBUG] API data loaded: ${_eventsResponse?.events.length} events');
      _deriveFilterOptions();
      print('[DEBUG] Events loaded successfully');
    } catch (e) {
      _errorMessage = 'Failed to load events: $e';
      print('[DEBUG] Error loading events: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserEvents() async {
    if (!mounted) return;

    print('[DEBUG] _loadUserEvents called, _isLoading: $_isLoading, _eventsResponse: ${_eventsResponse?.events.length ?? "null"}');

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    print('[DEBUG] Loading user events...');
    try {
      final filters = <String, String>{};
      if (_searchController.text.isNotEmpty) {
        filters['search'] = _searchController.text;
      }

      print('[DEBUG] Filters: $filters');
      // User events use regular getEvents API
      final response = await _apiService.getEvents(filters: filters);
      print('[DEBUG] User events loaded: ${response.events.length} events');

      if (mounted) {
        setState(() {
          _eventsResponse = response;
          _isLoading = false;
        });
        print('[DEBUG] State updated, _isLoading: $_isLoading, events count: ${response.events.length}');
      }
    } catch (e) {
      print('[DEBUG] Error loading user events: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load events: $e';
          _isLoading = false;
        });
      }
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.userProfile?.isSuperuser == true || authProvider.userProfile?.isStaff == true;

    print('[DEBUG] EventsScreen.build called, isAdmin: $isAdmin (superuser: ${authProvider.userProfile?.isSuperuser}, staff: ${authProvider.userProfile?.isStaff}), username: ${authProvider.userProfile?.username}, _eventsResponse: ${_eventsResponse?.events.length ?? "null"}, _isLoading: $_isLoading');

    // Load appropriate events based on user role
    if (_eventsResponse == null && !_isLoading && mounted) {
      print('[DEBUG] Triggering load');
      if (isAdmin) {
        _loadEvents();
      } else {
        _loadUserEvents();
      }
    }

    // Show different UI for admin vs regular users
    if (isAdmin) {
      return _buildAdminEventsScreen();
    } else {
      return _buildUserEventsScreen();
    }
  }

  Widget _buildUserEventsScreen() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
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
                    setState(() {
                      _eventsResponse = null;
                    });
                    _loadUserEvents();
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
              onSubmitted: (_) {
                setState(() {
                  _eventsResponse = null;
                });
                _loadUserEvents();
              },
            ),
          ),

          // Events list for users
          Expanded(
            child: _buildUserEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminEventsScreen() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Manage Events'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEvent,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewEvent() {
    _showEventDialog();
  }

  void _editEvent(Event event) {
    _showEventDialog(event: event);
  }

  void _showEventDialog({Event? event}) {
    final isEditing = event != null;

    // Form controllers
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final cityController = TextEditingController(text: event?.city ?? '');
    final popularityController = TextEditingController(text: event?.popularityScore.toString() ?? '0');

    // Date variables
    DateTime? startDate = event?.startDate ?? DateTime.now();
    DateTime? endDate = event?.endDate ?? DateTime.now().add(const Duration(days: 1));
    DateTime? registrationDeadline = event?.registrationDeadline ?? DateTime.now().add(const Duration(days: 30));
    String status = event?.status ?? 'upcoming';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Event' : 'Add New Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Start Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : 'Select date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // End Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => endDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : 'Select date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Registration Deadline
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: registrationDeadline ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => registrationDeadline = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Registration Deadline',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          registrationDeadline != null ? DateFormat('yyyy-MM-dd').format(registrationDeadline!) : 'Select date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['upcoming', 'ongoing', 'completed'].map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: popularityController,
                      decoration: const InputDecoration(
                        labelText: 'Popularity Score',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    // Validate and save
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        cityController.text.isEmpty ||
                        startDate == null ||
                        endDate == null ||
                        registrationDeadline == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }

                    final popularityScore = int.tryParse(popularityController.text) ?? 0;

                    final eventData = {
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'city': cityController.text,
                      'country': 'Indonesia', // Default
                      'start_date': startDate!.toIso8601String(),
                      'end_date': endDate!.toIso8601String(),
                      'registration_open_date': startDate!.subtract(const Duration(days: 30)).toIso8601String(),
                      'registration_deadline': registrationDeadline!.toIso8601String(),
                      'status': status,
                      'popularity_score': popularityScore,
                      'participant_limit': 1000, // Default
                      'featured': false, // Default
                    };

                    Navigator.of(context).pop();

                    try {
                      if (isEditing) {
                        if (DummyDataService.USE_DUMMY_DATA) {
                          await DummyDataService.updateEvent(event!.id, eventData);
                        } else {
                          await _apiService.updateEvent(event!.id, eventData);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event updated successfully')),
                        );
                      } else {
                        if (DummyDataService.USE_DUMMY_DATA) {
                          await DummyDataService.createEvent(eventData);
                        } else {
                          await _apiService.createEvent(eventData);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event created successfully')),
                        );
                      }
                      _loadEvents(); // Refresh list
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save event: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteEvent(Event event) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text('Are you sure you want to delete "${event.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  if (DummyDataService.USE_DUMMY_DATA) {
                    await DummyDataService.deleteEvent(event.id);
                  } else {
                    await _apiService.deleteEvent(event.id);
                  }
                  _loadEvents(); // Refresh list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete event: $e')),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
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

  Widget _buildUserEventsList() {
    print('[DEBUG] _buildUserEventsList called, _isLoading: $_isLoading, _errorMessage: "$_errorMessage", events count: ${_eventsResponse?.events.length ?? "null"}');

    if (_isLoading) {
      print('[DEBUG] Showing loading indicator');
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      print('[DEBUG] Showing error message: $_errorMessage');
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
              onPressed: _loadUserEvents,
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
      print('[DEBUG] Showing no events found');
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

    print('[DEBUG] Showing events list with ${_eventsResponse!.events.length} events');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventsResponse!.events.length,
      itemBuilder: (context, index) {
        final event = _eventsResponse!.events[index];
        return _buildUserEventCard(event);
      },
    );
  }

  Widget _buildUserEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to event detail for registration
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

              // Registration info and button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${event.registeredCount}/${event.participantLimit} registered',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          _editEvent(event);
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

              // Management buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${event.registeredCount}/${event.participantLimit} registered',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _editEvent(event),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteEvent(event),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
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
