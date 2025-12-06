import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../core/utils/result.dart';
import '../datasources/supabase_auth_datasource.dart';
import '../datasources/remote_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _supabaseDataSource;
  final RemoteAuthDataSource _remoteDataSource;

  AuthRepositoryImpl(this._supabaseDataSource, this._remoteDataSource);

  @override
  Future<Result<User>> signUp(String email, String password) {
    return _supabaseDataSource.signUp(email, password);
  }

  @override
  Future<Result<User>> signIn(String email, String password) {
    return _supabaseDataSource.signIn(email, password);
  }

  @override
  Future<Result<void>> signOut() {
    return _supabaseDataSource.signOut();
  }

  @override
  Future<Result<User?>> getCurrentUser() {
    return _supabaseDataSource.getCurrentUser();
  }

  @override
  Future<Result<String>> getOAuthUrl() {
    return _remoteDataSource.getOAuthUrl();
  }

  @override
  Future<Result<void>> connectGmail(String code) {
    return _remoteDataSource.connectGmail(code);
  }

  @override
  Future<Result<bool>> isGmailConnected() {
    return _remoteDataSource.isGmailConnected();
  }
}

