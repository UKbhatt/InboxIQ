import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/services/gemini_summary_service.dart';
import '../../data/datasources/remote_email_datasource.dart';
import '../../../../core/di/injection_container.dart';

class EmailSummaryService {
  final RemoteEmailDataSource _dataSource;

  EmailSummaryService(this._dataSource);

  Future<String?> getSummary(String emailId) async {
    if (!GeminiSummaryService.isAvailable) {
      return null;
    }

    final result = await _dataSource.getEmailDetailById(emailId);

    return await result.when(
      success: (emailDetail) async {
        String content = '';
        if (emailDetail.bodyText != null && emailDetail.bodyText!.isNotEmpty) {
          content = emailDetail.bodyText!;
        } else if (emailDetail.bodyHtml != null &&
            emailDetail.bodyHtml!.isNotEmpty) {
          content = emailDetail.bodyHtml!;
        } else if (emailDetail.snippet.isNotEmpty) {
          content = emailDetail.snippet;
        }

        if (content.isEmpty) {
          return null;
        }

        final summary = await GeminiSummaryService.summarizeEmail(
          subject: emailDetail.subject,
          content: content,
        );

        return summary;
      },
      error: (_) async => null,
    );
  }
}

final emailSummaryServiceProvider = Provider<EmailSummaryService>((ref) {
  final dataSource = ref.watch(remoteEmailDataSourceProvider);
  return EmailSummaryService(dataSource);
});
