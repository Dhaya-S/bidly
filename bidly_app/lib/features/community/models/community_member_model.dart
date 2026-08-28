class CommunityMemberModel {
  final String userId;
  final String name;
  final String phone;
  final String? avatarUrl;
  final String role; // "ADMIN", "MEMBER"
  final DateTime? joinedAt;

  const CommunityMemberModel({
    required this.userId,
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.role = 'MEMBER',
    this.joinedAt,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    DateTime? joined;
    if (json['joinedAt'] != null) {
      joined = DateTime.tryParse(json['joinedAt'].toString());
    }

    return CommunityMemberModel(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Member',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      joinedAt: joined,
    );
  }

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
}
