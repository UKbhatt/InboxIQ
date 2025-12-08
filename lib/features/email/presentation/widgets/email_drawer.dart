import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      child: SafeArea(
        child: Column(
          children: [
            if (authState.user != null)
              UserAccountsDrawerHeader(
                accountName: Text(authState.user!.email.split('@')[0]),
                accountEmail: Text(authState.user!.email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    authState.user!.email[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.inbox,
                    title: 'Inbox',
                    type: 'inbox',
                    isSelected: selectedType == 'inbox',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.send,
                    title: 'Sent',
                    type: 'sent',
                    isSelected: selectedType == 'sent',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.edit,
                    title: 'Drafts',
                    type: 'draft',
                    isSelected: selectedType == 'draft',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.star,
                    title: 'Starred',
                    type: 'starred',
                    isSelected: selectedType == 'starred',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.mark_email_unread,
                    title: 'Unread',
                    type: 'unread',
                    isSelected: selectedType == 'unread',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.delete,
                    title: 'Trash',
                    type: 'trash',
                    isSelected: selectedType == 'trash',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.report,
                    title: 'Spam',
                    type: 'spam',
                    isSelected: selectedType == 'spam',
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/signin');
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
    required IconData icon,
    required String title,
    required String type,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      onTap: () {
        Navigator.of(context).pop();
        onTypeSelected(type);
      },
    );
  }
}
