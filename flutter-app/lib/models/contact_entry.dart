import 'enums/canvass_result.dart';
import 'enums/contact_method.dart';

class ContactEntry {
  final String id;
  final String visitorId;
  final ContactMethod method;
  final CanvassResult result;
  final String? notes;
  final DateTime contactedAt;
  final String? contactedBy;

  const ContactEntry({
    required this.id,
    required this.visitorId,
    required this.method,
    required this.result,
    this.notes,
    required this.contactedAt,
    this.contactedBy,
  });

  factory ContactEntry.fromJson(Map<String, dynamic> json) {
    return ContactEntry(
      id: json['id'] ?? '',
      // Support both unique_id (new) and visitor_id (legacy)
      visitorId: json['unique_id'] ?? json['visitor_id'] ?? '',
      method: ContactMethod.fromString(json['contact_method']) ?? ContactMethod.call,
      result: CanvassResult.fromString(json['result'] ?? 'Not Contacted'),
      notes: json['notes'],
      contactedAt: json['contacted_at'] != null
          ? DateTime.parse(json['contacted_at'])
          : DateTime.now(),
      contactedBy: json['contacted_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unique_id': visitorId, // Save voter's unique_id for reliable lookups
      'visitor_id': visitorId, // Also save to visitor_id to satisfy NOT NULL constraint
      'contact_method': method.displayName,
      'result': result.displayName,
      'notes': notes,
      'contacted_at': contactedAt.toIso8601String(),
      'contacted_by': contactedBy,
    };
  }

  ContactEntry copyWith({
    String? id,
    String? visitorId,
    ContactMethod? method,
    CanvassResult? result,
    String? notes,
    DateTime? contactedAt,
    String? contactedBy,
  }) {
    return ContactEntry(
      id: id ?? this.id,
      visitorId: visitorId ?? this.visitorId,
      method: method ?? this.method,
      result: result ?? this.result,
      notes: notes ?? this.notes,
      contactedAt: contactedAt ?? this.contactedAt,
      contactedBy: contactedBy ?? this.contactedBy,
    );
  }
}
