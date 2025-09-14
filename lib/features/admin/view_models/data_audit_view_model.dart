import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_economy_dashboard/features/admin/services/data_audit_service.dart';
import 'package:geo_economy_dashboard/common/logger.dart';

class DataAuditNotifier extends StateNotifier<DataAuditState> {
  DataAuditNotifier() : super(const DataAuditState());

  Future<void> startFullAudit() async {
    state = state.copyWith(isAuditing: true, auditResults: []);

    await for (final message in DataAuditService.instance.auditDataIntegrity()) {
      state = state.copyWith(
        auditResults: [...state.auditResults, message],
      );
    }

    state = state.copyWith(isAuditing: false);

    // 감사 완료 후 최신 결과 로드
    await loadLatestAuditResults();
  }

  Future<void> startQuickAudit() async {
    state = state.copyWith(isAuditing: true, auditResults: []);

    await for (final message in DataAuditService.instance.quickAudit()) {
      state = state.copyWith(
        auditResults: [...state.auditResults, message],
      );
    }

    state = state.copyWith(isAuditing: false);

    // 빠른 감사 완료 후에도 최신 결과 로드
    await loadLatestAuditResults();
  }

  void clearResults() {
    state = state.copyWith(auditResults: []);
  }

  void updateHealthMetrics({
    required int duplicateCount,
    required int outdatedCount,
  }) {
    state = state.copyWith(
      duplicateCount: duplicateCount,
      outdatedCount: outdatedCount,
    );
  }

  // Firestore에서 최신 감사 결과 로드
  Future<void> loadLatestAuditResults() async {
    try {
      final summary = await DataAuditService.instance.getLatestAuditSummary();

      if (summary != null) {
        final statisticsSummary = summary['statisticsSummary'] as Map<String, dynamic>? ?? {};
        final totalIssues = statisticsSummary['totalIssues'] as int? ?? 0;
        final totalDocs = summary['totalDocumentsChecked'] as int? ?? 0;

        // 데이터 일관성 계산 (전체 문서 대비 문제 없는 문서 비율)
        double consistencyPercentage = 0.0;
        if (totalDocs > 0) {
          consistencyPercentage = ((totalDocs - totalIssues) / totalDocs) * 100;
          consistencyPercentage = consistencyPercentage.clamp(0.0, 100.0);
        }

        // 오래된 데이터 카운트 계산 (중복 데이터를 오래된 데이터로 간주)
        final duplicatesCount = summary['duplicateDataCount'] as int? ?? 0;
        final orphansCount = summary['orphanDocumentsCount'] as int? ?? 0;

        DateTime? auditTime;
        if (summary['auditEndTime'] != null) {
          auditTime = DateTime.parse(summary['auditEndTime']);
        }

        state = state.copyWith(
          duplicateCount: duplicatesCount,
          outdatedCount: duplicatesCount, // 중복 데이터를 오래된 데이터로 표시
          orphanDocumentCount: orphansCount,
          integrityIssueCount: summary['integrityIssuesCount'] as int? ?? 0,
          totalDocumentsChecked: totalDocs,
          dataConsistencyPercentage: consistencyPercentage,
          lastAuditTime: auditTime,
        );
      }
    } catch (e) {
      // 에러 발생 시 기본값 유지
      AppLogger.error('[DataAuditNotifier] Error loading latest audit results: $e');
    }
  }
}

class DataAuditState {
  final bool isAuditing;
  final List<String> auditResults;
  final int duplicateCount;
  final int outdatedCount;
  final int orphanDocumentCount;
  final int integrityIssueCount;
  final int totalDocumentsChecked;
  final double dataConsistencyPercentage;
  final DateTime? lastAuditTime;

  const DataAuditState({
    this.isAuditing = false,
    this.auditResults = const [],
    this.duplicateCount = 0,
    this.outdatedCount = 0,
    this.orphanDocumentCount = 0,
    this.integrityIssueCount = 0,
    this.totalDocumentsChecked = 0,
    this.dataConsistencyPercentage = 0.0,
    this.lastAuditTime,
  });

  DataAuditState copyWith({
    bool? isAuditing,
    List<String>? auditResults,
    int? duplicateCount,
    int? outdatedCount,
    int? orphanDocumentCount,
    int? integrityIssueCount,
    int? totalDocumentsChecked,
    double? dataConsistencyPercentage,
    DateTime? lastAuditTime,
  }) {
    return DataAuditState(
      isAuditing: isAuditing ?? this.isAuditing,
      auditResults: auditResults ?? this.auditResults,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      outdatedCount: outdatedCount ?? this.outdatedCount,
      orphanDocumentCount: orphanDocumentCount ?? this.orphanDocumentCount,
      integrityIssueCount: integrityIssueCount ?? this.integrityIssueCount,
      totalDocumentsChecked: totalDocumentsChecked ?? this.totalDocumentsChecked,
      dataConsistencyPercentage: dataConsistencyPercentage ?? this.dataConsistencyPercentage,
      lastAuditTime: lastAuditTime ?? this.lastAuditTime,
    );
  }
}

class DataCleanupNotifier extends StateNotifier<DataCleanupState> {
  DataCleanupNotifier(this.ref) : super(const DataCleanupState());
  
  final Ref ref;

  Future<void> removeDuplicates() async {
    state = state.copyWith(isCleaning: true);

    try {
      // 실제 중복 제거 실행
      await for (final message in DataAuditService.instance.removeDuplicateData()) {
        // 진행상황을 감사 결과에 표시
        final auditNotifier = ref.read(dataAuditProvider.notifier);
        final currentResults = ref.read(dataAuditProvider).auditResults;
        auditNotifier.state = auditNotifier.state.copyWith(
          auditResults: [...currentResults, message],
        );
      }

      // 성공 후 최신 감사 결과 다시 로드
      await ref.read(dataAuditProvider.notifier).loadLatestAuditResults();

    } catch (e) {
      AppLogger.error('[DataCleanupNotifier] Remove duplicates failed: $e');
    } finally {
      state = state.copyWith(isCleaning: false);
    }
  }

  Future<void> removeOutdated() async {
    state = state.copyWith(isCleaning: true);

    try {
      // 실제 오래된 데이터 제거 실행 (1년 이상 된 데이터)
      await for (final message in DataAuditService.instance.removeOutdatedData(daysOld: 365)) {
        // 진행상황을 감사 결과에 표시
        final auditNotifier = ref.read(dataAuditProvider.notifier);
        final currentResults = ref.read(dataAuditProvider).auditResults;
        auditNotifier.state = auditNotifier.state.copyWith(
          auditResults: [...currentResults, message],
        );
      }

      // 성공 후 최신 감사 결과 다시 로드
      await ref.read(dataAuditProvider.notifier).loadLatestAuditResults();

    } catch (e) {
      AppLogger.error('[DataCleanupNotifier] Remove outdated data failed: $e');
    } finally {
      state = state.copyWith(isCleaning: false);
    }
  }
}

class DataCleanupState {
  final bool isCleaning;

  const DataCleanupState({
    this.isCleaning = false,
  });

  DataCleanupState copyWith({
    bool? isCleaning,
  }) {
    return DataCleanupState(
      isCleaning: isCleaning ?? this.isCleaning,
    );
  }
}

// Providers
final dataAuditProvider = StateNotifierProvider<DataAuditNotifier, DataAuditState>((ref) {
  return DataAuditNotifier();
});

final dataCleanupProvider = StateNotifierProvider<DataCleanupNotifier, DataCleanupState>((ref) {
  return DataCleanupNotifier(ref);
});