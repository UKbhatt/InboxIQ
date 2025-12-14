import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class EmailSummary extends HiveObject {
  @HiveField(0)
  final String emailId;

  @HiveField(1)
  final String summary;

  @HiveField(2)
  final DateTime createdAt;

  EmailSummary({
    required this.emailId,
    required this.summary,
    required this.createdAt,
  });
}

