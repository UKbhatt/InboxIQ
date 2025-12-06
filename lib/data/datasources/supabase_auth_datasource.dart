import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';

class SupabaseAuthDataSource {
  final SupabaseClient _supabase;

  SupabaseAuthDataSource(this._supabase);

  Future<Result<User>> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        return const Error(ServerFailure('Sign up failed'));
      }

      final user = UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        name: response.user!.userMetadata?['name'] as String?,
        createdAt: DateTime.parse(response.user!.createdAt),
      );

      return Success(user);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  Future<Result<User>> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Error(AuthFailure('Sign in failed'));
      }

      final user = UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        name: response.user!.userMetadata?['name'] as String?,
        createdAt: DateTime.parse(response.user!.createdAt),
      );

      return Success(user);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  Future<Result<User?>> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Success(null);
      }

      final userModel = UserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String?,
        createdAt: DateTime.parse(user.createdAt),
      );

      return Success(userModel);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  String? getAccessToken() {
    return _supabase.auth.currentSession?.accessToken;
  }
}

