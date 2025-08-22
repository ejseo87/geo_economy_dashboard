// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sparkline_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// 스파크라인 뷰모델
@ProviderFor(SparklineViewModel)
const sparklineViewModelProvider = SparklineViewModelProvider._();

/// 스파크라인 뷰모델
final class SparklineViewModelProvider
    extends $NotifierProvider<SparklineViewModel, SparklineState> {
  /// 스파크라인 뷰모델
  const SparklineViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sparklineViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sparklineViewModelHash();

  @$internal
  @override
  SparklineViewModel create() => SparklineViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SparklineState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SparklineState>(value),
    );
  }
}

String _$sparklineViewModelHash() =>
    r'5d4012d636e82ea0c66f02f51755b000980bbde1';

abstract class _$SparklineViewModel extends $Notifier<SparklineState> {
  SparklineState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SparklineState, SparklineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SparklineState, SparklineState>,
              SparklineState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 국가별 스파크라인 프로바이더 (자동 갱신)
@ProviderFor(CountrySparklineViewModel)
const countrySparklineViewModelProvider = CountrySparklineViewModelProvider._();

/// 국가별 스파크라인 프로바이더 (자동 갱신)
final class CountrySparklineViewModelProvider
    extends
        $AsyncNotifierProvider<CountrySparklineViewModel, List<SparklineData>> {
  /// 국가별 스파크라인 프로바이더 (자동 갱신)
  const CountrySparklineViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countrySparklineViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countrySparklineViewModelHash();

  @$internal
  @override
  CountrySparklineViewModel create() => CountrySparklineViewModel();
}

String _$countrySparklineViewModelHash() =>
    r'77509210f2e7bbab0bd31eb5f351f9fc68f7d539';

abstract class _$CountrySparklineViewModel
    extends $AsyncNotifier<List<SparklineData>> {
  FutureOr<List<SparklineData>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<SparklineData>>, List<SparklineData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SparklineData>>, List<SparklineData>>,
              AsyncValue<List<SparklineData>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
