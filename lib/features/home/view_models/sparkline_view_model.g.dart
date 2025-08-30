// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sparkline_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sparklineViewModelHash() =>
    r'39209c2cd5817bd95318fb96b35613f4ba7e4fb9';

/// 스파크라인 뷰모델
///
/// Copied from [SparklineViewModel].
@ProviderFor(SparklineViewModel)
final sparklineViewModelProvider =
    AutoDisposeNotifierProvider<SparklineViewModel, SparklineState>.internal(
      SparklineViewModel.new,
      name: r'sparklineViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sparklineViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SparklineViewModel = AutoDisposeNotifier<SparklineState>;
String _$countrySparklineViewModelHash() =>
    r'354fb62e8a3877ef58fa19e849f1a219b0c99d77';

/// 국가별 스파크라인 프로바이더 (자동 갱신)
///
/// Copied from [CountrySparklineViewModel].
@ProviderFor(CountrySparklineViewModel)
final countrySparklineViewModelProvider =
    AutoDisposeAsyncNotifierProvider<
      CountrySparklineViewModel,
      List<SparklineData>
    >.internal(
      CountrySparklineViewModel.new,
      name: r'countrySparklineViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$countrySparklineViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CountrySparklineViewModel =
    AutoDisposeAsyncNotifier<List<SparklineData>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
