import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';
import '../entities/user.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Result<User>> call(String email, String password) {
    return repository.signIn(email, password);
  }
}
