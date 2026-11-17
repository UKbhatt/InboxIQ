import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../email/presentation/screens/dashboard_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(authProvider.select((s) => s.user != null));
    return isSignedIn ? const DashboardScreen() : const AuthScreen();
  }
}
