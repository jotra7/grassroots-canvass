class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String role; // 'pending', 'canvasser', 'team_lead', 'admin'
  final String? approvedAt;
  final String? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.approvedAt,
    this.createdAt,
  });

  bool get isApproved => role == 'canvasser' || role == 'team_lead' || role == 'admin';
  bool get isAdmin => role == 'admin';
  bool get isTeamLead => role == 'team_lead';
  bool get isPending => role == 'pending';
  /// Team leads and admins can manage cut lists and load all voters
  bool get canManageCutLists => role == 'team_lead' || role == 'admin';
  String? get displayName => fullName;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'],
      role: json['role'] ?? 'pending',
      approvedAt: json['approved_at'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'approved_at': approvedAt,
      'created_at': createdAt,
    };
  }
}
