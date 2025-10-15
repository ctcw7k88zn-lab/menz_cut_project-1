// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceModelAdapter extends TypeAdapter<ServiceModel> {
  @override
  final int typeId = 0;

  @override
  ServiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      price: fields[3] as double,
      durationMinutes: fields[4] as int,
      category: fields[5] as String,
      imageUrl: fields[6] as String?,
      salonId: fields[7] as String,
      isActive: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.durationMinutes)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.salonId)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
