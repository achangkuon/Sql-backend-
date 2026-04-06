import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/daily_activation_providers.dart';

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  static const int _startHour = 8;
  static const int _endHour = 20;

  String _formatHour(int hour) {
    if (hour < 12) return '${hour.toString().padLeft(2, '0')}:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${(hour - 12).toString().padLeft(2, '0')}:00 PM';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursAsync = ref.watch(availabilityHoursProvider);
    final selectedHours = hoursAsync.asData?.value ?? [];
    final isSaving = hoursAsync is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Disponibilidad',
          style: AppTypography.titleMD.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFE1E2E4)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Text(
              'Selecciona los rangos de tiempo que estarás disponible hoy.',
              style: AppTypography.bodyMD
                  .copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
            ),
          ),
          Expanded(
            child: hoursAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error al cargar horarios: $e')),
              data: (_) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _endHour - _startHour,
                itemBuilder: (context, index) {
                  final hour = _startHour + index;
                  final isSelected = selectedHours.contains(hour);
                  return _TimeSlotTile(
                    label: _formatHour(hour),
                    isSelected: isSelected,
                    onTap: () => ref
                        .read(availabilityHoursProvider.notifier)
                        .toggle(hour),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: ElevatedButton.icon(
            onPressed: isSaving
                ? null
                : () async {
                    try {
                      await ref
                          .read(availabilityHoursProvider.notifier)
                          .save();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Horarios guardados'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al guardar horarios'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              isSaving ? 'Guardando...' : 'Guardar Horarios',
              style: AppTypography.bodyLG
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSlotTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: AppTypography.labelMD.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSelected ? null : AppColors.surfaceContainerHighest,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isSelected
                    ? Text(
                        'Bloque seleccionado',
                        style: AppTypography.labelMD.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



