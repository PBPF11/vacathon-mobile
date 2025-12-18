import 'package:flutter/material.dart';
import '../models/models.dart' as models;
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  models.NotificationsResponse? _notificationsResponse;
  bool _isLoading = true;
  bool _showUnreadOnly = false;
  ApiService? _apiService;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _apiService = ApiService.instance;
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    print('[DEBUG] Loading notifications...');
    try {
      _notificationsResponse = await (DummyDataService.USE_DUMMY_DATA
          ? DummyDataService.getNotifications(unreadOnly: _showUnreadOnly)
          : _apiService!.getNotifications(unreadOnly: _showUnreadOnly));
      print('[DEBUG] Notifications loaded: ${_notificationsResponse?.notifications.length} notifications');
    } catch (e) {
      print('[DEBUG] Error loading notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    print('[ACTION] Mark notification as read: $notificationId');
    if (!DummyDataService.USE_DUMMY_DATA) {
      await _apiService!.markNotificationRead(notificationId);
    }
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    print('[ACTION] Mark all notifications as read');
    if (!DummyDataService.USE_DUMMY_DATA) {
      await _apiService!.markAllNotificationsRead();
    }
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          if (_notificationsResponse != null && _notificationsResponse!.unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: whiteColor,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  'Filter:',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('All'),
                  selected: !_showUnreadOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _showUnreadOnly = false;
                      });
                      _loadNotifications();
                    }
                  },
                  selectedColor: primaryColor.withOpacity(0.2),
                  checkmarkColor: primaryColor,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Unread (${_notificationsResponse?.unreadCount ?? 0})'),
                  selected: _showUnreadOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _showUnreadOnly = true;
                      });
                      _loadNotifications();
                    }
                  },
                  selectedColor: primaryColor.withOpacity(0.2),
                  checkmarkColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notificationsResponse == null || _notificationsResponse!.notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly ? 'No unread notifications' : 'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showUnreadOnly
                ? 'You\'re all caught up!'
                : 'Notifications about your events and registrations will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notificationsResponse!.notifications.length,
        itemBuilder: (context, index) {
          final notification = _notificationsResponse!.notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: notification.isRead ? 1 : 3,
            color: notification.isRead ? whiteColor : primaryColor.withOpacity(0.05),
            child: InkWell(
              onTap: () {
                if (!notification.isRead) {
                  _markAsRead(notification.id);
                }
                _handleNotificationTap(notification);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(notification.category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(notification.category),
                        color: _getCategoryColor(notification.category),
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Notification content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and unread indicator
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: notification.isRead
                                        ? textColor
                                        : primaryColor,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Message
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Category and timestamp
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(notification.category).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  notification.categoryDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getCategoryColor(notification.category),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatTimeAgo(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action button
                    if (notification.linkUrl != null)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: textColor.withOpacity(0.4),
                        ),
                        onPressed: () => _handleNotificationTap(notification),
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

  void _handleNotificationTap(models.Notification notification) {
    print('[ACTION] Notification tapped: ${notification.id}');
    if (notification.linkUrl != null) {
      // TODO: Navigate to the linked resource
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigate to: ${notification.linkUrl}')),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'registration':
        return Icons.assignment;
      case 'event':
        return Icons.event;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'registration':
        return Colors.blue;
      case 'event':
        return Colors.green;
      case 'system':
        return Colors.orange;
      default:
        return primaryColor;
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
