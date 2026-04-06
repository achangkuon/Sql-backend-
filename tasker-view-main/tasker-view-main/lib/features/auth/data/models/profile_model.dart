class ProfileModel {
  final String id;
  final String role;
  final String fullName;
  final String email;
  final String? phone;
  final bool phoneVerified;
  final String? avatarUrl;
  final String? city;
  final String? addressLine;
  final bool isOnline;

  ProfileModel({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone,
    required this.phoneVerified,
    this.avatarUrl,
    this.city,
    this.addressLine,
    required this.isOnline,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'client',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      addressLine: json['address_line'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'phone_verified': phoneVerified,
      'avatar_url': avatarUrl,
      'city': city,
      'address_line': addressLine,
      'is_online': isOnline,
    };
  }
}



