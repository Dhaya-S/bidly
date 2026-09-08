class CommunityModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? bannerUrl;
  final String type;
  final String category;
  final String? city;
  final String? state;
  final String? address;
  final int radiusKm;
  final String? rules;
  final String? createdBy;
  final int membersCount;
  final String? recentActivityText;
  final DateTime? recentActivityTime;
  final String? userRole;
  final bool isAdmin;
  final bool isJoined;
  final bool isMuted;
  final int unreadCount;

  const CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.bannerUrl,
    this.type = 'NEIGHBORHOOD',
    this.category = 'Other',
    this.city,
    this.state,
    this.address,
    this.radiusKm = 5,
    this.rules,
    this.createdBy,
    this.membersCount = 1,
    this.recentActivityText,
    this.recentActivityTime,
    this.userRole,
    this.isAdmin = false,
    this.isJoined = false,
    this.isMuted = false,
    this.unreadCount = 0,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    DateTime? activityTime;
    if (json['recentActivityTime'] != null) {
      activityTime = DateTime.tryParse(json['recentActivityTime'].toString());
    }

    return CommunityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      type: json['type'] as String? ?? 'NEIGHBORHOOD',
      category: json['category'] as String? ?? 'Other',
      city: json['city'] as String?,
      state: json['state'] as String?,
      address: json['address'] as String?,
      radiusKm: json['radiusKm'] as int? ?? 5,
      rules: json['rules'] as String?,
      createdBy: json['createdBy'] as String?,
      membersCount: json['membersCount'] as int? ?? 1,
      recentActivityText: json['recentActivityText'] as String?,
      recentActivityTime: activityTime,
      userRole: json['userRole'] as String?,
      isAdmin: json['admin'] as bool? ?? (json['userRole'] == 'ADMIN'),
      isJoined: json['joined'] as bool? ?? (json['userRole'] != null),
      isMuted: json['muted'] as bool? ?? json['isMuted'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'bannerUrl': bannerUrl,
      'type': type,
      'category': category,
      'city': city,
      'state': state,
      'address': address,
      'radiusKm': radiusKm,
      'rules': rules,
      'createdBy': createdBy,
      'membersCount': membersCount,
      'recentActivityText': recentActivityText,
      'recentActivityTime': recentActivityTime?.toIso8601String(),
      'userRole': userRole,
      'isAdmin': isAdmin,
      'isJoined': isJoined,
      'isMuted': isMuted,
      'unreadCount': unreadCount,
    };
  }

  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    String? bannerUrl,
    String? type,
    String? category,
    String? city,
    String? state,
    String? address,
    int? radiusKm,
    String? rules,
    String? createdBy,
    int? membersCount,
    String? recentActivityText,
    DateTime? recentActivityTime,
    String? userRole,
    bool? isAdmin,
    bool? isJoined,
    bool? isMuted,
    int? unreadCount,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      type: type ?? this.type,
      category: category ?? this.category,
      city: city ?? this.city,
      state: state ?? this.state,
      address: address ?? this.address,
      radiusKm: radiusKm ?? this.radiusKm,
      rules: rules ?? this.rules,
      createdBy: createdBy ?? this.createdBy,
      membersCount: membersCount ?? this.membersCount,
      recentActivityText: recentActivityText ?? this.recentActivityText,
      recentActivityTime: recentActivityTime ?? this.recentActivityTime,
      userRole: userRole ?? this.userRole,
      isAdmin: isAdmin ?? this.isAdmin,
      isJoined: isJoined ?? this.isJoined,
      isMuted: isMuted ?? this.isMuted,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  String get timeAgo {
    if (recentActivityTime == null) return 'Now';
    final diff = DateTime.now().difference(recentActivityTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
