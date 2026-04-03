import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingModel> _pages = [
    OnboardingModel(
      title: 'SAFE \nSERVICE',
      subtitle: 'Gana dinero con tus habilidades',
      description: 'Encuentra trabajo local que se adapte a tu horario y habilidades. Tú decides cuándo y cuánto trabajar.',
      icon: Icons.security_rounded,
      color: AppColors.primary,
    ),
    OnboardingModel(
      title: 'Controla tu agenda',
      subtitle: 'Sincroniza tus calendarios',
      description: 'Mantén tu disponibilidad actualizada y gestiona tus citas directamente desde la aplicación.',
      icon: Icons.calendar_today_rounded,
      color: AppColors.primary,
    ),
    OnboardingModel(
      title: 'Pagos rápidos y seguros',
      subtitle: 'Tus ganancias directo a tu cuenta',
      description: 'Recibe tus pagos de forma segura y transparente una vez finalizado el servicio.',
      icon: Icons.payments_rounded,
      color: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageContent(model: _pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Action Button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve:Curves.easeInOut,
                        );
                      } else {
                        // Navigate to Login
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1 ? 'Empezar' : 'Siguiente',
                            style: AppTypography.headlineSM.copyWith(
                              color: AppColors.surfaceLowest,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pages.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                            color: AppColors.surfaceLowest,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingModel {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingModel model;

  const _OnboardingPageContent({required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Placeholder
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              model.icon,
              size: 120,
              color: model.color.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            model.title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineLG.copyWith(
              fontSize: 32,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            model.subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.titleMD.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            model.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLG.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
