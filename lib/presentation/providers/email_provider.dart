import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/email.dart';
import '../../domain/usecases/get_emails_usecase.dart';
import '../../core/di/injection_container.dart';

class EmailState {
  final List<Email> emails;
  final bool isLoading;
  final String? error;
  final String? nextPageToken;

  const EmailState({
    this.emails = const [],
    this.isLoading = false,
    this.error,
    this.nextPageToken,
  });

  EmailState copyWith({
    List<Email>? emails,
    bool? isLoading,
    String? error,
    String? nextPageToken,
  }) {
    return EmailState(
      emails: emails ?? this.emails,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }
}

class EmailNotifier extends StateNotifier<EmailState> {
  final GetEmailsUseCase _getEmailsUseCase;

  EmailNotifier(this._getEmailsUseCase) : super(const EmailState());

  Future<void> loadEmails({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getEmailsUseCase(
      limit: 20,
      pageToken: refresh ? null : state.nextPageToken,
    );

    result.when(
      success: (emails) {
        state = state.copyWith(
          emails: refresh ? emails : [...state.emails, ...emails],
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
}

final emailProvider = StateNotifierProvider<EmailNotifier, EmailState>((ref) {
  return EmailNotifier(ref.watch(getEmailsUseCaseProvider));
});

