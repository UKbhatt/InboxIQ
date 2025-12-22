import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  
  static const String gmailScope = 'https://www.googleapis.com/auth/gmail.readonly';
  static const String oauthCallbackPath = '/api/oauth/callback';
  static const String emailsPath = '/api/emails';
  static const String connectGmailPath = '/api/oauth/connect';
  static const String emailSyncPath = '/api/emails/sync';
  static const String emailSyncStatusPath = '/api/emails/sync/status';
}
