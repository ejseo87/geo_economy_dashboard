import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:geo_economy_dashboard/features/admin/services/worldbank_data_collector.dart';
import 'package:geo_economy_dashboard/features/admin/services/admin_audit_service.dart';

part 'data_collection_view_model.g.dart';

enum DataCollectionType {
  full,
  test,
}

class DataCollectionState {
  final bool isCollecting;
  final DataCollectionType? currentType;
  final double progress;
  final String currentTask;
  final List<String> logs;
  final Map<String, dynamic>? result;
  final String? error;
  final DateTime? startTime;
  final String? auditLogId;

  const DataCollectionState({
    this.isCollecting = false,
    this.currentType,
    this.progress = 0.0,
    this.currentTask = '',
    this.logs = const [],
    this.result,
    this.error,
    this.startTime,
    this.auditLogId,
  });

  DataCollectionState copyWith({
    bool? isCollecting,
    DataCollectionType? currentType,
    double? progress,
    String? currentTask,
    List<String>? logs,
    Map<String, dynamic>? result,
    String? error,
    DateTime? startTime,
    String? auditLogId,
  }) {
    return DataCollectionState(
      isCollecting: isCollecting ?? this.isCollecting,
      currentType: currentType ?? this.currentType,
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
      logs: logs ?? this.logs,
      result: result ?? this.result,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      auditLogId: auditLogId ?? this.auditLogId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isCollecting': isCollecting,
      'currentType': currentType?.name,
      'progress': progress,
      'currentTask': currentTask,
      'logs': logs,
      'result': result,
      'error': error,
      'startTime': startTime?.toIso8601String(),
      'auditLogId': auditLogId,
    };
  }

  factory DataCollectionState.fromMap(Map<String, dynamic> map) {
    return DataCollectionState(
      isCollecting: map['isCollecting'] ?? false,
      currentType: map['currentType'] != null 
          ? DataCollectionType.values.firstWhere((e) => e.name == map['currentType'])
          : null,
      progress: (map['progress'] ?? 0.0).toDouble(),
      currentTask: map['currentTask'] ?? '',
      logs: List<String>.from(map['logs'] ?? []),
      result: map['result'] as Map<String, dynamic>?,
      error: map['error'],
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      auditLogId: map['auditLogId'],
    );
  }
}

@riverpod
class DataCollectionNotifier extends _$DataCollectionNotifier {
  static const String _firestoreCollection = 'admin_data_collection_state';
  static const String _documentId = 'current_state';

  @override
  DataCollectionState build() {
    _loadPersistedState();
    return const DataCollectionState();
  }

  Future<void> _loadPersistedState() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(_documentId)
          .get();

      if (doc.exists && doc.data() != null) {
        final persistedState = DataCollectionState.fromMap(doc.data()!);
        
        // 앱이 재시작된 경우 수집 중 상태를 해제
        if (persistedState.isCollecting) {
          final recoveredState = persistedState.copyWith(
            isCollecting: false,
            error: '앱 재시작으로 인해 중단됨',
          );
          state = recoveredState;
          await _persistState();
        } else {
          state = persistedState;
        }
        
        AppLogger.info('[DataCollectionNotifier] Loaded persisted state');
      }
    } catch (e) {
      AppLogger.error('[DataCollectionNotifier] Failed to load persisted state: $e');
    }
  }

  Future<void> _persistState() async {
    try {
      await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(_documentId)
          .set(state.toMap());
    } catch (e) {
      AppLogger.error('[DataCollectionNotifier] Failed to persist state: $e');
    }
  }

  Future<void> startFullDataCollection() async {
    if (state.isCollecting) return;

    final auditLogId = await AdminAuditService.instance.logAdminAction(
      actionType: AdminActionType.dataCollection,
      description: '전체 데이터 수집 시작',
      metadata: {
        'collectionType': 'full',
        'indicators': 20,
        'countries': 38,
      },
    );

    state = DataCollectionState(
      isCollecting: true,
      currentType: DataCollectionType.full,
      progress: 0.0,
      currentTask: '전체 데이터 수집 준비 중...',
      logs: ['전체 데이터 수집을 시작합니다.'],
      startTime: DateTime.now(),
      auditLogId: auditLogId,
    );
    
    await _persistState();

    try {
      final collector = WorldBankDataCollector();
      final result = await collector.collectAllIndicatorData(
        onProgress: _updateProgress,
      );

      state = state.copyWith(
        isCollecting: false,
        progress: 1.0,
        currentTask: '수집 완료',
        result: result,
        logs: [...state.logs, '전체 데이터 수집이 완료되었습니다.'],
      );

      final duration = DateTime.now().difference(state.startTime!);
      await AdminAuditService.instance.updateAdminActionStatus(
        entryId: auditLogId,
        status: AdminActionStatus.completed,
        duration: duration,
        additionalMetadata: {
          'totalProcessed': result['totalProcessed'],
          'successfullyProcessed': result['successfullyProcessed'],
          'errors': result['errors'],
        },
      );

    } catch (e) {
      state = state.copyWith(
        isCollecting: false,
        error: e.toString(),
        logs: [...state.logs, '오류 발생: ${e.toString()}'],
      );

      if (auditLogId.isNotEmpty) {
        await AdminAuditService.instance.updateAdminActionStatus(
          entryId: auditLogId,
          status: AdminActionStatus.failed,
          errorMessage: e.toString(),
        );
      }
    }

    await _persistState();
  }

  Future<void> startTestDataCollection() async {
    if (state.isCollecting) return;

    final auditLogId = await AdminAuditService.instance.logAdminAction(
      actionType: AdminActionType.dataCollection,
      description: '테스트 데이터 수집 시작',
      metadata: {
        'collectionType': 'test',
        'indicators': 3,
        'countries': 3,
      },
    );

    state = DataCollectionState(
      isCollecting: true,
      currentType: DataCollectionType.test,
      progress: 0.0,
      currentTask: '테스트 데이터 수집 준비 중...',
      logs: ['테스트 데이터 수집을 시작합니다.'],
      startTime: DateTime.now(),
      auditLogId: auditLogId,
    );

    await _persistState();

    try {
      final collector = WorldBankDataCollector();
      final result = await collector.collectTestData(
        onProgress: _updateProgress,
      );

      state = state.copyWith(
        isCollecting: false,
        progress: 1.0,
        currentTask: '테스트 수집 완료',
        result: result,
        logs: [...state.logs, '테스트 데이터 수집이 완료되었습니다.'],
      );

      final duration = DateTime.now().difference(state.startTime!);
      await AdminAuditService.instance.updateAdminActionStatus(
        entryId: auditLogId,
        status: AdminActionStatus.completed,
        duration: duration,
        additionalMetadata: {
          'totalProcessed': result['totalProcessed'],
          'successfullyProcessed': result['successfullyProcessed'],
          'errors': result['errors'],
        },
      );

    } catch (e) {
      state = state.copyWith(
        isCollecting: false,
        error: e.toString(),
        logs: [...state.logs, '오류 발생: ${e.toString()}'],
      );

      if (auditLogId.isNotEmpty) {
        await AdminAuditService.instance.updateAdminActionStatus(
          entryId: auditLogId,
          status: AdminActionStatus.failed,
          errorMessage: e.toString(),
        );
      }
    }

    await _persistState();
  }

  void _updateProgress(String message) {
    // 진행률 계산 로직 (간단한 예시)
    double newProgress = state.progress;
    if (state.currentType == DataCollectionType.test) {
      // 테스트: 3개 지표 기준
      if (message.contains('GDP')) {
        newProgress = 0.33;
      } else if (message.contains('실업률')) {
        newProgress = 0.66;
      } else if (message.contains('인플레이션')) {
        newProgress = 1.0;
      }
    } else {
      // 전체: 20개 지표 기준 - 단순 계산
      final indicatorNames = [
        'GDP', '실업률', '인플레이션', '제조업', '고정자본', 'M2', 
        '노동참가율', '고용률', '정부지출', '조세수입', '정부부채', 
        '경상수지', '수출', '수입', '외환보유액', '지니', '빈곤율', 
        'CO₂', '재생에너지'
      ];
      
      for (int i = 0; i < indicatorNames.length; i++) {
        if (message.contains(indicatorNames[i])) {
          newProgress = (i + 1) / indicatorNames.length;
          break;
        }
      }
    }

    state = state.copyWith(
      progress: newProgress,
      currentTask: message,
      logs: [...state.logs, message],
    );

    // 상태 변경을 즉시 저장하지 않고 주기적으로만 저장 (성능상 이유)
    if (state.logs.length % 5 == 0) {
      _persistState();
    }
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
    _persistState();
  }

  void resetState() {
    state = const DataCollectionState();
    _persistState();
  }
}