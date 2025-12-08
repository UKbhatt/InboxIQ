import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/email.dart';
import '../../domain/usecases/get_emails_usecase.dart';
import '../../../../core/di/injection_container.dart';

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
  int _currentOffset = 0;
  String _currentType = 'all';

  EmailNotifier(this._getEmailsUseCase) : super(const EmailState());

  Future<void> loadEmails({bool refresh = false, String? type}) async {
    if (state.isLoading) return;

    final emailType = type ?? _currentType;
    if (emailType != _currentType) {
      _currentType = emailType;
      _currentOffset = 0;
    }

    state = state.copyWith(isLoading: true, error: null);

    if (refresh) {
      _currentOffset = 0;
    }

    final result = await _getEmailsUseCase(
      limit: 500,
      offset: _currentOffset,
      type: emailType == 'inbox' ? null : emailType,
    );

    result.when(
      success: (emails) {
        _currentOffset += emails.length;
        state = state.copyWith(
          emails: refresh ? emails : [...state.emails, ...emails],
          isLoading: false,
        );
      },
      error: (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
    );
  }
}

final emailProvider = StateNotifierProvider<EmailNotifier, EmailState>((ref) {
  return EmailNotifier(ref.watch(getEmailsUseCaseProvider));
});
