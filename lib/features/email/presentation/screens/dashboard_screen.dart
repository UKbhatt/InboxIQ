import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/logo_loader.dart';
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

      ref.read(syncStatusProvider.notifier).loadSyncStatus();

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
      // Re-checking
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
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blue.shade400, size: 24),
            const SizedBox(width: 8),
            Text(
              _getEmailTypeTitle(_selectedEmailType),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/menu.svg',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
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
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A0E27),
                      const Color(0xFF1A1F3A),
                      const Color(0xFF0F1419),
                    ],
                  ),
                ),
                child: LogoLoader(message: 'Checking Gmail connection...'),
              )
            : _isGmailConnected
            ? emailState.isLoading && emailState.emails.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0A0E27),
                            const Color(0xFF1A1F3A),
                            const Color(0xFF0F1419),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          if (syncState.inProgress)
                            Container(
                              margin: const EdgeInsets.all(16.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade400,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Syncing emails... (${syncState.totalEmails} synced)',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: LogoLoader(
                              message:
                                  'Loading ${_getEmailTypeTitle(_selectedEmailType).toLowerCase()}...',
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0A0E27),
                            const Color(0xFF1A1F3A),
                            const Color(0xFF0F1419),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          if (syncState.inProgress)
                            Container(
                              margin: const EdgeInsets.all(16.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade400,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Syncing emails... (${syncState.totalEmails} synced)',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: emailState.emails.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/no_email.svg',
                                          width: 64,
                                          height: 64,
                                          color: Colors.grey.shade600,
                                        ),
                                        Text(
                                          'No emails found',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade400,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue.shade400,
                                                Colors.blue.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              ref
                                                  .read(emailProvider.notifier)
                                                  .loadEmails(
                                                    refresh: true,
                                                    type: _selectedEmailType,
                                                  );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Refresh',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
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
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A0E27),
                      const Color(0xFF1A1F3A),
                      const Color(0xFF0F1419),
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 80,
                          color: Colors.blue.shade400,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Connect Your Gmail',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'To access your emails, please connect your Gmail account. We will only request read-only access to your emails.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade400.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isConnecting ? null : _connectGmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isConnecting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.mail_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Connect Gmail',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
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
