import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../jobs/presentation/screens/available_jobs_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../business/presentation/screens/business_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AvailableJobsScreen(),
    const CalendarScreen(),
    const BusinessScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody was used for the glassmorphism BackdropFilter blur — now
      // disabled. Keeping it true forces an extra compositing layer that
      // causes SurfaceTexture duplication on TextureView, freezing HWUI 8s.
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildGlassmorphismBottomBar(),
    );
  }

  Widget _buildGlassmorphismBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        // NOTE: BackdropFilter (blur) is disabled because it causes a full
        // black screen with TextureView + Skia on Android API 37 emulators.
        // The blur layer fails to composite correctly in this render mode.
        // Restore BackdropFilter when targeting a real device with Impeller.
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'INICIO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: 'SOLICITUDES',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'CALENDARIO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'MI NEGOCIO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'PERFIL',
            ),
          ],
        ),
      ),

    );
  }
}



