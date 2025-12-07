import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/email_detail.dart';
import '../../domain/usecases/get_email_detail_usecase.dart';
import '../../core/di/injection_container.dart';

class EmailDetailState {
  final EmailDetail? email;
  final bool isLoading;
  final String? error;

  const EmailDetailState({
    this.email,
    this.isLoading = false,
    this.error,
  });

  EmailDetailState copyWith({
    EmailDetail? email,
    bool? isLoading,
    String? error,
  }) {
    return EmailDetailState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EmailDetailNotifier extends StateNotifier<EmailDetailState> {
  final GetEmailDetailUseCase _getEmailDetailUseCase;

  EmailDetailNotifier(this._getEmailDetailUseCase) : super(const EmailDetailState());

  Future<void> loadEmailDetail(String emailId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getEmailDetailUseCase(emailId);

    result.when(
      success: (email) {
        state = state.copyWith(
          email: email,
          isLoading: false,
        );
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  void clear() {
    state = const EmailDetailState();
  }
}

final emailDetailProvider = StateNotifierProvider.family<EmailDetailNotifier, EmailDetailState, String>((ref, emailId) {
  final notifier = EmailDetailNotifier(ref.watch(getEmailDetailUseCaseProvider));
  notifier.loadEmailDetail(emailId);
  return notifier;
});

