import 'package:hive_flutter/hive_flutter.dart';
import '../models/cached_email.dart';

class EmailCacheService {
  static const String _emailBoxName = 'emails';
  static Box<CachedEmail>? _emailBox;

  static Future<void> init() async {
    _emailBox = await Hive.openBox<CachedEmail>(_emailBoxName);
  }

  static Box<CachedEmail> get emailBox {
    if (_emailBox == null) {
      throw Exception('EmailCacheService not initialized. Call init() first.');
    }
    return _emailBox!;
  }

  static List<CachedEmail> getAllEmails({String? type}) {
    final emails = emailBox.values.toList();
    if (type != null) {
      return emails.where((email) => email.type == type).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    return emails..sort((a, b) => b.date.compareTo(a.date));
  }

  static CachedEmail? getEmailById(String id) {
    return emailBox.get(id);
  }

  static Future<void> cacheEmail(CachedEmail email) async {
    await emailBox.put(email.id, email);
  }

  static Future<void> cacheEmails(List<CachedEmail> emails) async {
    final Map<String, CachedEmail> emailMap = {
      for (var email in emails) email.id: email
    };
    await emailBox.putAll(emailMap);
  }

  static Future<void> updateEmail(String id, CachedEmail Function(CachedEmail) updateFn) async {
    final email = emailBox.get(id);
    if (email != null) {
      final updated = updateFn(email);
      await emailBox.put(id, updated);
    }
  }

  static Future<void> deleteEmail(String id) async {
    await emailBox.delete(id);
  }

  static Future<void> clearAll() async {
    await emailBox.clear();
  }

  static DateTime? getLastSyncTime(String type) {
    final emails = getAllEmails(type: type);
    if (emails.isEmpty) return null;
    return emails.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static int getEmailCount({String? type}) {
    if (type != null) {
      return emailBox.values.where((email) => email.type == type).length;
    }
    return emailBox.length;
  }
}

