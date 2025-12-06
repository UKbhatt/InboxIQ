import '../repositories/auth_repository.dart';
import '../../core/utils/result.dart';
import '../entities/user.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Result<User>> call(String email, String password) {
    return repository.signUp(email, password);
  }
}

