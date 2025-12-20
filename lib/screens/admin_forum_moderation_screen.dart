import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class AdminForumModerationScreen extends StatefulWidget {
  const AdminForumModerationScreen({super.key});

  @override
  State<AdminForumModerationScreen> createState() => _AdminForumModerationScreenState();
}

class _AdminForumModerationScreenState extends State<AdminForumModerationScreen> {
  List<ForumThread> _threads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    try {
      final response = await ApiService.instance.getThreads();
      setState(() {
        _threads = response.threads;
        _isLoading = false;
      });
    } catch (e) {
      print('[ADMIN] Failed to load threads: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load threads: $e')),
        );
      }
    }
  }

  Future<void> _pinThread(ForumThread thread) async {
    try {
      // For now, we'll just show a message since the API might not be implemented
      final newStatus = thread.isPinned ? 'unpinned' : 'pinned';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thread "${thread.title}" $newStatus (API not implemented)')),
      );
      // Reload threads
      await _loadThreads();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pin thread: $e')),
      );
    }
  }

  Future<void> _deleteThread(ForumThread thread) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thread'),
        content: Text('Are you sure you want to delete "${thread.title}"? This action cannot be undone.'),
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
      // For now, we'll just show a message since the API might not be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thread "${thread.title}" deleted (API not implemented)')),
      );
      // Reload threads
      await _loadThreads();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete thread: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Forum Moderation'),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No forum threads found',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Threads will appear here once users start discussions',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _threads.length,
                  itemBuilder: (context, index) {
                    final thread = _threads[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: darkColor.withOpacity(0.1),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (thread.isPinned)
                                            Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: accentColor.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'PINNED',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: darkColor,
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              thread.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'by ${thread.authorUsername} · ${_formatDate(thread.createdAt)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: thread.isLocked ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    thread.isLocked ? 'LOCKED' : 'OPEN',
                                    style: TextStyle(
                                      color: thread.isLocked ? Colors.red : Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              thread.body,
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
                                Icon(Icons.remove_red_eye_outlined, size: 16, color: textColor.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  '${thread.viewCount} views',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.chat_bubble_outline, size: 16, color: textColor.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  '8 replies', // Placeholder since we don't have post count in Thread model
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _pinThread(thread),
                                  icon: Icon(
                                    thread.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                    size: 16,
                                  ),
                                  label: Text(thread.isPinned ? 'Unpin' : 'Pin'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    // TODO: Navigate to thread detail for moderation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('View thread "${thread.title}" coming soon')),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text('View'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _deleteThread(thread),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}