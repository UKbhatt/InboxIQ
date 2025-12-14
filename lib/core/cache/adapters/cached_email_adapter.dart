import 'package:hive/hive.dart';
import '../models/cached_email.dart';

class CachedEmailAdapter extends TypeAdapter<CachedEmail> {
  @override
  final int typeId = 0;

  @override
  CachedEmail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedEmail(
      id: fields[0] as String,
      subject: fields[1] as String,
      from: fields[2] as String,
      fromName: fields[3] as String?,
      snippet: fields[4] as String,
      date: DateTime.parse(fields[5] as String),
      isRead: fields[6] as bool,
      isStarred: fields[7] as bool,
      labels: (fields[8] as List).cast<String>(),
      bodyText: fields[9] as String?,
      bodyHtml: fields[10] as String?,
      updatedAt: DateTime.parse(fields[11] as String),
      type: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedEmail obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subject)
      ..writeByte(2)
      ..write(obj.from)
      ..writeByte(3)
      ..write(obj.fromName)
      ..writeByte(4)
      ..write(obj.snippet)
      ..writeByte(5)
      ..write(obj.date.toIso8601String())
      ..writeByte(6)
      ..write(obj.isRead)
      ..writeByte(7)
      ..write(obj.isStarred)
      ..writeByte(8)
      ..write(obj.labels)
      ..writeByte(9)
      ..write(obj.bodyText)
      ..writeByte(10)
      ..write(obj.bodyHtml)
      ..writeByte(11)
      ..write(obj.updatedAt.toIso8601String())
      ..writeByte(12)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedEmailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

