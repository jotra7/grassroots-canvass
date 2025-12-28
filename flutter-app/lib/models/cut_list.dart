import 'package:latlong2/latlong.dart';

class CutList {
  final String id;
  final String name;
  final String? description;
  final List<LatLng>? boundaryPolygon;
  final int voterCount;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CutList({
    required this.id,
    required this.name,
    this.description,
    this.boundaryPolygon,
    this.voterCount = 0,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CutList.fromJson(Map<String, dynamic> json) {
    List<LatLng>? polygon;
    if (json['boundary_polygon'] != null) {
      final List<dynamic> coords = json['boundary_polygon'];
      polygon = coords.map((c) => LatLng(c['lat'], c['lng'])).toList();
    }

    return CutList(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      boundaryPolygon: polygon,
      voterCount: json['voter_count'] ?? 0,
      createdBy: json['created_by'],
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
      'name': name,
      'description': description,
      'boundary_polygon': boundaryPolygon
          ?.map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'voter_count': voterCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CutList copyWith({
    String? id,
    String? name,
    String? description,
    List<LatLng>? boundaryPolygon,
    int? voterCount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CutList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      boundaryPolygon: boundaryPolygon ?? this.boundaryPolygon,
      voterCount: voterCount ?? this.voterCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CutListAssignment {
  final String id;
  final String cutListId;
  final String userId;
  final String? userEmail;
  final String? userName;
  final DateTime assignedAt;
  final String? assignedBy;

  const CutListAssignment({
    required this.id,
    required this.cutListId,
    required this.userId,
    this.userEmail,
    this.userName,
    required this.assignedAt,
    this.assignedBy,
  });

  factory CutListAssignment.fromJson(Map<String, dynamic> json) {
    return CutListAssignment(
      id: json['id'] ?? '',
      cutListId: json['cut_list_id'] ?? '',
      userId: json['user_id'] ?? '',
      userEmail: json['user_profiles']?['email'],
      userName: json['user_profiles']?['full_name'],
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : DateTime.now(),
      assignedBy: json['assigned_by'],
    );
  }
}
