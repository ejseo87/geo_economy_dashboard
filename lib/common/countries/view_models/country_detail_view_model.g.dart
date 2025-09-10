// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$countryDetailViewModelHash() =>
    r'fb9bb22657dcaf378293008688699c61f1becaa7';

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

abstract class _$CountryDetailViewModel
    extends BuildlessAutoDisposeNotifier<CountryDetailState> {
  late final Country country;

  CountryDetailState build(Country country);
}

/// 국가상세화면 뷰모델
///
/// Copied from [CountryDetailViewModel].
@ProviderFor(CountryDetailViewModel)
const countryDetailViewModelProvider = CountryDetailViewModelFamily();

/// 국가상세화면 뷰모델
///
/// Copied from [CountryDetailViewModel].
class CountryDetailViewModelFamily extends Family<CountryDetailState> {
  /// 국가상세화면 뷰모델
  ///
  /// Copied from [CountryDetailViewModel].
  const CountryDetailViewModelFamily();

  /// 국가상세화면 뷰모델
  ///
  /// Copied from [CountryDetailViewModel].
  CountryDetailViewModelProvider call(Country country) {
    return CountryDetailViewModelProvider(country);
  }

  @override
  CountryDetailViewModelProvider getProviderOverride(
    covariant CountryDetailViewModelProvider provider,
  ) {
    return call(provider.country);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'countryDetailViewModelProvider';
}

/// 국가상세화면 뷰모델
///
/// Copied from [CountryDetailViewModel].
class CountryDetailViewModelProvider
    extends
        AutoDisposeNotifierProviderImpl<
          CountryDetailViewModel,
          CountryDetailState
        > {
  /// 국가상세화면 뷰모델
  ///
  /// Copied from [CountryDetailViewModel].
  CountryDetailViewModelProvider(Country country)
    : this._internal(
        () => CountryDetailViewModel()..country = country,
        from: countryDetailViewModelProvider,
        name: r'countryDetailViewModelProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$countryDetailViewModelHash,
        dependencies: CountryDetailViewModelFamily._dependencies,
        allTransitiveDependencies:
            CountryDetailViewModelFamily._allTransitiveDependencies,
        country: country,
      );

  CountryDetailViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.country,
  }) : super.internal();

  final Country country;

  @override
  CountryDetailState runNotifierBuild(
    covariant CountryDetailViewModel notifier,
  ) {
    return notifier.build(country);
  }

  @override
  Override overrideWith(CountryDetailViewModel Function() create) {
    return ProviderOverride(
      origin: this,
      override: CountryDetailViewModelProvider._internal(
        () => create()..country = country,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        country: country,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<CountryDetailViewModel, CountryDetailState>
  createElement() {
    return _CountryDetailViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CountryDetailViewModelProvider && other.country == country;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, country.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CountryDetailViewModelRef
    on AutoDisposeNotifierProviderRef<CountryDetailState> {
  /// The parameter `country` of this provider.
  Country get country;
}

class _CountryDetailViewModelProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          CountryDetailViewModel,
          CountryDetailState
        >
    with CountryDetailViewModelRef {
  _CountryDetailViewModelProviderElement(super.provider);

  @override
  Country get country => (origin as CountryDetailViewModelProvider).country;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
