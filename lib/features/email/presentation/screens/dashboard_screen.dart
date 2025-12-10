import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../providers/email_provider.dart';
import '../providers/sync_status_provider.dart';
import '../widgets/email_drawer.dart';
import '../widgets/email_card.dart';
import 'email_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isConnecting = false;
  String _selectedEmailType = 'inbox';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCheckingConnection = true;
  bool _isGmailConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    // Check Gmail connection status first
    final authRepository = ref.read(authRepositoryProvider);
    final connectionResult = await authRepository.isGmailConnected();
    
    final isConnected = connectionResult.when(
      success: (connected) => connected,
      error: (_) => false,
    );

    if (mounted) {
      setState(() {
        _isCheckingConnection = false;
        _isGmailConnected = isConnected;
      });

      // Load sync status
      ref.read(syncStatusProvider.notifier).loadSyncStatus();

      // If Gmail is connected, automatically load emails
      if (isConnected) {
        ref
            .read(emailProvider.notifier)
            .loadEmails(refresh: true, type: _selectedEmailType);
      }
    }
  }

  void _onEmailTypeSelected(String type) {
    setState(() {
      _selectedEmailType = type;
    });
    ref.read(emailProvider.notifier).loadEmails(refresh: true, type: type);
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
              content: Text(
                'No app found to open this URL. Please install a web browser.',
              ),
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
      // Re-check connection status after connecting
      final authRepository = ref.read(authRepositoryProvider);
      final connectionResult = await authRepository.isGmailConnected();
      final isConnected = connectionResult.when(
        success: (connected) => connected,
        error: (_) => false,
      );
      
      setState(() {
        _isGmailConnected = isConnected;
      });
      
      ref.read(syncStatusProvider.notifier).loadSyncStatus();
      
      if (isConnected) {
        ref
            .read(emailProvider.notifier)
            .loadEmails(refresh: true, type: _selectedEmailType);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailState = ref.watch(emailProvider);
    final syncState = ref.watch(syncStatusProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getEmailTypeTitle(_selectedEmailType)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: EmailDrawer(
        selectedType: _selectedEmailType,
        onTypeSelected: _onEmailTypeSelected,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(syncStatusProvider.notifier).loadSyncStatus();
          if (_isGmailConnected) {
            await ref
                .read(emailProvider.notifier)
                .loadEmails(refresh: true, type: _selectedEmailType);
          }
        },
        child: _isCheckingConnection
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking Gmail connection...'),
                  ],
                ),
              )
            : _isGmailConnected
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
                                    ref
                                        .read(emailProvider.notifier)
                                        .loadEmails(
                                          refresh: true,
                                          type: _selectedEmailType,
                                        );
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
                              return EmailCard(
                                email: email,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EmailDetailScreen(
                                        emailId: email.id,
                                      ),
                                    ),
                                  );
                                  // No need to refresh - optimistic update already handled UI
                                  // Optionally refresh in background to ensure consistency
                                  // (but UI is already updated via optimistic update)
                                },
                              );
                            },
                          ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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

  String _getEmailTypeTitle(String type) {
    switch (type) {
      case 'inbox':
        return 'Inbox';
      case 'sent':
        return 'Sent';
      case 'draft':
        return 'Drafts';
      case 'starred':
        return 'Starred';
      case 'unread':
        return 'Unread';
      case 'trash':
        return 'Trash';
      case 'spam':
        return 'Spam';
      default:
        return 'Inbox';
    }
  }
}
