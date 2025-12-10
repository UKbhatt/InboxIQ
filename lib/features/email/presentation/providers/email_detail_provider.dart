import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/email_detail.dart';
import '../../domain/usecases/get_email_detail_usecase.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/email_repository.dart';
import 'email_provider.dart';

class EmailDetailState {
  final EmailDetail? email;
  final bool isLoading;
  final String? error;

  const EmailDetailState({this.email, this.isLoading = false, this.error});

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
  final EmailRepository _emailRepository;
  final EmailNotifier _emailNotifier;

  EmailDetailNotifier(
    this._getEmailDetailUseCase,
    this._emailRepository,
    this._emailNotifier,
  ) : super(const EmailDetailState());

  Future<void> loadEmailDetail(String emailId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getEmailDetailUseCase(emailId);

    result.when(
      success: (email) {
        state = state.copyWith(email: email, isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
    );
  }

  /// Marks email as read with optimistic update
  /// Should be called AFTER the provider is built and email is loaded
  Future<void> markAsRead(String emailId) async {
    // Optimistic update: Mark as read immediately in the email list
    final originalEmail = _emailNotifier.markEmailAsReadOptimistic(emailId);

    // Mark email as read on server (non-blocking, in background)
    final result = await _emailRepository.markAsRead(emailId);
    
    result.when(
      success: (_) {
        // Success - optimistic update was correct, no rollback needed
      },
      error: (failure) {
        // API call failed - rollback the optimistic update
        if (originalEmail != null) {
          _emailNotifier.rollbackMarkAsRead(emailId, originalEmail);
        }
      },
    );
  }

  void clear() {
    state = const EmailDetailState();
  }
}

final emailDetailProvider =
    StateNotifierProvider.family<EmailDetailNotifier, EmailDetailState, String>(
      (ref, emailId) {
        final notifier = EmailDetailNotifier(
          ref.watch(getEmailDetailUseCaseProvider),
          ref.watch(emailRepositoryProvider),
          ref.read(emailProvider.notifier),
        );
        // Load email detail but don't mark as read yet
        notifier.loadEmailDetail(emailId);
        return notifier;
      },
    );
