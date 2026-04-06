import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/models/profile_model.dart';
import '../models/task_model.dart';
import '../models/message_model.dart';

// ──────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────

final taskDetailRepositoryProvider = Provider<TaskDetailRepository>((ref) {
  return TaskDetailRepository(ref.watch(supabaseProvider));
});

/// Provider to fetch a single task by ID
final taskByIdProvider =
    FutureProvider.family<TaskModel?, String>((ref, taskId) async {
  final repo = ref.watch(taskDetailRepositoryProvider);
  return repo.getTaskById(taskId);
});

/// Provider to fetch the client profile for a task
final clientProfileProvider =
    FutureProvider.family<ProfileModel?, String>((ref, clientId) async {
  final repo = ref.watch(taskDetailRepositoryProvider);
  return repo.getProfileById(clientId);
});

/// Provider to get the conversation for a task
final conversationProvider =
    FutureProvider.family<ConversationModel?, String>((ref, taskId) async {
  final repo = ref.watch(taskDetailRepositoryProvider);
  return repo.getConversation(taskId);
});

/// Provider to get messages for a conversation
final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
  final repo = ref.watch(taskDetailRepositoryProvider);
  return repo.watchMessages(conversationId);
});

/// Provider to get the review for a task (tasker as reviewee)
final taskReviewProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, taskId) async {
  final repo = ref.watch(taskDetailRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  return repo.getTaskReview(taskId, user.id);
});

// ──────────────────────────────────────────────────────────
// Repository
// ──────────────────────────────────────────────────────────

class TaskDetailRepository {
  final SupabaseClient _supabase;

  TaskDetailRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Task CRUD ─────────────────────────────────────────

  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final data = await _supabase
          .from('tasks')
          .select()
          .eq('id', taskId)
          .single();
      return TaskModel.fromJson(data);
    } catch (e) {
      debugPrint('Error getTaskById: $e');
      return null;
    }
  }

  Future<ProfileModel?> getProfileById(String profileId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', profileId)
          .single();
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('Error getProfileById: $e');
      return null;
    }
  }

  // ── Task Actions ──────────────────────────────────────

  /// Confirm (accept) a task — status goes to 'confirmed'
  Future<bool> confirmTask(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'status': 'confirmed',
        'assigned_tasker_id': _userId,
        'confirmed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', taskId);
      return true;
    } catch (e) {
      debugPrint('Error confirmTask: $e');
      return false;
    }
  }

  /// Reject a task — status goes to 'published' (releases it back)
  Future<bool> rejectTask(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'status': 'published',
        'assigned_tasker_id': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', taskId);
      return true;
    } catch (e) {
      debugPrint('Error rejectTask: $e');
      return false;
    }
  }

  /// Start working on a task — status goes to 'in_progress'
  Future<bool> startTask(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'status': 'in_progress',
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', taskId);
      return true;
    } catch (e) {
      debugPrint('Error startTask: $e');
      return false;
    }
  }

  /// Complete a task — status goes to 'pending_review'
  Future<bool> completeTask(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'status': 'pending_review',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', taskId);
      return true;
    } catch (e) {
      debugPrint('Error completeTask: $e');
      return false;
    }
  }

  /// Schedule (or reschedule) a task — updates date, duration, price and confirms it
  Future<bool> scheduleTask({
    required String taskId,
    required DateTime scheduledDate,
    required double estimatedHours,
    required double agreedPrice,
  }) async {
    try {
      final platformFee = agreedPrice * 0.15; // 15% Trust Fee
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('tasks').update({
        'preferred_date': scheduledDate.toIso8601String().split('T').first,
        'estimated_duration_hours': estimatedHours,
        'agreed_price': agreedPrice,
        'platform_fee': platformFee,
        'total_price': agreedPrice + platformFee,
        'status': 'confirmed',
        'assigned_tasker_id': _userId,
        'confirmed_at': now,
        'updated_at': now,
      }).eq('id', taskId);
      return true;
    } catch (e) {
      debugPrint('Error scheduleTask: $e');
      return false;
    }
  }

  /// Cancel a task from tasker side
  Future<bool> cancelTask(String taskId, String reason) async {
    try {
      await _supabase.from('tasks').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toUtc().toIso8601String(),
        'cancellation_reason': reason,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', taskId);
      return true;
    } catch (e) {
      debugPrint('Error cancelTask: $e');
      return false;
    }
  }

  // ── Conversation & Messages ───────────────────────────

  Future<ConversationModel?> getConversation(String taskId) async {
    try {
      final data = await _supabase
          .from('conversations')
          .select()
          .eq('task_id', taskId)
          .maybeSingle();
      if (data == null) return null;
      return ConversationModel.fromJson(data);
    } catch (e) {
      debugPrint('Error getConversation: $e');
      return null;
    }
  }

  /// Create a new conversation for a task if none exists.
  /// Works for pre-confirmation chats (nueva solicitud) and post-confirmation.
  Future<ConversationModel?> getOrCreateConversation(
      String taskId, String clientId) async {
    try {
      // Return existing conversation if found
      final existing = await getConversation(taskId);
      if (existing != null) return existing;

      // Attempt 1: insert with tasker_id (works if RLS allows it)
      try {
        final data = await _supabase
            .from('conversations')
            .insert({
              'task_id': taskId,
              'client_id': clientId,
              'tasker_id': _userId,
            })
            .select()
            .single();
        return ConversationModel.fromJson(data);
      } catch (e1) {
        debugPrint('getOrCreateConversation attempt 1 failed: $e1');
        // Attempt 2: insert without tasker_id (pre-confirmation fallback)
        final data = await _supabase
            .from('conversations')
            .insert({
              'task_id': taskId,
              'client_id': clientId,
            })
            .select()
            .single();
        return ConversationModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error getOrCreateConversation: $e');
      return null;
    }
  }

  /// Stream messages for a conversation (real-time)
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) =>
            rows.map((r) => MessageModel.fromJson(r)).toList());
  }

  /// Send a text message
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _userId,
        'content': content,
      });
      return true;
    } catch (e) {
      debugPrint('Error sendMessage: $e');
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', _userId ?? '')
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error markMessagesAsRead: $e');
    }
  }

  // ── Reviews ───────────────────────────────────────────

  Future<Map<String, dynamic>?> getTaskReview(
      String taskId, String revieweeId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select('*, profiles!reviewer_id(full_name, avatar_url)')
          .eq('task_id', taskId)
          .eq('reviewee_id', revieweeId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Error getTaskReview: $e');
      return null;
    }
  }
}



