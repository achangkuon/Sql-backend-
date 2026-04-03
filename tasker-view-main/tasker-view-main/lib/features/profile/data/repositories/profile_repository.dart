import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';

// ── Models ─────────────────────────────────────────────────────────────────

/// Represents a single skill from tasker_skills joined with subcategories.
class TaskerSkillModel {
  final String id;
  final String name;

  const TaskerSkillModel({required this.id, required this.name});

  factory TaskerSkillModel.fromJson(Map<String, dynamic> json) {
    return TaskerSkillModel(
      id: json['id'] as String? ?? '',
      name: (json['subcategories'] as Map<String, dynamic>?)?['name']
              as String? ??
          'Sin nombre',
    );
  }
}

/// Full tasker profile data needed for the profile screen.
class TaskerProfileData {
  final double averageRating;
  final String tier;
  final int totalTasksCompleted;
  final double totalEarnings;
  final String verificationStatus;

  const TaskerProfileData({
    required this.averageRating,
    required this.tier,
    required this.totalTasksCompleted,
    required this.totalEarnings,
    required this.verificationStatus,
  });

  factory TaskerProfileData.fromJson(Map<String, dynamic> json) {
    return TaskerProfileData(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      tier: json['tier'] as String? ?? 'new',
      totalTasksCompleted: json['total_tasks_completed'] as int? ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      verificationStatus:
          json['verification_status'] as String? ?? 'pending',
    );
  }
}

// ── Repository ─────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

final taskerProfileDataProvider =
    FutureProvider<TaskerProfileData?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  return repo.getTaskerProfileData(user.id);
});

final taskerSkillsProvider =
    FutureProvider<List<TaskerSkillModel>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return [];
  return repo.getTaskerSkills(user.id);
});

/// Repository for profile screen data.
class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  /// Fetches tasker profile stats and verification status.
  Future<TaskerProfileData?> getTaskerProfileData(String userId) async {
    try {
      final response = await _supabase
          .from('tasker_profiles')
          .select(
            'average_rating, tier, total_tasks_completed, total_earnings, verification_status',
          )
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      return TaskerProfileData.fromJson(response);
    } catch (e) {
      debugPrint('Error getTaskerProfileData: $e');
      return null;
    }
  }

  /// Fetches the list of skills (subcategory names) for the tasker.
  Future<List<TaskerSkillModel>> getTaskerSkills(String userId) async {
    try {
      // First get the tasker_profile id for this user
      final profileResp = await _supabase
          .from('tasker_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (profileResp == null) return [];

      final taskerId = profileResp['id'] as String;
      final response = await _supabase
          .from('tasker_skills')
          .select('id, subcategories(name)')
          .eq('tasker_id', taskerId)
          .limit(10);

      final list = List<Map<String, dynamic>>.from(response);
      return list.map((e) => TaskerSkillModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getTaskerSkills: $e');
      return [];
    }
  }
}
