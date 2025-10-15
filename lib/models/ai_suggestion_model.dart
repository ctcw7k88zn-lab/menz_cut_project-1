enum SuggestionType {
  hairstyle,
  color,
  treatment,
  accessory,
}

class AISuggestionModel {
  final String id;
  final String userId;
  final String? originalImageUrl;
  final SuggestionType type;
  final String name;
  final String description;
  final String imageUrl;
  final double confidenceScore;
  final List<String> tags;
  final Map<String, dynamic>? styleDetails;
  final DateTime createdAt;
  final bool isBooked;

  const AISuggestionModel({
    required this.id,
    required this.userId,
    this.originalImageUrl,
    required this.type,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.confidenceScore,
    required this.tags,
    this.styleDetails,
    required this.createdAt,
    this.isBooked = false,
  });

  double get confidence => confidenceScore;
  String get styleImageUrl => imageUrl;
  String get styleName => name;
  List<String> get features => tags;

  factory AISuggestionModel.fromJson(Map<String, dynamic> json) {
    return AISuggestionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      originalImageUrl: json['originalImageUrl'] as String?,
      type: SuggestionType.values.firstWhere((e) => e.name == json['type']),
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List),
      styleDetails: json['styleDetails'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isBooked: json['isBooked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'originalImageUrl': originalImageUrl,
      'type': type.name,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'confidenceScore': confidenceScore,
      'tags': tags,
      'styleDetails': styleDetails,
      'createdAt': createdAt.toIso8601String(),
      'isBooked': isBooked,
    };
  }

  AISuggestionModel copyWith({
    String? id,
    String? userId,
    String? originalImageUrl,
    SuggestionType? type,
    String? name,
    String? description,
    String? imageUrl,
    double? confidenceScore,
    List<String>? tags,
    Map<String, dynamic>? styleDetails,
    DateTime? createdAt,
    bool? isBooked,
  }) {
    return AISuggestionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalImageUrl: originalImageUrl ?? this.originalImageUrl,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      tags: tags ?? this.tags,
      styleDetails: styleDetails ?? this.styleDetails,
      createdAt: createdAt ?? this.createdAt,
      isBooked: isBooked ?? this.isBooked,
    );
  }

  String get formattedConfidence => '${(confidenceScore * 100).toInt()}% match';
  bool get isHighConfidence => confidenceScore >= 0.8;
  bool get isMediumConfidence => confidenceScore >= 0.6 && confidenceScore < 0.8;
  bool get isLowConfidence => confidenceScore < 0.6;
}
