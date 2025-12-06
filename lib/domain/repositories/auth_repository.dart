import '../entities/user.dart';
import '../../core/utils/result.dart';

abstract class AuthRepository {
  Future<Result<User>> signUp(String email, String password);
  Future<Result<User>> signIn(String email, String password);
  Future<Result<void>> signOut();
  Future<Result<User?>> getCurrentUser();
  Future<Result<String>> getOAuthUrl();
  Future<Result<void>> connectGmail(String code);
  Future<Result<bool>> isGmailConnected();
}

