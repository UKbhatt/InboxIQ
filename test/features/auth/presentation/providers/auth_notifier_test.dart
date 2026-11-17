import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inboxiq/core/utils/result.dart';
import 'package:inboxiq/features/auth/domain/entities/user.dart';
import 'package:inboxiq/features/auth/domain/repositories/auth_repository.dart';
import 'package:inboxiq/features/auth/domain/usecases/connect_gmail_usecase.dart';
import 'package:inboxiq/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:inboxiq/features/auth/domain/usecases/get_oauth_url_usecase.dart';
import 'package:inboxiq/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:inboxiq/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:inboxiq/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:inboxiq/features/auth/presentation/providers/auth_provider.dart';

final _alice = User(id: 'u1', email: 'alice@example.com', createdAt: DateTime(2026));

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.current);

  User? current;
  final changes = StreamController<User?>.broadcast();

  @override
  Result<User?> getCurrentUser() => Success(current);

  @override
  Stream<User?> watchUser() => changes.stream;

  @override
  Future<Result<void>> signOut() async {
    current = null;
    return const Success(null);
  }

  @override
  Future<Result<User>> signIn(String email, String password) => throw UnimplementedError();
  @override
  Future<Result<User>> signUp(String email, String password) => throw UnimplementedError();
  @override
  Future<Result<String>> getOAuthUrl() => throw UnimplementedError();
  @override
  Future<Result<void>> connectGmail(String code) => throw UnimplementedError();
  @override
  Future<Result<bool>> isGmailConnected() => throw UnimplementedError();
}

AuthNotifier _notifier(_FakeAuthRepository repo) => AuthNotifier(
      SignUpUseCase(repo),
      SignInUseCase(repo),
      SignOutUseCase(repo),
      GetCurrentUserUseCase(repo),
      GetOAuthUrlUseCase(repo),
      ConnectGmailUseCase(repo),
      repo.watchUser(),
    );

void main() {
  test('starts with the persisted user before any frame is built', () {
    final notifier = _notifier(_FakeAuthRepository(_alice));

    expect(notifier.state.user?.id, 'u1');
    expect(notifier.state.isLoading, isFalse);
  });

  test('starts signed out when no session is persisted', () {
    final notifier = _notifier(_FakeAuthRepository(null));

    expect(notifier.state.user, isNull);
  });

  test('keeps the user across session refreshes and clears it only on sign-out', () async {
    final repo = _FakeAuthRepository(_alice);
    final notifier = _notifier(repo);

    repo.changes.add(_alice);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.user?.id, 'u1');

    repo.changes.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.user, isNull);
  });

  test('stops listening once disposed', () async {
    final repo = _FakeAuthRepository(_alice);
    final notifier = _notifier(repo);

    notifier.dispose();

    expect(repo.changes.hasListener, isFalse);
  });
}
