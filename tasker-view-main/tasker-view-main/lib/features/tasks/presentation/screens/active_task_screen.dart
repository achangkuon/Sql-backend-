import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_detail_repository.dart';
import '../../data/repositories/tasks_repository.dart';
import 'task_summary_screen.dart';
import 'schedule_task_screen.dart';

class ActiveTaskScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const ActiveTaskScreen({super.key, required this.task});

  @override
  ConsumerState<ActiveTaskScreen> createState() => _ActiveTaskScreenState();
}

class _ActiveTaskScreenState extends ConsumerState<ActiveTaskScreen> {
  bool _isLoading = false;

  TaskModel get task => widget.task;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── AppBar ──
          _buildAppBar(),

          // ── Content + overlayed action bar ──
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Map
                      _buildMapSection(),
                      const SizedBox(height: 24),

                      // Title & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: AppTypography.headline.copyWith(fontSize: 26),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'EN PROCESO',
                              style: AppTypography.labelSM.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: AppTypography.bodyMD
                            .copyWith(color: AppColors.onSurfaceVariant, height: 1.6),
                      ),

                      const SizedBox(height: 24),

                      // Bento Cards: Size & Tools
                      Row(
                        children: [
                          Expanded(child: _buildBentoCard(
                            icon: Icons.straighten_rounded,
                            label: 'Tamano/Dificultad',
                            value: '${task.taskSizeShort} - Intermedio',
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildBentoCard(
                            icon: Icons.construction_rounded,
                            label: 'Herramientas',
                            value: task.toolsRequired.isNotEmpty
                                ? task.toolsRequired.first
                                : 'Basicas',
                          )),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Address Section
                      _buildAddressSection(),
                    ],
                  ),
                ),
                // Bottom action overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Text('Tarea en curso', style: AppTypography.titleMD),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surfaceContainerHighest,
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.surfaceContainerLow,
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.map_outlined,
                  size: 48, color: AppColors.onSurfaceVariant),
            ),
          ),
          // Pin
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on,
                  color: AppColors.primary, size: 32),
            ),
          ),
          // Floating card
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ubicacion del Servicio',
                            style: AppTypography.labelMD),
                        Text(task.addressLine,
                            style: AppTypography.bodyMD
                                .copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.directions,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.labelSM),
          const SizedBox(height: 4),
          Text(value,
              style:
                  AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DIRECCION',
              style: AppTypography.labelSM.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            task.addressLine + (task.city != null ? ', ${task.city}' : ''),
            style: AppTypography.titleMD,
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          // Reagendar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ScheduleTaskScreen(
                          task: task,
                          isRescheduling: true,
                        )),
              );
            },
            child: Row(
              children: [
                const Icon(Icons.event_repeat_rounded,
                    color: AppColors.onSurfaceVariant, size: 18),
                const SizedBox(width: 10),
                Text('Reagendar tarea',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Cancelar
          GestureDetector(
            onTap: _showCancelDialog,
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    color: AppColors.onSurfaceVariant, size: 18),
                const SizedBox(width: 10),
                Text('Cancelar tarea',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
      ),
      child: GestureDetector(
        onTap: _isLoading ? null : _handleGenerateInvoice,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    'Generar factura',
                    style: AppTypography.bodyMD.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGenerateInvoice() async {
    setState(() => _isLoading = true);
    final repo = ref.read(taskDetailRepositoryProvider);
    final success = await repo.completeTask(task.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(ongoingTasksProvider);
      ref.invalidate(pastTasksProvider);

      final updatedTask = await repo.getTaskById(task.id);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TaskSummaryScreen(task: updatedTask ?? task),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al completar la tarea')),
      );
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierColor: AppColors.onSurface.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded,
                    color: AppColors.error, size: 32),
              ),
              const SizedBox(height: 20),
              Text('Cancelar tarea?',
                  style: AppTypography.titleMD, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Esta accion no se puede deshacer. La tarea volvera a estar disponible para otros taskers.',
                style: AppTypography.bodyMD
                    .copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('Continuar con la tarea',
                        style: AppTypography.bodyMD
                            .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleCancel();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Cancelar tarea',
                        style: AppTypography.bodyMD
                            .copyWith(color: AppColors.error, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancel() async {
    setState(() => _isLoading = true);
    final repo = ref.read(taskDetailRepositoryProvider);
    final success = await repo.cancelTask(task.id, 'Cancelada por el tasker');
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(ongoingTasksProvider);
      ref.invalidate(pastTasksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea cancelada')),
      );
      Navigator.of(context).pop();
    }
  }
}



