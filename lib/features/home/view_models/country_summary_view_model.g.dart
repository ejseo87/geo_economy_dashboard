// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_summary_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(CountrySummaryViewModel)
const countrySummaryViewModelProvider = CountrySummaryViewModelProvider._();

final class CountrySummaryViewModelProvider
    extends
        $NotifierProvider<CountrySummaryViewModel, AsyncValue<CountrySummary>> {
  const CountrySummaryViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countrySummaryViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countrySummaryViewModelHash();

  @$internal
  @override
  CountrySummaryViewModel create() => CountrySummaryViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<CountrySummary> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<CountrySummary>>(value),
    );
  }
}

String _$countrySummaryViewModelHash() =>
    r'6d2dfa72cffc77a3ad0c4c964d26c3c5db858af4';

abstract class _$CountrySummaryViewModel
    extends $Notifier<AsyncValue<CountrySummary>> {
  AsyncValue<CountrySummary> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<CountrySummary>, AsyncValue<CountrySummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CountrySummary>,
                AsyncValue<CountrySummary>
              >,
              AsyncValue<CountrySummary>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
