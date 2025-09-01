// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$indicatorDetailHash() => r'91b2fff1160d01156c8cf05673e52004a14aa6e7';

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

/// 지표 상세 정보 프로바이더
///
/// Copied from [indicatorDetail].
@ProviderFor(indicatorDetail)
const indicatorDetailProvider = IndicatorDetailFamily();

/// 지표 상세 정보 프로바이더
///
/// Copied from [indicatorDetail].
class IndicatorDetailFamily extends Family<AsyncValue<IndicatorDetail>> {
  /// 지표 상세 정보 프로바이더
  ///
  /// Copied from [indicatorDetail].
  const IndicatorDetailFamily();

  /// 지표 상세 정보 프로바이더
  ///
  /// Copied from [indicatorDetail].
  IndicatorDetailProvider call(IndicatorCode indicatorCode, Country country) {
    return IndicatorDetailProvider(indicatorCode, country);
  }

  @override
  IndicatorDetailProvider getProviderOverride(
    covariant IndicatorDetailProvider provider,
  ) {
    return call(provider.indicatorCode, provider.country);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'indicatorDetailProvider';
}

/// 지표 상세 정보 프로바이더
///
/// Copied from [indicatorDetail].
class IndicatorDetailProvider
    extends AutoDisposeFutureProvider<IndicatorDetail> {
  /// 지표 상세 정보 프로바이더
  ///
  /// Copied from [indicatorDetail].
  IndicatorDetailProvider(IndicatorCode indicatorCode, Country country)
    : this._internal(
        (ref) =>
            indicatorDetail(ref as IndicatorDetailRef, indicatorCode, country),
        from: indicatorDetailProvider,
        name: r'indicatorDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$indicatorDetailHash,
        dependencies: IndicatorDetailFamily._dependencies,
        allTransitiveDependencies:
            IndicatorDetailFamily._allTransitiveDependencies,
        indicatorCode: indicatorCode,
        country: country,
      );

  IndicatorDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.indicatorCode,
    required this.country,
  }) : super.internal();

  final IndicatorCode indicatorCode;
  final Country country;

  @override
  Override overrideWith(
    FutureOr<IndicatorDetail> Function(IndicatorDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IndicatorDetailProvider._internal(
        (ref) => create(ref as IndicatorDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        indicatorCode: indicatorCode,
        country: country,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<IndicatorDetail> createElement() {
    return _IndicatorDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IndicatorDetailProvider &&
        other.indicatorCode == indicatorCode &&
        other.country == country;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, indicatorCode.hashCode);
    hash = _SystemHash.combine(hash, country.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IndicatorDetailRef on AutoDisposeFutureProviderRef<IndicatorDetail> {
  /// The parameter `indicatorCode` of this provider.
  IndicatorCode get indicatorCode;

  /// The parameter `country` of this provider.
  Country get country;
}

class _IndicatorDetailProviderElement
    extends AutoDisposeFutureProviderElement<IndicatorDetail>
    with IndicatorDetailRef {
  _IndicatorDetailProviderElement(super.provider);

  @override
  IndicatorCode get indicatorCode =>
      (origin as IndicatorDetailProvider).indicatorCode;
  @override
  Country get country => (origin as IndicatorDetailProvider).country;
}

String _$indicatorMetadataHash() => r'65bada9cfc1a8f721ee587d710cc10313d6800d0';

/// 지표 메타데이터 프로바이더
///
/// Copied from [indicatorMetadata].
@ProviderFor(indicatorMetadata)
const indicatorMetadataProvider = IndicatorMetadataFamily();

/// 지표 메타데이터 프로바이더
///
/// Copied from [indicatorMetadata].
class IndicatorMetadataFamily extends Family<IndicatorDetailMetadata> {
  /// 지표 메타데이터 프로바이더
  ///
  /// Copied from [indicatorMetadata].
  const IndicatorMetadataFamily();

  /// 지표 메타데이터 프로바이더
  ///
  /// Copied from [indicatorMetadata].
  IndicatorMetadataProvider call(IndicatorCode indicatorCode) {
    return IndicatorMetadataProvider(indicatorCode);
  }

  @override
  IndicatorMetadataProvider getProviderOverride(
    covariant IndicatorMetadataProvider provider,
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
  String? get name => r'indicatorMetadataProvider';
}

/// 지표 메타데이터 프로바이더
///
/// Copied from [indicatorMetadata].
class IndicatorMetadataProvider
    extends AutoDisposeProvider<IndicatorDetailMetadata> {
  /// 지표 메타데이터 프로바이더
  ///
  /// Copied from [indicatorMetadata].
  IndicatorMetadataProvider(IndicatorCode indicatorCode)
    : this._internal(
        (ref) => indicatorMetadata(ref as IndicatorMetadataRef, indicatorCode),
        from: indicatorMetadataProvider,
        name: r'indicatorMetadataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$indicatorMetadataHash,
        dependencies: IndicatorMetadataFamily._dependencies,
        allTransitiveDependencies:
            IndicatorMetadataFamily._allTransitiveDependencies,
        indicatorCode: indicatorCode,
      );

  IndicatorMetadataProvider._internal(
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
    IndicatorDetailMetadata Function(IndicatorMetadataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IndicatorMetadataProvider._internal(
        (ref) => create(ref as IndicatorMetadataRef),
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
  AutoDisposeProviderElement<IndicatorDetailMetadata> createElement() {
    return _IndicatorMetadataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IndicatorMetadataProvider &&
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
mixin IndicatorMetadataRef on AutoDisposeProviderRef<IndicatorDetailMetadata> {
  /// The parameter `indicatorCode` of this provider.
  IndicatorCode get indicatorCode;
}

class _IndicatorMetadataProviderElement
    extends AutoDisposeProviderElement<IndicatorDetailMetadata>
    with IndicatorMetadataRef {
  _IndicatorMetadataProviderElement(super.provider);

  @override
  IndicatorCode get indicatorCode =>
      (origin as IndicatorMetadataProvider).indicatorCode;
}

String _$bookmarkViewModelHash() => r'6a3086c73d226b95cc48efb382776861f644a1c3';

/// 북마크 관리 뷰모델
///
/// Copied from [BookmarkViewModel].
@ProviderFor(BookmarkViewModel)
final bookmarkViewModelProvider =
    AutoDisposeNotifierProvider<BookmarkViewModel, Set<String>>.internal(
      BookmarkViewModel.new,
      name: r'bookmarkViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bookmarkViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BookmarkViewModel = AutoDisposeNotifier<Set<String>>;
String _$indicatorComparisonViewModelHash() =>
    r'bd58f5e68f075c040e59712e164fbb3b8dd85a73';

/// 지표 비교 뷰모델
///
/// Copied from [IndicatorComparisonViewModel].
@ProviderFor(IndicatorComparisonViewModel)
final indicatorComparisonViewModelProvider =
    AutoDisposeNotifierProvider<
      IndicatorComparisonViewModel,
      List<IndicatorCode>
    >.internal(
      IndicatorComparisonViewModel.new,
      name: r'indicatorComparisonViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$indicatorComparisonViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IndicatorComparisonViewModel =
    AutoDisposeNotifier<List<IndicatorCode>>;
String _$recentIndicatorsViewModelHash() =>
    r'74a043c93a411e076381dadf1da9d111a2fcd720';

/// 최근 본 지표 뷰모델
///
/// Copied from [RecentIndicatorsViewModel].
@ProviderFor(RecentIndicatorsViewModel)
final recentIndicatorsViewModelProvider =
    AutoDisposeNotifierProvider<
      RecentIndicatorsViewModel,
      List<RecentIndicator>
    >.internal(
      RecentIndicatorsViewModel.new,
      name: r'recentIndicatorsViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recentIndicatorsViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecentIndicatorsViewModel =
    AutoDisposeNotifier<List<RecentIndicator>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
