import 'event.dart';

/// Represents a user's race history entry.
class UserRaceHistory {
  final int id;
  final Event event;
  final String category;
  final DateTime registrationDate;
  final String status;
  final String? bibNumber;
  final Duration? finishTime;
  final bool medalAwarded;
  final String? certificateUrl;
  final String? notes;
  final DateTime updatedAt;

  UserRaceHistory({
    required this.id,
    required this.event,
    required this.category,
    required this.registrationDate,
    required this.status,
    this.bibNumber,
    this.finishTime,
    this.medalAwarded = false,
    this.certificateUrl,
    this.notes,
    required this.updatedAt,
  });

  factory UserRaceHistory.fromJson(Map<String, dynamic> json) {
    return UserRaceHistory(
      id: json['id'],
      event: Event.fromJson(json['event']),
      category: json['category'],
      registrationDate: DateTime.parse(json['registration_date']),
      status: json['status'],
      bibNumber: json['bib_number'],
      finishTime: json['finish_time'] != null
          ? Duration(seconds: json['finish_time'])
          : null,
      medalAwarded: json['medal_awarded'] ?? false,
      certificateUrl: json['certificate_url'],
      notes: json['notes'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event.toJson(),
      'category': category,
      'registration_date': registrationDate.toIso8601String(),
      'status': status,
      'bib_number': bibNumber,
      'finish_time': finishTime?.inSeconds,
      'medal_awarded': medalAwarded,
      'certificate_url': certificateUrl,
      'notes': notes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get status display name
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'registered':
        return 'Registered';
      case 'completed':
        return 'Completed';
      case 'dnf':
        return 'Did Not Finish';
      case 'dns':
        return 'Did Not Start';
      case 'upcoming':
        return 'Upcoming';
      default:
        return status;
    }
  }
}

/// Represents a runner achievement.
class RunnerAchievement {
  final int id;
  final String title;
  final String? description;
  final DateTime? achievedOn;
  final String? link;

  RunnerAchievement({
    required this.id,
    required this.title,
    this.description,
    this.achievedOn,
    this.link,
  });

  factory RunnerAchievement.fromJson(Map<String, dynamic> json) {
    return RunnerAchievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      achievedOn: json['achieved_on'] != null
          ? DateTime.parse(json['achieved_on'])
          : null,
      link: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'achieved_on': achievedOn?.toIso8601String(),
      'link': link,
    };
  }
}

/// Represents a user profile.
class UserProfile {
  final int id;
  final String username;
  final String displayName;
  final String? bio;
  final String? city;
  final String? country;
  final String? avatarUrl;
  final String? favoriteDistance;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? website;
  final String? instagramHandle;
  final String? stravaProfile;
  final DateTime? birthDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UserRaceHistory> history;
  final List<RunnerAchievement> achievements;
  final bool isSuperuser;
  final bool isStaff;

  UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.city,
    this.country,
    this.avatarUrl,
    this.favoriteDistance,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.website,
    this.instagramHandle,
    this.stravaProfile,
    this.birthDate,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
    required this.achievements,
    this.isSuperuser = false,
    this.isStaff = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      username: json['username'],
      displayName: json['display_name'] ?? json['username'],
      bio: json['bio'],
      city: json['city'],
      country: json['country'],
      avatarUrl: json['avatar_url'],
      favoriteDistance: json['favorite_distance'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      website: json['website'],
      instagramHandle: json['instagram_handle'],
      stravaProfile: json['strava_profile'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      history: (json['history'] as List? ?? [])
          .map((item) => UserRaceHistory.fromJson(item))
          .toList(),
      achievements: (json['achievements'] as List? ?? [])
          .map((item) => RunnerAchievement.fromJson(item))
          .toList(),
      isSuperuser: json['is_superuser'] ?? false,
      isStaff: json['is_staff'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'city': city,
      'country': country,
      'avatar_url': avatarUrl,
      'favorite_distance': favoriteDistance,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'website': website,
      'instagram_handle': instagramHandle,
      'strava_profile': stravaProfile,
      'birth_date': birthDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'history': history.map((item) => item.toJson()).toList(),
      'achievements': achievements.map((item) => item.toJson()).toList(),
    };
  }

  /// Get completed races count
  int get completedRaces {
    return history.where((item) => item.status == 'completed').length;
  }

  /// Get upcoming races
  List<UserRaceHistory> get upcomingRaces {
    return history
        .where(
          (item) => item.status == 'upcoming' || item.status == 'registered',
        )
        .toList();
  }

  /// Get stats
  Map<String, int> get stats {
    return {
      'total_events': history.length,
      'completed': completedRaces,
      'upcoming': upcomingRaces.length,
    };
  }

  /// Get next event
  UserRaceHistory? get nextEvent {
    final upcoming = upcomingRaces;
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.event.startDate.compareTo(b.event.startDate));
    return upcoming.first;
  }
}
