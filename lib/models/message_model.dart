import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 2)
enum MessageStatus {
  @HiveField(0)
  sending,
  @HiveField(1)
  sent,
  @HiveField(2)
  delivered,
  @HiveField(3)
  read,
  @HiveField(4)
  failed,
}

@HiveType(typeId: 3)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String threadId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String receiverId;

  @HiveField(4)
  final String text;

  @HiveField(5)
  final List<String> attachments;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final MessageStatus status;

  MessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.attachments,
    required this.createdAt,
    required this.status,
  });

  MessageModel copyWith({
    String? id,
    String? threadId,
    String? senderId,
    String? receiverId,
    String? text,
    List<String>? attachments,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String,
      attachments: (json['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, threadId: $threadId, senderId: $senderId, receiverId: $receiverId, text: $text, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel &&
        other.id == id &&
        other.threadId == threadId &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.text == text &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        threadId.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        text.hashCode ^
        status.hashCode;
  }
}