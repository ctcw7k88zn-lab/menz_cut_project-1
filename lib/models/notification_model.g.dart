// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationModelAdapter extends TypeAdapter<NotificationModel> {
  @override
  final int typeId = 5;

  @override
  NotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as NotificationType,
      title: fields[3] as String,
      message: fields[4] as String,
      data: (fields[5] as Map).cast<String, dynamic>(),
      isRead: fields[6] as bool,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.data)
      ..writeByte(6)
      ..write(obj.isRead)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 4;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.newAppointment;
      case 1:
        return NotificationType.appointmentConfirmed;
      case 2:
        return NotificationType.appointmentCancelled;
      case 3:
        return NotificationType.appointmentCompleted;
      case 4:
        return NotificationType.appointmentReminder;
      case 5:
        return NotificationType.newMessage;
      case 6:
        return NotificationType.serviceUpdate;
      case 7:
        return NotificationType.salonUpdate;
      case 8:
        return NotificationType.reviewRequest;
      case 9:
        return NotificationType.general;
      default:
        return NotificationType.newAppointment;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.newAppointment:
        writer.writeByte(0);
        break;
      case NotificationType.appointmentConfirmed:
        writer.writeByte(1);
        break;
      case NotificationType.appointmentCancelled:
        writer.writeByte(2);
        break;
      case NotificationType.appointmentCompleted:
        writer.writeByte(3);
        break;
      case NotificationType.appointmentReminder:
        writer.writeByte(4);
        break;
      case NotificationType.newMessage:
        writer.writeByte(5);
        break;
      case NotificationType.serviceUpdate:
        writer.writeByte(6);
        break;
      case NotificationType.salonUpdate:
        writer.writeByte(7);
        break;
      case NotificationType.reviewRequest:
        writer.writeByte(8);
        break;
      case NotificationType.general:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
