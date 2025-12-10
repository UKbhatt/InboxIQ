import 'package:flutter/material.dart';
import '../../domain/entities/email.dart';

class EmailCard extends StatelessWidget {
  final Email email;
  final VoidCallback onTap;

  const EmailCard({
    super.key,
    required this.email,
    required this.onTap,
  });

  String _getInitials(String from) {
    if (from.isEmpty) return '?';
    
    // Try to extract name from "Name <email@domain.com>" format
    String name = from;
    if (from.contains('<')) {
      name = from.substring(0, from.indexOf('<')).trim();
    }
    
    // Remove email if it's just an email address
    if (name.contains('@')) {
      name = name.split('@')[0];
    }
    
    // Get first letter, or first two letters if available
    name = name.trim();
    if (name.isEmpty) {
      // Fallback to email first letter
      final emailPart = from.split('@').first;
      return emailPart.isNotEmpty ? emailPart[0].toUpperCase() : '?';
    }
    
    final words = name.split(' ');
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String from) {
    // Generate a consistent color based on the sender's email/name
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

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(email.from);
    final avatarColor = _getAvatarColor(email.from);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with read/unread indicator
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
                  // Read/Unread indicator dot
                  if (!email.isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Email content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            email.from,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: email.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: email.isRead
                                  ? Colors.grey.shade700
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(email.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: email.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.subject.isEmpty ? '(No Subject)' : email.subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: email.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: email.isRead
                            ? Colors.grey.shade700
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.snippet.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email.snippet,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: email.isRead
                              ? FontWeight.normal
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

