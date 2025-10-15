// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 5;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      email: fields[1] as String,
      fullName: fields[2] as String,
      phone: fields[3] as String?,
      profileImageUrl: fields[4] as String?,
      role: fields[5] as UserRole,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      isEmailVerified: fields[8] as bool,
      isPhoneVerified: fields[9] as bool,
      preferences: (fields[10] as Map?)?.cast<String, dynamic>(),
      salonId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.fullName)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.profileImageUrl)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.isEmailVerified)
      ..writeByte(9)
      ..write(obj.isPhoneVerified)
      ..writeByte(10)
      ..write(obj.preferences)
      ..writeByte(11)
      ..write(obj.salonId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 8;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.customer;
      case 1:
        return UserRole.salonOwner;
      case 2:
        return UserRole.owner;
      default:
        return UserRole.customer;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.customer:
        writer.writeByte(0);
        break;
      case UserRole.salonOwner:
        writer.writeByte(1);
        break;
      case UserRole.owner:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
