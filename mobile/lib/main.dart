import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routing/app_router.dart';
import 'core/services/background_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeBackgroundService();

  // Initialize Supabase with correct credentials
  await Supabase.initialize(
    url: 'https://crktpdsijoneauexgsoj.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNya3RwZHNpam9uZWF1ZXhnc29qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4MTg2MjUsImV4cCI6MjA5NzM5NDYyNX0.9gH1B6fsD4DRMXRw0Dis5MmwePiUX_CxCKm-6TQiATI',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterPrv);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ResQLink',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0C0E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Indigo
          secondary: Color(0xFFA855F7), // Purple
          error: Color(0xFFEF4444), // Crimson/Rose
        ),
      ),
      routerConfig: router,
    );
  }
}