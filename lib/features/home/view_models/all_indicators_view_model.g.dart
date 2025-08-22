// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_indicators_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(AllIndicatorsViewModel)
const allIndicatorsViewModelProvider = AllIndicatorsViewModelProvider._();

final class AllIndicatorsViewModelProvider
    extends
        $NotifierProvider<
          AllIndicatorsViewModel,
          AsyncValue<Map<String, List<IndicatorComparison>>>
        > {
  const AllIndicatorsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allIndicatorsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allIndicatorsViewModelHash();

  @$internal
  @override
  AllIndicatorsViewModel create() => AllIndicatorsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<Map<String, List<IndicatorComparison>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<Map<String, List<IndicatorComparison>>>
          >(value),
    );
  }
}

String _$allIndicatorsViewModelHash() =>
    r'26b9d8355727f6ce19f8fb1e476537aae098b53a';

abstract class _$AllIndicatorsViewModel
    extends $Notifier<AsyncValue<Map<String, List<IndicatorComparison>>>> {
  AsyncValue<Map<String, List<IndicatorComparison>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, List<IndicatorComparison>>>,
              AsyncValue<Map<String, List<IndicatorComparison>>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, List<IndicatorComparison>>>,
                AsyncValue<Map<String, List<IndicatorComparison>>>
              >,
              AsyncValue<Map<String, List<IndicatorComparison>>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 특정 카테고리 성과 요약 프로바이더
@ProviderFor(categoryPerformance)
const categoryPerformanceProvider = CategoryPerformanceFamily._();

/// 특정 카테고리 성과 요약 프로바이더
final class CategoryPerformanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<CategoryPerformanceSummary>,
          CategoryPerformanceSummary,
          FutureOr<CategoryPerformanceSummary>
        >
    with
        $FutureModifier<CategoryPerformanceSummary>,
        $FutureProvider<CategoryPerformanceSummary> {
  /// 특정 카테고리 성과 요약 프로바이더
  const CategoryPerformanceProvider._({
    required CategoryPerformanceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'categoryPerformanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryPerformanceHash();

  @override
  String toString() {
    return r'categoryPerformanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CategoryPerformanceSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CategoryPerformanceSummary> create(Ref ref) {
    final argument = this.argument as String;
    return categoryPerformance(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryPerformanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryPerformanceHash() =>
    r'ee205933dbf2b5bdcafbe121d420f1823404c63d';

/// 특정 카테고리 성과 요약 프로바이더
final class CategoryPerformanceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CategoryPerformanceSummary>,
          String
        > {
  const CategoryPerformanceFamily._()
    : super(
        retry: null,
        name: r'categoryPerformanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 특정 카테고리 성과 요약 프로바이더
  CategoryPerformanceProvider call(String category) =>
      CategoryPerformanceProvider._(argument: category, from: this);

  @override
  String toString() => r'categoryPerformanceProvider';
}

/// 단일 지표 비교 프로바이더 (개선된 버전)
@ProviderFor(singleIndicatorComparison)
const singleIndicatorComparisonProvider = SingleIndicatorComparisonFamily._();

/// 단일 지표 비교 프로바이더 (개선된 버전)
final class SingleIndicatorComparisonProvider
    extends
        $FunctionalProvider<
          AsyncValue<IndicatorComparison>,
          IndicatorComparison,
          FutureOr<IndicatorComparison>
        >
    with
        $FutureModifier<IndicatorComparison>,
        $FutureProvider<IndicatorComparison> {
  /// 단일 지표 비교 프로바이더 (개선된 버전)
  const SingleIndicatorComparisonProvider._({
    required SingleIndicatorComparisonFamily super.from,
    required IndicatorCode super.argument,
  }) : super(
         retry: null,
         name: r'singleIndicatorComparisonProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$singleIndicatorComparisonHash();

  @override
  String toString() {
    return r'singleIndicatorComparisonProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<IndicatorComparison> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IndicatorComparison> create(Ref ref) {
    final argument = this.argument as IndicatorCode;
    return singleIndicatorComparison(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleIndicatorComparisonProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$singleIndicatorComparisonHash() =>
    r'fe64b30c55583c8764d12cd8787f1b4ff0769f43';

/// 단일 지표 비교 프로바이더 (개선된 버전)
final class SingleIndicatorComparisonFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<IndicatorComparison>,
          IndicatorCode
        > {
  const SingleIndicatorComparisonFamily._()
    : super(
        retry: null,
        name: r'singleIndicatorComparisonProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 단일 지표 비교 프로바이더 (개선된 버전)
  SingleIndicatorComparisonProvider call(IndicatorCode indicatorCode) =>
      SingleIndicatorComparisonProvider._(argument: indicatorCode, from: this);

  @override
  String toString() => r'singleIndicatorComparisonProvider';
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
