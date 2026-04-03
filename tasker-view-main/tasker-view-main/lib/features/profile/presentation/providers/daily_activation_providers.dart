import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/daily_activation_repository.dart';

// ── Completion status ─────────────────────────────────────────────────────────

final activationCompletionProvider =
    FutureProvider<Map<String, bool>>((ref) async {
  final repo = ref.read(dailyActivationRepositoryProvider);
  return repo.getCompletionStatus();
});

// ── Availability hours ────────────────────────────────────────────────────────

class AvailabilityHoursNotifier extends AsyncNotifier<List<int>> {
  @override
  Future<List<int>> build() async {
    final repo = ref.read(dailyActivationRepositoryProvider);
    return repo.getTodaySelectedHours();
  }

  void toggle(int hour) {
    final current = state.asData?.value ?? [];
    if (current.contains(hour)) {
      state = AsyncData(current.where((h) => h != hour).toList());
    } else {
      state = AsyncData([...current, hour]..sort());
    }
  }

  Future<void> save() async {
    final hours = state.asData?.value ?? [];
    final repo = ref.read(dailyActivationRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.saveAvailabilityHours(hours);
      state = AsyncData(hours);
      ref.invalidate(activationCompletionProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final availabilityHoursProvider =
    AsyncNotifierProvider<AvailabilityHoursNotifier, List<int>>(
  AvailabilityHoursNotifier.new,
);

// ── Skills ────────────────────────────────────────────────────────────────────

class SkillsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final repo = ref.read(dailyActivationRepositoryProvider);
    return repo.getSelectedSkills();
  }

  void toggle(String skill) {
    final current = state.asData?.value ?? [];
    if (current.contains(skill)) {
      state = AsyncData(current.where((s) => s != skill).toList());
    } else {
      state = AsyncData([...current, skill]);
    }
  }

  Future<void> save() async {
    final skills = state.asData?.value ?? [];
    final repo = ref.read(dailyActivationRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.saveSkills(skills);
      state = AsyncData(skills);
      ref.invalidate(activationCompletionProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final skillsProvider =
    AsyncNotifierProvider<SkillsNotifier, List<String>>(
  SkillsNotifier.new,
);

// ── Work zone radius ──────────────────────────────────────────────────────────

class WorkZoneNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() async {
    final repo = ref.read(dailyActivationRepositoryProvider);
    return (await repo.getServiceRadius()) ?? 15.0;
  }

  void setRadius(double radius) {
    state = AsyncData(radius);
  }

  Future<void> save() async {
    final radius = state.asData?.value ?? 15.0;
    final repo = ref.read(dailyActivationRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.saveServiceRadius(radius);
      state = AsyncData(radius);
      ref.invalidate(activationCompletionProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final workZoneProvider =
    AsyncNotifierProvider<WorkZoneNotifier, double>(
  WorkZoneNotifier.new,
);
