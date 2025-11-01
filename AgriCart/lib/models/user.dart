class User {
  final String userId;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role; // 'buyer', 'seller', 'trader'
  final String? address;
  final bool isVerified;
  final Map<String, dynamic>? verificationStatus;
  final String? profileImageId;

  User({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.address,
    required this.isVerified,
    this.verificationStatus,
    this.profileImageId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? 'buyer',
      address: json['address'],
      isVerified: json['is_verified'] ?? false,
      verificationStatus: json['verification_status'],
      profileImageId: json['profile_image_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'address': address,
      'is_verified': isVerified,
      'verification_status': verificationStatus,
      'profile_image_id': profileImageId,
    };
  }
}

