// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_country_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// 선택된 국가 상태 관리 Provider
@ProviderFor(SelectedCountry)
const selectedCountryProvider = SelectedCountryProvider._();

/// 선택된 국가 상태 관리 Provider
final class SelectedCountryProvider
    extends $NotifierProvider<SelectedCountry, Country> {
  /// 선택된 국가 상태 관리 Provider
  const SelectedCountryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCountryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCountryHash();

  @$internal
  @override
  SelectedCountry create() => SelectedCountry();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Country value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Country>(value),
    );
  }
}

String _$selectedCountryHash() => r'c1df1671cce716f544ff9af25293cc3395bc9385';

abstract class _$SelectedCountry extends $Notifier<Country> {
  Country build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Country, Country>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Country, Country>,
              Country,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 선택된 국가 정보를 제공하는 편의 Provider들
@ProviderFor(selectedCountryCode)
const selectedCountryCodeProvider = SelectedCountryCodeProvider._();

/// 선택된 국가 정보를 제공하는 편의 Provider들
final class SelectedCountryCodeProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// 선택된 국가 정보를 제공하는 편의 Provider들
  const SelectedCountryCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCountryCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCountryCodeHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return selectedCountryCode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedCountryCodeHash() =>
    r'619ed45e23f0db4699a0079bcbec5bf1a33e8dbf';

@ProviderFor(selectedCountryName)
const selectedCountryNameProvider = SelectedCountryNameProvider._();

final class SelectedCountryNameProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  const SelectedCountryNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCountryNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCountryNameHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return selectedCountryName(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedCountryNameHash() =>
    r'c96614e059cbdea7e3ba19cdabc6d693e7207309';

@ProviderFor(selectedCountryFlag)
const selectedCountryFlagProvider = SelectedCountryFlagProvider._();

final class SelectedCountryFlagProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  const SelectedCountryFlagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCountryFlagProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCountryFlagHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return selectedCountryFlag(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedCountryFlagHash() =>
    r'79cc2e161eabca769a89c85505310c06a76bffc7';

/// 국가가 한국인지 확인하는 Provider
@ProviderFor(isKoreaSelected)
const isKoreaSelectedProvider = IsKoreaSelectedProvider._();

/// 국가가 한국인지 확인하는 Provider
final class IsKoreaSelectedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 국가가 한국인지 확인하는 Provider
  const IsKoreaSelectedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isKoreaSelectedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isKoreaSelectedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isKoreaSelected(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isKoreaSelectedHash() => r'dbfbc0df05d58a18616c8c90d2ea60efc206d40e';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
