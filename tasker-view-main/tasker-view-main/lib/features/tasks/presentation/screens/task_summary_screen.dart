import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_detail_repository.dart';
import '../../../dashboard/presentation/screens/main_dashboard_screen.dart';

class TaskSummaryScreen extends ConsumerWidget {
  final TaskModel task;

  const TaskSummaryScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientProfileProvider(task.clientId));
    final reviewAsync = ref.watch(taskReviewProvider(task.id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text('Resumen de Tarea', style: AppTypography.titleMD),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          children: [
            // ── Status & Title Card ─────────────────────────
            _buildStatusCard(context),
            const SizedBox(height: 16),

            // ── Service Details ──────────────────────────────
            _buildServiceDetailsCard(),
            const SizedBox(height: 16),

            // ── Duration & Client Row ───────────────────────
            Row(
              children: [
                Expanded(child: _buildDurationCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildClientCard(clientAsync)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Client Rating ───────────────────────────────
            _buildRatingCard(reviewAsync),
            const SizedBox(height: 16),

            // ── Billing Section ─────────────────────────────
            _buildBillingCard(),
            const SizedBox(height: 24),

            // ── Action Buttons ──────────────────────────────
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'COMPLETADA',
                      style: AppTypography.labelSM.copyWith(
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  // Synced indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B5E20),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Sincronizado',
                            style: AppTypography.labelSM
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                task.title,
                style: AppTypography.headlineMD.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                'Servicio finalizado con exito',
                style: AppTypography.bodyMD
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETALLES DEL SERVICIO',
              style: AppTypography.labelSM.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  task.description,
                  style: AppTypography.bodyMD.copyWith(height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DURACION',
              style: AppTypography.labelSM.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                task.estimatedDurationLabel.isNotEmpty
                    ? task.estimatedDurationLabel
                    : 'N/A',
                style: AppTypography.bodyMD,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(AsyncValue clientAsync) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLIENTE',
              style: AppTypography.labelSM.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 10),
          clientAsync.when(
            data: (profile) {
              if (profile == null) {
                return Text('Desconocido', style: AppTypography.bodyMD);
              }
              final initials = _getInitials(profile.fullName);
              return Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    child: profile.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(profile.avatarUrl!,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Text(initials,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary))),
                          )
                        : Text(initials,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profile.fullName.split(' ').first +
                          (profile.fullName.split(' ').length > 1
                              ? ' ${profile.fullName.split(' ')[1][0]}.'
                              : ''),
                      style: AppTypography.bodyMD,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, _) => Text('Error', style: AppTypography.bodyMD),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(AsyncValue<Map<String, dynamic>?> reviewAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CALIFICACION DEL CLIENTE',
              style: AppTypography.labelSM.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 14),
          reviewAsync.when(
            data: (review) {
              if (review == null) {
                return Text(
                  'Aun no hay calificacion para esta tarea.',
                  style: AppTypography.bodyMD
                      .copyWith(color: AppColors.textSecondary),
                );
              }
              final rating = review['rating'] as int? ?? 0;
              final comment = review['comment'] as String?;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        color: i < rating
                            ? const Color(0xFFFFB400)
                            : AppColors.surfaceContainerHighest,
                        size: 24,
                      ),
                    ),
                  ),
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"$comment"',
                      style: AppTypography.bodyMD.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const SizedBox(
                height: 24,
                child: Center(child: LinearProgressIndicator())),
            error: (_, _) => Text('Error al cargar resena',
                style: AppTypography.bodyMD
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCard() {
    final subtotal = task.agreedPrice ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Decorative receipt icon
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.receipt_long,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FACTURACION',
                style: AppTypography.labelSM.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildBillingRow(
                  'Subtotal mano de obra', '\$${subtotal.toStringAsFixed(2)}'),
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Final',
                      style: AppTypography.bodyMD
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: AppTypography.titleMD.copyWith(
                      color: AppColors.primary,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppTypography.bodyMD.copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Ver factura
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Factura en desarrollo')),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text('Ver factura',
                  style: AppTypography.bodyMD.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Volver al inicio
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const MainDashboardScreen()),
              (route) => false,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text('Volver al inicio',
                  style: AppTypography.bodyMD.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
