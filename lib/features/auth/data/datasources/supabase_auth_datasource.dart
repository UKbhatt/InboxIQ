import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
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
        emailRedirectTo: null,
      );

      if (response.user == null) {
        return const Error(ServerFailure('Sign up failed'));
      }

      final user = UserModel.fromSupabase(response.user!);

      if (response.session == null) {
        return Error(
          AuthFailure(
            'Email confirmation required. Please check your email and confirm your account.',
          ),
        );
      }

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

      return Success(UserModel.fromSupabase(response.user!));
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

  Result<User?> getCurrentUser() {
    try {
      final user = _supabase.auth.currentUser;
      return Success(user == null ? null : UserModel.fromSupabase(user));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  Stream<User?> watchUser() {
    return _supabase.auth.onAuthStateChange.map((change) {
      final user = change.session?.user;
      return user == null ? null : UserModel.fromSupabase(user);
    });
  }

  String? getAccessToken() {
    return _supabase.auth.currentSession?.accessToken;
  }
}
