// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      salonId: json['salon_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customerName: json['customer_name'] as String?,
      customerAvatar: json['customer_avatar'] as String?,
    );

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) => <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'salon_id': instance.salonId,
      'appointment_id': instance.appointmentId,
      'rating': instance.rating,
      'comment': instance.comment,
      'images': instance.images,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'customer_name': instance.customerName,
      'customer_avatar': instance.customerAvatar,
    };
