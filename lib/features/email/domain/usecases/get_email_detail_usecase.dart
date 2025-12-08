import '../repositories/email_repository.dart';
import '../../../../core/utils/result.dart';
import '../entities/email_detail.dart';

class GetEmailDetailUseCase {
  final EmailRepository repository;

  GetEmailDetailUseCase(this.repository);

  Future<Result<EmailDetail>> call(String emailId) {
    return repository.getEmailDetailById(emailId);
  }
}
