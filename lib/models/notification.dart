/// Represents a user notification.
class Notification {
  final int id;
  final int recipientId;
  final String title;
  final String message;
  final String category;
  final String? linkUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Notification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.category,
    this.linkUrl,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      recipientId: json['recipient'],
      title: json['title'],
      message: json['message'],
      category: json['category'],
      linkUrl: json['link_url'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient': recipientId,
      'title': title,
      'message': message,
      'category': category,
      'link_url': linkUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  /// Get category display name
  String get categoryDisplay {
    switch (category) {
      case 'registration':
        return 'Registration';
      case 'event':
        return 'Event';
      case 'system':
        return 'System';
      default:
        return category;
    }
  }

  /// Mark as read
  Notification markAsRead() {
    return Notification(
      id: id,
      recipientId: recipientId,
      title: title,
      message: message,
      category: category,
      linkUrl: linkUrl,
      isRead: true,
      createdAt: createdAt,
      readAt: DateTime.now(),
    );
  }
}

/// Response for notifications list
class NotificationsResponse {
  final List<Notification> notifications;
  final int total;
  final bool hasNext;
  final int unreadCount;

  NotificationsResponse({
    required this.notifications,
    required this.total,
    required this.hasNext,
    required this.unreadCount,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      notifications: (json['results'] as List)
          .map((notif) => Notification.fromJson(notif))
          .toList(),
      total: json['total'] ?? 0,
      hasNext: json['has_next'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

/// Summary of notifications for context processor
class NotificationSummary {
  final int unreadCount;
  final List<Notification> recentNotifications;

  NotificationSummary({
    required this.unreadCount,
    required this.recentNotifications,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      unreadCount: json['unread_count'] ?? 0,
      recentNotifications: (json['recent'] as List? ?? [])
          .map((notif) => Notification.fromJson(notif))
          .toList(),
    );
  }
}