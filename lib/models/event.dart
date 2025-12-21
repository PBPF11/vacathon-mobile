import 'dart:math';

class EventCategory {
  final int id;
  final String name;
  final double distanceKm;
  final String displayName;

  EventCategory({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.displayName,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      distanceKm: _parseDouble(json['distance_km']),
      displayName: json['display_name']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'distance_km': distanceKm,
      'display_name': displayName,
    };
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _parseDouble(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class Event {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String city;
  final String country;
  final String? venue;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? registrationOpenDate;
  final DateTime registrationDeadline;
  final String status;
  final int popularityScore;
  final int participantLimit;
  final int registeredCount;
  final bool featured;
  final String? bannerImage;
  final List<EventCategory> categories;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.city,
    required this.country,
    this.venue,
    required this.startDate,
    this.endDate,
    this.registrationOpenDate,
    required this.registrationDeadline,
    required this.status,
    required this.popularityScore,
    required this.participantLimit,
    required this.registeredCount,
    required this.featured,
    this.bannerImage,
    required this.categories,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final categories = <EventCategory>[];
    final rawCategories = json['categories'];
    if (rawCategories is List) {
      for (final item in rawCategories) {
        if (item is Map<String, dynamic>) {
          categories.add(EventCategory.fromJson(item));
        }
      }
    }

    return Event(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      venue: _parseOptionalString(json['venue']),
      startDate: _parseDate(json['start_date'] ?? json['startDate']),
      endDate: _parseDateOrNull(json['end_date'] ?? json['endDate']),
      registrationOpenDate: _parseDateOrNull(
        json['registration_open_date'] ?? json['registrationOpenDate'],
      ),
      registrationDeadline: _parseDate(
        json['registration_deadline'] ?? json['registrationDeadline'],
      ),
      status: json['status']?.toString() ?? 'upcoming',
      popularityScore: _parseInt(json['popularity_score'] ?? json['popularityScore']),
      participantLimit: _parseInt(json['participant_limit'] ?? json['participantLimit']),
      registeredCount: _parseInt(json['registered_count'] ?? json['registeredCount']),
      featured: _parseBool(json['featured']),
      bannerImage: _parseOptionalString(json['banner_image'] ?? json['bannerImage']),
      categories: categories,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'city': city,
      'country': country,
      'venue': venue,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'registration_open_date': registrationOpenDate?.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      'status': status,
      'popularity_score': popularityScore,
      'participant_limit': participantLimit,
      'registered_count': registeredCount,
      'featured': featured,
      'banner_image': bannerImage,
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int? get durationDays {
    if (endDate == null) {
      return null;
    }
    final diff = endDate!.difference(startDate).inDays + 1;
    return max(diff, 1);
  }

  String get formattedDateRange {
    if (endDate == null || _isSameDay(startDate, endDate!)) {
      return _formatDate(startDate);
    }
    return '${_formatDate(startDate)} - ${_formatDate(endDate!)}';
  }

  double get capacityRatio {
    if (participantLimit <= 0) {
      return 0;
    }
    final ratio = (registeredCount / participantLimit) * 100;
    if (ratio.isNaN || ratio.isInfinite) {
      return 0;
    }
    return ratio.clamp(0, 100).toDouble();
  }

  int? get remainingSlots {
    if (participantLimit <= 0) {
      return null;
    }
    final remaining = participantLimit - registeredCount;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isRegistrationOpen {
    if (status == 'completed') {
      return false;
    }
    final now = DateTime.now();
    final openDate = registrationOpenDate ?? now;
    final isAfterOpen = openDate.isBefore(now) || _isSameDay(openDate, now);
    final isBeforeClose =
        registrationDeadline.isAfter(now) || _isSameDay(registrationDeadline, now);
    if (!isAfterOpen || !isBeforeClose) {
      return false;
    }
    if (participantLimit > 0 && registeredCount >= participantLimit) {
      return false;
    }
    return true;
  }

  String get registrationStatusMessage {
    if (status == 'completed') {
      return 'Event completed';
    }
    if (participantLimit > 0 && registeredCount >= participantLimit) {
      return 'Registration full';
    }
    final now = DateTime.now();
    if (registrationOpenDate != null && now.isBefore(registrationOpenDate!)) {
      return 'Registration opens on ${_formatDate(registrationOpenDate!)}';
    }
    if (now.isAfter(registrationDeadline)) {
      return 'Registration closed';
    }
    return 'Registration open';
  }

  String get statusDisplay {
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Event && other.id == id && other.slug == slug;
  }

  @override
  int get hashCode => Object.hash(id, slug);

  static String? _parseOptionalString(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value != 0;
    }
    final normalized = value?.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }

  static DateTime? _parseDateOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return null;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }
}

class EventPagination {
  final int page;
  final int pages;
  final bool hasNext;
  final bool hasPrevious;
  final int total;

  EventPagination({
    required this.page,
    required this.pages,
    required this.hasNext,
    required this.hasPrevious,
    required this.total,
  });

  factory EventPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return EventPagination(
        page: 1,
        pages: 1,
        hasNext: false,
        hasPrevious: false,
        total: 0,
      );
    }
    return EventPagination(
      page: _parseInt(json['page'], fallback: 1),
      pages: _parseInt(json['pages'], fallback: 1),
      hasNext: json['has_next'] == true || json['hasNext'] == true,
      hasPrevious: json['has_previous'] == true || json['hasPrevious'] == true,
      total: _parseInt(json['total'], fallback: 0),
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class EventsResponse {
  final List<Event> events;
  final EventPagination pagination;

  EventsResponse({required this.events, required this.pagination});

  factory EventsResponse.fromJson(dynamic json) {
    if (json is List) {
      final events = json
          .whereType<Map<String, dynamic>>()
          .map(Event.fromJson)
          .toList();
      return EventsResponse(
        events: events,
        pagination: EventPagination(
          page: 1,
          pages: 1,
          hasNext: false,
          hasPrevious: false,
          total: events.length,
        ),
      );
    }

    if (json is Map<String, dynamic>) {
      final rawResults = json['results'] ?? json['events'] ?? [];
      final events = <Event>[];
      if (rawResults is List) {
        for (final item in rawResults) {
          if (item is Map<String, dynamic>) {
            events.add(Event.fromJson(item));
          }
        }
      }
      final pagination = json['pagination'] is Map<String, dynamic>
          ? EventPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : EventPagination(
              page: 1,
              pages: 1,
              hasNext: false,
              hasPrevious: false,
              total: events.length,
            );

      return EventsResponse(events: events, pagination: pagination);
    }

    return EventsResponse(
      events: [],
      pagination: EventPagination(
        page: 1,
        pages: 1,
        hasNext: false,
        hasPrevious: false,
        total: 0,
      ),
    );
  }
}

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
