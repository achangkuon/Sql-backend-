import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_detail_repository.dart';
import '../../data/repositories/tasks_repository.dart';

class ScheduleTaskScreen extends ConsumerStatefulWidget {
  final TaskModel task;
  /// When true, shows "Reagendar" labels (called from active task screen).
  /// When false, shows "Agendar" labels (called from confirming a new solicitud).
  final bool isRescheduling;

  const ScheduleTaskScreen({
    super.key,
    required this.task,
    this.isRescheduling = false,
  });

  @override
  ConsumerState<ScheduleTaskScreen> createState() => _ScheduleTaskScreenState();
}

class _ScheduleTaskScreenState extends ConsumerState<ScheduleTaskScreen> {
  late DateTime _selectedDate;
  int _hours = 4;
  int _minutes = 0;
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.task.preferredDate ?? DateTime.now().add(const Duration(days: 1));
    if (widget.task.estimatedDurationHours != null) {
      _hours = widget.task.estimatedDurationHours!.toInt();
      _minutes = ((widget.task.estimatedDurationHours! - _hours) * 60).toInt();
    }
    if (widget.task.agreedPrice != null) {
      _priceController.text = widget.task.agreedPrice!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
        ),
        title: Text(
          widget.isRescheduling ? 'Reagendar Tarea' : 'Agendar Tarea',
          style: AppTypography.titleMD,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1: Date Selector ──
                _buildSectionHeader('Seleccionar dia', _monthLabel()),
                const SizedBox(height: 12),
                _buildDateSelector(),

                const SizedBox(height: 32),

                // ── Section 2: Duration ──
                Text('Tiempo estimado',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                _buildDurationSelector(),

                const SizedBox(height: 32),

                // ── Section 3: Price ──
                Text('Fijar tarifa',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                _buildPriceInput(),

                const SizedBox(height: 32),

                // ── Section 4: Task Summary ──
                Text('Resumen de la tarea',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                _buildTaskSummary(),

                const SizedBox(height: 32),

                // ── Save Button ──
                _buildSaveButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left,
            style:
                AppTypography.bodyMD.copyWith(color: AppColors.onSurfaceVariant)),
        Text(right,
            style: AppTypography.bodyMD
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _monthLabel() {
    return DateFormat('MMMM yyyy', 'es').format(_selectedDate);
  }

  Widget _buildDateSelector() {
    // Show 7 days starting from today
    final today = DateTime.now();
    final dates = List.generate(7, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final date = dates[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'es').format(date).toUpperCase(),
                    style: AppTypography.labelSM.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${date.day}',
                    style: AppTypography.titleMD.copyWith(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      children: [
        Expanded(child: _buildCounterCard('HORAS', _hours, (v) {
          setState(() => _hours = v.clamp(0, 24));
        })),
        const SizedBox(width: 16),
        Expanded(child: _buildCounterCard('MINUTOS', _minutes, (v) {
          setState(() => _minutes = (v % 60).clamp(0, 59));
        })),
      ],
    );
  }

  Widget _buildCounterCard(String label, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelSM.copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onChanged(value - (label == 'MINUTOS' ? 15 : 1)),
                child: const Icon(Icons.remove, color: AppColors.primary),
              ),
              const SizedBox(width: 20),
              Text(
                value.toString().padLeft(2, '0'),
                style: AppTypography.headlineSM.copyWith(fontSize: 24),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => onChanged(value + (label == 'MINUTOS' ? 15 : 1)),
                child: const Icon(Icons.add, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
        ],
      ),
      child: TextField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTypography.titleMD.copyWith(fontSize: 20),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20, right: 4),
            child: Text('\$',
                style: AppTypography.titleMD
                    .copyWith(color: AppColors.primary, fontSize: 20)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text('USD / TOTAL',
                style: AppTypography.labelSM),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0),
          hintText: '0.00',
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        ),
      ),
    );
  }

  Widget _buildTaskSummary() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.task.title,
                style: AppTypography.titleMD
                    .copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              widget.task.description,
              style: AppTypography.bodyMD
                  .copyWith(color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: AppColors.background,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.addressLine +
                            (widget.task.city != null
                                ? ', ${widget.task.city}'
                                : ''),
                        style: AppTypography.bodyMD,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ver en el mapa',
                        style: AppTypography.bodyMD.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSave,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
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
                  widget.isRescheduling ? 'Reagendar tarea' : 'Agendar tarea',
                  style: AppTypography.bodyMD.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16),
                ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final price = double.tryParse(_priceController.text) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una tarifa valida')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(taskDetailRepositoryProvider);
    final estimatedHours = _hours + (_minutes / 60);

    final success = await repo.scheduleTask(
      taskId: widget.task.id,
      scheduledDate: _selectedDate,
      estimatedHours: estimatedHours,
      agreedPrice: price,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(ongoingTasksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea agendada exitosamente')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agendar la tarea')),
      );
    }
  }
}



