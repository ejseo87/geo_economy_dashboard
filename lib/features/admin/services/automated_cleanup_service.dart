import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/logger.dart';
import 'data_audit_service.dart';
import 'admin_audit_service.dart';

/// 자동화된 데이터 정리 서비스
class AutomatedCleanupService {
  static final AutomatedCleanupService _instance = AutomatedCleanupService._internal();
  factory AutomatedCleanupService() => _instance;
  AutomatedCleanupService._internal();

  static AutomatedCleanupService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataAuditService _auditService = DataAuditService.instance;
  final AdminAuditService _adminAuditService = AdminAuditService.instance;

  Timer? _cleanupTimer;
  final StreamController<CleanupProgress> _progressController =
      StreamController<CleanupProgress>.broadcast();

  /// 정리 진행 상황 스트림
  Stream<CleanupProgress> get progressStream => _progressController.stream;

  /// 자동 정리 시작
  void startAutomatedCleanup({
    CleanupSchedule schedule = CleanupSchedule.daily,
    CleanupPolicy? policy,
  }) {
    stopAutomatedCleanup();

    final interval = _getScheduleInterval(schedule);
    policy ??= CleanupPolicy.defaultPolicy();

    AppLogger.info('[AutomatedCleanupService] Starting automated cleanup with $schedule schedule');

    // 즉시 한 번 실행
    _executeCleanup(policy);

    // 정기적 실행 스케줄링
    _cleanupTimer = Timer.periodic(interval, (_) {
      _executeCleanup(policy!);
    });
  }

  /// 자동 정리 중지
  void stopAutomatedCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    AppLogger.info('[AutomatedCleanupService] Automated cleanup stopped');
  }

  /// 수동 정리 실행
  Future<CleanupResult> executeManualCleanup({
    CleanupPolicy? policy,
    List<CleanupType>? specificTypes,
  }) async {
    policy ??= CleanupPolicy.defaultPolicy();

    try {
      return await _performCleanup(policy, specificTypes: specificTypes);
    } catch (e) {
      AppLogger.error('[AutomatedCleanupService] Manual cleanup failed: $e');
      rethrow;
    }
  }

  /// 정리 실행 (내부 메서드)
  Future<void> _executeCleanup(CleanupPolicy policy) async {
    try {
      final result = await _performCleanup(policy);

      // 관리자 로그 기록
      await _adminAuditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '자동 데이터 정리 완료',
        status: AdminActionStatus.completed,
        metadata: result.toMap(),
      );

      AppLogger.info('[AutomatedCleanupService] Automated cleanup completed: ${result.totalCleaned} items');
    } catch (e) {
      AppLogger.error('[AutomatedCleanupService] Automated cleanup failed: $e');

      await _adminAuditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '자동 데이터 정리 실패',
        status: AdminActionStatus.failed,
        metadata: {'error': e.toString()},
      );
    }
  }

  /// 실제 정리 작업 수행
  Future<CleanupResult> _performCleanup(
    CleanupPolicy policy, {
    List<CleanupType>? specificTypes,
  }) async {
    final startTime = DateTime.now();
    final result = CleanupResult(startTime: startTime);

    _progressController.add(CleanupProgress(
      stage: CleanupStage.starting,
      message: '데이터 정리를 시작합니다...',
      progress: 0.0,
    ));

    try {
      // 1. 감사 실행하여 문제 파악
      if (specificTypes == null || specificTypes.contains(CleanupType.audit)) {
        _progressController.add(CleanupProgress(
          stage: CleanupStage.auditing,
          message: '데이터 감사 중...',
          progress: 0.1,
        ));

        // 스트림을 리스트로 변환하여 모든 로그 수집
        final auditLogs = <String>[];
        await for (final log in _auditService.auditDataIntegrity()) {
          auditLogs.add(log);
          AppLogger.debug('[AutomatedCleanupService] Audit: $log');
        }

        result.auditLogCount = auditLogs.length;
      }

      // 2. 중복 데이터 정리
      if (policy.cleanupDuplicates && (specificTypes == null || specificTypes.contains(CleanupType.duplicates))) {
        _progressController.add(CleanupProgress(
          stage: CleanupStage.cleaningDuplicates,
          message: '중복 데이터 정리 중...',
          progress: 0.3,
        ));

        final cleanedDuplicates = await _cleanupDuplicates(policy);
        result.duplicatesCleaned = cleanedDuplicates;
      }

      // 3. 고아 문서 정리
      if (policy.cleanupOrphans && (specificTypes == null || specificTypes.contains(CleanupType.orphans))) {
        _progressController.add(CleanupProgress(
          stage: CleanupStage.cleaningOrphans,
          message: '고아 문서 정리 중...',
          progress: 0.5,
        ));

        final cleanedOrphans = await _cleanupOrphans(policy);
        result.orphansCleaned = cleanedOrphans;
      }

      // 4. 오래된 데이터 정리
      if (policy.cleanupOldData && (specificTypes == null || specificTypes.contains(CleanupType.oldData))) {
        _progressController.add(CleanupProgress(
          stage: CleanupStage.cleaningOldData,
          message: '오래된 데이터 정리 중...',
          progress: 0.7,
        ));

        final cleanedOldData = await _cleanupOldData(policy);
        result.oldDataCleaned = cleanedOldData;
      }

      // 5. 최적화 및 정리
      if (policy.optimizeStorage && (specificTypes == null || specificTypes.contains(CleanupType.optimization))) {
        _progressController.add(CleanupProgress(
          stage: CleanupStage.optimizing,
          message: '데이터베이스 최적화 중...',
          progress: 0.9,
        ));

        await _optimizeDatabase();
      }

      result.endTime = DateTime.now();
      result.success = true;

      _progressController.add(CleanupProgress(
        stage: CleanupStage.completed,
        message: '데이터 정리가 완료되었습니다.',
        progress: 1.0,
        result: result,
      ));

      return result;

    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();

      _progressController.add(CleanupProgress(
        stage: CleanupStage.error,
        message: '데이터 정리 중 오류 발생: $e',
        progress: 0.0,
        error: e.toString(),
      ));

      rethrow;
    }
  }

  /// 중복 데이터 정리
  Future<int> _cleanupDuplicates(CleanupPolicy policy) async {
    int cleaned = 0;

    try {
      final duplicates = await _auditService.findDuplicateData();

      for (final duplicate in duplicates) {
        if (policy.shouldCleanDuplicate(duplicate)) {
          final success = await _auditService.resolveDuplicateData(duplicate);
          if (success) {
            cleaned++;
            AppLogger.debug('[AutomatedCleanupService] Cleaned duplicate: ${duplicate.indicatorCode}/${duplicate.countryCode}');
          }

          // 과부하 방지를 위한 지연
          if (policy.delayBetweenOperations > Duration.zero) {
            await Future.delayed(policy.delayBetweenOperations);
          }

          // 배치 크기 제한
          if (policy.batchSize > 0 && cleaned >= policy.batchSize) {
            AppLogger.info('[AutomatedCleanupService] Reached batch limit for duplicates: ${policy.batchSize}');
            break;
          }
        }
      }
    } catch (e) {
      AppLogger.error('[AutomatedCleanupService] Error cleaning duplicates: $e');
    }

    return cleaned;
  }

  /// 고아 문서 정리
  Future<int> _cleanupOrphans(CleanupPolicy policy) async {
    int cleaned = 0;

    try {
      final orphans = await _auditService.findOrphanDocuments();

      for (final orphan in orphans) {
        if (policy.shouldCleanOrphan(orphan)) {
          try {
            await _firestore.doc(orphan.path).delete();
            cleaned++;
            AppLogger.debug('[AutomatedCleanupService] Cleaned orphan: ${orphan.path}');
          } catch (e) {
            AppLogger.warning('[AutomatedCleanupService] Failed to delete orphan ${orphan.path}: $e');
          }

          // 과부하 방지를 위한 지연
          if (policy.delayBetweenOperations > Duration.zero) {
            await Future.delayed(policy.delayBetweenOperations);
          }

          // 배치 크기 제한
          if (policy.batchSize > 0 && cleaned >= policy.batchSize) {
            AppLogger.info('[AutomatedCleanupService] Reached batch limit for orphans: ${policy.batchSize}');
            break;
          }
        }
      }
    } catch (e) {
      AppLogger.error('[AutomatedCleanupService] Error cleaning orphans: $e');
    }

    return cleaned;
  }

  /// 오래된 데이터 정리
  Future<int> _cleanupOldData(CleanupPolicy policy) async {
    int cleaned = 0;

    try {
      final cutoffDate = DateTime.now().subtract(policy.oldDataThreshold);

      // indicators 컬렉션의 오래된 데이터 정리
      final indicatorsSnapshot = await _firestore
          .collection('indicators')
          .where('lastUpdated', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(policy.batchSize > 0 ? policy.batchSize : 100)
          .get();

      for (final doc in indicatorsSnapshot.docs) {
        if (policy.shouldCleanOldData(doc.data(), cutoffDate)) {
          try {
            // 하위 컬렉션도 함께 삭제
            final seriesSnapshot = await doc.reference.collection('series').get();
            final batch = _firestore.batch();

            for (final seriesDoc in seriesSnapshot.docs) {
              batch.delete(seriesDoc.reference);
            }
            batch.delete(doc.reference);

            await batch.commit();
            cleaned++;
            AppLogger.debug('[AutomatedCleanupService] Cleaned old indicator: ${doc.id}');
          } catch (e) {
            AppLogger.warning('[AutomatedCleanupService] Failed to delete old indicator ${doc.id}: $e');
          }

          // 과부하 방지를 위한 지연
          if (policy.delayBetweenOperations > Duration.zero) {
            await Future.delayed(policy.delayBetweenOperations);
          }
        }
      }
    } catch (e) {
      AppLogger.error('[AutomatedCleanupService] Error cleaning old data: $e');
    }

    return cleaned;
  }

  /// 데이터베이스 최적화
  Future<void> _optimizeDatabase() async {
    try {
      // Firestore는 자동으로 최적화되므로 여기서는 로깅만
      AppLogger.info('[AutomatedCleanupService] Database optimization completed (Firestore auto-optimizes)');
    } catch (e) {
      AppLogger.error('[AutomatedCleanupService] Database optimization failed: $e');
    }
  }

  /// 스케줄 간격 반환
  Duration _getScheduleInterval(CleanupSchedule schedule) {
    switch (schedule) {
      case CleanupSchedule.hourly:
        return const Duration(hours: 1);
      case CleanupSchedule.daily:
        return const Duration(days: 1);
      case CleanupSchedule.weekly:
        return const Duration(days: 7);
      case CleanupSchedule.monthly:
        return const Duration(days: 30);
    }
  }

  /// 서비스 정리
  void dispose() {
    stopAutomatedCleanup();
    _progressController.close();
  }
}

/// 정리 정책
class CleanupPolicy {
  final bool cleanupDuplicates;
  final bool cleanupOrphans;
  final bool cleanupOldData;
  final bool optimizeStorage;
  final Duration oldDataThreshold;
  final Duration delayBetweenOperations;
  final int batchSize; // 0이면 무제한

  const CleanupPolicy({
    this.cleanupDuplicates = true,
    this.cleanupOrphans = true,
    this.cleanupOldData = false, // 기본적으로 비활성화
    this.optimizeStorage = true,
    this.oldDataThreshold = const Duration(days: 90),
    this.delayBetweenOperations = const Duration(milliseconds: 100),
    this.batchSize = 50,
  });

  factory CleanupPolicy.defaultPolicy() {
    return const CleanupPolicy();
  }

  factory CleanupPolicy.aggressive() {
    return const CleanupPolicy(
      cleanupDuplicates: true,
      cleanupOrphans: true,
      cleanupOldData: true,
      optimizeStorage: true,
      oldDataThreshold: Duration(days: 30),
      delayBetweenOperations: Duration(milliseconds: 50),
      batchSize: 100,
    );
  }

  factory CleanupPolicy.conservative() {
    return const CleanupPolicy(
      cleanupDuplicates: true,
      cleanupOrphans: false,
      cleanupOldData: false,
      optimizeStorage: false,
      oldDataThreshold: Duration(days: 180),
      delayBetweenOperations: Duration(milliseconds: 500),
      batchSize: 10,
    );
  }

  bool shouldCleanDuplicate(DuplicateData duplicate) {
    // 기본적으로 모든 중복 데이터 정리
    return true;
  }

  bool shouldCleanOrphan(OrphanDocument orphan) {
    // 기본적으로 모든 고아 문서 정리
    return true;
  }

  bool shouldCleanOldData(Map<String, dynamic> data, DateTime cutoffDate) {
    // 추가적인 검증 로직 추가 가능
    return true;
  }
}

/// 정리 스케줄
enum CleanupSchedule {
  hourly,
  daily,
  weekly,
  monthly,
}

/// 정리 유형
enum CleanupType {
  audit,
  duplicates,
  orphans,
  oldData,
  optimization,
}

/// 정리 단계
enum CleanupStage {
  starting,
  auditing,
  cleaningDuplicates,
  cleaningOrphans,
  cleaningOldData,
  optimizing,
  completed,
  error,
}

/// 정리 진행 상황
class CleanupProgress {
  final CleanupStage stage;
  final String message;
  final double progress; // 0.0 - 1.0
  final CleanupResult? result;
  final String? error;

  const CleanupProgress({
    required this.stage,
    required this.message,
    required this.progress,
    this.result,
    this.error,
  });

  bool get isCompleted => stage == CleanupStage.completed;
  bool get hasError => stage == CleanupStage.error;
}

/// 정리 결과
class CleanupResult {
  final DateTime startTime;
  DateTime? endTime;
  bool success = false;
  String? error;

  int duplicatesCleaned = 0;
  int orphansCleaned = 0;
  int oldDataCleaned = 0;
  int auditLogCount = 0;

  CleanupResult({required this.startTime});

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  int get totalCleaned => duplicatesCleaned + orphansCleaned + oldDataCleaned;

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inMilliseconds,
      'success': success,
      'error': error,
      'duplicatesCleaned': duplicatesCleaned,
      'orphansCleaned': orphansCleaned,
      'oldDataCleaned': oldDataCleaned,
      'auditLogCount': auditLogCount,
      'totalCleaned': totalCleaned,
    };
  }
}