import 'package:hive/hive.dart';

part 'service_model.g.dart';

@HiveType(typeId: 0)
class ServiceModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final double price;
  
  @HiveField(4)
  final int durationMinutes; // in minutes
  
  @HiveField(5)
  final String category;
  
  @HiveField(6)
  final String? imageUrl;
  
  @HiveField(7)
  final String salonId;
  
  @HiveField(8)
  final bool isActive;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    this.imageUrl,
    required this.salonId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int? ?? json['duration'] as int? ?? 60,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String?,
      salonId: json['salonId'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'category': category,
      'imageUrl': imageUrl,
      'salonId': salonId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    String? category,
    String? imageUrl,
    String? salonId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      salonId: salonId ?? this.salonId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}