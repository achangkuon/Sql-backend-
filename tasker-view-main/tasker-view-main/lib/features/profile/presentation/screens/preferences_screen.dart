import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/preferences_providers.dart';
import '../providers/daily_activation_providers.dart';
import 'availability_screen.dart';
import 'skills_screen.dart';
import 'work_zone_screen.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(taskerOnlineStatusProvider);
    final isOnline = isOnlineAsync.value ?? false;

    final completionAsync = ref.watch(activationCompletionProvider);
    final completion = completionAsync.asData?.value ?? {};
    final availabilityDone = completion['availability'] ?? false;
    final skillsDone = completion['skills'] ?? false;
    final workZoneDone = completion['workZone'] ?? false;
    final allDone = availabilityDone && skillsDone && workZoneDone;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Invitaciones para hoy',
          style: AppTypography.titleMD.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active,
                color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Main toggle ─────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SwitchListTile.adaptive(
                  value: isOnline,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    ref
                        .read(taskerOnlineStatusProvider.notifier)
                        .toggleOnlineStatus(val);
                  },
                  title: Text(
                    'Recibir invitaciones para hoy',
                    style: AppTypography.titleMD.copyWith(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    isOnline ? 'Disponible ahora' : 'No disponible',
                    style: AppTypography.bodySM
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),

              // ── Reminder banner (shown when all 3 sections complete) ────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: allDone
                    ? Container(
                        key: const ValueKey('reminder'),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.outlineVariant
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.schedule_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Asegúrate de responder a las invitaciones para hoy en menos de una hora.',
                                style: AppTypography.bodySM.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-reminder')),
              ),

              // ── Setting cards ────────────────────────────────────────────
              _SettingCard(
                title: 'Disponibilidad',
                subtitle: availabilityDone
                    ? 'Horario configurado'
                    : 'Selecciona tus horarios disponibles',
                icon: Icons.calendar_today_rounded,
                isDone: availabilityDone,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AvailabilityScreen()),
                ).then((_) =>
                    ref.invalidate(activationCompletionProvider)),
              ),
              _SettingCard(
                title: 'Habilidades',
                subtitle: skillsDone
                    ? 'Habilidades seleccionadas'
                    : 'Selecciona las tareas que puedes hacer hoy',
                icon: Icons.build_rounded,
                isDone: skillsDone,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SkillsScreen()),
                ).then((_) =>
                    ref.invalidate(activationCompletionProvider)),
              ),
              _SettingCard(
                title: 'Zona de trabajo',
                subtitle: workZoneDone
                    ? 'Área establecida'
                    : 'Selecciona tu ubicación en el mapa',
                icon: Icons.map_rounded,
                isDone: workZoneDone,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WorkZoneScreen()),
                ).then((_) =>
                    ref.invalidate(activationCompletionProvider)),
              ),

              const SizedBox(height: 16),

              // ── Map preview card ─────────────────────────────────────────
              _buildMapCard(),

              const SizedBox(height: 24),

              // ── Save button ──────────────────────────────────────────────
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Guardar y Activarse',
                  style: AppTypography.bodyLG.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8D4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GridPaper(
                color: Colors.white.withValues(alpha: 0.5),
                divisions: 2,
                subdivisions: 1,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu área actual está configurada en Ciudad de México',
                      style: AppTypography.bodySM.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable setting card ─────────────────────────────────────────────────────

class _SettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDone;
  final VoidCallback onTap;

  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isDone ? AppColors.primary : AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMD.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySM.copyWith(
                      color: isDone
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isDone
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
