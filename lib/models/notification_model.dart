import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 4)
enum NotificationType {
  @HiveField(0)
  newAppointment,
  @HiveField(1)
  appointmentConfirmed,
  @HiveField(2)
  appointmentCancelled,
  @HiveField(3)
  appointmentCompleted,
  @HiveField(4)
  appointmentReminder,
  @HiveField(5)
  newMessage,
  @HiveField(6)
  serviceUpdate,
  @HiveField(7)
  salonUpdate,
  @HiveField(8)
  reviewRequest,
  @HiveField(9)
  general,
}

@HiveType(typeId: 5)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final NotificationType type;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String message;

  @HiveField(5)
  final Map<String, dynamic> data;

  @HiveField(6)
  final bool isRead;

  @HiveField(7)
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        isRead.hashCode;
  }
}