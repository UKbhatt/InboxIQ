import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/email_provider.dart';
import '../providers/sync_status_provider.dart';
import 'email_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncStatusProvider.notifier).loadSyncStatus();
      final syncState = ref.read(syncStatusProvider);
      if (syncState.hasSynced) {
        ref.read(emailProvider.notifier).loadEmails(refresh: true);
      }
    });
  }

  Future<void> _connectGmail() async {
    setState(() => _isConnecting = true);

    final authUrl = await ref.read(authProvider.notifier).getOAuthUrl();

    if (authUrl == null) {
      if (mounted) {
        final error = ref.read(authProvider).error ?? 'Failed to get OAuth URL';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _connectGmail(),
            ),
          ),
        );
      }
      setState(() => _isConnecting = false);
      return;
    }

    try {
      final uri = Uri.parse(authUrl);
      
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid URL format: $authUrl'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isConnecting = false);
        return;
      }
      
      bool canLaunch = await canLaunchUrl(uri);
      
      if (!canLaunch) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No app found to open this URL. Please install a web browser.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isConnecting = false);
        return;
      }
      
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open browser. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    setState(() => _isConnecting = false);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ref.read(syncStatusProvider.notifier).loadSyncStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailState = ref.watch(emailProvider);
    final syncState = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('InboxIQ'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/signin');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(syncStatusProvider.notifier).loadSyncStatus();
          if (syncState.hasSynced) {
            await ref.read(emailProvider.notifier).loadEmails(refresh: true);
          }
        },
        child: syncState.hasSynced || syncState.inProgress
            ? Column(
                children: [
                  if (syncState.inProgress)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const LinearProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                'Syncing emails... (${syncState.totalEmails} synced)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: emailState.isLoading && emailState.emails.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : emailState.emails.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('No emails found'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.read(emailProvider.notifier).loadEmails(refresh: true);
                                      },
                                      child: const Text('Refresh'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: emailState.emails.length,
                                itemBuilder: (context, index) {
                                  final email = emailState.emails[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        email.subject,
                                        style: TextStyle(
                                          fontWeight: email.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(email.from),
                                          const SizedBox(height: 4),
                                          Text(
                                            email.snippet,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        _formatDate(email.date),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => EmailDetailScreen(emailId: email.id),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                  if (emailState.isLoading && emailState.emails.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Connect Your Gmail',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'To access your emails, please connect your Gmail account. We will only request read-only access to your emails.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: _isConnecting ? null : _connectGmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isConnecting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Connect Gmail'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

