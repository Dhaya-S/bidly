class UserModel {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String sellerType; // 'INDIVIDUAL' or 'BUSINESS'
  final String? avatarUrl;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final bool active;
  final bool identityVerified;
  final String? identityProvider;
  final int trustScore;
  final String? address;
  final String? pincode;
  final int searchRadiusKm;
  final bool onboardingCompleted;
  final Set<String> interests;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.sellerType = 'INDIVIDUAL',
    this.avatarUrl,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.active = true,
    this.identityVerified = false,
    this.identityProvider,
    this.trustScore = 0,
    this.address,
    this.pincode,
    this.searchRadiusKm = 5,
    this.onboardingCompleted = false,
    this.interests = const {},
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    Set<String> parsedInterests = {};
    if (json['interests'] != null && json['interests'] is List) {
      parsedInterests = (json['interests'] as List).map((e) => e.toString()).toSet();
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      sellerType: json['sellerType'] as String? ?? 'INDIVIDUAL',
      avatarUrl: json['avatarUrl'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      active: json['active'] as bool? ?? true,
      identityVerified: json['identityVerified'] as bool? ?? false,
      identityProvider: json['identityProvider'] as String?,
      trustScore: json['trustScore'] as int? ?? 0,
      address: json['address'] as String?,
      pincode: json['pincode'] as String?,
      searchRadiusKm: json['searchRadiusKm'] as int? ?? 5,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      interests: parsedInterests,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'sellerType': sellerType,
      'avatarUrl': avatarUrl,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'active': active,
      'identityVerified': identityVerified,
      'identityProvider': identityProvider,
      'trustScore': trustScore,
      'address': address,
      'pincode': pincode,
      'searchRadiusKm': searchRadiusKm,
      'onboardingCompleted': onboardingCompleted,
      'interests': interests.toList(),
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? sellerType,
    String? avatarUrl,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    bool? active,
    bool? identityVerified,
    String? identityProvider,
    int? trustScore,
    String? address,
    String? pincode,
    int? searchRadiusKm,
    bool? onboardingCompleted,
    Set<String>? interests,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      sellerType: sellerType ?? this.sellerType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      active: active ?? this.active,
      identityVerified: identityVerified ?? this.identityVerified,
      identityProvider: identityProvider ?? this.identityProvider,
      trustScore: trustScore ?? this.trustScore,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
