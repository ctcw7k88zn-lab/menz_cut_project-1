// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salon_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SalonModelAdapter extends TypeAdapter<SalonModel> {
  @override
  final int typeId = 4;

  @override
  SalonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SalonModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      address: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      imageUrls: (fields[6] as List).cast<String>(),
      rating: fields[7] as double,
      reviewCount: fields[8] as int,
      categories: (fields[9] as List).cast<String>(),
      openingHours: (fields[10] as Map).cast<String, String>(),
      phone: fields[11] as String,
      email: fields[12] as String,
      ownerId: fields[13] as String,
      isVerified: fields[14] as bool,
      isActive: fields[15] as bool,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      amenities: (fields[18] as Map?)?.cast<String, dynamic>(),
      averagePrice: fields[19] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, SalonModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.imageUrls)
      ..writeByte(7)
      ..write(obj.rating)
      ..writeByte(8)
      ..write(obj.reviewCount)
      ..writeByte(9)
      ..write(obj.categories)
      ..writeByte(10)
      ..write(obj.openingHours)
      ..writeByte(11)
      ..write(obj.phone)
      ..writeByte(12)
      ..write(obj.email)
      ..writeByte(13)
      ..write(obj.ownerId)
      ..writeByte(14)
      ..write(obj.isVerified)
      ..writeByte(15)
      ..write(obj.isActive)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.amenities)
      ..writeByte(19)
      ..write(obj.averagePrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
