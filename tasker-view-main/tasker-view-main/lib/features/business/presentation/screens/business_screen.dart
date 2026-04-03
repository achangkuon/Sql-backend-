import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/models/review_model.dart';
import '../widgets/business_analytics_chart.dart';

/// Main screen for the Tasker's financial dashboard ("Mi Negocio").
class BusinessScreen extends ConsumerWidget {
  const BusinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(taskerStatsProvider);
    final reviewsAsync = ref.watch(taskerReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Mi Negocio', style: AppTypography.headlineMD),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Earnings Hero Card ─────────────────────────────────
            statsAsync.when(
              data: (stats) {
                final earnings = stats?.totalEarnings ?? 0.0;
                final tier = stats?.tier.toUpperCase() ?? 'NEW';
                final tasksCompleted = stats?.totalTasksCompleted ?? 0;

                int tasksNeeded = 0;
                String nextTier = '';
                if (tier == 'NEW') {
                  tasksNeeded = (10 - tasksCompleted).clamp(0, 10);
                  nextTier = 'STANDARD';
                } else if (tier == 'STANDARD') {
                  tasksNeeded = (30 - tasksCompleted).clamp(0, 30);
                  nextTier = 'PRO';
                } else if (tier == 'PRO') {
                  tasksNeeded = (100 - tasksCompleted).clamp(0, 100);
                  nextTier = 'PLATINUM';
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${earnings.toStringAsFixed(2)}',
                        style: AppTypography.displayMD.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TOTAL RECAUDADO',
                        style: AppTypography.labelSM.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nivel Actual: $tier',
                            style: AppTypography.bodyMD.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tier,
                              style: AppTypography.labelSM.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (tier != 'PLATINUM') ...[
                        const SizedBox(height: 10),
                        Text(
                          '$tasksNeeded trabajos más para alcanzar $nextTier.',
                          style: AppTypography.bodySM.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),

            const SizedBox(height: 24),

            // ── Analytics Chart (Bar / Pie toggle) ────────────────
            const BusinessAnalyticsChart(),

            const SizedBox(height: 24),

            // ── Financial Breakdown (Invoice style) ───────────────
            Text('Desglose financiero', style: AppTypography.headlineMD),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (stats) {
                final gross = stats?.totalEarnings ?? 0.0;
                final tips = gross * 0.08;
                final net = gross + tips;
                return _buildInvoiceCard(
                  gross: gross,
                  tips: tips,
                  net: net,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // ── Reviews ──────────────────────────────────────────
            Text('Reseñas de clientes', style: AppTypography.headlineMD),
            const SizedBox(height: 12),
            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star_outline_rounded,
                          size: 40,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aún no tienes reseñas.',
                          style: AppTypography.bodyMD.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children:
                      reviews
                          .map((r) => _buildReviewCard(r))
                          .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Text('Error al cargar reseñas.'),
            ),

            const SizedBox(height: 24),

            // ── Financial Navigation Links ─────────────────────────
            _buildFinancialNav(
              Icons.account_balance_wallet_outlined,
              'Retiros y Pagos',
            ),
            const SizedBox(height: 10),
            _buildFinancialNav(
              Icons.receipt_long_outlined,
              'Historial de Transacciones',
            ),
            const SizedBox(height: 10),
            _buildFinancialNav(
              Icons.bar_chart_rounded,
              'Estadísticas Financieras',
            ),
          ],
        ),
      ),
    );
  }

  /// Navigation row for financial actions.
  Widget _buildFinancialNav(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTypography.bodyMD),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  /// Invoice-style receipt card showing earning breakdown.
  Widget _buildInvoiceCard({
    required double gross,
    required double tips,
    required double net,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header of the invoice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen del período',
                  style: AppTypography.bodyMD.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Este mes',
                  style: AppTypography.labelSM.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Invoice line items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildInvoiceLine(
                  label: 'Servicios realizados',
                  amount: gross,
                  isTotal: false,
                ),
                _buildDivider(),
                _buildInvoiceLine(
                  label: 'Propinas recibidas',
                  amount: tips,
                  isTotal: false,
                  amountColor: AppColors.success,
                  prefix: '+',
                ),
                // Dashed separator before total
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildDashedDivider(),
                ),
                _buildInvoiceLine(
                  label: 'Neto a cobrar',
                  amount: net,
                  isTotal: true,
                  amountColor: AppColors.primary,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single line in the invoice.
  Widget _buildInvoiceLine({
    required String label,
    required double amount,
    bool isTotal = false,
    Color? amountColor,
    String prefix = '',
  }) {
    final effectiveColor = amountColor ?? AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                isTotal
                    ? AppTypography.bodyMD.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    )
                    : AppTypography.bodyMD.copyWith(
                      color: AppColors.textSecondary,
                    ),
          ),
          Text(
            '$prefix\$${amount.toStringAsFixed(2)}',
            style:
                isTotal
                    ? AppTypography.headlineMD.copyWith(color: effectiveColor)
                    : AppTypography.bodyMD.copyWith(color: effectiveColor),
          ),
        ],
      ),
    );
  }

  /// Thin separator used between regular invoice lines.
  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.surfaceContainerHigh,
    );
  }

  /// Dashed separator used above the total line.
  Widget _buildDashedDivider() {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const gapWidth = 4.0;
          final count =
              (constraints.maxWidth / (dashWidth + gapWidth)).floor();
          return Row(
            children: List.generate(count, (_) {
              return Padding(
                padding: const EdgeInsets.only(right: gapWidth),
                child: Container(
                  width: dashWidth,
                  height: 1,
                  color: AppColors.outlineVariant,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// Review card with stars and quoted comment.
  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar placeholder circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente verificado',
                    style: AppTypography.bodyMD.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Star rating row
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.warning,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${review.comment}"',
            style: AppTypography.bodyMD.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
