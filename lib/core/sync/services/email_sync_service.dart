import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cache/services/email_cache_service.dart';
import '../../cache/services/offline_action_queue.dart';
import '../../cache/models/cached_email.dart';
import '../../../features/email/data/datasources/remote_email_datasource.dart';

class EmailSyncService {
  final RemoteEmailDataSource _remoteDataSource;
  final Connectivity _connectivity = Connectivity();
  bool _isSyncing = false;

  EmailSyncService(this._remoteDataSource);

  // Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Get last sync time from SharedPreferences
  Future<DateTime?> getLastSyncTime(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('lastSyncTime_$type');
    if (lastSyncStr == null) return null;
    return DateTime.parse(lastSyncStr);
  }

  // Save last sync time
  Future<void> saveLastSyncTime(String type, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSyncTime_$type', time.toIso8601String());
  }

  // Sync emails (delta sync if lastSyncTime exists)
  Future<void> syncEmails({
    String type = 'inbox',
    bool forceFull = false,
  }) async {
    if (_isSyncing) {
      print('Sync already in progress, skipping...');
      return;
    }

    final online = await isOnline();
    if (!online) {
      print('Device is offline, skipping sync');
      return;
    }

    _isSyncing = true;
    try {
      final lastSyncTime = forceFull ? null : await getLastSyncTime(type);

      // Fetch emails from backend (delta sync if lastSyncTime exists)
      final result = await _remoteDataSource.getEmails(
        limit: 500,
        offset: 0,
        type: type,
        updatedAfter: lastSyncTime?.toIso8601String(),
      );

      result.when(
        success: (emails) async {
          // Convert Email entities to CachedEmail and cache
          final cachedEmails = emails.map((email) {
            return CachedEmail(
              id: email.id,
              subject: email.subject,
              from: email.from,
              fromName: email.fromName,
              snippet: email.snippet,
              date: email.date,
              isRead: email.isRead,
              isStarred:
                  false, // Will be updated from API response if available
              labels: [], // Will be populated from API if available
              updatedAt: DateTime.now(),
              type: type,
            );
          }).toList();

          await EmailCacheService.cacheEmails(cachedEmails);
          await saveLastSyncTime(type, DateTime.now());
          print('✓ Synced ${cachedEmails.length} emails for $type');
        },
        error: (failure) {
          print('Sync error: ${failure.message}');
        },
      );

      // Process pending offline actions
      await processPendingActions();
    } finally {
      _isSyncing = false;
    }
  }

  // Process pending offline actions
  Future<void> processPendingActions() async {
    final actions = OfflineActionQueue.getPendingActions();
    if (actions.isEmpty) return;

    print('Processing ${actions.length} pending actions...');

    for (final action in actions) {
      try {
        switch (action.type) {
          case 'MARK_READ':
            final markResult = await _remoteDataSource.markAsRead(
              action.emailId,
            );
            markResult.when(
              success: (_) async {
                // Update local cache
                await EmailCacheService.updateEmail(
                  action.emailId,
                  (email) => email.copyWith(isRead: true),
                );
                await OfflineActionQueue.removeAction(action.id);
                print(
                  '✓ Processed action: ${action.type} for ${action.emailId}',
                );
              },
              error: (failure) {
                print('Error processing MARK_READ: ${failure.message}');
                // Keep action in queue to retry later
              },
            );
            break;
          case 'STAR':
            // Implement star API call when available
            await EmailCacheService.updateEmail(
              action.emailId,
              (email) => email.copyWith(isStarred: true),
            );
            await OfflineActionQueue.removeAction(action.id);
            print('✓ Processed action: ${action.type} for ${action.emailId}');
            break;
          case 'UNSTAR':
            // Implement unstar API call when available
            await EmailCacheService.updateEmail(
              action.emailId,
              (email) => email.copyWith(isStarred: false),
            );
            await OfflineActionQueue.removeAction(action.id);
            print('✓ Processed action: ${action.type} for ${action.emailId}');
            break;
        }
      } catch (e) {
        print('Error processing action ${action.id}: $e');
        // Keep action in queue to retry later
      }
    }
  }

  // Sync email body (when user opens email)
  Future<void> syncEmailBody(String emailId) async {
    final cached = EmailCacheService.getEmailById(emailId);
    if (cached != null && cached.bodyText != null) {
      // Already cached
      return;
    }

    final online = await isOnline();
    if (!online) {
      print('Device is offline, cannot fetch email body');
      return;
    }

    try {
      final result = await _remoteDataSource.getEmailDetailById(emailId);
      result.when(
        success: (emailDetail) {
          if (cached != null) {
            EmailCacheService.updateEmail(
              emailId,
              (email) => email.copyWith(
                bodyText: emailDetail.bodyText,
                bodyHtml: emailDetail.bodyHtml,
              ),
            );
          }
        },
        error: (failure) {
          print('Error fetching email body: ${failure.message}');
        },
      );
    } catch (e) {
      print('Error syncing email body: $e');
    }
  }

  void startAutoSync() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('Internet connection restored, starting sync...');
        syncEmails(type: 'inbox');
      }
    });
  }
}
