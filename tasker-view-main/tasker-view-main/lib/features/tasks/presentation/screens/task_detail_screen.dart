import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_detail_repository.dart';
import '../../data/repositories/tasks_repository.dart';
import 'task_chat_tab.dart';
import 'schedule_task_screen.dart';
import 'active_task_screen.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  int _tabIndex = 0; // 0 = Detalles, 1 = Chat
  bool _isLoading = false;

  TaskModel get task => widget.task;

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientProfileProvider(task.clientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          _buildAppBar(clientAsync),

          // ── Tabs Toggle ─────────────────────────────────
          _buildTabToggle(),

          // ── Content + overlayed action bar ──────────────
          Expanded(
            child: Stack(
              children: [
                _tabIndex == 0
                    ? _buildDetailsTab(clientAsync)
                    : TaskChatTab(task: task),
                if (_tabIndex == 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomActions(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AsyncValue clientAsync) {
    return Container(
      color: AppColors.background,
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _tabIndex == 0 ? 'Detalle de la Tarea' : '',
                  style: AppTypography.titleMD,
                ),
              ),
              // Client avatar (only in Chat tab header)
              if (_tabIndex == 1)
                clientAsync.when(
                  data: (profile) {
                    if (profile == null) return const SizedBox.shrink();
                    final initials = _getInitials(profile.fullName);
                    return Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(profile.fullName,
                                style: AppTypography.bodyMD
                                    .copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surfaceContainerHighest,
                          child: Text(initials,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12)),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                )
              else
                clientAsync.when(
                  data: (profile) {
                    if (profile == null) return const SizedBox.shrink();
                    final initials = _getInitials(profile.fullName);
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      child: profile.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(profile.avatarUrl!,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Text(initials,
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12))),
                            )
                          : Text(initials,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12)),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildTab('Detalles', 0),
            _buildTab('Chat', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyMD.copyWith(
                color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── DETAILS TAB ───────────────────────────────────────

  Widget _buildDetailsTab(AsyncValue clientAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          _buildMapSection(),
          const SizedBox(height: 20),

          // Status + Time
          _buildStatusRow(),
          const SizedBox(height: 12),

          // Title
          Text(
            task.title,
            style: AppTypography.headline.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            task.description,
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // ── Bento Details Grid ──────────────────────────
          // Size & Difficulty
          _buildDetailCard(
            icon: Icons.speed_rounded,
            label: 'Tamano y dificultad',
            value: task.taskSizeLabel,
          ),
          const SizedBox(height: 12),

          // Tools
          if (task.toolsRequired.isNotEmpty)
            _buildToolsCard(),
          if (task.toolsRequired.isNotEmpty) const SizedBox(height: 12),

          // Address
          _buildDetailCard(
            icon: Icons.pin_drop_rounded,
            label: 'Direccion',
            value: task.addressLine +
                (task.city != null ? ', ${task.city}' : ''),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surfaceContainerHighest,
      ),
      child: Stack(
        children: [
          // Map placeholder background
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

          // Location pin
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

          // Bottom info card
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me,
                      size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Area de servicio: ${task.city ?? 'Sin especificar'}',
                      style: AppTypography.labelMD,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildStatusRow() {
    String label;
    Color color;
    switch (task.status) {
      case 'published':
      case 'matched':
        label = 'PENDIENTE';
        color = AppColors.alert;
        break;
      case 'confirmed':
        label = 'CONFIRMADA';
        color = AppColors.success;
        break;
      case 'in_progress':
        label = 'EN PROCESO';
        color = AppColors.primary;
        break;
      case 'completed':
      case 'pending_review':
        label = 'COMPLETADA';
        color = AppColors.success;
        break;
      default:
        label = task.status.toUpperCase();
        color = AppColors.onSurfaceVariant;
    }

    final timeAgo = _timeAgo(task.publishedAt ?? task.createdAt);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTypography.labelSM.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Publicado $timeAgo',
          style: AppTypography.labelMD,
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.labelSM.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                Text(value,
                    style: AppTypography.bodyMD
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.construction_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HERRAMIENTAS',
                  style: AppTypography.labelSM.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: task.toolsRequired
                      .map((tool) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tool, style: AppTypography.bodySM),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM ACTIONS ────────────────────────────────────

  Widget _buildBottomActions() {
    // Different actions depending on status
    if (task.status == 'published' || task.status == 'matched') {
      return _buildConfirmRejectBar();
    } else if (task.status == 'confirmed') {
      return _buildStartTaskBar();
    } else if (task.status == 'in_progress') {
      return _buildCompleteTaskBar();
    }
    return const SizedBox.shrink();
  }

  Widget _buildConfirmRejectBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : () => _showRejectDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Rechazar',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isLoading ? null : _handleConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
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
                          'Confirmar tarea',
                          style: AppTypography.bodyMD.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartTaskBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleTaskScreen(
                      task: task,
                      isRescheduling: true,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Agendar',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isLoading ? null : _handleStart,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
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
                          'Iniciar tarea',
                          style: AppTypography.bodyMD.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteTaskBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
      ),
      child: GestureDetector(
        onTap: _isLoading ? null : _handleComplete,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
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

  // ── ACTIONS ───────────────────────────────────────────

  Future<void> _handleConfirm() async {
    // Navigate to ScheduleTaskScreen to set date, duration and price
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleTaskScreen(task: task),
      ),
    );
    // If the tasker saved the schedule, invalidate providers and go back
    if (result == true && mounted) {
      ref.invalidate(ongoingTasksProvider);
      ref.invalidate(newSolicitudesProvider);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleStart() async {
    setState(() => _isLoading = true);
    final repo = ref.read(taskDetailRepositoryProvider);
    final success = await repo.startTask(task.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(ongoingTasksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea iniciada')),
      );
      // Navigate to active task screen
      if (!mounted) return;
      final updatedTask = await repo.getTaskById(task.id);
      if (updatedTask != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ActiveTaskScreen(task: updatedTask),
          ),
        );
      }
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);
    final repo = ref.read(taskDetailRepositoryProvider);
    final success = await repo.completeTask(task.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(ongoingTasksProvider);
      ref.invalidate(pastTasksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea completada')),
      );
      Navigator.of(context).pop(true);
    }
  }

  void _showRejectDialog() {
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
              // Warning icon
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

              Text(
                'Quieres rechazar esta tarea?',
                style: AppTypography.titleMD,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Estas seguro que quieres rechazar esta tarea? Tiene un potencial de ganancia de: \$${task.agreedPrice?.toStringAsFixed(2) ?? '0.00'}',
                style: AppTypography.bodyMD
                    .copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Volver a la tarea
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
                    child: Text(
                      'Volver a la tarea',
                      style: AppTypography.bodyMD.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Rechazar tarea
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleReject();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Rechazar tarea',
                      style: AppTypography.bodyMD.copyWith(
                          color: AppColors.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReject() async {
    setState(() => _isLoading = true);
    final repo = ref.read(taskDetailRepositoryProvider);
    final success = await repo.rejectTask(task.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(ongoingTasksProvider);
      ref.invalidate(pastTasksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea rechazada')),
      );
      Navigator.of(context).pop(true);
    }
  }

  // ── Helpers ───────────────────────────────────────────

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return DateFormat('dd MMM', 'es').format(date);
  }
}



