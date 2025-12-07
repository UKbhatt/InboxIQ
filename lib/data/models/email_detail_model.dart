import '../../domain/entities/email_detail.dart';

class EmailDetailModel extends EmailDetail {
  const EmailDetailModel({
    required super.id,
    required super.subject,
    required super.from,
    super.fromName,
    super.to,
    super.cc,
    super.bcc,
    required super.snippet,
    super.bodyText,
    super.bodyHtml,
    required super.date,
    required super.isRead,
    required super.isStarred,
  });

  factory EmailDetailModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    DateTime date;
    try {
      date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (e) {
      date = DateTime.now();
    }

    return EmailDetailModel(
      id: json['id'] as String? ?? json['gmail_message_id'] as String? ?? '',
      subject: json['subject'] as String? ?? '(No Subject)',
      from: json['from'] as String? ?? json['from_email'] as String? ?? '',
      fromName: json['fromName'] as String?,
      to: json['to'] as String? ?? json['to_email'] as String?,
      cc: json['cc'] as String?,
      bcc: json['bcc'] as String?,
      snippet: json['snippet'] as String? ?? '',
      bodyText: json['bodyText'] as String? ?? json['body_text'] as String?,
      bodyHtml: json['bodyHtml'] as String? ?? json['body_html'] as String?,
      date: date,
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      isStarred:
          json['isStarred'] as bool? ?? json['is_starred'] as bool? ?? false,
    );
  }
}
