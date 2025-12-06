import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/get_oauth_url_usecase.dart';
import '../../domain/usecases/connect_gmail_usecase.dart';
import '../../core/di/injection_container.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SignUpUseCase _signUpUseCase;
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final GetOAuthUrlUseCase _getOAuthUrlUseCase;
  final ConnectGmailUseCase _connectGmailUseCase;

  AuthNotifier(
    this._signUpUseCase,
    this._signInUseCase,
    this._signOutUseCase,
    this._getCurrentUserUseCase,
    this._getOAuthUrlUseCase,
    this._connectGmailUseCase,
  ) : super(const AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    final result = await _getCurrentUserUseCase();
    result.when(
      success: (user) => state = state.copyWith(user: user, isLoading: false),
      error: (failure) => state = state.copyWith(isLoading: false),
    );
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _signUpUseCase(email, password);
    return result.when(
      success: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _signInUseCase(email, password);
    return result.when(
      success: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _signOutUseCase();
    state = const AuthState();
  }

  Future<String?> getOAuthUrl() async {
    final result = await _getOAuthUrlUseCase();
    return result.when(
      success: (url) => url,
      error: (failure) {
        state = state.copyWith(error: failure.message);
        return null;
      },
    );
  }

  Future<bool> connectGmail(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _connectGmailUseCase(code);
    return result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(signUpUseCaseProvider),
    ref.watch(signInUseCaseProvider),
    ref.watch(signOutUseCaseProvider),
    ref.watch(getCurrentUserUseCaseProvider),
    ref.watch(getOAuthUrlUseCaseProvider),
    ref.watch(connectGmailUseCaseProvider),
  );
});

