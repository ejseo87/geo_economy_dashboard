// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comparison_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$indicatorRepositoryHash() =>
    r'9cd71486210853143f7b70a1c5206b4282c695c0';

/// See also [indicatorRepository].
@ProviderFor(indicatorRepository)
final indicatorRepositoryProvider =
    AutoDisposeProvider<IndicatorRepository>.internal(
      indicatorRepository,
      name: r'indicatorRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$indicatorRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IndicatorRepositoryRef = AutoDisposeProviderRef<IndicatorRepository>;
String _$indicatorComparisonHash() =>
    r'123f5200a6801a7d7e388f7a602ca1ff3ecaacef';

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

/// See also [indicatorComparison].
@ProviderFor(indicatorComparison)
const indicatorComparisonProvider = IndicatorComparisonFamily();

/// See also [indicatorComparison].
class IndicatorComparisonFamily
    extends Family<AsyncValue<IndicatorComparison>> {
  /// See also [indicatorComparison].
  const IndicatorComparisonFamily();

  /// See also [indicatorComparison].
  IndicatorComparisonProvider call(String indicatorCode) {
    return IndicatorComparisonProvider(indicatorCode);
  }

  @override
  IndicatorComparisonProvider getProviderOverride(
    covariant IndicatorComparisonProvider provider,
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
  String? get name => r'indicatorComparisonProvider';
}

/// See also [indicatorComparison].
class IndicatorComparisonProvider
    extends AutoDisposeFutureProvider<IndicatorComparison> {
  /// See also [indicatorComparison].
  IndicatorComparisonProvider(String indicatorCode)
    : this._internal(
        (ref) =>
            indicatorComparison(ref as IndicatorComparisonRef, indicatorCode),
        from: indicatorComparisonProvider,
        name: r'indicatorComparisonProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$indicatorComparisonHash,
        dependencies: IndicatorComparisonFamily._dependencies,
        allTransitiveDependencies:
            IndicatorComparisonFamily._allTransitiveDependencies,
        indicatorCode: indicatorCode,
      );

  IndicatorComparisonProvider._internal(
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
    FutureOr<IndicatorComparison> Function(IndicatorComparisonRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IndicatorComparisonProvider._internal(
        (ref) => create(ref as IndicatorComparisonRef),
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
    return _IndicatorComparisonProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IndicatorComparisonProvider &&
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
mixin IndicatorComparisonRef
    on AutoDisposeFutureProviderRef<IndicatorComparison> {
  /// The parameter `indicatorCode` of this provider.
  String get indicatorCode;
}

class _IndicatorComparisonProviderElement
    extends AutoDisposeFutureProviderElement<IndicatorComparison>
    with IndicatorComparisonRef {
  _IndicatorComparisonProviderElement(super.provider);

  @override
  String get indicatorCode =>
      (origin as IndicatorComparisonProvider).indicatorCode;
}

String _$comparisonViewModelHash() =>
    r'15a91743f6be58d3f35e55bf8dcc32d989157f0f';

/// See also [ComparisonViewModel].
@ProviderFor(ComparisonViewModel)
final comparisonViewModelProvider =
    AutoDisposeNotifierProvider<
      ComparisonViewModel,
      AsyncValue<RecommendedComparison>
    >.internal(
      ComparisonViewModel.new,
      name: r'comparisonViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$comparisonViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ComparisonViewModel =
    AutoDisposeNotifier<AsyncValue<RecommendedComparison>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
