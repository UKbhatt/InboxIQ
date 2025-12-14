import 'package:hive/hive.dart';
import '../models/email_summary.dart';

class EmailSummaryAdapter extends TypeAdapter<EmailSummary> {
  @override
  final int typeId = 2;

  @override
  EmailSummary read(BinaryReader reader) {
    return EmailSummary(
      emailId: reader.readString(),
      summary: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, EmailSummary obj) {
    writer.writeString(obj.emailId);
    writer.writeString(obj.summary);
    writer.writeString(obj.createdAt.toIso8601String());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
