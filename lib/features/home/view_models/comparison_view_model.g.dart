// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comparison_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(ComparisonViewModel)
const comparisonViewModelProvider = ComparisonViewModelProvider._();

final class ComparisonViewModelProvider
    extends
        $NotifierProvider<
          ComparisonViewModel,
          AsyncValue<RecommendedComparison>
        > {
  const ComparisonViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'comparisonViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$comparisonViewModelHash();

  @$internal
  @override
  ComparisonViewModel create() => ComparisonViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RecommendedComparison> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<RecommendedComparison>>(
        value,
      ),
    );
  }
}

String _$comparisonViewModelHash() =>
    r'15a91743f6be58d3f35e55bf8dcc32d989157f0f';

abstract class _$ComparisonViewModel
    extends $Notifier<AsyncValue<RecommendedComparison>> {
  AsyncValue<RecommendedComparison> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<RecommendedComparison>,
              AsyncValue<RecommendedComparison>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<RecommendedComparison>,
                AsyncValue<RecommendedComparison>
              >,
              AsyncValue<RecommendedComparison>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(indicatorRepository)
const indicatorRepositoryProvider = IndicatorRepositoryProvider._();

final class IndicatorRepositoryProvider
    extends
        $FunctionalProvider<
          IndicatorRepository,
          IndicatorRepository,
          IndicatorRepository
        >
    with $Provider<IndicatorRepository> {
  const IndicatorRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indicatorRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indicatorRepositoryHash();

  @$internal
  @override
  $ProviderElement<IndicatorRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IndicatorRepository create(Ref ref) {
    return indicatorRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IndicatorRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IndicatorRepository>(value),
    );
  }
}

String _$indicatorRepositoryHash() =>
    r'7712e6ad3db06ee0704d7ac6c1f9f15c13b2b0eb';

@ProviderFor(indicatorComparison)
const indicatorComparisonProvider = IndicatorComparisonFamily._();

final class IndicatorComparisonProvider
    extends
        $FunctionalProvider<
          AsyncValue<IndicatorComparison>,
          IndicatorComparison,
          FutureOr<IndicatorComparison>
        >
    with
        $FutureModifier<IndicatorComparison>,
        $FutureProvider<IndicatorComparison> {
  const IndicatorComparisonProvider._({
    required IndicatorComparisonFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'indicatorComparisonProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$indicatorComparisonHash();

  @override
  String toString() {
    return r'indicatorComparisonProvider'
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
    final argument = this.argument as String;
    return indicatorComparison(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IndicatorComparisonProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$indicatorComparisonHash() =>
    r'a139ebf0f4a55a94d21990063632108aa658c85d';

final class IndicatorComparisonFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<IndicatorComparison>, String> {
  const IndicatorComparisonFamily._()
    : super(
        retry: null,
        name: r'indicatorComparisonProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IndicatorComparisonProvider call(String indicatorCode) =>
      IndicatorComparisonProvider._(argument: indicatorCode, from: this);

  @override
  String toString() => r'indicatorComparisonProvider';
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
