import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_monitoring_service.dart';

part 'data_monitoring_provider.g.dart';

/// 실시간 데이터 상태 모니터링 프로바이더
@riverpod
Stream<DataStatusSnapshot> dataStatusMonitoring(Ref ref) {
  final monitoringService = DataMonitoringService.instance;

  // 컴포넌트가 마운트될 때 모니터링 시작
  ref.onDispose(() {
    monitoringService.stopMonitoring();
  });

  // 모니터링 시작
  monitoringService.startMonitoring(interval: const Duration(minutes: 2));

  return monitoringService.dataStatusStream;
}

/// 데이터 모니터링 서비스 프로바이더
@riverpod
DataMonitoringService dataMonitoringService(Ref ref) {
  return DataMonitoringService.instance;
}

/// 수동 새로고침 프로바이더
@riverpod
class DataStatusRefresh extends _$DataStatusRefresh {
  @override
  bool build() => false;

  /// 데이터 상태 수동 새로고침
  Future<void> refresh() async {
    state = true;
    try {
      final service = ref.read(dataMonitoringServiceProvider);
      await service.refreshStatus();
    } finally {
      state = false;
    }
  }
}

/// 모니터링 활성화 상태 프로바이더
@riverpod
class MonitoringActive extends _$MonitoringActive {
  @override
  bool build() => false;

  void toggle() {
    final service = ref.read(dataMonitoringServiceProvider);

    if (state) {
      service.stopMonitoring();
    } else {
      service.startMonitoring(interval: const Duration(minutes: 2));
    }

    state = !state;
  }

  void start() {
    if (!state) {
      final service = ref.read(dataMonitoringServiceProvider);
      service.startMonitoring(interval: const Duration(minutes: 2));
      state = true;
    }
  }

  void stop() {
    if (state) {
      final service = ref.read(dataMonitoringServiceProvider);
      service.stopMonitoring();
      state = false;
    }
  }
}