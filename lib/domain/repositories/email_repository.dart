import '../entities/email.dart';
import '../../core/utils/result.dart';

abstract class EmailRepository {
  Future<Result<List<Email>>> getEmails({int? limit, String? pageToken});
  Future<Result<Email>> getEmailById(String emailId);
}

