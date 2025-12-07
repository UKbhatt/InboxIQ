import '../entities/email.dart';
import '../../core/utils/result.dart';

abstract class EmailRepository {
  Future<Result<List<Email>>> getEmails({int? limit, String? pageToken, int? offset});
  Future<Result<Email>> getEmailById(String emailId);
  Future<Result<Map<String, dynamic>>> getSyncStatus();
  Future<Result<void>> startSync();
}

