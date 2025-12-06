import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/email_provider.dart';
import 'connect_gmail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emailProvider.notifier).loadEmails(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final emailState = ref.watch(emailProvider);

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
          await ref.read(emailProvider.notifier).loadEmails(refresh: true);
        },
        child: Column(
          children: [
            if (authState.user != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListTile(
                    title: const Text('User'),
                    subtitle: Text(authState.user!.email),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConnectGmailScreen(),
                          ),
                        );
                      },
                      child: const Text('Connect Gmail'),
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
                                onTap: () {},
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

