import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
    // Mark as read after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markEmailAsRead();
    });
  }

  void _markEmailAsRead() {
    if (_hasMarkedAsRead) return;
    
    final emailDetailState = ref.read(emailDetailProvider(widget.emailId));
    
    // Only mark as read if email is loaded and not already read
    if (emailDetailState.email != null && !emailDetailState.email!.isRead) {
      _hasMarkedAsRead = true;
      ref.read(emailDetailProvider(widget.emailId).notifier).markAsRead(widget.emailId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailDetailState = ref.watch(emailDetailProvider(widget.emailId));
    
    // Mark as read when email is loaded (if not already marked)
    if (emailDetailState.email != null && !_hasMarkedAsRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markEmailAsRead();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Email Details')),
      body: emailDetailState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : emailDetailState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emailDetailState.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(emailDetailProvider(widget.emailId).notifier)
                          .loadEmailDetail(widget.emailId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : emailDetailState.email == null
          ? const Center(child: Text('Email not found'))
          : _buildEmailContent(context, emailDetailState.email!),
    );
  }

  Widget _buildEmailContent(BuildContext context, EmailDetail email) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    email.subject,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (email.isStarred)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.star, color: Colors.amber),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
            const Divider(height: 32),
            if (email.bodyText != null && email.bodyText!.isNotEmpty)
              _buildTextBody(context, email.bodyText!)
            else if (email.bodyHtml != null && email.bodyHtml!.isNotEmpty)
              _buildHtmlBody(context, email.bodyHtml!)
            else if (email.snippet.isNotEmpty)
              _buildTextBody(context, email.snippet)
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No content available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBody(BuildContext context, String text) {
    if (text.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No content available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: SelectableText(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  Widget _buildHtmlBody(BuildContext context, String html) {
    final strippedText = _stripHtml(html);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: SelectableText(
        strippedText.isNotEmpty
            ? strippedText
            : 'No readable content available',
        style: Theme.of(context).textTheme.bodyLarge,
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
