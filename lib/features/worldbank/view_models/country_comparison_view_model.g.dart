// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_comparison_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$countryComparisonViewModelHash() =>
    r'da3f4c42b3b42afc9cb7c252f67efe212edf79f8';

/// PRD v1.1 - 국가간 비교 또는 지표별 전체 국가 비교를 위한 ViewModel
///
/// Copied from [CountryComparisonViewModel].
@ProviderFor(CountryComparisonViewModel)
final countryComparisonViewModelProvider =
    AutoDisposeNotifierProvider<
      CountryComparisonViewModel,
      AsyncValue<CountryComparisonResult?>
    >.internal(
      CountryComparisonViewModel.new,
      name: r'countryComparisonViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$countryComparisonViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CountryComparisonViewModel =
    AutoDisposeNotifier<AsyncValue<CountryComparisonResult?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
