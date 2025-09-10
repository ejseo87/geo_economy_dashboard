// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_country_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedCountryCodeHash() =>
    r'619ed45e23f0db4699a0079bcbec5bf1a33e8dbf';

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
    r'c96614e059cbdea7e3ba19cdabc6d693e7207309';

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
    r'79cc2e161eabca769a89c85505310c06a76bffc7';

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
String _$isKoreaSelectedHash() => r'dbfbc0df05d58a18616c8c90d2ea60efc206d40e';

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
