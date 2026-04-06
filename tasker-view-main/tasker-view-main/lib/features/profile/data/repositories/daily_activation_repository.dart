import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';

final dailyActivationRepositoryProvider =
    Provider<DailyActivationRepository>((ref) {
  return DailyActivationRepository(ref.read(supabaseProvider));
});

class DailyActivationRepository {
  final SupabaseClient _supabase;

  DailyActivationRepository(this._supabase);

  /// Returns the authenticated user's UUID from auth.users.
  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Tasker Profile Helper ─────────────────────────────────────────────────────

  /// Returns the tasker_profiles.id for the current user.
  /// availability_blocks.tasker_id → tasker_profiles.id (NOT profiles.id).
  Future<String?> _getTaskerProfileId() async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final res = await _supabase
          .from('tasker_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return res?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Availability ──────────────────────────────────────────────────────────────

  /// Fetches the hours (0-23) the tasker has marked available today.
  Future<List<int>> getTodaySelectedHours() async {
    final taskerProfileId = await _getTaskerProfileId();
    if (taskerProfileId == null) return [];
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
    final endOfDay =
        DateTime(today.year, today.month, today.day, 23, 59, 59)
            .toUtc()
            .toIso8601String();
    try {
      final response = await _supabase
          .from('availability_blocks')
          .select('start_time')
          .eq('tasker_id', taskerProfileId)
          .eq('block_type', 'available')
          .gte('start_time', startOfDay)
          .lte('start_time', endOfDay);
      return (response as List<dynamic>)
          .map((e) =>
              DateTime.parse(e['start_time'] as String).toLocal().hour)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Replaces todays availability blocks with the given [selectedHours].
  Future<void> saveAvailabilityHours(List<int> selectedHours) async {
    final taskerProfileId = await _getTaskerProfileId();
    if (taskerProfileId == null) return;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
    final endOfDay =
        DateTime(today.year, today.month, today.day, 23, 59, 59)
            .toUtc()
            .toIso8601String();

    // Delete existing blocks for today before re-inserting.
    await _supabase
        .from('availability_blocks')
        .delete()
        .eq('tasker_id', taskerProfileId)
        .eq('block_type', 'available')
        .gte('start_time', startOfDay)
        .lte('start_time', endOfDay);

    if (selectedHours.isEmpty) return;

    final blocks = selectedHours.map((hour) {
      final startTime =
          DateTime(today.year, today.month, today.day, hour).toUtc();
      final endTime =
          DateTime(today.year, today.month, today.day, hour + 1).toUtc();
      return {
        'tasker_id': taskerProfileId,
        'title': 'Disponible',
        'block_type': 'available',
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'is_recurring': false,
      };
    }).toList();

    await _supabase.from('availability_blocks').insert(blocks);
  }

  // ── Skills ────────────────────────────────────────────────────────────────────

  /// Fetches the tasker's selected skill IDs from the `tasker_skills` join table.
  /// Returns the subcategory slug strings stored as the skill identifiers.
  Future<List<String>> getSelectedSkills() async {
    final taskerProfileId = await _getTaskerProfileId();
    if (taskerProfileId == null) return [];
    try {
      // tasker_skills → subcategories(slug) is the correct relation per schema.
      final res = await _supabase
          .from('tasker_skills')
          .select('subcategories(slug)')
          .eq('tasker_id', taskerProfileId);

      return (res as List<dynamic>)
          .map((row) {
            final sub = row['subcategories'];
            if (sub == null) return null;
            return sub['slug'] as String?;
          })
          .whereType<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves the selected skills by upserting rows in `tasker_skills`.
  /// [skills] contains subcategory slugs (e.g. 'limpieza', 'pintura').
  Future<void> saveSkills(List<String> skills) async {
    final taskerProfileId = await _getTaskerProfileId();
    if (taskerProfileId == null) return;

    // Fetch subcategory IDs for the given slugs.
    final subcategoryRows = await _supabase
        .from('subcategories')
        .select('id, slug')
        .inFilter('slug', skills);

    final slugToId = {
      for (final row in (subcategoryRows as List<dynamic>))
        row['slug'] as String: row['id'] as String,
    };

    // Delete existing skill rows for this tasker to start fresh.
    await _supabase
        .from('tasker_skills')
        .delete()
        .eq('tasker_id', taskerProfileId);

    if (skills.isEmpty) return;

    final rows = skills
        .where((slug) => slugToId.containsKey(slug))
        .map((slug) => {
              'tasker_id': taskerProfileId,
              'subcategory_id': slugToId[slug],
            })
        .toList();

    if (rows.isNotEmpty) {
      await _supabase.from('tasker_skills').insert(rows);
    }
  }

  // ── Work Zone ─────────────────────────────────────────────────────────────────

  /// Returns the tasker's service radius in km, or null if not set.
  Future<double?> getServiceRadius() async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final res = await _supabase
          .from('tasker_profiles')
          .select('service_radius_km')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && res['service_radius_km'] != null) {
        return (res['service_radius_km'] as num).toDouble();
      }
    } catch (_) {}
    return null;
  }

  /// Persists the service radius [radiusKm] to the tasker_profiles table.
  Future<void> saveServiceRadius(double radiusKm) async {
    final userId = _userId;
    if (userId == null) return;
    await _supabase.from('tasker_profiles').upsert(
      {'user_id': userId, 'service_radius_km': radiusKm},
      onConflict: 'user_id',
    );
  }

  // ── Completion Status ─────────────────────────────────────────────────────────

  /// Returns a map indicating which daily-activation steps are complete.
  Future<Map<String, bool>> getCompletionStatus() async {
    final results = await Future.wait([
      getTodaySelectedHours(),
      getSelectedSkills(),
      getServiceRadius(),
    ]);
    return {
      'availability': (results[0] as List).isNotEmpty,
      'skills': (results[1] as List).isNotEmpty,
      'workZone': results[2] != null,
    };
  }
}



