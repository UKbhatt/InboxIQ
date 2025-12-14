import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'features/auth/presentation/screens/sign_up_screen.dart';
import 'features/email/presentation/screens/dashboard_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/cache/adapters/cached_email_adapter.dart';
import 'core/cache/adapters/offline_action_adapter.dart';
import 'core/cache/services/email_cache_service.dart';
import 'core/cache/services/offline_action_queue.dart';
import 'core/ai/services/gemini_summary_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  print('API BASE URL: ${dotenv.env['GEMINI_API_KEY']}');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await Hive.initFlutter();

  Hive.registerAdapter(CachedEmailAdapter());
  Hive.registerAdapter(OfflineActionAdapter());

  await EmailCacheService.init();
  await OfflineActionQueue.init();

  GeminiSummaryService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'InboxIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          if (authState.user != null) {
            return const DashboardScreen();
          }
          return const SignInScreen();
        },
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
