import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/availability_block_model.dart';
import '../../data/repositories/calendar_repository.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dailyBlocksAsync = ref.watch(dailyBlocksProvider(selectedDate));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Calendario', style: AppTypography.headlineMD),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'Gestiona tu disponibilidad',
              style: AppTypography.displaySM,
            ),
          ),
          _buildWeeklySelector(context, ref, selectedDate),
          const SizedBox(height: 16),
          Expanded(
            child: dailyBlocksAsync.when(
              data: (blocks) => _buildBlocksList(blocks),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error: $error', style: AppTypography.bodyMD.copyWith(color: AppColors.error)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBlockModal(context, ref, selectedDate),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWeeklySelector(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    // Generate dates: 3 days before, today, 3 days after relative to the *currently selected* date or just scrollable.
    // Let's create a scrollable list starting from today extending 30 days.
    final today = DateTime.now();
    final dates = List.generate(30, (index) => today.add(Duration(days: index)));

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return GestureDetector(
            onTap: () => ref.read(selectedDateProvider.notifier).setDate(date),
            child: Container(
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'es').format(date).toUpperCase(),
                    style: AppTypography.labelMD.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${date.day}',
                    style: AppTypography.headlineMD.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
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

  Widget _buildBlocksList(List<AvailabilityBlockModel> blocks) {
    if (blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: AppColors.textSecondary.withAlpha(128)),
            const SizedBox(height: 16),
            Text(
              'No tienes bloques programados\npara este día.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMD,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: blocks.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final block = blocks[index];
        return _BlockCard(block: block);
      },
    );
  }

  void _showAddBlockModal(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddBlockBottomSheet(
        selectedDate: selectedDate,
        onAdd: (title, type, start, end) async {
          final repo = ref.read(calendarRepositoryProvider);
          await repo.createBlock(
            title: title,
            blockType: type,
            startTime: start,
            endTime: end,
          );
          // Refresh list
          ref.invalidate(dailyBlocksProvider(selectedDate));
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  final AvailabilityBlockModel block;

  const _BlockCard({required this.block});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on block type
    Color badgeColor;
    Color badgeBgColor;
    switch (block.blockType) {
      case 'available':
        badgeColor = AppColors.success;
        badgeBgColor = AppColors.success.withAlpha(26);
        break;
      case 'busy':
        badgeColor = AppColors.error;
        badgeBgColor = AppColors.error.withAlpha(26);
        break;
      case 'personal':
      default:
        badgeColor = AppColors.primary;
        badgeBgColor = AppColors.primary.withAlpha(26);
        break;
    }

    final formatTime = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              block.blockType.toUpperCase(),
              style: AppTypography.labelSM.copyWith(color: badgeColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: AppTypography.headlineMD,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${formatTime.format(block.startTime)} - ${formatTime.format(block.endTime)}',
                      style: AppTypography.bodySM,
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
}

// Bottom sheet formulary component
class _AddBlockBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Function(String title, String type, DateTime start, DateTime end) onAdd;

  const _AddBlockBottomSheet({required this.selectedDate, required this.onAdd});

  @override
  State<_AddBlockBottomSheet> createState() => _AddBlockBottomSheetState();
}

class _AddBlockBottomSheetState extends State<_AddBlockBottomSheet> {
  final _titleController = TextEditingController();
  String _selectedType = 'busy';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  bool _isLoading = false;

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final start = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    try {
      await widget.onAdd(_titleController.text.trim(), _selectedType, start, end);
    } catch (e) {
       // Ideally show error toast
       setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Añadir Bloque', style: AppTypography.displaySM),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Ej. Cita Médica',
              filled: true,
              fillColor: AppColors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            value: _selectedType,
            isExpanded: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'available', child: Text('Disponible')),
              DropdownMenuItem(value: 'busy', child: Text('Ocupado')),
              DropdownMenuItem(value: 'personal', child: Text('Personal')),
            ],
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: _startTime);
                    if (time != null) setState(() => _startTime = time);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('Inicio: ${_startTime.format(context)}', style: AppTypography.bodyMD),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: _endTime);
                    if (time != null) setState(() => _endTime = time);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('Fin: ${_endTime.format(context)}', style: AppTypography.bodyMD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar Bloque', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
