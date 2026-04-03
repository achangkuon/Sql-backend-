import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';

enum ChartPeriod { weekly, monthly }

class ChartPeriodNotifier extends Notifier<ChartPeriod> {
  @override
  ChartPeriod build() => ChartPeriod.weekly;
  void setPeriod(ChartPeriod p) => state = p;
}

final chartPeriodProvider = NotifierProvider<ChartPeriodNotifier, ChartPeriod>(ChartPeriodNotifier.new);

class BusinessAnalyticsChart extends ConsumerWidget {
  const BusinessAnalyticsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(chartPeriodProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  period == ChartPeriod.weekly ? 'Análisis Semanal' : 'Análisis Mensual',
                  style: AppTypography.headlineMD,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Segmented Button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildSegmentButton(
                      'Sem', 
                      period == ChartPeriod.weekly, 
                      () => ref.read(chartPeriodProvider.notifier).setPeriod(ChartPeriod.weekly)
                    ),
                    const SizedBox(width: 4),
                    _buildSegmentButton(
                      'Mes', 
                      period == ChartPeriod.monthly, 
                      () => ref.read(chartPeriodProvider.notifier).setPeriod(ChartPeriod.monthly)
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: period == ChartPeriod.weekly ? _buildBarChart() : _buildPieChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTypography.labelSM.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.outlineVariant.withAlpha(30),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text('\$${value.toInt()}', style: AppTypography.bodySM.copyWith(color: AppColors.textSecondary, fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Lun'; break;
                  case 1: text = 'Mar'; break;
                  case 2: text = 'Mié'; break;
                  case 3: text = 'Jue'; break;
                  case 4: text = 'Vie'; break;
                  case 5: text = 'Sáb'; break;
                  case 6: text = 'Dom'; break;
                  default: text = ''; break;
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(text, style: style),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeBarData(0, 40),
          _makeBarData(1, 65),
          _makeBarData(2, 30),
          _makeBarData(3, 85),
          _makeBarData(4, 55),
          _makeBarData(5, 90),
          _makeBarData(6, 20),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), // Flat bottom
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: AppColors.surfaceContainerHigh,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: AppColors.primary,
                  value: 60,
                  title: '60%',
                  radius: 20,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: AppColors.success,
                  value: 25,
                  title: '25%',
                  radius: 20,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: AppColors.warning,
                  value: 15,
                  title: '15%',
                  radius: 20,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPieLegend(AppColors.primary, 'Servicios Base'),
              const SizedBox(height: 8),
              _buildPieLegend(AppColors.success, 'Propinas'),
              const SizedBox(height: 8),
              _buildPieLegend(AppColors.warning, 'Cargos Extras'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTypography.bodySM, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
