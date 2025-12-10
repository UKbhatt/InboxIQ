import '../../domain/repositories/email_repository.dart';
import '../../domain/entities/email.dart';
import '../../domain/entities/email_detail.dart';
import '../../../../core/utils/result.dart';
import '../datasources/remote_email_datasource.dart';

class EmailRepositoryImpl implements EmailRepository {
  final RemoteEmailDataSource _dataSource;

  EmailRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Email>>> getEmails({
    int? limit,
    String? pageToken,
    int? offset,
    String? type,
  }) {
    return _dataSource.getEmails(
      limit: limit,
      pageToken: pageToken,
      offset: offset,
      type: type,
    );
  }

  @override
  Future<Result<Email>> getEmailById(String emailId) {
    return _dataSource.getEmailById(emailId);
  }

  @override
  Future<Result<EmailDetail>> getEmailDetailById(String emailId) {
    return _dataSource.getEmailDetailById(emailId);
  }

  @override
  Future<Result<Map<String, dynamic>>> getSyncStatus() {
    return _dataSource.getSyncStatus();
  }

  @override
  Future<Result<void>> startSync() {
    return _dataSource.startSync();
  }

  @override
  Future<Result<void>> markAsRead(String emailId) {
    return _dataSource.markAsRead(emailId);
  }
}
