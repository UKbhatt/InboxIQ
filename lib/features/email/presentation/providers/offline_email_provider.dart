import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/cache/services/email_cache_service.dart';
import '../../../../core/cache/services/offline_action_queue.dart';
import '../../../../core/cache/models/offline_action.dart';
import '../../../../core/sync/services/email_sync_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/email.dart';
import '../providers/email_provider.dart';

class OfflineEmailNotifier extends StateNotifier<EmailState> {
  final EmailSyncService _syncService;

  OfflineEmailNotifier(this._syncService) : super(const EmailState()) {
    _loadCachedEmails();

    _syncService.startAutoSync();
  }

  void _loadCachedEmails({String? type}) {
    final cachedEmails = EmailCacheService.getAllEmails(type: type);
    final emails = cachedEmails
        .map(
          (cached) => Email(
            id: cached.id,
            subject: cached.subject,
            from: cached.from,
            fromName: cached.fromName,
            snippet: cached.snippet,
            date: cached.date,
            isRead: cached.isRead,
          ),
        )
        .toList();

    state = state.copyWith(emails: emails, isLoading: false);
  }

  Future<void> loadEmails({bool refresh = false, String? type}) async {
    _loadCachedEmails(type: type);

    state = state.copyWith(isLoading: true);

    try {
      await _syncService.syncEmails(type: type ?? 'inbox', forceFull: refresh);

      // Reload cache 
      _loadCachedEmails(type: type);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sync failed: ${e.toString()}',
      );
    }
  }

  Future<void> markAsRead(String emailId) async {
    await EmailCacheService.updateEmail(
      emailId,
      (email) => email.copyWith(isRead: true),
    );

    final updatedEmails = state.emails.map((email) {
      if (email.id == emailId) {
        return email.copyWith(isRead: true);
      }
      return email;
    }).toList();

    state = state.copyWith(emails: updatedEmails);

    final action = OfflineAction.markRead(emailId);
    await OfflineActionQueue.addAction(action);

    final online = await _syncService.isOnline();
    if (online) {
      await _syncService.processPendingActions();
    }
  }

  Future<Email?> getEmailDetail(String emailId) async {
    final cached = EmailCacheService.getEmailById(emailId);
    if (cached != null) {
      return Email(
        id: cached.id,
        subject: cached.subject,
        from: cached.from,
        fromName: cached.fromName,
        snippet: cached.snippet,
        date: cached.date,
        isRead: cached.isRead,
      );
    }

    final online = await _syncService.isOnline();
    if (online) {
      await _syncService.syncEmailBody(emailId);
      final updated = EmailCacheService.getEmailById(emailId);
      if (updated != null) {
        return Email(
          id: updated.id,
          subject: updated.subject,
          from: updated.from,
          fromName: updated.fromName,
          snippet: updated.snippet,
          date: updated.date,
          isRead: updated.isRead,
        );
      }
    }

    return null;
  }
}

final offlineEmailProvider =
    StateNotifierProvider<OfflineEmailNotifier, EmailState>((ref) {
      final remoteDataSource = ref.watch(remoteEmailDataSourceProvider);
      final syncService = EmailSyncService(remoteDataSource);
      return OfflineEmailNotifier(syncService);
    });
