import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/daily_activation_providers.dart';

class _Skill {
  final String id;
  final String label;
  final IconData icon;

  const _Skill(this.id, this.label, this.icon);
}

/// Skill IDs must match the 'slug' values in the 'subcategories' table.
/// These are derived from the ServiTask seed data (see tablas-supabase rules).
const _allSkills = [
  // reparaciones
  _Skill('handyman', 'Handyman', Icons.home_repair_service),
  _Skill('plomeria', 'Plomería', Icons.plumbing),
  _Skill('electricidad', 'Electricidad', Icons.bolt),
  _Skill('electrodomesticos', 'Electrodomésticos', Icons.kitchen),
  _Skill('mecanica', 'Mecánica', Icons.car_repair),
  // limpieza
  _Skill('limpieza-residencial', 'Limpieza Residencial', Icons.cleaning_services),
  _Skill('limpieza-oficinas', 'Oficinas y Locales', Icons.business_center),
  _Skill('deep-cleaning', 'Deep Cleaning', Icons.sanitizer),
  _Skill('car-wash', 'Car Wash', Icons.local_car_wash),
  // construccion
  _Skill('montaje-ligero', 'Montaje Ligero', Icons.construction),
  _Skill('pintura', 'Pintura', Icons.format_paint),
  _Skill('albanileria', 'Albañilería', Icons.foundation),
  // exteriores
  _Skill('jardineria', 'Jardinería', Icons.grass),
  // tecnologia
  _Skill('soporte-tecnico', 'Soporte Técnico PC', Icons.computer),
  _Skill('redes-internet', 'Redes e Internet', Icons.wifi),
];

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);
    final selectedSkills = skillsAsync.asData?.value ?? [];
    final isSaving = skillsAsync is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Habilidades',
          style: AppTypography.titleMD.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE1E2E4)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis habilidades',
                  style: AppTypography.headlineMD.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  'Selecciona las tareas que puedes realizar hoy',
                  style: AppTypography.bodyMD
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: skillsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error al cargar habilidades: $e')),
              data: (_) => ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 4.0),
                children: [
                  ..._allSkills.map(
                    (skill) => _SkillCard(
                      skill: skill,
                      isSelected: selectedSkills.contains(skill.id),
                      onToggle: () => ref
                          .read(skillsProvider.notifier)
                          .toggle(skill.id),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Mantén tus habilidades actualizadas para recibir solicitudes que se ajusten a tu perfil profesional en tiempo real.',
                      style: AppTypography.bodySM.copyWith(
                        color: AppColors.primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    try {
                      await ref.read(skillsProvider.notifier).save();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Habilidades guardadas'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al guardar habilidades'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Guardar selección',
                    style: AppTypography.bodyLG.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final _Skill skill;
  final bool isSelected;
  final VoidCallback onToggle;

  const _SkillCard({
    required this.skill,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(skill.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              skill.label,
              style: AppTypography.titleMD
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Switch.adaptive(
            value: isSelected,
            onChanged: (_) => onToggle(),
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
