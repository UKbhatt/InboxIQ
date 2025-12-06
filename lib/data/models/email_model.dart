import '../../domain/entities/email.dart';

class EmailModel extends Email {
  const EmailModel({
    required super.id,
    required super.subject,
    required super.from,
    required super.snippet,
    required super.date,
    required super.isRead,
  });

  factory EmailModel.fromGmailApi(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>?;
    final headers = payload?['headers'] as List<dynamic>? ?? [];
    
    String subject = '';
    String from = '';
    
    for (final header in headers) {
      final name = (header as Map<String, dynamic>)['name'] as String?;
      final value = header['value'] as String?;
      if (name == 'Subject') subject = value ?? '';
      if (name == 'From') from = value ?? '';
    }

    return EmailModel(
      id: json['id'] as String,
      subject: subject,
      from: from,
      snippet: json['snippet'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        int.parse(json['internalDate'] as String),
      ),
      isRead: !((json['labelIds'] as List<dynamic>?)?.contains('UNREAD') ?? true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'from': from,
      'snippet': snippet,
      'date': date.toIso8601String(),
      'isRead': isRead,
    };
  }
}

