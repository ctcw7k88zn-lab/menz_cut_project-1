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
    
    // Debug logging
    print('🕐 Checking if $name is open:');
    print('   Current day: $dayName');
    print('   Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    print('   Opening hours for $dayName: $hours');
    print('   All opening hours: $openingHours');
    
    if (hours == null || hours.isEmpty || hours.toLowerCase() == 'closed') {
      print('   ❌ No hours found or closed for $dayName');
      return false;
    }
    
    // Try different formats: "9:00-18:00", "9:00 - 18:00", "11:00 AM - 8:00 PM"
    String? openTimeStr;
    String? closeTimeStr;
    
    // Try splitting by " - " (with spaces)
    if (hours.contains(' - ')) {
      final parts = hours.split(' - ');
      if (parts.length == 2) {
        openTimeStr = parts[0].trim();
        closeTimeStr = parts[1].trim();
      }
    }
    // Try splitting by "-" (without spaces)
    else if (hours.contains('-')) {
      final parts = hours.split('-');
      if (parts.length == 2) {
        openTimeStr = parts[0].trim();
        closeTimeStr = parts[1].trim();
      }
    }
    
    print('   Parsed open time: $openTimeStr, close time: $closeTimeStr');
    
    if (openTimeStr == null || closeTimeStr == null) {
      print('   ❌ Could not parse time format');
      return false;
    }
    
    try {
      final openTime = _parseTime(openTimeStr);
      final closeTime = _parseTime(closeTimeStr);
      final currentTime = now.hour * 60 + now.minute;
      
      print('   Open time (minutes): $openTime, Close time (minutes): $closeTime');
      print('   Current time (minutes): $currentTime');
      
      // Handle case where closing time is next day (e.g., 11 PM - 2 AM)
      bool isOpen;
      if (closeTime < openTime) {
        // Salon closes after midnight (e.g., 11 PM - 2 AM)
        isOpen = currentTime >= openTime || currentTime <= closeTime;
        print('   ⏰ Salon closes after midnight (${openTime}min - ${closeTime}min next day)');
      } else {
        // Normal case: same day closing
        isOpen = currentTime >= openTime && currentTime <= closeTime;
      }
      
      print('   Result: ${isOpen ? "✅ OPEN" : "❌ CLOSED"}');
      
      return isOpen;
    } catch (e) {
      // If parsing fails, assume closed
      print('   ❌ Error parsing time: $e');
      return false;
    }
  }
  
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  int _parseTime(String time) {
    // Remove any extra whitespace
    time = time.trim();
    
    // Handle AM/PM format: "11:00 AM" or "8:00 PM"
    bool isPM = false;
    if (time.toUpperCase().contains('PM')) {
      isPM = true;
      time = time.replaceAll(RegExp(r'[Pp][Mm]'), '').trim();
    } else if (time.toUpperCase().contains('AM')) {
      time = time.replaceAll(RegExp(r'[Aa][Mm]'), '').trim();
    }
    
    // Parse time in format "HH:MM" or "H:MM"
    final parts = time.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $time');
    }
    
    int hour = int.parse(parts[0].trim());
    int minute = int.parse(parts[1].trim());
    
    // Validate hour and minute ranges
    if (hour < 0 || hour > 23) {
      throw FormatException('Invalid hour: $hour');
    }
    if (minute < 0 || minute > 59) {
      throw FormatException('Invalid minute: $minute');
    }
    
    // Convert to 24-hour format if PM
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    
    // Ensure hour is in valid range after conversion
    if (hour < 0 || hour > 23) {
      throw FormatException('Invalid hour after conversion: $hour');
    }
    
    final totalMinutes = hour * 60 + minute;
    print('      Parsed "$time" (isPM: $isPM) -> $hour:$minute (${totalMinutes} minutes)');
    
    return totalMinutes;
  }
}
