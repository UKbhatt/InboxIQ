import 'package:hive_flutter/hive_flutter.dart';
import '../models/email_summary.dart';

class EmailSummaryCache {
  static const String _summaryBoxName = 'email_summaries';
  static Box<EmailSummary>? _summaryBox;

  static Future<void> init() async {
    _summaryBox = await Hive.openBox<EmailSummary>(_summaryBoxName);
  }

  static Box<EmailSummary> get summaryBox {
    if (_summaryBox == null) {
      throw Exception('EmailSummaryCache not initialized. Call init() first.');
    }
    return _summaryBox!;
  }

  static String? getSummary(String emailId) {
    final summary = summaryBox.get(emailId);
    return summary?.summary;
  }

  static Future<void> cacheSummary(String emailId, String summary) async {
    await summaryBox.put(
      emailId,
      EmailSummary(
        emailId: emailId,
        summary: summary,
        createdAt: DateTime.now(),
      ),
    );
  }

  static bool hasSummary(String emailId) {
    return summaryBox.containsKey(emailId);
  }

  static Future<void> deleteSummary(String emailId) async {
    await summaryBox.delete(emailId);
  }

  static Future<void> clearAll() async {
    await summaryBox.clear();
  }
}

