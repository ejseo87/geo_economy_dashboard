// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automated_cleanup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$automatedCleanupServiceHash() =>
    r'945a252f73acf037077d2d02b2ec0169e6ea7c0b';

/// 자동화된 정리 서비스 프로바이더
///
/// Copied from [automatedCleanupService].
@ProviderFor(automatedCleanupService)
final automatedCleanupServiceProvider =
    AutoDisposeProvider<AutomatedCleanupService>.internal(
      automatedCleanupService,
      name: r'automatedCleanupServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$automatedCleanupServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AutomatedCleanupServiceRef =
    AutoDisposeProviderRef<AutomatedCleanupService>;
String _$cleanupProgressStreamHash() =>
    r'448abfcb52620f8c320ff0937ab7f79c73c35a48';

/// 정리 진행 상황 스트림 프로바이더
///
/// Copied from [cleanupProgressStream].
@ProviderFor(cleanupProgressStream)
final cleanupProgressStreamProvider =
    AutoDisposeStreamProvider<CleanupProgress>.internal(
      cleanupProgressStream,
      name: r'cleanupProgressStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cleanupProgressStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CleanupProgressStreamRef =
    AutoDisposeStreamProviderRef<CleanupProgress>;
String _$autoCleanupEnabledHash() =>
    r'815fba882c760e233f426850ea182fff4be9611c';

/// 자동 정리 활성화 상태 프로바이더
///
/// Copied from [AutoCleanupEnabled].
@ProviderFor(AutoCleanupEnabled)
final autoCleanupEnabledProvider =
    AutoDisposeNotifierProvider<AutoCleanupEnabled, bool>.internal(
      AutoCleanupEnabled.new,
      name: r'autoCleanupEnabledProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$autoCleanupEnabledHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AutoCleanupEnabled = AutoDisposeNotifier<bool>;
String _$manualCleanupExecutionHash() =>
    r'f308e8a30e236e62e38c7ad641d29cae70a6ffff';

/// 수동 정리 실행 프로바이더
///
/// Copied from [ManualCleanupExecution].
@ProviderFor(ManualCleanupExecution)
final manualCleanupExecutionProvider =
    AutoDisposeNotifierProvider<
      ManualCleanupExecution,
      AsyncValue<CleanupResult?>
    >.internal(
      ManualCleanupExecution.new,
      name: r'manualCleanupExecutionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$manualCleanupExecutionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ManualCleanupExecution =
    AutoDisposeNotifier<AsyncValue<CleanupResult?>>;
String _$cleanupPolicySettingsHash() =>
    r'805395a37ad4f14fb915f15c55e5d9b1400842db';

/// 정리 정책 설정 프로바이더
///
/// Copied from [CleanupPolicySettings].
@ProviderFor(CleanupPolicySettings)
final cleanupPolicySettingsProvider =
    AutoDisposeNotifierProvider<CleanupPolicySettings, CleanupPolicy>.internal(
      CleanupPolicySettings.new,
      name: r'cleanupPolicySettingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cleanupPolicySettingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CleanupPolicySettings = AutoDisposeNotifier<CleanupPolicy>;
String _$cleanupScheduleSettingsHash() =>
    r'2c8bd040807895b12fc3765591e337c7c479ecb0';

/// 정리 스케줄 설정 프로바이더
///
/// Copied from [CleanupScheduleSettings].
@ProviderFor(CleanupScheduleSettings)
final cleanupScheduleSettingsProvider =
    AutoDisposeNotifierProvider<
      CleanupScheduleSettings,
      CleanupSchedule
    >.internal(
      CleanupScheduleSettings.new,
      name: r'cleanupScheduleSettingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cleanupScheduleSettingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CleanupScheduleSettings = AutoDisposeNotifier<CleanupSchedule>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
