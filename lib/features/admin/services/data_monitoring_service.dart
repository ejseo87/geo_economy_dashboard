import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/logger.dart';

/// 실시간 데이터 상태 모니터링 서비스
class DataMonitoringService {
  static final DataMonitoringService _instance = DataMonitoringService._internal();
  factory DataMonitoringService() => _instance;
  DataMonitoringService._internal();

  static DataMonitoringService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _monitoringTimer;
  final StreamController<DataStatusSnapshot> _statusController =
      StreamController<DataStatusSnapshot>.broadcast();

  /// 데이터 상태 실시간 스트림
  Stream<DataStatusSnapshot> get dataStatusStream => _statusController.stream;

  /// 모니터링 시작
  void startMonitoring({Duration interval = const Duration(minutes: 5)}) {
    stopMonitoring();

    AppLogger.info('[DataMonitoringService] Starting real-time monitoring with ${interval.inMinutes}min interval');

    // 즉시 첫 번째 상태 업데이트
    _updateDataStatus();

    // 정기적 업데이트 스케줄링
    _monitoringTimer = Timer.periodic(interval, (_) {
      _updateDataStatus();
    });
  }

  /// 모니터링 중지
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    AppLogger.info('[DataMonitoringService] Monitoring stopped');
  }

  /// 수동 상태 새로고침
  Future<void> refreshStatus() async {
    await _updateDataStatus();
  }

  /// 데이터 상태 업데이트
  Future<void> _updateDataStatus() async {
    try {
      final snapshot = await _collectDataStatusSnapshot();
      _statusController.add(snapshot);
      AppLogger.debug('[DataMonitoringService] Status updated: ${snapshot.totalDocuments} documents');
    } catch (e) {
      AppLogger.error('[DataMonitoringService] Failed to update status: $e');

      // 에러 상태로 스냅샷 전송
      _statusController.add(DataStatusSnapshot.error(e.toString()));
    }
  }

  /// 데이터 상태 스냅샷 수집
  Future<DataStatusSnapshot> _collectDataStatusSnapshot() async {
    final startTime = DateTime.now();

    // 병렬로 데이터 수집
    final futures = await Future.wait([
      _getIndicatorsCount(),
      _getCountriesCount(),
      _getRecentActivity(),
      _getDataFreshness(),
      _getLastAuditSummary(),
    ]);

    final indicatorsCount = futures[0] as int;
    final countriesCount = futures[1] as int;
    final recentActivity = futures[2] as RecentActivityData;
    final freshness = futures[3] as DataFreshnessInfo;
    final auditSummary = futures[4] as AuditSummaryData?;

    final endTime = DateTime.now();
    final collectDuration = endTime.difference(startTime);

    return DataStatusSnapshot(
      timestamp: endTime,
      totalIndicators: indicatorsCount,
      totalCountries: countriesCount,
      totalDocuments: indicatorsCount + countriesCount + recentActivity.totalSeriesCount,
      recentActivity: recentActivity,
      dataFreshness: freshness,
      lastAudit: auditSummary,
      collectionDuration: collectDuration,
      isHealthy: _determineHealthStatus(indicatorsCount, countriesCount, freshness, auditSummary),
    );
  }

  /// indicators 컬렉션 문서 수 계산
  Future<int> _getIndicatorsCount() async {
    try {
      final snapshot = await _firestore.collection('indicators').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.warning('[DataMonitoringService] Failed to count indicators: $e');
      return 0;
    }
  }

  /// countries 컬렉션 문서 수 계산
  Future<int> _getCountriesCount() async {
    try {
      final snapshot = await _firestore.collection('countries').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.warning('[DataMonitoringService] Failed to count countries: $e');
      return 0;
    }
  }

  /// 최근 활동 데이터 수집
  Future<RecentActivityData> _getRecentActivity() async {
    try {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      // 최근 업데이트된 indicators
      final recentIndicators = await _firestore
          .collection('indicators')
          .where('lastUpdated', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .count()
          .get();

      // 최근 감사 로그
      final recentAudits = await _firestore
          .collection('admin_audit_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
          .count()
          .get();

      // 전체 series 문서 수 추정 (샘플링)
      final sampleIndicators = await _firestore
          .collection('indicators')
          .limit(5)
          .get();

      int totalSeriesCount = 0;
      for (final doc in sampleIndicators.docs) {
        final seriesCount = await _firestore
            .collection('indicators')
            .doc(doc.id)
            .collection('series')
            .count()
            .get();
        totalSeriesCount += (seriesCount.count ?? 0);
      }

      // 전체 추정치 계산 (샘플 기반)
      final estimatedTotalSeries = sampleIndicators.docs.isNotEmpty
          ? (totalSeriesCount * await _getIndicatorsCount() / sampleIndicators.docs.length).round()
          : 0;

      return RecentActivityData(
        updatedIndicatorsToday: recentIndicators.count ?? 0,
        auditRunsThisWeek: recentAudits.count ?? 0,
        totalSeriesCount: estimatedTotalSeries,
        lastActivityTime: DateTime.now(),
      );
    } catch (e) {
      AppLogger.warning('[DataMonitoringService] Failed to get recent activity: $e');
      return RecentActivityData(
        updatedIndicatorsToday: 0,
        auditRunsThisWeek: 0,
        totalSeriesCount: 0,
        lastActivityTime: DateTime.now(),
      );
    }
  }

  /// 데이터 신선도 정보 수집
  Future<DataFreshnessInfo> _getDataFreshness() async {
    try {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      // 최근 1일 내 업데이트된 데이터
      final freshData = await _firestore
          .collection('indicators')
          .where('lastUpdated', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .count()
          .get();

      // 1주일 이상 오래된 데이터
      final staleData = await _firestore
          .collection('indicators')
          .where('lastUpdated', isLessThan: Timestamp.fromDate(oneWeekAgo))
          .count()
          .get();

      return DataFreshnessInfo(
        freshDataCount: freshData.count ?? 0,
        staleDataCount: staleData.count ?? 0,
        lastUpdateCheck: DateTime.now(),
      );
    } catch (e) {
      AppLogger.warning('[DataMonitoringService] Failed to get data freshness: $e');
      return DataFreshnessInfo(
        freshDataCount: 0,
        staleDataCount: 0,
        lastUpdateCheck: DateTime.now(),
      );
    }
  }

  /// 최근 감사 요약 정보
  Future<AuditSummaryData?> _getLastAuditSummary() async {
    try {
      final auditSnapshot = await _firestore
          .collection('admin_audit_logs')
          .where('actionType', isEqualTo: 'systemMaintenance')
          .where('status', isEqualTo: 'completed')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (auditSnapshot.docs.isEmpty) return null;

      final auditDoc = auditSnapshot.docs.first;
      final auditData = auditDoc.data();
      final metadata = auditData['metadata'] as Map<String, dynamic>? ?? {};

      return AuditSummaryData(
        auditId: auditDoc.id,
        completedAt: (auditData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        totalIssues: metadata['totalIssues'] as int? ?? 0,
        duplicates: metadata['duplicates'] as int? ?? 0,
        orphans: metadata['orphans'] as int? ?? 0,
        integrityIssues: metadata['totalIssues'] as int? ?? 0 -
                         (metadata['duplicates'] as int? ?? 0) -
                         (metadata['orphans'] as int? ?? 0),
        logFileUrl: metadata['logFile'] as String?,
      );
    } catch (e) {
      AppLogger.warning('[DataMonitoringService] Failed to get audit summary: $e');
      return null;
    }
  }

  /// 전체적인 데이터 상태 건강도 판단
  bool _determineHealthStatus(
    int indicatorsCount,
    int countriesCount,
    DataFreshnessInfo freshness,
    AuditSummaryData? audit
  ) {
    // 기본적인 데이터 존재 확인
    if (indicatorsCount == 0 || countriesCount == 0) return false;

    // 너무 많은 오래된 데이터가 있으면 비건강
    if (freshness.staleDataCount > indicatorsCount * 0.5) return false;

    // 최근 감사에서 심각한 문제가 많이 발견되었으면 비건강
    if (audit != null && audit.totalIssues > 100) return false;

    return true;
  }

  /// 리소스 정리
  void dispose() {
    stopMonitoring();
    _statusController.close();
  }
}

/// 데이터 상태 스냅샷
class DataStatusSnapshot {
  final DateTime timestamp;
  final int totalIndicators;
  final int totalCountries;
  final int totalDocuments;
  final RecentActivityData recentActivity;
  final DataFreshnessInfo dataFreshness;
  final AuditSummaryData? lastAudit;
  final Duration collectionDuration;
  final bool isHealthy;
  final String? error;

  const DataStatusSnapshot({
    required this.timestamp,
    required this.totalIndicators,
    required this.totalCountries,
    required this.totalDocuments,
    required this.recentActivity,
    required this.dataFreshness,
    this.lastAudit,
    required this.collectionDuration,
    required this.isHealthy,
    this.error,
  });

  /// 에러 상태 스냅샷 생성
  factory DataStatusSnapshot.error(String error) {
    return DataStatusSnapshot(
      timestamp: DateTime.now(),
      totalIndicators: 0,
      totalCountries: 0,
      totalDocuments: 0,
      recentActivity: RecentActivityData(
        updatedIndicatorsToday: 0,
        auditRunsThisWeek: 0,
        totalSeriesCount: 0,
        lastActivityTime: DateTime.now(),
      ),
      dataFreshness: DataFreshnessInfo(
        freshDataCount: 0,
        staleDataCount: 0,
        lastUpdateCheck: DateTime.now(),
      ),
      collectionDuration: Duration.zero,
      isHealthy: false,
      error: error,
    );
  }

  bool get hasError => error != null;
}

/// 최근 활동 데이터
class RecentActivityData {
  final int updatedIndicatorsToday;
  final int auditRunsThisWeek;
  final int totalSeriesCount;
  final DateTime lastActivityTime;

  const RecentActivityData({
    required this.updatedIndicatorsToday,
    required this.auditRunsThisWeek,
    required this.totalSeriesCount,
    required this.lastActivityTime,
  });
}

/// 데이터 신선도 정보
class DataFreshnessInfo {
  final int freshDataCount;
  final int staleDataCount;
  final DateTime lastUpdateCheck;

  const DataFreshnessInfo({
    required this.freshDataCount,
    required this.staleDataCount,
    required this.lastUpdateCheck,
  });

  double get freshPercentage {
    final total = freshDataCount + staleDataCount;
    return total > 0 ? (freshDataCount / total * 100) : 0.0;
  }

  bool get isHealthy => freshPercentage > 70.0;
}

/// 감사 요약 데이터
class AuditSummaryData {
  final String auditId;
  final DateTime completedAt;
  final int totalIssues;
  final int duplicates;
  final int orphans;
  final int integrityIssues;
  final String? logFileUrl;

  const AuditSummaryData({
    required this.auditId,
    required this.completedAt,
    required this.totalIssues,
    required this.duplicates,
    required this.orphans,
    required this.integrityIssues,
    this.logFileUrl,
  });

  bool get hasLogFile => logFileUrl != null;
}