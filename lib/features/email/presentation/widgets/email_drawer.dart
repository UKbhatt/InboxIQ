import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EmailDrawer extends ConsumerWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const EmailDrawer({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Drawer(
      backgroundColor: const Color(0xFF1A1F3A),
      child: SafeArea(
        child: Column(
          children: [
            if (authState.user != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0A0E27), const Color(0xFF1A1F3A)],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue.shade400,
                      child: Text(
                        authState.user!.email[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authState.user!.email.split('@')[0],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.user!.email,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context,
                    svgPath: 'assets/inbox.svg',
                    title: 'Inbox',
                    type: 'inbox',
                    isSelected: selectedType == 'inbox',
                  ),
                  _buildDrawerItem(
                    context,
                    svgPath: 'assets/sent.svg',
                    title: 'Sent',
                    type: 'sent',
                    isSelected: selectedType == 'sent',
                  ),
                  _buildDrawerItem(
                    context,
                    svgPath: 'assets/draft.svg',
                    title: 'Drafts',
                    type: 'draft',
                    isSelected: selectedType == 'draft',
                  ),
                  _buildDrawerItem(
                    context,
                    svgPath: 'assets/starred.svg',
                    title: 'Starred',
                    type: 'starred',
                    isSelected: selectedType == 'starred',
                  ),
                  _buildDrawerItem(
                    context,
                    svgPath: 'assets/unread.svg',
                    title: 'Unread',
                    type: 'unread',
                    isSelected: selectedType == 'unread',
                  ),
                  _buildDrawerItem(
                    context,
                    svgPath: 'assets/trash.svg',
                    title: 'Trash',
                    type: 'trash',
                    isSelected: selectedType == 'trash',
                  ),
                  _buildDrawerItem(
                    context,
                    svgPath: 'assets/spam.svg',
                    title: 'Spam',
                    type: 'spam',
                    isSelected: selectedType == 'spam',
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/logout.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Colors.red.shade400,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: Text(
                      'Sign Out',
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required String svgPath,
    required String title,
    required String type,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.shade400.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: Colors.blue.shade400.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: SvgPicture.asset(
          svgPath,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.blue.shade400 : Colors.grey.shade400,
            BlendMode.srcIn,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey.shade300,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          onTypeSelected(type);
        },
      ),
    );
  }
}
