// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppointmentModelAdapter extends TypeAdapter<AppointmentModel> {
  @override
  final int typeId = 1;

  @override
  AppointmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppointmentModel(
      id: fields[0] as String,
      customerId: fields[1] as String,
      salonId: fields[2] as String,
      serviceId: fields[3] as String,
      staffId: fields[4] as String?,
      stylistId: fields[5] as String?,
      startAt: fields[6] as DateTime,
      endAt: fields[7] as DateTime,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      status: fields[10] as AppointmentStatus,
      paymentStatus: fields[11] as PaymentStatus,
      totalAmount: fields[12] as double,
      notes: fields[13] as String?,
      cancellationReason: fields[14] as String?,
      duration: fields[15] as int?,
      price: fields[16] as double?,
      serviceDetails: (fields[17] as Map?)?.cast<String, dynamic>(),
      customerDetails: (fields[18] as Map?)?.cast<String, dynamic>(),
      salonDetails: (fields[19] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.salonId)
      ..writeByte(3)
      ..write(obj.serviceId)
      ..writeByte(4)
      ..write(obj.staffId)
      ..writeByte(5)
      ..write(obj.stylistId)
      ..writeByte(6)
      ..write(obj.startAt)
      ..writeByte(7)
      ..write(obj.endAt)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.paymentStatus)
      ..writeByte(12)
      ..write(obj.totalAmount)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.cancellationReason)
      ..writeByte(15)
      ..write(obj.duration)
      ..writeByte(16)
      ..write(obj.price)
      ..writeByte(17)
      ..write(obj.serviceDetails)
      ..writeByte(18)
      ..write(obj.customerDetails)
      ..writeByte(19)
      ..write(obj.salonDetails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppointmentStatusAdapter extends TypeAdapter<AppointmentStatus> {
  @override
  final int typeId = 6;

  @override
  AppointmentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppointmentStatus.pending;
      case 1:
        return AppointmentStatus.confirmed;
      case 2:
        return AppointmentStatus.inProgress;
      case 3:
        return AppointmentStatus.completed;
      case 4:
        return AppointmentStatus.cancelled;
      case 5:
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, AppointmentStatus obj) {
    switch (obj) {
      case AppointmentStatus.pending:
        writer.writeByte(0);
        break;
      case AppointmentStatus.confirmed:
        writer.writeByte(1);
        break;
      case AppointmentStatus.inProgress:
        writer.writeByte(2);
        break;
      case AppointmentStatus.completed:
        writer.writeByte(3);
        break;
      case AppointmentStatus.cancelled:
        writer.writeByte(4);
        break;
      case AppointmentStatus.noShow:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentStatusAdapter extends TypeAdapter<PaymentStatus> {
  @override
  final int typeId = 7;

  @override
  PaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentStatus.pending;
      case 1:
        return PaymentStatus.paid;
      case 2:
        return PaymentStatus.refunded;
      case 3:
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentStatus obj) {
    switch (obj) {
      case PaymentStatus.pending:
        writer.writeByte(0);
        break;
      case PaymentStatus.paid:
        writer.writeByte(1);
        break;
      case PaymentStatus.refunded:
        writer.writeByte(2);
        break;
      case PaymentStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
