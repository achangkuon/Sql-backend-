import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../data/models/task_model.dart';
import 'task_detail_screen.dart';
import 'active_task_screen.dart';
import 'task_summary_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _tabIndex = 0; // 0 = En Curso, 1 = Pasadas

  @override
  Widget build(BuildContext context) {
    final ongoingAsync = ref.watch(ongoingTasksProvider);
    final solicitudesAsync = ref.watch(newSolicitudesProvider);
    final pastAsync = ref.watch(pastTasksProvider);

    final pendingCount = (ongoingAsync.asData?.value.length ?? 0) +
        (solicitudesAsync.asData?.value.length ?? 0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            _buildHeader(pendingCount),
            const SizedBox(height: 16),
            // ── Pill Tabs ───────────────────────────────────
            _buildPillTabs(),
            const SizedBox(height: 8),
            // ── Content ─────────────────────────────────────
            Expanded(
              child: _tabIndex == 0
                  ? _OngoingView(
                      ongoingAsync: ongoingAsync,
                      solicitudesAsync: solicitudesAsync,
                    )
                  : _PastView(pastAsync: pastAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Tareas', style: AppTypography.headlineMD.copyWith(fontSize: 28)),
          if (pendingCount > 0)
            Text(
              '$pendingCount PENDIENTES',
              style: AppTypography.labelSM.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPillTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildPillTab('EN CURSO', 0),
            _buildPillTab('PASADAS', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab(String label, int index) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelMD.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Ongoing View (Activas + Nuevas Solicitudes)
// ═══════════════════════════════════════════════════════════════

class _OngoingView extends StatelessWidget {
  final AsyncValue<List<TaskModel>> ongoingAsync;
  final AsyncValue<List<TaskModel>> solicitudesAsync;

  const _OngoingView({
    required this.ongoingAsync,
    required this.solicitudesAsync,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = ongoingAsync.isLoading || solicitudesAsync.isLoading;
    final hasError = ongoingAsync.hasError || solicitudesAsync.hasError;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError) {
      return Center(child: Text('Error al cargar tareas', style: AppTypography.bodyMD));
    }

    final activeTasks = ongoingAsync.asData?.value ?? [];
    final solicitudes = solicitudesAsync.asData?.value ?? [];

    if (activeTasks.isEmpty && solicitudes.isEmpty) {
      return Center(
        child: Text('No tienes tareas activas',
            style: AppTypography.bodyMD.copyWith(color: AppColors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      children: [
        // ── Activas ahora ──────────────────────────────────
        if (activeTasks.isNotEmpty) ...[
          Text('Activas ahora',
              style: AppTypography.titleMD.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...activeTasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TaskCard(task: t, cardType: _CardType.active),
              )),
          const SizedBox(height: 20),
        ],

        // ── Nuevas solicitudes ─────────────────────────────
        if (solicitudes.isNotEmpty) ...[
          Row(
            children: [
              Text('Nuevas solicitudes',
                  style:
                      AppTypography.titleMD.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.urgent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${solicitudes.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Text('Ver todas',
                  style: AppTypography.bodyMD.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...solicitudes.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TaskCard(task: t, cardType: _CardType.solicitud),
              )),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Past View
// ═══════════════════════════════════════════════════════════════

class _PastView extends StatelessWidget {
  final AsyncValue<List<TaskModel>> pastAsync;

  const _PastView({required this.pastAsync});

  @override
  Widget build(BuildContext context) {
    return pastAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Text('No tienes tareas pasadas',
                style: AppTypography.bodyMD
                    .copyWith(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, i) =>
              _TaskCard(task: tasks[i], cardType: _CardType.past),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Task Card
// ═══════════════════════════════════════════════════════════════

enum _CardType { active, solicitud, past }

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final _CardType cardType;

  const _TaskCard({required this.task, required this.cardType});

  Color get _borderColor {
    switch (cardType) {
      case _CardType.active:
        return AppColors.primary;
      case _CardType.solicitud:
        return const Color(0xFFFF5C3A);
      case _CardType.past:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigate(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: _borderColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left side ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    task.title,
                    style: AppTypography.titleMD
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Dynamic badge area
                  _buildDynamicBadge(),
                  const SizedBox(height: 10),

                  // Info chips row
                  _buildInfoChips(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Right side ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (cardType == _CardType.past) ...[
                  Text(
                    'TOTAL RECAUDADO',
                    style: AppTypography.labelSM.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${task.agreedPrice?.toStringAsFixed(2) ?? '0.00'} USD',
                    style: AppTypography.titleMD.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ] else ...[
                  Text(
                    '\$${task.agreedPrice?.toStringAsFixed(2) ?? '0.00'}',
                    style: AppTypography.headlineMD.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'ESTIMADO',
                    style: AppTypography.labelSM.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Client avatar
                _buildClientAvatar(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBadge() {
    switch (cardType) {
      case _CardType.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'EN CURSO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case _CardType.solicitud:
        return _CountdownBadge(task: task);
      case _CardType.past:
        return Row(
          children: [
            const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Duracion: ${task.estimatedDurationLabel.isNotEmpty ? task.estimatedDurationLabel : 'N/A'}',
              style: AppTypography.labelMD.copyWith(fontSize: 12),
            ),
          ],
        );
    }
  }

  Widget _buildInfoChips() {
    final date = task.preferredDate ?? task.createdAt;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1;

    String dateLabel;
    if (isToday) {
      dateLabel = 'HOY';
    } else if (isTomorrow) {
      dateLabel = 'MANANA';
    } else {
      dateLabel = DateFormat('dd MMM').format(date).toUpperCase();
    }

    final timeLabel = task.preferredTime ?? DateFormat('h:mm a').format(date);
    final locationLabel = task.city ?? task.addressLine.split(',').first;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _InfoChip(icon: Icons.calendar_today, label: dateLabel),
        _InfoChip(icon: Icons.schedule, label: timeLabel),
        _InfoChip(icon: Icons.near_me, label: locationLabel),
      ],
    );
  }

  Widget _buildClientAvatar() {
    // Show initials-based avatar
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.surfaceContainerHigh,
      child: const Icon(Icons.person, size: 14, color: AppColors.primary),
    );
  }

  void _navigate(BuildContext context) {
    Widget screen;
    switch (cardType) {
      case _CardType.active:
        screen = ActiveTaskScreen(task: task);
        break;
      case _CardType.solicitud:
        screen = TaskDetailScreen(task: task);
        break;
      case _CardType.past:
        screen = TaskSummaryScreen(task: task);
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

// ── Info Chip ────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Countdown Badge for solicitudes ─────────────────────────

class _CountdownBadge extends StatefulWidget {
  final TaskModel task;

  const _CountdownBadge({required this.task});

  @override
  State<_CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<_CountdownBadge> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    // Calculate remaining time from when the task was published/created
    // Tasker has 60 minutes to respond
    final publishedAt = widget.task.publishedAt ?? widget.task.createdAt;
    final deadline = publishedAt.add(const Duration(minutes: 60));
    _remaining = deadline.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining - const Duration(seconds: 1);
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final label = _remaining == Duration.zero
        ? 'TIEMPO AGOTADO'
        : 'RESPONDE EN $minutes MIN';

    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: _remaining.inMinutes < 10
            ? AppColors.error
            : const Color(0xFFEF4444),
        letterSpacing: -0.3,
      ),
    );
  }
}
