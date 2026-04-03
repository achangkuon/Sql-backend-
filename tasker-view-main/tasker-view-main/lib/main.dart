import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all unhandled Flutter framework errors and log them
  // instead of crashing silently (helps diagnose black screen issues)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FLUTTER ERROR: ${details.exception}');
    debugPrint('🔴 STACK: ${details.stack}');
  };

  // Initialize date formatting for Spanish locale
  await initializeDateFormatting('es', null);

  // Initialize Supabase BEFORE runApp — the SplashScreen depends on the
  // client being ready to check session state.
  try {
    // Proyecto unificado: compartido con ServiTask App (React Native)
    // para sincronización de datos entre taskers y clientes.
    await Supabase.initialize(
      url: 'https://qsadtpckaowrkxkbxcxe.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFzYWR0cGNrYW93cnt4a2J4Y3hlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxNjc5NjcsImV4cCI6MjA5MDc0Mzk2N30.SmiEwt2Z-Vm71dqnkTOSJraFei64Txrv-WHJRegCmEc'
    );
    debugPrint('✅ Supabase initialized successfully');

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      debugPrint('✅ Sesión activa: ${user.email}');
    } else {
      debugPrint('ℹ️ Sin sesión activa');
    }
  } catch (e) {
    // Log but don't crash — SplashScreen handles the error state
    debugPrint('⚠️ Supabase init failed: $e');
  }

  // Start the application
  runApp(const ProviderScope(child: ServiTaskApp()));
}



class ServiTaskApp extends StatelessWidget {
  const ServiTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ServiTask',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
