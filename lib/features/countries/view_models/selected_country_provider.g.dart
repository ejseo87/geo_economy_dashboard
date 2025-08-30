// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_country_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedCountryCodeHash() =>
    r'808b504acafc436a0042ad237d1629b826a7d2a5';

/// 선택된 국가 정보를 제공하는 편의 Provider들
///
/// Copied from [selectedCountryCode].
@ProviderFor(selectedCountryCode)
final selectedCountryCodeProvider = AutoDisposeProvider<String>.internal(
  selectedCountryCode,
  name: r'selectedCountryCodeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCountryCodeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SelectedCountryCodeRef = AutoDisposeProviderRef<String>;
String _$selectedCountryNameHash() =>
    r'a5a2077e6f9f784bff471d62b198cc8c29d6b3f8';

/// See also [selectedCountryName].
@ProviderFor(selectedCountryName)
final selectedCountryNameProvider = AutoDisposeProvider<String>.internal(
  selectedCountryName,
  name: r'selectedCountryNameProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCountryNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SelectedCountryNameRef = AutoDisposeProviderRef<String>;
String _$selectedCountryFlagHash() =>
    r'c936b83c6dd8dc82985f8b74f13d26743b11de8a';

/// See also [selectedCountryFlag].
@ProviderFor(selectedCountryFlag)
final selectedCountryFlagProvider = AutoDisposeProvider<String>.internal(
  selectedCountryFlag,
  name: r'selectedCountryFlagProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCountryFlagHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SelectedCountryFlagRef = AutoDisposeProviderRef<String>;
String _$isKoreaSelectedHash() => r'bc6686759e4736b01122b8bce70bd1539e4c4a00';

/// 국가가 한국인지 확인하는 Provider
///
/// Copied from [isKoreaSelected].
@ProviderFor(isKoreaSelected)
final isKoreaSelectedProvider = AutoDisposeProvider<bool>.internal(
  isKoreaSelected,
  name: r'isKoreaSelectedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isKoreaSelectedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsKoreaSelectedRef = AutoDisposeProviderRef<bool>;
String _$selectedCountryHash() => r'c1df1671cce716f544ff9af25293cc3395bc9385';

/// 선택된 국가 상태 관리 Provider
///
/// Copied from [SelectedCountry].
@ProviderFor(SelectedCountry)
final selectedCountryProvider =
    AutoDisposeNotifierProvider<SelectedCountry, Country>.internal(
      SelectedCountry.new,
      name: r'selectedCountryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedCountryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedCountry = AutoDisposeNotifier<Country>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
