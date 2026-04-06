import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../models/tasker_stats_model.dart';
import '../models/review_model.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(ref.watch(supabaseProvider));
});

final taskerStatsProvider = FutureProvider<TaskerStatsModel?>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  return repo.getTaskerStats(user.id);
});

final taskerReviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return [];
  return repo.getTaskerReviews(user.id);
});

class BusinessRepository {
  final SupabaseClient _supabase;
  BusinessRepository(this._supabase);

  Future<TaskerStatsModel?> getTaskerStats(String userId) async {
    try {
      final response = await _supabase
          .from('tasker_profiles')
          .select('total_earnings, tier, total_tasks_completed')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return TaskerStatsModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getTaskerStats: $e');
      return null;
    }
  }

  Future<List<ReviewModel>> getTaskerReviews(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('comment, rating')
          .eq('reviewee_id', userId)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(10);

      final list = List<Map<String, dynamic>>.from(response);
      return list.map((e) => ReviewModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getTaskerReviews: $e');
      return [];
    }
  }
}



