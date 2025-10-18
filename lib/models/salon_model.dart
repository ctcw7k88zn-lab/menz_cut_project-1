import 'package:hive/hive.dart';

part 'salon_model.g.dart';

@HiveType(typeId: 4)
class SalonModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String address;
  
  @HiveField(4)
  final double latitude;
  
  @HiveField(5)
  final double longitude;
  
  @HiveField(6)
  final List<String> imageUrls;
  
  @HiveField(7)
  final double rating;
  
  @HiveField(8)
  final int reviewCount;
  
  @HiveField(9)
  final List<String> categories;
  
  @HiveField(10)
  final Map<String, String> openingHours;
  
  @HiveField(11)
  final String phone;
  
  @HiveField(12)
  final String email;
  
  @HiveField(13)
  final String ownerId;
  
  @HiveField(14)
  final bool isVerified;
  
  @HiveField(15)
  final bool isActive;
  
  @HiveField(16)
  final DateTime createdAt;
  
  @HiveField(17)
  final DateTime updatedAt;
  
  @HiveField(18)
  final Map<String, dynamic>? amenities;
  
  @HiveField(19)
  final double? averagePrice;

  SalonModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.categories,
    required this.openingHours,
    required this.phone,
    required this.email,
    required this.ownerId,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.amenities,
    this.averagePrice,
  });

  // Compatibility getter
  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400';

  factory SalonModel.fromJson(Map<String, dynamic> json) {
    return SalonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrls: List<String>.from(json['imageUrls'] as List),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      categories: List<String>.from(json['categories'] as List),
      openingHours: Map<String, String>.from(json['openingHours'] as Map),
      phone: json['phone'] as String,
      email: json['email'] as String,
      ownerId: json['ownerId'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      amenities: json['amenities'] as Map<String, dynamic>?,
      averagePrice: (json['averagePrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'categories': categories,
      'openingHours': openingHours,
      'phone': phone,
      'email': email,
      'ownerId': ownerId,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'amenities': amenities,
      'averagePrice': averagePrice,
    };
  }

  SalonModel copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    double? rating,
    int? reviewCount,
    List<String>? categories,
    Map<String, String>? openingHours,
    String? phone,
    String? email,
    String? ownerId,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? amenities,
    double? averagePrice,
  }) {
    return SalonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      categories: categories ?? this.categories,
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ownerId: ownerId ?? this.ownerId,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      amenities: amenities ?? this.amenities,
      averagePrice: averagePrice ?? this.averagePrice,
    );
  }

  String get formattedRating => rating.toStringAsFixed(1);
  bool get isOpen => _isCurrentlyOpen();
  String get website => 'www.${name.toLowerCase().replaceAll(' ', '')}.com';
  Map<String, String> get operatingHours => openingHours;
  List<String> get images => imageUrls;
  
  bool _isCurrentlyOpen() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final hours = openingHours[dayName];
    
    if (hours == null || hours == 'Closed') return false;
    
    final timeParts = hours.split(' - ');
    if (timeParts.length != 2) return false;
    
    try {
      final openTime = _parseTime(timeParts[0]);
      final closeTime = _parseTime(timeParts[1]);
      final currentTime = now.hour * 60 + now.minute;
      
      return currentTime >= openTime && currentTime <= closeTime;
    } catch (e) {
      return false;
    }
  }
  
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
