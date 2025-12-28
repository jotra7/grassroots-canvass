import 'package:flutter/material.dart';

class Campaign {
  final String id;
  final String name;
  final String? description;
  final String? organizationName;
  final String? candidateName;
  final DateTime? electionDate;
  final String? district;
  final double defaultLatitude;
  final double defaultLongitude;
  final int defaultZoom;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;
  final DateTime createdAt;
  final String? userRole; // User's role in this campaign

  Campaign({
    required this.id,
    required this.name,
    this.description,
    this.organizationName,
    this.candidateName,
    this.electionDate,
    this.district,
    this.defaultLatitude = 33.4484,
    this.defaultLongitude = -112.0740,
    this.defaultZoom = 12,
    this.primaryColor = const Color(0xFF2563eb),
    this.secondaryColor = const Color(0xFF16a34a),
    this.isActive = true,
    required this.createdAt,
    this.userRole,
  });

  factory Campaign.fromJson(Map<String, dynamic> json, {String? userRole}) {
    return Campaign(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      organizationName: json['organization_name'] as String?,
      candidateName: json['candidate_name'] as String?,
      electionDate: json['election_date'] != null
          ? DateTime.parse(json['election_date'] as String)
          : null,
      district: json['district'] as String?,
      defaultLatitude: (json['default_latitude'] as num?)?.toDouble() ?? 33.4484,
      defaultLongitude: (json['default_longitude'] as num?)?.toDouble() ?? -112.0740,
      defaultZoom: (json['default_zoom'] as int?) ?? 12,
      primaryColor: _parseColor(json['primary_color'] as String?) ?? const Color(0xFF2563eb),
      secondaryColor: _parseColor(json['secondary_color'] as String?) ?? const Color(0xFF16a34a),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      userRole: userRole ?? json['user_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'organization_name': organizationName,
      'candidate_name': candidateName,
      'election_date': electionDate?.toIso8601String().split('T').first,
      'district': district,
      'default_latitude': defaultLatitude,
      'default_longitude': defaultLongitude,
      'default_zoom': defaultZoom,
      'primary_color': _colorToHex(primaryColor),
      'secondary_color': _colorToHex(secondaryColor),
      'is_active': isActive,
    };
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return null;
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  bool get isAdmin => userRole == 'admin';
  bool get isTeamLead => userRole == 'team_lead';
  bool get isCanvasser => userRole == 'canvasser';
  bool get canManage => isAdmin || isTeamLead;

  String get displayName {
    if (candidateName != null && candidateName!.isNotEmpty) {
      return '$name - $candidateName';
    }
    return name;
  }

  Campaign copyWith({
    String? id,
    String? name,
    String? description,
    String? organizationName,
    String? candidateName,
    DateTime? electionDate,
    String? district,
    double? defaultLatitude,
    double? defaultLongitude,
    int? defaultZoom,
    Color? primaryColor,
    Color? secondaryColor,
    bool? isActive,
    DateTime? createdAt,
    String? userRole,
  }) {
    return Campaign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      organizationName: organizationName ?? this.organizationName,
      candidateName: candidateName ?? this.candidateName,
      electionDate: electionDate ?? this.electionDate,
      district: district ?? this.district,
      defaultLatitude: defaultLatitude ?? this.defaultLatitude,
      defaultLongitude: defaultLongitude ?? this.defaultLongitude,
      defaultZoom: defaultZoom ?? this.defaultZoom,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      userRole: userRole ?? this.userRole,
    );
  }
}

class CampaignMember {
  final String id;
  final String campaignId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final String? userEmail;
  final String? userName;

  CampaignMember({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.userEmail,
    this.userName,
  });

  factory CampaignMember.fromJson(Map<String, dynamic> json) {
    final userProfile = json['user_profiles'] as Map<String, dynamic>?;
    return CampaignMember(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      userEmail: userProfile?['email'] as String?,
      userName: userProfile?['full_name'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isTeamLead => role == 'team_lead';
  bool get isCanvasser => role == 'canvasser';
}
