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
}

