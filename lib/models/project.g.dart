// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as String?,
      name: fields[1] as String,
      date: fields[2] as DateTime?,
      items: (fields[3] as List?)?.cast<ProjectItem>(),
      images: (fields[4] as List?)?.cast<String>(),
      lastEdited: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.images)
      ..writeByte(5)
      ..write(obj.lastEdited);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProjectAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

class ProjectItemAdapter extends TypeAdapter<ProjectItem> {
  @override
  final int typeId = 1;

  @override
  ProjectItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectItem(
      quantity: fields[0] as double,
      unit: fields[1] as String,
      description: fields[2] as String,
      pricePerUnit: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.quantity)
      ..writeByte(1)
      ..write(obj.unit)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.pricePerUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProjectItemAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}
