import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../models/task_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(ref.watch(supabaseProvider));
});

final ongoingTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.watch(tasksRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;

  if (user == null) return [];

  return repo.getOngoingTasks(user.id);
});

/// New solicitudes: tasks matched to this tasker but not yet confirmed (published/matched)
final newSolicitudesProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.watch(tasksRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;

  if (user == null) return [];

  return repo.getNewSolicitudes(user.id);
});

final todayTasksCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(tasksRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  
  if (user == null) return 0;
  return repo.getTodayTasksCount(user.id);
});

final pastTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.watch(tasksRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  
  if (user == null) return [];
  
  return repo.getPastTasks(user.id);
});

class TasksRepository {
  final SupabaseClient _supabase;

  TasksRepository(this._supabase);

  Future<List<TaskModel>> getOngoingTasks(String userId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .or('client_id.eq.$userId,assigned_tasker_id.eq.$userId')
          .inFilter('status', ['confirmed', 'in_progress'])
          .order('created_at', ascending: false);

      final tasksList = List<Map<String, dynamic>>.from(response);
      return tasksList.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error en getOngoingTasks: $e');
      return [];
    }
  }

  Future<List<TaskModel>> getPastTasks(String userId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .or('client_id.eq.$userId,assigned_tasker_id.eq.$userId')
          .inFilter('status', ['completed', 'cancelled', 'disputed'])
          .order('created_at', ascending: false);

      final tasksList = List<Map<String, dynamic>>.from(response);
      return tasksList.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error en getPastTasks: $e');
      return [];
    }
  }

  Future<int> getTodayTasksCount(String userId) async {
    try {
      // Simplificado: Tareas con estado 'pending' o 'confirmed' para hoy o después (simulación por ahora)
      final response = await _supabase
          .from('tasks')
          .select('id')
          .or('client_id.eq.$userId,assigned_tasker_id.eq.$userId')
          .inFilter('status', ['published', 'matched', 'confirmed', 'in_progress']);

      return List.from(response).length;
    } catch (e) {
      debugPrint('Error en getTodayTasksCount: $e');
      return 0;
    }
  }

  /// Fetch tasks that are new solicitudes (published/matched) assigned to this tasker
  Future<List<TaskModel>> getNewSolicitudes(String userId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('assigned_tasker_id', userId)
          .inFilter('status', ['published', 'matched'])
          .order('created_at', ascending: false);

      final tasksList = List<Map<String, dynamic>>.from(response);
      return tasksList.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error en getNewSolicitudes: $e');
      return [];
    }
  }

  Future<int> getCompletedTasksCount(String userId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('id')
          .or('client_id.eq.$userId,assigned_tasker_id.eq.$userId')
          .eq('status', 'completed');

      return List.from(response).length;
    } catch (e) {
      return 0;
    }
  }
}



