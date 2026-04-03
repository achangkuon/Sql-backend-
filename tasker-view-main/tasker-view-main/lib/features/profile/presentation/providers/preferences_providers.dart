import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';

final taskerOnlineStatusProvider = AsyncNotifierProvider<TaskerOnlineStatusNotifier, bool>(() {
  return TaskerOnlineStatusNotifier();
});

class TaskerOnlineStatusNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final client = ref.read(supabaseProvider);
    final user = client.auth.currentUser;
    if (user == null) return false;

    // Obtener estado inicial desde Profiles/tasker_profiles
    try {
      final res = await client
          .from('tasker_profiles') 
          .select('is_online')
          .eq('user_id', user.id)
          .maybeSingle();

      if (res != null && res['is_online'] != null) {
        return res['is_online'] as bool;
      }
    } catch (_) {}

    return false; // Valor por defecto
  }

  Future<void> toggleOnlineStatus(bool newValue) async {
    final client = ref.read(supabaseProvider);
    final user = client.auth.currentUser;
    if (user == null) return;

    // Actualización optimista de estado
    state = AsyncData(newValue);

    try {
      // Modificar el campo en la BD (tasker_profiles como lo solicitó el usuario)
      await client
          .from('tasker_profiles')
          .update({'is_online': newValue})
          .eq('user_id', user.id);
    } catch (e) {
      // Si falla, revertir el switch
      state = AsyncData(!newValue);
    }
  }
}
