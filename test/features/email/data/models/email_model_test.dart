import 'package:flutter_test/flutter_test.dart';
import 'package:inboxiq/features/email/data/models/email_model.dart';

void main() {
  group('EmailModel.fromGmailApi', () {
    test('parses the backend list shape', () {
      final email = EmailModel.fromGmailApi({
        'id': 'abc',
        'gmail_message_id': 'abc',
        'subject': 'Hello',
        'from_email': 'a@b.com',
        'from_name': 'Alice',
        'snippet': 'hi',
        'date': '2026-01-02T03:04:05.000Z',
        'is_read': true,
      });

      expect(email.id, 'abc');
      expect(email.subject, 'Hello');
      expect(email.from, 'a@b.com');
      expect(email.fromName, 'Alice');
      expect(email.isRead, isTrue);
      expect(email.date.toUtc(), DateTime.utc(2026, 1, 2, 3, 4, 5));
    });

    test('parses a raw Gmail message shape', () {
      final email = EmailModel.fromGmailApi({
        'id': 'raw1',
        'snippet': 'snip',
        'internalDate': '1700000000000',
        'labelIds': ['INBOX', 'UNREAD'],
        'payload': {
          'headers': [
            {'name': 'Subject', 'value': 'Raw subject'},
            {'name': 'From', 'value': 'Bob <bob@x.com>'},
          ],
        },
      });

      expect(email.id, 'raw1');
      expect(email.subject, 'Raw subject');
      expect(email.from, 'Bob <bob@x.com>');
      expect(email.isRead, isFalse);
    });
  });
}
