/// Represents a forum thread.
class ForumThread {
  final int id;
  final String eventTitle;
  final String authorId;
  final String authorUsername;
  final String title;
  final String slug;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActivityAt;
  final bool isPinned;
  final bool isLocked;
  final int viewCount;

  ForumThread({
    required this.id,
    required this.eventTitle,
    required this.authorId,
    required this.authorUsername,
    required this.title,
    required this.slug,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActivityAt,
    required this.isPinned,
    required this.isLocked,
    required this.viewCount,
  });

  factory ForumThread.fromJson(Map<String, dynamic> json) {
    return ForumThread(
      id: json['id'],
      eventTitle: json['event']?.toString() ?? 'Unknown Event',
      authorId: json['author']?.toString() ?? '0',
      authorUsername: json['author_username'] ?? 'Unknown',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'])
          : DateTime.now(),
      isPinned: json['is_pinned'] ?? false,
      isLocked: json['is_locked'] ?? false,
      viewCount: json['view_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': eventTitle,
      'author': authorId,
      'author_username': authorUsername,
      'title': title,
      'slug': slug,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_activity_at': lastActivityAt.toIso8601String(),
      'is_pinned': isPinned,
      'is_locked': isLocked,
      'view_count': viewCount,
    };
  }
}

/// Represents a forum post.
class ForumPost {
  final int id;
  final int threadId;
  final String authorId;
  final String authorUsername;
  final int? parentId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final bool isLikedByUser;

  ForumPost({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.authorUsername,
    this.parentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.isLikedByUser,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'],
      threadId: json['thread'],
      authorId: json['author'].toString(),
      authorUsername: json['author_username'] ?? 'Unknown',
      parentId: json['parent'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      likesCount: json['likes_count'] ?? 0,
      isLikedByUser: json['is_liked_by_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thread': threadId,
      'author': authorId,
      'author_username': authorUsername,
      'parent': parentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'likes_count': likesCount,
      'is_liked_by_user': isLikedByUser,
    };
  }

  /// Check if this is a reply
  bool get isReply => parentId != null;
}

/// Represents a post report.
class PostReport {
  final int id;
  final int postId;
  final int reporterId;
  final String reporterUsername;
  final String reason;
  final DateTime createdAt;
  final bool resolved;

  PostReport({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reporterUsername,
    required this.reason,
    required this.createdAt,
    required this.resolved,
  });

  factory PostReport.fromJson(Map<String, dynamic> json) {
    return PostReport(
      id: json['id'],
      postId: json['post'],
      reporterId: json['reporter'],
      reporterUsername: json['reporter_username'] ?? 'Unknown',
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']),
      resolved: json['resolved'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post': postId,
      'reporter': reporterId,
      'reporter_username': reporterUsername,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'resolved': resolved,
    };
  }
}

/// Response for threads list
class ThreadsResponse {
  final List<ForumThread> threads;
  final int total;
  final bool hasNext;

  ThreadsResponse({
    required this.threads,
    required this.total,
    required this.hasNext,
  });

  factory ThreadsResponse.fromJson(Map<String, dynamic> json) {
    return ThreadsResponse(
      threads: (json['results'] as List)
          .map((thread) => ForumThread.fromJson(thread))
          .toList(),
      total: json['total'] ?? 0,
      hasNext: json['has_next'] ?? false,
    );
  }
}

/// Response for posts in a thread
class PostsResponse {
  final List<ForumPost> posts;
  final int total;
  final bool hasNext;

  PostsResponse({
    required this.posts,
    required this.total,
    required this.hasNext,
  });

  factory PostsResponse.fromJson(Map<String, dynamic> json) {
    return PostsResponse(
      posts: (json['results'] as List)
          .map((post) => ForumPost.fromJson(post))
          .toList(),
      total: json['total'] ?? 0,
      hasNext: json['has_next'] ?? false,
    );
  }
}
