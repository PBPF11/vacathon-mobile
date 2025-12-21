import 'event.dart';

/// Represents an event registration.
class EventRegistration {
  final String id;
  final String referenceCode;
  final int userId;
  final String userUsername;
  final Event event;
  final int? categoryId;
  final String? categoryDisplayName;
  final String distanceLabel;
  final String phoneNumber;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String? medicalNotes;
  final String status;
  final String paymentStatus;
  final Map<String, dynamic> formPayload;
  final String? decisionNote;
  final String? bibNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;

  EventRegistration({
    required this.id,
    required this.referenceCode,
    required this.userId,
    required this.userUsername,
    required this.event,
    this.categoryId,
    this.categoryDisplayName,
    required this.distanceLabel,
    required this.phoneNumber,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    this.medicalNotes,
    required this.status,
    required this.paymentStatus,
    required this.formPayload,
    this.decisionNote,
    this.bibNumber,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.cancelledAt,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    int? categoryId;
    final rawCategory = json['category'] ?? json['category_id'];
    if (rawCategory != null) {
      categoryId = int.tryParse(rawCategory.toString());
    }

    return EventRegistration(
      id: json['id']?.toString() ?? "0",
      referenceCode: json['reference_code'] ?? "",
      userId: json['user_id'] ?? 0,
      userUsername: json['user_username'] ?? "",
      
      // Memanggil Event.fromJson yang sudah kita buat 'safe' di atas
      event: Event.fromJson(json['event'] ?? {}),

      // KUNCI: Paksa jadi String karena di JSON isinya angka 100
      distanceLabel: json['distance_label']?.toString() ?? "",
      
      phoneNumber: json['phone_number'] ?? "",
      emergencyContactName: json['emergency_contact_name'] ?? "",
      
      // Tambahkan fallback untuk field yang mungkin gak ada di JSON detail
      emergencyContactPhone: json['emergency_contact_phone'] ?? "", 

      categoryId: categoryId,
      categoryDisplayName: json['category_display_name'],
      medicalNotes: json['medical_notes'],
      status: json['status'] ?? "pending",
      paymentStatus: json['payment_status'] ?? "unpaid",
      
      formPayload: json['form_payload'] ?? {},
      decisionNote: json['decision_note'],
      bibNumber: json['bib_number'],
      
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_code': referenceCode,
      'user': userId,
      'user_username': userUsername,
      'event': event.toJson(),
      'category': categoryId,
      'category_display_name': categoryDisplayName,
      'distance_label': distanceLabel,
      'phone_number': phoneNumber,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'medical_notes': medicalNotes,
      'status': status,
      'payment_status': paymentStatus,
      'form_payload': formPayload,
      'decision_note': decisionNote,
      'bib_number': bibNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  /// Get status display name
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'confirmed':
        return 'Confirmed';
      case 'waitlisted':
        return 'Waitlisted';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  /// Get payment status display name
  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case 'unpaid':
        return 'Unpaid';
      case 'paid':
        return 'Paid';
      case 'refunded':
        return 'Refunded';
      default:
        return paymentStatus;
    }
  }

  /// Check if registration is active
  bool get isActive {
    return status == 'pending' || status == 'confirmed' || status == 'waitlisted';
  }

  /// Check if confirmed
  bool get isConfirmed => status == 'confirmed';
}

/// Response for registrations list
class RegistrationsResponse {
  final List<EventRegistration> registrations;
  final int total;
  final bool hasNext;

  RegistrationsResponse({
    required this.registrations,
    required this.total,
    required this.hasNext,
  });

  factory RegistrationsResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationsResponse(
      registrations: (json['results'] as List)
          .map((reg) => EventRegistration.fromJson(reg))
          .toList(),
      total: json['total'] ?? 0,
      hasNext: json['has_next'] ?? false,
    );
  }
}
