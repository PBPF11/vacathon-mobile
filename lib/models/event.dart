import 'package:intl/intl.dart';
import 'package:intl/intl.dart';

/// Represents an event category (e.g., 5K, 21K).
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
      id: json['id'],
      name: json['name'],
      distanceKm: (json['distance_km'] as num).toDouble(),
      displayName: json['display_name'],
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
}

/// Represents a marathon event.
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

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();

    // Handle backend's broken date format: "0026-01-01" -> "2026-01-01"
    if (dateStr.startsWith('00') && dateStr.length >= 10) {
      dateStr = '20' + dateStr.substring(2);
      print('[DATE_FIX] Corrected backend date: $dateStr');
    }

    // Handle year-only dates like "2026" -> "2026-01-01"
    if (RegExp(r'^\d{4}$').hasMatch(dateStr)) {
      dateStr = '$dateStr-01-01';
      print('[DATE_FIX] Fixed year-only date: $dateStr');
    }

    try {
      final dt = DateTime.parse(dateStr);
      return dt;
    } catch (e) {
      print('[DATE_FIX] Failed to parse date: "$dateStr", error: $e');
      // Last resort: try to extract year and create a valid date
      final yearMatch = RegExp(r'(\d{4})').firstMatch(dateStr);
      if (yearMatch != null) {
        final year = int.tryParse(yearMatch.group(1)!) ?? DateTime.now().year;
        return DateTime(year, 1, 1);
      }
      return DateTime.now();
    }
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      slug: json['slug'] ?? "",
      description: json['description'] ?? "",
      city: json['city'] ?? "",
      country: json['country'] ?? "",
      venue: json['venue'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      registrationOpenDate: json['registration_open_date'] != null
          ? DateTime.parse(json['registration_open_date'])
          : null,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.parse(json['registration_deadline'])
          : DateTime.now(),
      status: json['status'] ?? "",
      popularityScore: json['popularity_score'] ?? 0,
      participantLimit: json['participant_limit'] == 0 ? 100 : (json['participant_limit'] ?? 100),
      registeredCount: json['registered_count'] ?? 0,
      featured: json['featured'] ?? false,
      bannerImage: json['banner_image'],
      // Handle list categories biar gak null error
      categories: (json['categories'] as List? ?? [])
          .map((i) => EventCategory.fromJson(i))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
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

  /// Check if registration is open
  bool get isRegistrationOpen {
    final now = DateTime.now();
    final openDate = registrationOpenDate ?? now;
    final hasCapacity = participantLimit == 0 || registeredCount < participantLimit;
    return openDate.isBefore(now) &&
        now.isBefore(registrationDeadline) &&
        status != 'completed' &&
        hasCapacity;
  }

  /// Get capacity ratio (0-100)
  double get capacityRatio {
    if (participantLimit == 0) return 0;
    return (registeredCount / participantLimit).clamp(0.0, 1.0) * 100;
  }

  /// Get remaining slots
  int? get remainingSlots {
    if (participantLimit == 0) return null;
    return participantLimit - registeredCount;
  }

  /// Get specific registration status message
  String get registrationStatusMessage {
    if (status == 'completed') {
      return 'This event has been completed.';
    }
    if (DateTime.now().isAfter(registrationDeadline)) {
      return 'Registration deadline has passed.';
    }
    if (registrationOpenDate != null && DateTime.now().isBefore(registrationOpenDate!)) {
      return 'Registration opens on ${registrationOpenDate!.month}/${registrationOpenDate!.day}/${registrationOpenDate!.year}.';
    }
    if (participantLimit > 0 && registeredCount >= participantLimit) {
      return 'This event is fully booked.';
    }
    if (isRegistrationOpen) {
      return 'Registration is open. Secure your bib today!';
    }
    return 'Registration is currently closed.';
  }

  /// Get duration in days
  int? get durationDays {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays + 1;
  }

  /// Formatted date range
  String get formattedDateRange {
    final formatter = DateFormat('MMM dd, yyyy');
    if (endDate == null) {
      return formatter.format(startDate);
    }
    return '${formatter.format(startDate)} - ${formatter.format(endDate!)}';
  }
}

/// Pagination info for events list
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

  factory EventPagination.fromJson(Map<String, dynamic> json) {
    return EventPagination(
      page: json['page'],
      pages: json['pages'],
      hasNext: json['has_next'],
      hasPrevious: json['has_previous'],
      total: json['total'],
    );
  }
}

/// Response for events API
class EventsResponse {
  final List<Event> events;
  final EventPagination pagination;

  EventsResponse({
    required this.events,
    required this.pagination,
  });

  factory EventsResponse.fromJson(Map<String, dynamic> json) {
    return EventsResponse(
      events: (json['results'] as List)
          .map((event) => Event.fromJson(event))
          .toList(),
      pagination: EventPagination.fromJson(json['pagination']),
    );
  }
}