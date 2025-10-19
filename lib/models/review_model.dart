import 'package:json_annotation/json_annotation.dart';

part 'review_model.g.dart';

@JsonSerializable()
class ReviewModel {
  final String id;
  final String customerId;
  final String salonId;
  final String? appointmentId;
  final int rating; // 1-5 stars
  final String comment;
  final List<String> images; // URLs to review images
  final DateTime createdAt;
  final DateTime updatedAt;

  // Customer details (populated from join)
  final String? customerName;
  final String? customerAvatar;

  const ReviewModel({
    required this.id,
    required this.customerId,
    required this.salonId,
    this.appointmentId,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.customerAvatar,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => _$ReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewModelToJson(this);

  ReviewModel copyWith({
    String? id,
    String? customerId,
    String? salonId,
    String? appointmentId,
    int? rating,
    String? comment,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? customerAvatar,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salonId: salonId ?? this.salonId,
      appointmentId: appointmentId ?? this.appointmentId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
    );
  }

  @override
  String toString() {
    return 'ReviewModel(id: $id, customerId: $customerId, salonId: $salonId, rating: $rating, comment: $comment, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel &&
        other.id == id &&
        other.customerId == customerId &&
        other.salonId == salonId &&
        other.rating == rating &&
        other.comment == comment &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        customerId.hashCode ^
        salonId.hashCode ^
        rating.hashCode ^
        comment.hashCode ^
        createdAt.hashCode;
  }
}

enum ReviewType {
  appointment, // Review for a specific appointment
  general, // General salon review
}

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // rating -> count

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      ratingDistribution: Map<int, int>.from(json['rating_distribution'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'rating_distribution': ratingDistribution,
    };
  }
}
