import '../repositories/auth_repository.dart';
import '../../core/utils/result.dart';

class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  Future<Result<void>> call() {
    return repository.signOut();
  }
}

