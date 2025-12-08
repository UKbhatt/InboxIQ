import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

class ConnectGmailUseCase {
  final AuthRepository repository;

  ConnectGmailUseCase(this.repository);

  Future<Result<void>> call(String code) {
    return repository.connectGmail(code);
  }
}

