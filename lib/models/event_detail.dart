/// Represents an event schedule item.
class EventSchedule {
  final int id;
  final int eventId;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String? description;

  EventSchedule({
    required this.id,
    required this.eventId,
    required this.title,
    required this.startTime,
    this.endTime,
    this.description,
  });

  factory EventSchedule.fromJson(Map<String, dynamic> json) {
    return EventSchedule(
      id: json['id'],
      eventId: json['event'],
      title: json['title'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': eventId,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'description': description,
    };
  }

  /// Formatted time range
  String get formattedTime {
    final timeFormat = 'HH:mm';
    if (endTime == null) {
      return startTime.toString().split(' ')[1].substring(0, 5);
    }
    return '${startTime.toString().split(' ')[1].substring(0, 5)} - ${endTime!.toString().split(' ')[1].substring(0, 5)}';
  }
}

/// Represents an aid station.
class AidStation {
  final int id;
  final int eventId;
  final String name;
  final double kilometerMarker;
  final String supplies;
  final bool isMedical;

  AidStation({
    required this.id,
    required this.eventId,
    required this.name,
    required this.kilometerMarker,
    required this.supplies,
    required this.isMedical,
  });

  factory AidStation.fromJson(Map<String, dynamic> json) {
    return AidStation(
      id: json['id'],
      eventId: json['event'],
      name: json['name'],
      kilometerMarker: (json['kilometer_marker'] as num).toDouble(),
      supplies: json['supplies'],
      isMedical: json['is_medical'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': eventId,
      'name': name,
      'kilometer_marker': kilometerMarker,
      'supplies': supplies,
      'is_medical': isMedical,
    };
  }
}

/// Represents a route segment.
class RouteSegment {
  final int id;
  final int eventId;
  final int order;
  final String title;
  final String description;
  final double distanceKm;
  final int elevationGain;

  RouteSegment({
    required this.id,
    required this.eventId,
    required this.order,
    required this.title,
    required this.description,
    required this.distanceKm,
    required this.elevationGain,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      id: json['id'],
      eventId: json['event'],
      order: json['order'],
      title: json['title'],
      description: json['description'],
      distanceKm: (json['distance_km'] as num).toDouble(),
      elevationGain: json['elevation_gain'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': eventId,
      'order': order,
      'title': title,
      'description': description,
      'distance_km': distanceKm,
      'elevation_gain': elevationGain,
    };
  }
}

/// Represents an event document.
class EventDocument {
  final int id;
  final int eventId;
  final String title;
  final String documentUrl;
  final String documentType;
  final String uploadedBy;
  final DateTime uploadedAt;

  EventDocument({
    required this.id,
    required this.eventId,
    required this.title,
    required this.documentUrl,
    required this.documentType,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory EventDocument.fromJson(Map<String, dynamic> json) {
    return EventDocument(
      id: json['id'],
      eventId: json['event'],
      title: json['title'],
      documentUrl: json['document_url'],
      documentType: json['document_type'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': eventId,
      'title': title,
      'document_url': documentUrl,
      'document_type': documentType,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  /// Get document type display name
  String get documentTypeDisplay {
    switch (documentType) {
      case 'gpx':
        return 'GPX Route';
      case 'guide':
        return 'Race Guide';
      case 'brochure':
        return 'Brochure';
      case 'other':
        return 'Other';
      default:
        return documentType;
    }
  }
}

/// Complete event detail response
class EventDetail {
  final List<EventSchedule> schedules;
  final List<AidStation> aidStations;
  final List<RouteSegment> routeSegments;
  final List<EventDocument> documents;

  EventDetail({
    required this.schedules,
    required this.aidStations,
    required this.routeSegments,
    required this.documents,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    return EventDetail(
      schedules: (json['schedules'] as List? ?? [])
          .map((item) => EventSchedule.fromJson(item))
          .toList(),
      aidStations: (json['aid_stations'] as List? ?? [])
          .map((item) => AidStation.fromJson(item))
          .toList(),
      routeSegments: (json['route_segments'] as List? ?? [])
          .map((item) => RouteSegment.fromJson(item))
          .toList(),
      documents: (json['documents'] as List? ?? [])
          .map((item) => EventDocument.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedules': schedules.map((item) => item.toJson()).toList(),
      'aid_stations': aidStations.map((item) => item.toJson()).toList(),
      'route_segments': routeSegments.map((item) => item.toJson()).toList(),
      'documents': documents.map((item) => item.toJson()).toList(),
    };
  }
}