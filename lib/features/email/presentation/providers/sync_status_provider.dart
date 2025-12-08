import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/email_repository.dart';
import '../../../../core/di/injection_container.dart';

class SyncStatusState {
  final bool hasSynced;
  final bool inProgress;
  final DateTime? lastSyncAt;
  final int totalEmails;
  final String? lastError;
  final bool isLoading;

  const SyncStatusState({
    this.hasSynced = false,
    this.inProgress = false,
    this.lastSyncAt,
    this.totalEmails = 0,
    this.lastError,
    this.isLoading = false,
  });

  SyncStatusState copyWith({
    bool? hasSynced,
    bool? inProgress,
    DateTime? lastSyncAt,
    int? totalEmails,
    String? lastError,
    bool? isLoading,
  }) {
    return SyncStatusState(
      hasSynced: hasSynced ?? this.hasSynced,
      inProgress: inProgress ?? this.inProgress,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      totalEmails: totalEmails ?? this.totalEmails,
      lastError: lastError ?? this.lastError,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  final EmailRepository _emailRepository;

  SyncStatusNotifier(this._emailRepository) : super(const SyncStatusState()) {
    loadSyncStatus();
  }

  Future<void> loadSyncStatus() async {
    state = state.copyWith(isLoading: true);

    final result = await _emailRepository.getSyncStatus();

    result.when(
      success: (data) {
        state = SyncStatusState(
          hasSynced: data['hasSynced'] as bool? ?? false,
          inProgress: data['inProgress'] as bool? ?? false,
          lastSyncAt: data['lastSyncAt'] != null
              ? DateTime.parse(data['lastSyncAt'] as String)
              : null,
          totalEmails: data['totalEmails'] as int? ?? 0,
          lastError: data['lastError'] as String?,
          isLoading: false,
        );
      },
      error: (failure) {
        state = state.copyWith(isLoading: false, lastError: failure.message);
      },
    );
  }

  Future<void> startSync() async {
    if (state.inProgress) return;

    state = state.copyWith(inProgress: true, lastError: null);

    final result = await _emailRepository.startSync();

    result.when(
      success: (_) {
        loadSyncStatus();
      },
      error: (failure) {
        state = state.copyWith(inProgress: false, lastError: failure.message);
      },
    );
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
      return SyncStatusNotifier(ref.watch(emailRepositoryProvider));
    });
