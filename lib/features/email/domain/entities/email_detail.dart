class EmailDetail {
  final String id;
  final String subject;
  final String from;
  final String? fromName;
  final String? to;
  final String? cc;
  final String? bcc;
  final String snippet;
  final String? bodyText;
  final String? bodyHtml;
  final DateTime date;
  final bool isRead;
  final bool isStarred;

  const EmailDetail({
    required this.id,
    required this.subject,
    required this.from,
    this.fromName,
    this.to,
    this.cc,
    this.bcc,
    required this.snippet,
    this.bodyText,
    this.bodyHtml,
    required this.date,
    required this.isRead,
    required this.isStarred,
  });
}
