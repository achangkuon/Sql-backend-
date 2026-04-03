import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/task_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/task_detail_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class TaskChatTab extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskChatTab({super.key, required this.task});

  @override
  ConsumerState<TaskChatTab> createState() => _TaskChatTabState();
}

class _TaskChatTabState extends ConsumerState<TaskChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _conversationId;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  Future<void> _initConversation() async {
    final repo = ref.read(taskDetailRepositoryProvider);
    final conversation = await repo.getOrCreateConversation(
      widget.task.id,
      widget.task.clientId,
    );
    if (!mounted) return;
    setState(() {
      _conversationId = conversation?.id;
      _initializing = false;
    });

    // Mark messages as read
    if (_conversationId != null) {
      repo.markMessagesAsRead(_conversationId!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_conversationId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se pudo iniciar el chat. Intenta confirmar la tarea primero.',
            style: AppTypography.bodyMD.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final messagesAsync = ref.watch(messagesProvider(_conversationId!));
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;

    return Column(
      children: [
        // Service info pill
        _buildServicePill(),

        // Messages list
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48,
                          color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Inicia la conversacion',
                        style: AppTypography.bodyMD
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMine = msg.senderId == currentUserId;

                  // Date separator logic
                  Widget? dateSeparator;
                  if (index == 0 ||
                      !_isSameDay(
                          messages[index - 1].createdAt, msg.createdAt)) {
                    dateSeparator = _buildDateSeparator(msg.createdAt);
                  }

                  return Column(
                    children: [
                      ?dateSeparator,
                      _buildMessageBubble(msg, isMine),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),

        // Chat active indicator
        _buildChatActiveIndicator(),

        // Input bar
        _buildInputBar(),
      ],
    );
  }

  Widget _buildServicePill() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'SERVICIO: ${widget.task.title.toUpperCase()}',
          style: AppTypography.labelSM.copyWith(letterSpacing: 1.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMine ? null : AppColors.surfaceContainerHighest,
                gradient: isMine ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 0),
                  bottomRight: Radius.circular(isMine ? 0 : 14),
                ),
                boxShadow: isMine
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                msg.content ?? '',
                style: AppTypography.bodyMD.copyWith(
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm a').format(msg.createdAt.toLocal()),
                  style: AppTypography.labelSM,
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color:
                        msg.isRead ? AppColors.primary : AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label =
        isToday ? 'Hoy' : DateFormat('dd MMMM yyyy', 'es').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
                height: 1,
                color:
                    AppColors.surfaceContainerHighest.withValues(alpha: 0.3)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label.toUpperCase(),
              style: AppTypography.labelSM.copyWith(letterSpacing: 1.5),
            ),
          ),
          Expanded(
            child: Container(
                height: 1,
                color:
                    AppColors.surfaceContainerHighest.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatActiveIndicator() {
    return Padding(
      padding: const EdgeInsets.only(right: 24, bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
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
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Chat Activo',
                style: AppTypography.labelSM
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          // Camera button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.photo_camera_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),

          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                style: AppTypography.bodyMD,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle:
                      AppTypography.bodyMD.copyWith(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    _controller.clear();
    final repo = ref.read(taskDetailRepositoryProvider);
    await repo.sendMessage(
      conversationId: _conversationId!,
      content: text,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
