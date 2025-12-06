import '../repositories/email_repository.dart';
import '../../core/utils/result.dart';
import '../entities/email.dart';

class GetEmailsUseCase {
  final EmailRepository repository;

  GetEmailsUseCase(this.repository);

  Future<Result<List<Email>>> call({int? limit, String? pageToken}) {
    return repository.getEmails(limit: limit, pageToken: pageToken);
  }
}

