import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/available_job_model.dart';
import '../../data/repositories/jobs_repository.dart';
import '../../../tasks/data/repositories/tasks_repository.dart';

class AvailableJobsScreen extends ConsumerStatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  ConsumerState<AvailableJobsScreen> createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends ConsumerState<AvailableJobsScreen> {
  String? _acceptingJobId;

  Future<void> _onAccept(AvailableJobModel job) async {
    setState(() => _acceptingJobId = job.id);
    try {
      await ref.read(jobsRepositoryProvider).acceptJob(job.id);
      // Refrescar la lista de solicitudes y las tareas activas del home
      ref.invalidate(availableJobsProvider);
      ref.invalidate(ongoingTasksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Solicitud aceptada! El cliente fue notificado.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('job_not_available')
            ? 'Este trabajo ya fue tomado por otro Tasker.'
            : 'Error al aceptar: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _acceptingJobId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(availableJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: jobsAsync.when(
                data: (jobs) => jobs.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(availableJobsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          itemCount: jobs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _JobCard(
                            job: jobs[i],
                            isAccepting: _acceptingJobId == jobs[i].id,
                            onAccept: () => _onAccept(jobs[i]),
                          ),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error al cargar solicitudes.\nDesliza hacia abajo para reintentar.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMD,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solicitudes', style: AppTypography.headline),
          const SizedBox(height: 4),
          Text(
            'Trabajos disponibles para aceptar',
            style: AppTypography.bodyMD,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No hay solicitudes disponibles',
            style: AppTypography.headline.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando un cliente publique un trabajo\naparecerá aquí.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMD,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(availableJobsProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualizar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de job ────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final AvailableJobModel job;
  final bool isAccepting;
  final VoidCallback onAccept;

  const _JobCard({
    required this.job,
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título + tiempo ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: AppTypography.headline.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  job.timeAgo,
                  style: AppTypography.bodySM,
                ),
              ],
            ),

            // ── Descripción ──────────────────────────────────
            if (job.details != null && job.details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                job.details!,
                style: AppTypography.bodyMD,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // ── Chips: ubicación + precio ────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (job.locationLabel != null && job.locationLabel!.isNotEmpty)
                  _Chip(
                    icon: Icons.location_on_outlined,
                    label: job.locationLabel!,
                    bgColor: AppColors.primary.withValues(alpha: 0.08),
                    fgColor: AppColors.primary,
                  ),
                _Chip(
                  icon: Icons.attach_money_rounded,
                  label: job.priceRange,
                  bgColor: AppColors.success.withValues(alpha: 0.10),
                  fgColor: AppColors.success,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Botón Aceptar ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAccepting ? null : onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isAccepting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Aceptar solicitud',
                        style: AppTypography.labelLG.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de información ───────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;

  const _Chip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySM.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
