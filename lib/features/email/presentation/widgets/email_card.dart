import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/email.dart';
import '../services/email_summary_service.dart';
import 'email_summary_popover.dart';

class EmailCard extends ConsumerStatefulWidget {
  final Email email;
  final VoidCallback onTap;

  const EmailCard({super.key, required this.email, required this.onTap});

  @override
  ConsumerState<EmailCard> createState() => _EmailCardState();
}

class _EmailCardState extends ConsumerState<EmailCard> {
  bool _isLoadingSummary = false;
  bool _showPopover = false;
  final GlobalKey _aiButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  String _getInitials(String from) {
    String name = widget.email.fromName ?? '';

    if (name.isEmpty) {
      name = from;
      if (from.contains('<')) {
        name = from.substring(0, from.indexOf('<')).trim();
      }

      if (name.contains('@')) {
        name = name.split('@')[0];
      }
    }

    name = name.trim();
    if (name.isEmpty) {
      if (from.contains('@')) {
        final emailPart = from.split('@').first;
        return emailPart.isNotEmpty ? emailPart[0].toUpperCase() : '?';
      }
      return '?';
    }

    final words = name.split(' ');
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String from) {
    final hash = from.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[hash.abs() % colors.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getSenderName() {
    if (widget.email.fromName != null && widget.email.fromName!.isNotEmpty) {
      return widget.email.fromName!;
    }

    String name = widget.email.from;
    if (widget.email.from.contains('<')) {
      name = widget.email.from
          .substring(0, widget.email.from.indexOf('<'))
          .trim();
      name = name.replaceAll('"', '').replaceAll("'", '');
    }

    if (name.isEmpty || name.contains('@')) {
      if (widget.email.from.contains('@')) {
        name = widget.email.from.split('@')[0];
      }
    }

    return name.trim().isEmpty ? 'Unknown' : name.trim();
  }

  void _showPopoverOverlay({String? summary, bool isLoading = false}) {
    _hidePopover(); 

    _overlayEntry = OverlayEntry(
      builder: (context) => EmailSummaryPopover(
        summary: summary ?? 'Generating summary...',
        isLoading: isLoading,
        buttonKey: _aiButtonKey,
        onDismiss: _hidePopover,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showPopover = true;
    });
  }

  void _hidePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showPopover = false;
    });
  }

  Future<void> _showSummary() async {
    if (_isLoadingSummary || _showPopover) return;

    setState(() {
      _isLoadingSummary = true;
    });

    // Show loading popover
    if (mounted) {
      _showPopoverOverlay(isLoading: true);
    }

    try {
      final summaryService = ref.read(emailSummaryServiceProvider);
      final summary = await summaryService.getSummary(widget.email.id);

      if (!mounted) return;

      if (summary != null) {
        _hidePopover();
        if (mounted) {
          _showPopoverOverlay(summary: summary, isLoading: false);
        }
      } else {
        _hidePopover();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to generate summary. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _hidePopover();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _hidePopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final senderName = _getSenderName();
    final initials = _getInitials(widget.email.from);
    final avatarColor = _getAvatarColor(widget.email.from);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColor,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!widget.email.isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            senderName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: widget.email.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: widget.email.isRead
                                  ? Colors.grey.shade700
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(widget.email.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: widget.email.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.email.subject.isEmpty
                          ? '(No Subject)'
                          : widget.email.subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.email.isRead
                            ? FontWeight.normal
                            : FontWeight.w500,
                        color: widget.email.isRead
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: _aiButtonKey,
                onTap: _showPopover ? _hidePopover : _showSummary,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _showPopover
                      ? BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        )
                      : null,
                  child: _isLoadingSummary
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: _showPopover
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
