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
    // Prefer fromName if available for better initials
    String name = email.fromName ?? '';
    
    if (name.isEmpty) {
      // Fallback: extract name from "Name <email@domain.com>" format
      name = from;
      if (from.contains('<')) {
        name = from.substring(0, from.indexOf('<')).trim();
      }
      
      // Remove email if it's just an email address
      if (name.contains('@')) {
        name = name.split('@')[0];
      }
    }
    
    // Get first letter, or first two letters if available
    name = name.trim();
    if (name.isEmpty) {
      // Fallback to email first letter
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

  String _getSenderName() {
    // Use fromName if available, otherwise parse from email
    if (email.fromName != null && email.fromName!.isNotEmpty) {
      return email.fromName!;
    }
    
    // Fallback: extract name from "Name <email@domain.com>" format
    String name = email.from;
    if (email.from.contains('<')) {
      name = email.from.substring(0, email.from.indexOf('<')).trim();
      name = name.replaceAll('"', '').replaceAll("'", '');
    }
    
    // If still looks like email, use username part
    if (name.isEmpty || name.contains('@')) {
      if (email.from.contains('@')) {
        name = email.from.split('@')[0];
      }
    }
    
    return name.trim().isEmpty ? 'Unknown' : name.trim();
  }

  @override
  Widget build(BuildContext context) {
    final senderName = _getSenderName();
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
                    Text(
                      email.subject.isEmpty ? '(No Subject)' : email.subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: email.isRead
                            ? FontWeight.normal
                            : FontWeight.w500,
                        color: email.isRead
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

