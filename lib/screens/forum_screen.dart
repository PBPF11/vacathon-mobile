import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';
import 'forum_detail_screen.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  // Removed TabController
  List<Event> _events = [];
  List<ForumThread> _threads = []; // Unified list
  bool _isLoading = true;
  late ApiService _apiService;
  UserProfile? _currentUser;

  // For Create Dialog
  Event? _selectedEventForCreation;

  // Filter State
  String _searchQuery = '';
  String _selectedSort = 'recent'; // recent, popular, oldest
  Event? _selectedEventFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _apiService = ApiService.instance;
    await _loadCurrentUser();
    await _loadData();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _apiService.getProfile();
      setState(() {
        _currentUser = profile;
      });
    } catch (e) {
      print('[ERROR] Failed to load user profile: $e');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Load Events (for creating threads)
      final eventsResponse = DummyDataService.USE_DUMMY_DATA
          ? await DummyDataService.getEvents()
          : await _apiService.getEvents();

      // 2. Load Threads with Filters
      final threadsResponse = DummyDataService.USE_DUMMY_DATA
          ? await DummyDataService.getThreads(
              eventId: _selectedEventFilter?.id,
              query: _searchQuery,
              sort: _selectedSort,
              page: 1,
            )
          : await _apiService.getThreads(
              eventId: _selectedEventFilter?.id,
              query: _searchQuery,
              sort: _selectedSort,
            );

      if (mounted) {
        setState(() {
          _events = eventsResponse.events
              .where((event) => event.status != 'completed')
              .toList();
          _threads = threadsResponse.threads;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[DEBUG] Error loading forum data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Forum'),
          backgroundColor: primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_events.isEmpty && _threads.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Forum'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildThreadList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateThreadDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Forum'), backgroundColor: primaryColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No discussions available',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _bootstrap,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: whiteColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search topics...',
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
                  borderSide: const BorderSide(color: primaryColor),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value);
                _loadData();
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: primaryColor),
              onPressed: _showFilterModal,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedEventFilter = null;
                            _selectedSort = 'recent';
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          _loadData();
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Event',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Event?>(
                    value: _selectedEventFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<Event?>(
                        value: null,
                        child: Text('All Events'),
                      ),
                      ..._events.map(
                        (e) => DropdownMenuItem<Event?>(
                          value: e,
                          child: Text(e.title, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setModalState(() => _selectedEventFilter = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sort By',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSort,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'recent',
                        child: Text('Recently Active'),
                      ),
                      DropdownMenuItem(
                        value: 'latest',
                        child: Text('Newest Threads'),
                      ),
                      DropdownMenuItem(
                        value: 'popular',
                        child: Text('Most Replies'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _selectedSort = val);
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply filters
                        setState(() {}); // Trigger parent rebuild if needed
                        _loadData();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThreadList() {
    if (_threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No discussions yet',
              style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _threads.length,
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _navigateToThread(thread),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Context (Event Name)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "In ${thread.eventTitle}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                    ),

                    // Title & Pin
                    Row(
                      children: [
                        if (thread.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.push_pin,
                              size: 16,
                              color: primaryColor,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            thread.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: thread.isPinned ? primaryColor : textColor,
                            ),
                          ),
                        ),
                        if (_canDelete(thread.authorUsername))
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () => _deleteThread(context, thread),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 8),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.body.length > 100
                          ? '${thread.body.substring(0, 100)}...'
                          : thread.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Metadata
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Text(
                            thread.authorUsername.isNotEmpty
                                ? thread.authorUsername[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          thread.authorUsername,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: textColor.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${thread.viewCount}",
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: textColor.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(thread.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToThread(ForumThread thread) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumDetailScreen(thread: thread),
      ),
    );
    // Refresh list when returning
    _loadData();
  }

  void _showCreateThreadDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    // Default selection
    _selectedEventForCreation = _events.isNotEmpty ? _events[0] : null;

    if (_events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No active events available to create a thread."),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: whiteColor,
            elevation: 8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stylish Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start a Discussion',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share tips, build hype, and help runners prepare for the big day.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Dropdown
                        const Text(
                          "Select Event",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Event>(
                              value: _selectedEventForCreation,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: primaryColor,
                              ),
                              items: _events.map((event) {
                                return DropdownMenuItem(
                                  value: event,
                                  child: Text(
                                    event.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: textColor),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  _selectedEventForCreation = val;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title Input
                        const Text(
                          "Title",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Thread title',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: bgColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Body Input
                        const Text(
                          "Message",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: bodyController,
                          style: const TextStyle(color: textColor),
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Start the discussion...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: bgColor,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_selectedEventForCreation == null) return;
                                  if (titleController.text.trim().isNotEmpty &&
                                      bodyController.text.trim().isNotEmpty) {
                                    _submitThread(
                                      _selectedEventForCreation!,
                                      titleController.text.trim(),
                                      bodyController.text.trim(),
                                    );
                                    Navigator.of(context).pop();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in all fields',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Create Post',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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
        },
      ),
    );
  }

  Future<void> _submitThread(Event event, String title, String body) async {
    try {
      if (DummyDataService.USE_DUMMY_DATA) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thread creation disabled in dummy mode'),
          ),
        );
        return;
      }

      await _apiService.createThread(event.id, title, body);
      _loadData(); // Refresh all to show new thread

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread created successfully!')),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to create thread: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create thread: $e')));
    }
  }

  bool _canDelete(String authorUsername) {
    if (DummyDataService.USE_DUMMY_DATA || _currentUser == null) return false;
    if (_currentUser!.isSuperuser || _currentUser!.isStaff) return true;
    return _currentUser!.username == authorUsername;
  }

  Future<void> _deleteThread(BuildContext context, ForumThread thread) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thread'),
        content: const Text('Are you sure you want to delete this thread?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteThread(thread.slug);
      _loadData(); // Refresh list

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete thread: $e')));
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
