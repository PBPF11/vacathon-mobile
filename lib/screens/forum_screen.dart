import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';

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

class _ForumScreenState extends State<ForumScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  List<Event> _events = [];
  Map<int, ThreadsResponse> _threadsCache = {};
  bool _isLoading = true;
  late ApiService _apiService;

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
    print('[DEBUG] ForumScreen loading events...');
    try {
      final eventsResponse = DummyDataService.USE_DUMMY_DATA
          ? await DummyDataService.getEvents()
          : await _apiService.getEvents();
      print('[DEBUG] Forum events loaded: ${eventsResponse.events.length} events');
      setState(() {
        _events = eventsResponse.events.where((event) => event.status != 'completed').toList();
        if (_events.isNotEmpty) {
          _tabController = TabController(length: _events.length, vsync: this);
        }
        _isLoading = false;
      });

      // Load threads for first event
      if (_events.isNotEmpty) {
        await _loadThreadsForEvent(_events[0].id);
      }
    } catch (e) {
      print('[DEBUG] Error loading forum events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadThreadsForEvent(int eventId) async {
    if (_threadsCache.containsKey(eventId)) return;

    try {
      final threadsResponse = DummyDataService.USE_DUMMY_DATA
          ? await DummyDataService.getThreads(eventId)
          : await _apiService.getThreads(eventId);
      setState(() {
        _threadsCache[eventId] = threadsResponse;
      });
    } catch (e) {
      print('[ERROR] Failed to load threads for event $eventId: $e');
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

    if (_events.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Forum'),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No active events with forums', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Forum'),
        backgroundColor: primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController!,
          isScrollable: true,
          tabs: _events.map((event) => Tab(text: event.title)).toList(),
          labelColor: whiteColor,
          unselectedLabelColor: whiteColor.withOpacity(0.7),
          indicatorColor: accentColor,
          onTap: (index) {
            final eventId = _events[index].id;
            _loadThreadsForEvent(eventId);
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: _events.map((event) => _buildForumTab(event)).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('[ACTION] Create new thread tapped');
          _showCreateThreadDialog();
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildForumTab(Event event) {
    final threadsResponse = _threadsCache[event.id];

    if (threadsResponse == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final threads = threadsResponse.threads;

    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No discussions yet',
              style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to start a conversation!',
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.4)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _threadsCache.remove(event.id);
        await _loadThreadsForEvent(event.id);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                print('[NAV] Navigate to thread: ${thread.id}');
                _navigateToThread(thread);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thread title and pinned indicator
                    Row(
                      children: [
                        if (thread.isPinned)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PINNED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: darkColor,
                              ),
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
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Thread preview
                    Text(
                      thread.body.length > 150
                          ? '${thread.body.substring(0, 150)}...'
                          : thread.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Thread metadata
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Text(
                            thread.authorUsername.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          thread.authorUsername,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
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
                        const Spacer(),
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: textColor.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          thread.viewCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    // Last activity
                    if (thread.lastActivityAt.difference(thread.createdAt).inMinutes > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Last activity ${_formatTimeAgo(thread.lastActivityAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
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

  void _navigateToThread(ForumThread thread) {
    // TODO: Navigate to thread detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thread detail for "${thread.title}" coming soon!')),
    );
  }

  void _showCreateThreadDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Thread'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Thread Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty &&
                  bodyController.text.trim().isNotEmpty) {
                _submitThread(titleController.text.trim(), bodyController.text.trim());
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitThread(String title, String body) async {
    if (_events.isEmpty) return;
    final event = _events[_tabController?.index ?? 0];

    try {
      if (DummyDataService.USE_DUMMY_DATA) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread creation disabled in dummy mode')),
        );
        return;
      }

      await _apiService!.createThread(event.id, title, body);
      _threadsCache.remove(event.id);
      await _loadThreadsForEvent(event.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thread created successfully!')),
      );
    } catch (e) {
      print('[ERROR] Failed to create thread: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create thread: $e')),
      );
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

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
