import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiSummaryService {
  static String? _apiKey;
  static GenerativeModel? _model;

  static void initialize() {
    _apiKey = dotenv.env['GEMINI_API_KEY'];
    // print('this is the api key ${_apiKey}');
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey!);
    }
  }

  static bool get isAvailable =>
      _apiKey != null && _apiKey!.isNotEmpty && _model != null;

  static Future<String?> summarizeEmail({
    required String subject,
    required String content,
  }) async {
    if (!isAvailable) {
      return null;
    }

    try {
      final cleanContent = _cleanEmailContent(content);

      final limitedContent = cleanContent.length > 2000
          ? cleanContent.substring(0, 2000)
          : cleanContent;

      final prompt =
          '''
      Summarize this email in 3-4 very short single line bullet points. Focus only on the main content and key points. Do not include sender names, email addresses, or any personal information. Be concise and clear.
      Subject: $subject
      Content:
      $limitedContent
      Summary:''';
      final response = await _model!.generateContent([Content.text(prompt)]);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      }

      return null;
    } catch (e) {
      print('Error generating email summary: $e');
      return null;
    }
  }

  static String _cleanEmailContent(String content) {
    String cleaned = content
        .replaceAll(
          RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '...')
        .trim();

    cleaned = cleaned
        .replaceAll(
          RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
          '',
        )
        .replaceAll(RegExp(r'https?://[^\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned;
  }
}
