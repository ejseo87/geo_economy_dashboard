// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tab_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(TabViewModel)
const tabViewModelProvider = TabViewModelProvider._();

final class TabViewModelProvider
    extends $NotifierProvider<TabViewModel, TabState> {
  const TabViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tabViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tabViewModelHash();

  @$internal
  @override
  TabViewModel create() => TabViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TabState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TabState>(value),
    );
  }
}

String _$tabViewModelHash() => r'bdeba5d8ef93bf6bf8b6caf258fe7d8dc8d3169c';

abstract class _$TabViewModel extends $Notifier<TabState> {
  TabState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TabState, TabState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TabState, TabState>,
              TabState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
