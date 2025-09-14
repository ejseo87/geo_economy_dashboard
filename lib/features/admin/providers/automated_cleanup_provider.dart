import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/automated_cleanup_service.dart';

part 'automated_cleanup_provider.g.dart';

/// 자동화된 정리 서비스 프로바이더
@riverpod
AutomatedCleanupService automatedCleanupService(Ref ref) {
  return AutomatedCleanupService.instance;
}

/// 정리 진행 상황 스트림 프로바이더
@riverpod
Stream<CleanupProgress> cleanupProgressStream(Ref ref) {
  final service = ref.watch(automatedCleanupServiceProvider);
  return service.progressStream;
}

/// 자동 정리 활성화 상태 프로바이더
@riverpod
class AutoCleanupEnabled extends _$AutoCleanupEnabled {
  @override
  bool build() => false;

  void toggle() {
    final service = ref.read(automatedCleanupServiceProvider);

    if (state) {
      service.stopAutomatedCleanup();
    } else {
      service.startAutomatedCleanup(
        schedule: CleanupSchedule.daily,
        policy: CleanupPolicy.defaultPolicy(),
      );
    }

    state = !state;
  }

  void enable(CleanupSchedule schedule, CleanupPolicy policy) {
    if (!state) {
      final service = ref.read(automatedCleanupServiceProvider);
      service.startAutomatedCleanup(schedule: schedule, policy: policy);
      state = true;
    }
  }

  void disable() {
    if (state) {
      final service = ref.read(automatedCleanupServiceProvider);
      service.stopAutomatedCleanup();
      state = false;
    }
  }
}

/// 수동 정리 실행 프로바이더
@riverpod
class ManualCleanupExecution extends _$ManualCleanupExecution {
  @override
  AsyncValue<CleanupResult?> build() => const AsyncValue.data(null);

  Future<void> executeCleanup({
    CleanupPolicy? policy,
    List<CleanupType>? specificTypes,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(automatedCleanupServiceProvider);
      final result = await service.executeManualCleanup(
        policy: policy,
        specificTypes: specificTypes,
      );

      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// 정리 정책 설정 프로바이더
@riverpod
class CleanupPolicySettings extends _$CleanupPolicySettings {
  @override
  CleanupPolicy build() => CleanupPolicy.defaultPolicy();

  void updatePolicy(CleanupPolicy policy) {
    state = policy;
  }

  void updateCleanupDuplicates(bool enabled) {
    state = CleanupPolicy(
      cleanupDuplicates: enabled,
      cleanupOrphans: state.cleanupOrphans,
      cleanupOldData: state.cleanupOldData,
      optimizeStorage: state.optimizeStorage,
      oldDataThreshold: state.oldDataThreshold,
      delayBetweenOperations: state.delayBetweenOperations,
      batchSize: state.batchSize,
    );
  }

  void updateCleanupOrphans(bool enabled) {
    state = CleanupPolicy(
      cleanupDuplicates: state.cleanupDuplicates,
      cleanupOrphans: enabled,
      cleanupOldData: state.cleanupOldData,
      optimizeStorage: state.optimizeStorage,
      oldDataThreshold: state.oldDataThreshold,
      delayBetweenOperations: state.delayBetweenOperations,
      batchSize: state.batchSize,
    );
  }

  void updateCleanupOldData(bool enabled) {
    state = CleanupPolicy(
      cleanupDuplicates: state.cleanupDuplicates,
      cleanupOrphans: state.cleanupOrphans,
      cleanupOldData: enabled,
      optimizeStorage: state.optimizeStorage,
      oldDataThreshold: state.oldDataThreshold,
      delayBetweenOperations: state.delayBetweenOperations,
      batchSize: state.batchSize,
    );
  }

  void updateOptimizeStorage(bool enabled) {
    state = CleanupPolicy(
      cleanupDuplicates: state.cleanupDuplicates,
      cleanupOrphans: state.cleanupOrphans,
      cleanupOldData: state.cleanupOldData,
      optimizeStorage: enabled,
      oldDataThreshold: state.oldDataThreshold,
      delayBetweenOperations: state.delayBetweenOperations,
      batchSize: state.batchSize,
    );
  }

  void updateOldDataThreshold(Duration threshold) {
    state = CleanupPolicy(
      cleanupDuplicates: state.cleanupDuplicates,
      cleanupOrphans: state.cleanupOrphans,
      cleanupOldData: state.cleanupOldData,
      optimizeStorage: state.optimizeStorage,
      oldDataThreshold: threshold,
      delayBetweenOperations: state.delayBetweenOperations,
      batchSize: state.batchSize,
    );
  }

  void updateBatchSize(int batchSize) {
    state = CleanupPolicy(
      cleanupDuplicates: state.cleanupDuplicates,
      cleanupOrphans: state.cleanupOrphans,
      cleanupOldData: state.cleanupOldData,
      optimizeStorage: state.optimizeStorage,
      oldDataThreshold: state.oldDataThreshold,
      delayBetweenOperations: state.delayBetweenOperations,
      batchSize: batchSize,
    );
  }

  void setConservativePolicy() {
    state = CleanupPolicy.conservative();
  }

  void setAggressivePolicy() {
    state = CleanupPolicy.aggressive();
  }

  void setDefaultPolicy() {
    state = CleanupPolicy.defaultPolicy();
  }
}

/// 정리 스케줄 설정 프로바이더
@riverpod
class CleanupScheduleSettings extends _$CleanupScheduleSettings {
  @override
  CleanupSchedule build() => CleanupSchedule.daily;

  void updateSchedule(CleanupSchedule schedule) {
    state = schedule;

    // 자동 정리가 활성화되어 있으면 새 스케줄로 재시작
    final isEnabled = ref.read(autoCleanupEnabledProvider);
    if (isEnabled) {
      final policy = ref.read(cleanupPolicySettingsProvider);
      ref.read(autoCleanupEnabledProvider.notifier).disable();
      ref.read(autoCleanupEnabledProvider.notifier).enable(schedule, policy);
    }
  }
}