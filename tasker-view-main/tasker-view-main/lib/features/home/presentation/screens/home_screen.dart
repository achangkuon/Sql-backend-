import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../tasks/data/repositories/tasks_repository.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../business/data/repositories/business_repository.dart';
import '../../../profile/presentation/screens/preferences_screen.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../tasks/presentation/screens/active_task_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // Space for bottom bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                data: (profile) => _buildHeader(
                  name: profile?.fullName.split(' ').first ?? 'Usuario',
                  initials: _getInitials(profile?.fullName ?? ''),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) =>
                    _buildHeader(name: 'Error', initials: 'ER'),
              ),
              const SizedBox(height: 24),
              profileAsync.when(
                data: (profile) => _buildBanners(
                  profile?.fullName.split(' ').first ?? 'Usuario',
                ),
                loading: () => const SizedBox(height: 180),
                error: (e, s) => const SizedBox(height: 180),
              ),
              const SizedBox(height: 24),
              _buildMetrics(ref),
              const SizedBox(height: 32),
              _buildDailyStatus(context),
              const SizedBox(height: 32),
              _buildOngoingTasks(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'US';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildHeader({required String name, required String initials}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hola, $name',
                style: AppTypography.headlineMD.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanners(String firstName) {
    return SizedBox(
      height: 180,
      child: PageView(
        controller: PageController(viewportFraction: 0.9),
        children: [
          _buildBannerCard(
            title: 'Hola $firstName, aquí está el resumen de hoy.',
            subtitle: 'Tienes tareas urgentes esperando tu respuesta.',
            gradientColors: [const Color(0xFF1A6BFF), const Color(0xFF0053D3)],
          ),
          _buildBannerCard(
            title: '¡Nueva oportunidad!',
            subtitle: 'Hay servicios de limpieza disponibles cerca de ti.',
            gradientColors: [const Color(0xFF5A4FCF), const Color(0xFF4A3FBF)],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard({
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTypography.headlineMD.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMD.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(WidgetRef ref) {
    final pendingCountAsync = ref.watch(todayTasksCountProvider);
    final statsAsync = ref.watch(taskerStatsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          statsAsync.when(
            data: (stats) => _buildMetricCard(
              'Ganado',
              stats != null
                  ? '\$${stats.totalEarnings.toStringAsFixed(0)}'
                  : '\$0',
              AppColors.primary,
            ),
            loading: () => _buildMetricCard('Ganado', '...', AppColors.primary),
            error: (e, s) =>
                _buildMetricCard('Ganado', '\$0', AppColors.primary),
          ),
          statsAsync.when(
            data: (stats) => _buildMetricCard(
              'Hechas',
              stats?.totalTasksCompleted.toString() ?? '0',
              AppColors.success,
            ),
            loading: () => _buildMetricCard('Hechas', '...', AppColors.success),
            error: (e, s) => _buildMetricCard('Hechas', '0', AppColors.success),
          ),
          pendingCountAsync.when(
            data: (count) => _buildMetricCard(
              'Pendientes',
              count.toString(),
              AppColors.warning,
            ),
            loading: () =>
                _buildMetricCard('Pendientes', '-', AppColors.warning),
            error: (e, s) =>
                _buildMetricCard('Pendientes', '0', AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.labelMD.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.headlineMD.copyWith(
                color: valueColor,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado del día',
            style: AppTypography.headlineMD.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.alarm_on_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actívate para recibir tareas',
                            style: AppTypography.labelBold,
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PreferencesScreen(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Configurar preferencias',
                                  style: AppTypography.labelMD.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(height: 1),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.grey[300],
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay tareas programadas para hoy',
                      style: AppTypography.bodyMD.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingTasks(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(ongoingTasksProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tareas en curso',
            style: AppTypography.headlineMD.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No hay tareas en curso actualmente',
                      style: AppTypography.bodyMD.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: tasks.map((task) => _buildTaskItem(task, ctx: context)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error al cargar tareas: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task, {BuildContext? ctx}) {
    return GestureDetector(
      onTap: ctx != null
          ? () {
              Widget screen;
              if (task.status == 'in_progress') {
                screen = ActiveTaskScreen(task: task);
              } else {
                screen = TaskDetailScreen(task: task);
              }
              Navigator.push(
                  ctx, MaterialPageRoute(builder: (_) => screen));
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: task.status == 'in_progress'
                  ? AppColors.primary
                  : Colors.green,
              width: 4,
            ),
          ),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home_repair_service_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppTypography.labelBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.agreedPrice != null)
                        Text(
                          '\$${task.agreedPrice?.toInt()}',
                          style: AppTypography.headlineMD.copyWith(
                            color: AppColors.primary,
                            fontSize: 18,
                          ),
                        )
                      else
                        Text(
                          'Pendiente',
                          style: AppTypography.labelMD.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.addressLine,
                    style: AppTypography.labelMD.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: task.status == 'in_progress'
                              ? const Color(0xFFE8F0FF)
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              task.status == 'in_progress'
                                  ? Icons.sync_rounded
                                  : Icons.check_circle,
                              size: 12,
                              color: task.status == 'in_progress'
                                  ? AppColors.primary
                                  : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.status.toUpperCase(),
                              style: AppTypography.labelMD.copyWith(
                                fontSize: 10,
                                color: task.status == 'in_progress'
                                    ? AppColors.primary
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('dd MMM').format(task.createdAt),
                          style: AppTypography.labelMD.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
