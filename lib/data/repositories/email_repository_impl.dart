import '../../domain/repositories/email_repository.dart';
import '../../domain/entities/email.dart';
import '../../core/utils/result.dart';
import '../datasources/remote_email_datasource.dart';

class EmailRepositoryImpl implements EmailRepository {
  final RemoteEmailDataSource _dataSource;

  EmailRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Email>>> getEmails({int? limit, String? pageToken}) {
    return _dataSource.getEmails(limit: limit, pageToken: pageToken);
  }

  @override
  Future<Result<Email>> getEmailById(String emailId) {
    return _dataSource.getEmailById(emailId);
  }
}

