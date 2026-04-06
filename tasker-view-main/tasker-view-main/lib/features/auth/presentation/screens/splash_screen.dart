import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/screens/main_dashboard_screen.dart';
import '../../../onboarding/presentation/screens/welcome_screen.dart';

/// Splash screen that resolves auth state before routing the user.
///
/// - If Supabase session is active  → navigate to [MainDashboardScreen]
/// - If no session                  → navigate to [WelcomeScreen]
///
/// Shown briefly while Supabase initializes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  /// Routes the user based on Supabase session state.
  ///
  /// Supabase is guaranteed to be initialized before [runApp] is called,
  /// so this method can safely access the client synchronously.
  Future<void> _redirect() async {
    // Minimal delay to let the first frame paint (avoids janky black flash)
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // TEMPORARY: Disabled auto-login to prevent dashboard crash.
    // Always navigate to WelcomeScreen for now.
    debugPrint('ℹ️ Redirección automática deshabilitada — mostrando pantalla de bienvenida');
    _navigateTo(const WelcomeScreen());
  }

  /// Replaces the splash screen in the navigation stack.
  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.work_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.surfaceContainerLowest),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}



