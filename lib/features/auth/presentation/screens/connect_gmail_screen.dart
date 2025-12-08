import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../../../email/presentation/providers/sync_status_provider.dart';
import '../../../email/presentation/screens/dashboard_screen.dart';

class ConnectGmailScreen extends ConsumerStatefulWidget {
  const ConnectGmailScreen({super.key});

  @override
  ConsumerState<ConnectGmailScreen> createState() => _ConnectGmailScreenState();
}

class _ConnectGmailScreenState extends ConsumerState<ConnectGmailScreen> {
  bool _isConnecting = false;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Gmail')),
      body: SafeArea(
        child: Center(
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
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
