import '../repositories/auth_repository.dart';
import '../../core/utils/result.dart';

class GetOAuthUrlUseCase {
  final AuthRepository repository;

  GetOAuthUrlUseCase(this.repository);

  Future<Result<String>> call() {
    return repository.getOAuthUrl();
  }
}

