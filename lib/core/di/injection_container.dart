import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';
import '../../features/auth/data/datasources/supabase_auth_datasource.dart';
import '../../features/auth/data/datasources/remote_auth_datasource.dart';
import '../../features/email/data/datasources/remote_email_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/email/data/repositories/email_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/email/domain/repositories/email_repository.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/get_oauth_url_usecase.dart';
import '../../features/auth/domain/usecases/connect_gmail_usecase.dart';
import '../../features/email/domain/usecases/get_emails_usecase.dart';
import '../../features/email/domain/usecases/get_email_detail_usecase.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  return dio;
});

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((ref) {
  return SupabaseAuthDataSource(ref.watch(supabaseClientProvider));
});

final remoteAuthDataSourceProvider = Provider<RemoteAuthDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return RemoteAuthDataSource(
    dio,
    () => supabase.auth.currentSession?.accessToken,
  );
});

final remoteEmailDataSourceProvider = Provider<RemoteEmailDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return RemoteEmailDataSource(
    dio,
    () => supabase.auth.currentSession?.accessToken,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(supabaseAuthDataSourceProvider),
    ref.watch(remoteAuthDataSourceProvider),
  );
});

final emailRepositoryProvider = Provider<EmailRepository>((ref) {
  return EmailRepositoryImpl(ref.watch(remoteEmailDataSourceProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final getOAuthUrlUseCaseProvider = Provider<GetOAuthUrlUseCase>((ref) {
  return GetOAuthUrlUseCase(ref.watch(authRepositoryProvider));
});

final connectGmailUseCaseProvider = Provider<ConnectGmailUseCase>((ref) {
  return ConnectGmailUseCase(ref.watch(authRepositoryProvider));
});

final getEmailsUseCaseProvider = Provider<GetEmailsUseCase>((ref) {
  return GetEmailsUseCase(ref.watch(emailRepositoryProvider));
});

final getEmailDetailUseCaseProvider = Provider<GetEmailDetailUseCase>((ref) {
  return GetEmailDetailUseCase(ref.watch(emailRepositoryProvider));
});
