import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/remote_email_datasource.dart';

class EmailSummaryService {
  final RemoteEmailDataSource _dataSource;

  EmailSummaryService(this._dataSource);

  Future<Result<String>> getSummary(String emailId) {
    return _dataSource.getEmailSummary(emailId);
  }
}

final emailSummaryServiceProvider = Provider<EmailSummaryService>((ref) {
  return EmailSummaryService(ref.watch(remoteEmailDataSourceProvider));
});
