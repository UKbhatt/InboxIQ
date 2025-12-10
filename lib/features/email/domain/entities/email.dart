class Email {
  final String id;
  final String subject;
  final String from;
  final String snippet;
  final DateTime date;
  final bool isRead;

  const Email({
    required this.id,
    required this.subject,
    required this.from,
    required this.snippet,
    required this.date,
    required this.isRead,
  });

  Email copyWith({
    String? id,
    String? subject,
    String? from,
    String? snippet,
    DateTime? date,
    bool? isRead,
  }) {
    return Email(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      from: from ?? this.from,
      snippet: snippet ?? this.snippet,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
    );
  }
}

