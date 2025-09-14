// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_monitoring_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dataStatusMonitoringHash() =>
    r'e82c048ead27b6d5c291e9df709d552b38f123d8';

/// 실시간 데이터 상태 모니터링 프로바이더
///
/// Copied from [dataStatusMonitoring].
@ProviderFor(dataStatusMonitoring)
final dataStatusMonitoringProvider =
    AutoDisposeStreamProvider<DataStatusSnapshot>.internal(
      dataStatusMonitoring,
      name: r'dataStatusMonitoringProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dataStatusMonitoringHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DataStatusMonitoringRef =
    AutoDisposeStreamProviderRef<DataStatusSnapshot>;
String _$dataMonitoringServiceHash() =>
    r'b6c4967fbe84b80b97f90618e8fd87d026237b9e';

/// 데이터 모니터링 서비스 프로바이더
///
/// Copied from [dataMonitoringService].
@ProviderFor(dataMonitoringService)
final dataMonitoringServiceProvider =
    AutoDisposeProvider<DataMonitoringService>.internal(
      dataMonitoringService,
      name: r'dataMonitoringServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dataMonitoringServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DataMonitoringServiceRef =
    AutoDisposeProviderRef<DataMonitoringService>;
String _$dataStatusRefreshHash() => r'a6f3ee0fa18c2991ec411a7a1698a4cf761e75a3';

/// 수동 새로고침 프로바이더
///
/// Copied from [DataStatusRefresh].
@ProviderFor(DataStatusRefresh)
final dataStatusRefreshProvider =
    AutoDisposeNotifierProvider<DataStatusRefresh, bool>.internal(
      DataStatusRefresh.new,
      name: r'dataStatusRefreshProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dataStatusRefreshHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DataStatusRefresh = AutoDisposeNotifier<bool>;
String _$monitoringActiveHash() => r'0e6a2252e70ec24d1f5f3be0027647fb5544b98b';

/// 모니터링 활성화 상태 프로바이더
///
/// Copied from [MonitoringActive].
@ProviderFor(MonitoringActive)
final monitoringActiveProvider =
    AutoDisposeNotifierProvider<MonitoringActive, bool>.internal(
      MonitoringActive.new,
      name: r'monitoringActiveProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$monitoringActiveHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MonitoringActive = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
