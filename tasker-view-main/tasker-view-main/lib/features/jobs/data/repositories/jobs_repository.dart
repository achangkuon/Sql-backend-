import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../models/available_job_model.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.watch(supabaseProvider));
});

/// Lista de jobs pendientes que el Tasker puede aceptar.
final availableJobsProvider = FutureProvider<List<AvailableJobModel>>((ref) async {
  return ref.watch(jobsRepositoryProvider).getAvailableJobs();
});

class JobsRepository {
  final SupabaseClient _supabase;

  JobsRepository(this._supabase);

  /// Lee todos los jobs con status='pending' ordenados por más reciente.
  Future<List<AvailableJobModel>> getAvailableJobs() async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((e) => AvailableJobModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error en getAvailableJobs: $e');
      return [];
    }
  }

  /// Llama a la función RPC fn_accept_job en Supabase.
  /// Crea el task, vincula el job y notifica al cliente.
  /// Retorna el task_id creado.
  Future<String> acceptJob(String jobId) async {
    final response = await _supabase.rpc(
      'fn_accept_job',
      params: {
        'p_job_id':    jobId,
        'p_tasker_id': _supabase.auth.currentUser!.id,
      },
    );
    return response as String;
  }
}
