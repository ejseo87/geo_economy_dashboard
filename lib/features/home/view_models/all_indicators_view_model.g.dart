// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_indicators_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryPerformanceHash() =>
    r'7c4b468f928a686fcfccf82381fadbdb5dad2923';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 특정 카테고리 성과 요약 프로바이더
///
/// Copied from [categoryPerformance].
@ProviderFor(categoryPerformance)
const categoryPerformanceProvider = CategoryPerformanceFamily();

/// 특정 카테고리 성과 요약 프로바이더
///
/// Copied from [categoryPerformance].
class CategoryPerformanceFamily
    extends Family<AsyncValue<CategoryPerformanceSummary>> {
  /// 특정 카테고리 성과 요약 프로바이더
  ///
  /// Copied from [categoryPerformance].
  const CategoryPerformanceFamily();

  /// 특정 카테고리 성과 요약 프로바이더
  ///
  /// Copied from [categoryPerformance].
  CategoryPerformanceProvider call(String category) {
    return CategoryPerformanceProvider(category);
  }

  @override
  CategoryPerformanceProvider getProviderOverride(
    covariant CategoryPerformanceProvider provider,
  ) {
    return call(provider.category);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoryPerformanceProvider';
}

/// 특정 카테고리 성과 요약 프로바이더
///
/// Copied from [categoryPerformance].
class CategoryPerformanceProvider
    extends AutoDisposeFutureProvider<CategoryPerformanceSummary> {
  /// 특정 카테고리 성과 요약 프로바이더
  ///
  /// Copied from [categoryPerformance].
  CategoryPerformanceProvider(String category)
    : this._internal(
        (ref) => categoryPerformance(ref as CategoryPerformanceRef, category),
        from: categoryPerformanceProvider,
        name: r'categoryPerformanceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$categoryPerformanceHash,
        dependencies: CategoryPerformanceFamily._dependencies,
        allTransitiveDependencies:
            CategoryPerformanceFamily._allTransitiveDependencies,
        category: category,
      );

  CategoryPerformanceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final String category;

  @override
  Override overrideWith(
    FutureOr<CategoryPerformanceSummary> Function(
      CategoryPerformanceRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CategoryPerformanceProvider._internal(
        (ref) => create(ref as CategoryPerformanceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CategoryPerformanceSummary> createElement() {
    return _CategoryPerformanceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryPerformanceProvider && other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoryPerformanceRef
    on AutoDisposeFutureProviderRef<CategoryPerformanceSummary> {
  /// The parameter `category` of this provider.
  String get category;
}

class _CategoryPerformanceProviderElement
    extends AutoDisposeFutureProviderElement<CategoryPerformanceSummary>
    with CategoryPerformanceRef {
  _CategoryPerformanceProviderElement(super.provider);

  @override
  String get category => (origin as CategoryPerformanceProvider).category;
}

String _$singleIndicatorComparisonHash() =>
    r'fe87b9e4722a37afb16e44dbe9dbcb550cd1d486';

/// 단일 지표 비교 프로바이더 (개선된 버전)
///
/// Copied from [singleIndicatorComparison].
@ProviderFor(singleIndicatorComparison)
const singleIndicatorComparisonProvider = SingleIndicatorComparisonFamily();

/// 단일 지표 비교 프로바이더 (개선된 버전)
///
/// Copied from [singleIndicatorComparison].
class SingleIndicatorComparisonFamily
    extends Family<AsyncValue<IndicatorComparison>> {
  /// 단일 지표 비교 프로바이더 (개선된 버전)
  ///
  /// Copied from [singleIndicatorComparison].
  const SingleIndicatorComparisonFamily();

  /// 단일 지표 비교 프로바이더 (개선된 버전)
  ///
  /// Copied from [singleIndicatorComparison].
  SingleIndicatorComparisonProvider call(IndicatorCode indicatorCode) {
    return SingleIndicatorComparisonProvider(indicatorCode);
  }

  @override
  SingleIndicatorComparisonProvider getProviderOverride(
    covariant SingleIndicatorComparisonProvider provider,
  ) {
    return call(provider.indicatorCode);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'singleIndicatorComparisonProvider';
}

/// 단일 지표 비교 프로바이더 (개선된 버전)
///
/// Copied from [singleIndicatorComparison].
class SingleIndicatorComparisonProvider
    extends AutoDisposeFutureProvider<IndicatorComparison> {
  /// 단일 지표 비교 프로바이더 (개선된 버전)
  ///
  /// Copied from [singleIndicatorComparison].
  SingleIndicatorComparisonProvider(IndicatorCode indicatorCode)
    : this._internal(
        (ref) => singleIndicatorComparison(
          ref as SingleIndicatorComparisonRef,
          indicatorCode,
        ),
        from: singleIndicatorComparisonProvider,
        name: r'singleIndicatorComparisonProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$singleIndicatorComparisonHash,
        dependencies: SingleIndicatorComparisonFamily._dependencies,
        allTransitiveDependencies:
            SingleIndicatorComparisonFamily._allTransitiveDependencies,
        indicatorCode: indicatorCode,
      );

  SingleIndicatorComparisonProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.indicatorCode,
  }) : super.internal();

  final IndicatorCode indicatorCode;

  @override
  Override overrideWith(
    FutureOr<IndicatorComparison> Function(
      SingleIndicatorComparisonRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SingleIndicatorComparisonProvider._internal(
        (ref) => create(ref as SingleIndicatorComparisonRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        indicatorCode: indicatorCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<IndicatorComparison> createElement() {
    return _SingleIndicatorComparisonProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleIndicatorComparisonProvider &&
        other.indicatorCode == indicatorCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, indicatorCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SingleIndicatorComparisonRef
    on AutoDisposeFutureProviderRef<IndicatorComparison> {
  /// The parameter `indicatorCode` of this provider.
  IndicatorCode get indicatorCode;
}

class _SingleIndicatorComparisonProviderElement
    extends AutoDisposeFutureProviderElement<IndicatorComparison>
    with SingleIndicatorComparisonRef {
  _SingleIndicatorComparisonProviderElement(super.provider);

  @override
  IndicatorCode get indicatorCode =>
      (origin as SingleIndicatorComparisonProvider).indicatorCode;
}

String _$allIndicatorsViewModelHash() =>
    r'26b9d8355727f6ce19f8fb1e476537aae098b53a';

/// See also [AllIndicatorsViewModel].
@ProviderFor(AllIndicatorsViewModel)
final allIndicatorsViewModelProvider =
    AutoDisposeNotifierProvider<
      AllIndicatorsViewModel,
      AsyncValue<Map<String, List<IndicatorComparison>>>
    >.internal(
      AllIndicatorsViewModel.new,
      name: r'allIndicatorsViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allIndicatorsViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AllIndicatorsViewModel =
    AutoDisposeNotifier<AsyncValue<Map<String, List<IndicatorComparison>>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
