import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class CachedEmail extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subject;

  @HiveField(2)
  final String from;

  @HiveField(3)
  String? fromName;

  @HiveField(4)
  final String snippet;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  bool isRead;

  @HiveField(7)
  bool isStarred;

  @HiveField(8)
  final List<String> labels;

  @HiveField(9)
  String? bodyText;

  @HiveField(10)
  String? bodyHtml;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final String? type; 

  CachedEmail({
    required this.id,
    required this.subject,
    required this.from,
    this.fromName,
    required this.snippet,
    required this.date,
    required this.isRead,
    required this.isStarred,
    required this.labels,
    this.bodyText,
    this.bodyHtml,
    required this.updatedAt,
    this.type,
  });

  CachedEmail copyWith({
    String? id,
    String? subject,
    String? from,
    String? fromName,
    String? snippet,
    DateTime? date,
    bool? isRead,
    bool? isStarred,
    List<String>? labels,
    String? bodyText,
    String? bodyHtml,
    DateTime? updatedAt,
    String? type,
  }) {
    return CachedEmail(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      from: from ?? this.from,
      fromName: fromName ?? this.fromName,
      snippet: snippet ?? this.snippet,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      labels: labels ?? this.labels,
      bodyText: bodyText ?? this.bodyText,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
    );
  }
}
