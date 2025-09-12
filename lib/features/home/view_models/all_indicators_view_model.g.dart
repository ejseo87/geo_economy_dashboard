// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_indicators_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryPerformanceHash() =>
    r'2a260110ff238c3f77e48b47a283903c33389a77';

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
  CategoryPerformanceProvider call(CoreIndicatorCategory category) {
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
  CategoryPerformanceProvider(CoreIndicatorCategory category)
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

  final CoreIndicatorCategory category;

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
  CoreIndicatorCategory get category;
}

class _CategoryPerformanceProviderElement
    extends AutoDisposeFutureProviderElement<CategoryPerformanceSummary>
    with CategoryPerformanceRef {
  _CategoryPerformanceProviderElement(super.provider);

  @override
  CoreIndicatorCategory get category =>
      (origin as CategoryPerformanceProvider).category;
}

String _$singleIndicatorDataHash() =>
    r'c90fa67fd210df306b5c40086b40328ba9735d9a';

/// 단일 지표 데이터 프로바이더 (개선된 버전)
///
/// Copied from [singleIndicatorData].
@ProviderFor(singleIndicatorData)
const singleIndicatorDataProvider = SingleIndicatorDataFamily();

/// 단일 지표 데이터 프로바이더 (개선된 버전)
///
/// Copied from [singleIndicatorData].
class SingleIndicatorDataFamily extends Family<AsyncValue<CountryIndicator>> {
  /// 단일 지표 데이터 프로바이더 (개선된 버전)
  ///
  /// Copied from [singleIndicatorData].
  const SingleIndicatorDataFamily();

  /// 단일 지표 데이터 프로바이더 (개선된 버전)
  ///
  /// Copied from [singleIndicatorData].
  SingleIndicatorDataProvider call(String indicatorCode) {
    return SingleIndicatorDataProvider(indicatorCode);
  }

  @override
  SingleIndicatorDataProvider getProviderOverride(
    covariant SingleIndicatorDataProvider provider,
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
  String? get name => r'singleIndicatorDataProvider';
}

/// 단일 지표 데이터 프로바이더 (개선된 버전)
///
/// Copied from [singleIndicatorData].
class SingleIndicatorDataProvider
    extends AutoDisposeFutureProvider<CountryIndicator> {
  /// 단일 지표 데이터 프로바이더 (개선된 버전)
  ///
  /// Copied from [singleIndicatorData].
  SingleIndicatorDataProvider(String indicatorCode)
    : this._internal(
        (ref) =>
            singleIndicatorData(ref as SingleIndicatorDataRef, indicatorCode),
        from: singleIndicatorDataProvider,
        name: r'singleIndicatorDataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$singleIndicatorDataHash,
        dependencies: SingleIndicatorDataFamily._dependencies,
        allTransitiveDependencies:
            SingleIndicatorDataFamily._allTransitiveDependencies,
        indicatorCode: indicatorCode,
      );

  SingleIndicatorDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.indicatorCode,
  }) : super.internal();

  final String indicatorCode;

  @override
  Override overrideWith(
    FutureOr<CountryIndicator> Function(SingleIndicatorDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SingleIndicatorDataProvider._internal(
        (ref) => create(ref as SingleIndicatorDataRef),
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
  AutoDisposeFutureProviderElement<CountryIndicator> createElement() {
    return _SingleIndicatorDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleIndicatorDataProvider &&
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
mixin SingleIndicatorDataRef on AutoDisposeFutureProviderRef<CountryIndicator> {
  /// The parameter `indicatorCode` of this provider.
  String get indicatorCode;
}

class _SingleIndicatorDataProviderElement
    extends AutoDisposeFutureProviderElement<CountryIndicator>
    with SingleIndicatorDataRef {
  _SingleIndicatorDataProviderElement(super.provider);

  @override
  String get indicatorCode =>
      (origin as SingleIndicatorDataProvider).indicatorCode;
}

String _$allIndicatorsViewModelHash() =>
    r'235dbd4ecc0c981c113be01dc5bcc244a68fab48';

/// See also [AllIndicatorsViewModel].
@ProviderFor(AllIndicatorsViewModel)
final allIndicatorsViewModelProvider =
    AutoDisposeNotifierProvider<
      AllIndicatorsViewModel,
      AsyncValue<Map<CoreIndicatorCategory, List<CountryIndicator>>>
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
    AutoDisposeNotifier<
      AsyncValue<Map<CoreIndicatorCategory, List<CountryIndicator>>>
    >;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
