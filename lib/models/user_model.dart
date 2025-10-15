import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 8)
enum UserRole {
  @HiveField(0)
  customer,
  @HiveField(1)
  salonOwner,
  @HiveField(2)
  owner, // Alias for salonOwner for compatibility
}

@HiveType(typeId: 5)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String fullName;
  
  @HiveField(3)
  final String? phone;
  
  @HiveField(4)
  final String? profileImageUrl;
  
  @HiveField(5)
  final UserRole role;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final DateTime updatedAt;
  
  @HiveField(8)
  final bool isEmailVerified;
  
  @HiveField(9)
  final bool isPhoneVerified;
  
  @HiveField(10)
  final Map<String, dynamic>? preferences;
  
  @HiveField(11)
  final String? salonId; // For salon owners

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.preferences,
    this.salonId,
  });

  // Compatibility getters
  String get name => fullName;
  String? get phoneNumber => phone;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      preferences: json['preferences'] as Map<String, dynamic>?,
      salonId: json['salonId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      preferences: preferences ?? this.preferences,
    );
  }

  bool get isCustomer => role == UserRole.customer;
  bool get isSalonOwner => role == UserRole.salonOwner;
}
