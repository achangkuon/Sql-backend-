import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'ServiTask',
                style: AppTypography.headlineLG.copyWith(
                  color: AppColors.surfaceLowest,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bienvenido a ServiTask',
                style: AppTypography.titleMD.copyWith(
                  color: AppColors.surfaceLowest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu plataforma profesional para conectar con clientes locales y hacer crecer tu negocio de servicios.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLG.copyWith(
                  color: AppColors.surfaceLowest.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLowest,
                  foregroundColor: AppColors.primary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Empezar',
                      style: AppTypography.headlineSM.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
