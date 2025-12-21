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

class ForumDetailScreen extends StatefulWidget {
  final ForumThread thread;

  const ForumDetailScreen({super.key, required this.thread});

  @override
  State<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
  late ForumThread _thread;
  List<ForumPost> _posts = [];
  List<ThreadedPost> _organizedPosts = [];
  bool _isLoading = true;
  UserProfile? _currentUser;

  // Input Controller
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _isSubmitting = false;

  // Reply State
  ForumPost? _replyingTo;

  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadCurrentUser();
    await _loadThreadDetail();
    await _loadPosts();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await ApiService.instance.getProfile();
      setState(() {
        _currentUser = profile;
      });
    } catch (e) {
      print('[ERROR] Failed to load user profile: $e');
    }
  }

  Future<void> _loadThreadDetail() async {
    if (DummyDataService.USE_DUMMY_DATA) return;
    try {
      print('[DEBUG] Fetching thread detail for ${_thread.slug}...');
      final updatedThread = await ApiService.instance.getThreadDetail(
        _thread.slug,
      );
      print(
        '[DEBUG] Fetched thread detail. View Count: ${updatedThread.viewCount}',
      );
      if (mounted) {
        setState(() {
          _thread = updatedThread;
        });
      }
    } catch (e) {
      print('[ERROR] Failed to refresh thread detail: $e');
      // Non-critical, just keep old thread data
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final postsResponse = DummyDataService.USE_DUMMY_DATA
          ? await DummyDataService.getPosts(_thread.slug)
          : await ApiService.instance.getPosts(_thread.slug);

      final rawPosts = postsResponse.posts;
      final List<ThreadedPost> organized = [];

      // Map parentId -> List<Children>
      final Map<int?, List<ForumPost>> childrenMap = {};

      for (var post in rawPosts) {
        final pid = post.parentId;
        if (!childrenMap.containsKey(pid)) {
          childrenMap[pid] = [];
        }
        childrenMap[pid]!.add(post);
      }

      // Recursive function to build flat list
      void addPosts(int? parentId, int depth) {
        final children = childrenMap[parentId];
        if (children == null) return;

        // Sort by ID or Date if needed
        for (var post in children) {
          organized.add(ThreadedPost(post, depth));
          addPosts(post.id, depth + 1);
        }
      }

      // Start with null parent (root posts)
      addPosts(null, 0);

      setState(() {
        _posts = rawPosts;
        _organizedPosts = organized;
        _isLoading = false;
      });
    } catch (e) {
      print('[ERROR] Failed to load posts: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load posts: $e')));
      }
    }
  }

  void _setReplyTo(ForumPost? post) {
    setState(() {
      _replyingTo = post;
    });
    if (post != null) {
      _replyFocusNode.requestFocus();
    }
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      if (DummyDataService.USE_DUMMY_DATA) {
        final newPost = await DummyDataService.addPost(
          _thread.slug,
          content,
          parentId: _replyingTo?.id,
          authorUsername: _currentUser?.username ?? 'you',
        );
        _replyController.clear();
        _setReplyTo(null);
        _replyFocusNode.unfocus();
        setState(() {
          _posts.add(newPost);
          _organizedPosts.add(ThreadedPost(newPost, _replyingTo == null ? 0 : 1));
        });
      } else {
        await ApiService.instance.createPost(
          _thread.slug,
          content,
          parentId: _replyingTo?.id,
        );
        _replyController.clear();
        _setReplyTo(null); // Reset reply state
        _replyFocusNode.unfocus();
        await _loadPosts(); // Reload posts
      }
    } catch (e) {
      print('[ERROR] Failed to submit reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit reply: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleLike(ForumPost post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final oldPost = _posts[index];
    final newLiked = !oldPost.isLikedByUser;
    final newCount = newLiked
        ? oldPost.likesCount + 1
        : (oldPost.likesCount - 1).clamp(0, 999999);

    // Optimistic Update: Update UI immediately
    setState(() {
      final updatedPost = ForumPost(
        id: oldPost.id,
        threadId: oldPost.threadId,
        authorId: oldPost.authorId,
        authorUsername: oldPost.authorUsername,
        parentId: oldPost.parentId,
        content: oldPost.content,
        createdAt: oldPost.createdAt,
        updatedAt: oldPost.updatedAt,
        likesCount: newCount,
        isLikedByUser: newLiked,
      );
      _posts[index] = updatedPost;

      // Update organized posts (which drives the UI)
      final orgIndex = _organizedPosts.indexWhere(
        (tp) => tp.post.id == post.id,
      );
      if (orgIndex != -1) {
        _organizedPosts[orgIndex] = ThreadedPost(
          updatedPost,
          _organizedPosts[orgIndex].depth,
        );
      }
    });

    try {
      await ApiService.instance.likePost(post.id);
    } catch (e) {
      print('[ERROR] Failed to like post: $e');
      // Revert change if API fails
      if (mounted) {
        setState(() {
          _posts[index] = oldPost;
          final orgIndex = _organizedPosts.indexWhere(
            (tp) => tp.post.id == post.id,
          );
          if (orgIndex != -1) {
            _organizedPosts[orgIndex] = ThreadedPost(
              oldPost,
              _organizedPosts[orgIndex].depth,
            );
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to like post')));
      }
    }
  }

  Future<void> _deleteThread() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thread'),
        content: const Text(
          'Are you sure you want to delete this thread? This action cannot be undone.',
        ),
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
      await ApiService.instance.deleteThread(_thread.slug);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete thread: $e')));
      }
    }
  }

  Future<void> _deletePost(ForumPost post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
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
      await ApiService.instance.deletePost(post.id);
      await _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
      }
    }
  }

  bool _canDelete(String authorUsername) {
    if (DummyDataService.USE_DUMMY_DATA || _currentUser == null) return false;
    if (_currentUser!.isSuperuser || _currentUser!.isStaff) return true;
    return _currentUser!.username == authorUsername;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Thread Detail'),
        backgroundColor: primaryColor,
        actions: [
          if (_canDelete(_thread.authorUsername))
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteThread,
              tooltip: 'Delete Thread',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildThreadHeader(),
                        const SizedBox(height: 24),
                        const Divider(thickness: 1),
                        const SizedBox(height: 16),
                        Text(
                          'Replies (${_posts.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_organizedPosts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'No replies yet. Be the first!',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _organizedPosts.length,
                            itemBuilder: (context, index) {
                              final item = _organizedPosts[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: 16,
                                  left: (item.depth * 16.0).clamp(
                                    0.0,
                                    96.0,
                                  ), // Increased indentation clamp
                                ),
                                child: _buildPostItem(item.post),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildThreadHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_thread.isPinned)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        Text(
          _thread.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor,
              child: Text(
                _thread.authorUsername[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _thread.authorUsername,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _formatDate(_thread.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dot separator
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.remove_red_eye_outlined,
                      size: 14,
                      color: textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_thread.viewCount} views',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _thread.body,
          style: const TextStyle(fontSize: 16, height: 1.5, color: textColor),
        ),
      ],
    );
  }

  Widget _buildPostItem(ForumPost post) {
    final bool canDelete = _canDelete(post.authorUsername);
    final bool isReplyingToThis = _replyingTo?.id == post.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReplyingToThis ? primaryColor.withOpacity(0.1) : whiteColor,
        borderRadius: BorderRadius.circular(8),
        border: isReplyingToThis ? Border.all(color: primaryColor) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[300],
                child: Text(
                  post.authorUsername[0].toUpperCase(),
                  style: const TextStyle(
                    color: darkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.authorUsername,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _formatDate(post.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withOpacity(0.5),
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                  onPressed: () => _deletePost(post),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: const TextStyle(fontSize: 14, color: textColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () => _toggleLike(post),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: post.isLikedByUser ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likesCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Reply Button
              InkWell(
                onTap: () => _setReplyTo(post),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Report Button
              InkWell(
                onTap: () => _reportPost(post),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Report',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reportPost(ForumPost post) async {
    final reasonController = TextEditingController();
    final shouldReport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Let us know why this post should be reviewed:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (e.g. spam, harassment)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (shouldReport == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please provide a reason.')),
          );
        }
        return;
      }
      try {
        final response = await ApiService.instance.reportPost(post.id, reason);
        if (mounted) {
          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Report submitted. Thank you for keeping the forum safe.',
                ),
              ),
            );
          } else {
            final message = response['message'] ?? 'Failed to submit report.';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit report: $e')),
          );
        }
      }
    }
  }

  Widget _buildReplyInput() {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replying Banner
            if (_replyingTo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replying to ${_replyingTo!.authorUsername}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _setReplyTo(null),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      focusNode: _replyFocusNode, // Attach focus node
                      decoration: InputDecoration(
                        hintText: 'Type a reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isSubmitting ? null : _submitReply,
                    mini: true,
                    backgroundColor: primaryColor,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter, you might want to use intl package
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }
}

class ThreadedPost {
  final ForumPost post;
  final int depth;

  ThreadedPost(this.post, this.depth);
}
