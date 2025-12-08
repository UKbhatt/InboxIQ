import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';
import '../entities/user.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Result<User?>> call() {
    return repository.getCurrentUser();
  }
}

