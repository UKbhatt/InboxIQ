import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/logo_loader.dart';
import '../providers/email_detail_provider.dart';
import '../../domain/entities/email_detail.dart';

class EmailDetailScreen extends ConsumerStatefulWidget {
  final String emailId;

  const EmailDetailScreen({super.key, required this.emailId});

  @override
  ConsumerState<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends ConsumerState<EmailDetailScreen> {
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markEmailAsRead();
    });
  }

  void _markEmailAsRead() {
    if (_hasMarkedAsRead) return;
    
    final emailDetailState = ref.read(emailDetailProvider(widget.emailId));
    
    if (emailDetailState.email != null && !emailDetailState.email!.isRead) {
      _hasMarkedAsRead = true;
      ref.read(emailDetailProvider(widget.emailId).notifier).markAsRead(widget.emailId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailDetailState = ref.watch(emailDetailProvider(widget.emailId));
    
    if (emailDetailState.email != null && !_hasMarkedAsRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markEmailAsRead();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: Colors.blue.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Email Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Container(
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
        child: emailDetailState.isLoading
            ? LogoLoader(
                message: 'Loading email...',
              )
            : emailDetailState.error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emailDetailState.error!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade300,
                        ),
                        textAlign: TextAlign.center,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(emailDetailProvider(widget.emailId).notifier)
                                .loadEmailDetail(widget.emailId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Retry',
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
                ),
              )
            : emailDetailState.email == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 64,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email not found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              )
            : _buildEmailContent(context, emailDetailState.email!),
      ),
    );
  }

  Widget _buildEmailContent(BuildContext context, EmailDetail email) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      email.subject.isEmpty ? '(No Subject)' : email.subject,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (email.isStarred)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.star,
                        color: Colors.amber.shade400,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    'From',
                    email.fromName != null && email.fromName!.isNotEmpty
                        ? '${email.fromName} <${email.from}>'
                        : email.from,
                  ),
                  if (email.to != null && email.to!.isNotEmpty)
                    _buildInfoRow(context, 'To', email.to!),
                  if (email.cc != null && email.cc!.isNotEmpty)
                    _buildInfoRow(context, 'CC', email.cc!),
                  if (email.bcc != null && email.bcc!.isNotEmpty)
                    _buildInfoRow(context, 'BCC', email.bcc!),
                  _buildInfoRow(context, 'Date', _formatDate(email.date)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (email.bodyText != null && email.bodyText!.isNotEmpty)
              _buildTextBody(context, email.bodyText!)
            else if (email.bodyHtml != null && email.bodyHtml!.isNotEmpty)
              _buildHtmlBody(context, email.bodyHtml!)
            else if (email.snippet.isNotEmpty)
              _buildTextBody(context, email.snippet)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  'No content available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade200,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBody(BuildContext context, String text) {
    if (text.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          'No content available',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: SelectableText(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade200,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildHtmlBody(BuildContext context, String html) {
    final strippedText = _stripHtml(html);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: SelectableText(
        strippedText.isNotEmpty
            ? strippedText
            : 'No readable content available',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade200,
          height: 1.6,
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    String text = html
        .replaceAll(
          RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '...')
        .trim();

    return text.isEmpty ? html : text;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
