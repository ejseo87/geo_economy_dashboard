// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// 지표 상세 정보 프로바이더
@ProviderFor(indicatorDetail)
const indicatorDetailProvider = IndicatorDetailFamily._();

/// 지표 상세 정보 프로바이더
final class IndicatorDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<IndicatorDetail>,
          IndicatorDetail,
          FutureOr<IndicatorDetail>
        >
    with $FutureModifier<IndicatorDetail>, $FutureProvider<IndicatorDetail> {
  /// 지표 상세 정보 프로바이더
  const IndicatorDetailProvider._({
    required IndicatorDetailFamily super.from,
    required (IndicatorCode, Country) super.argument,
  }) : super(
         retry: null,
         name: r'indicatorDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$indicatorDetailHash();

  @override
  String toString() {
    return r'indicatorDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<IndicatorDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IndicatorDetail> create(Ref ref) {
    final argument = this.argument as (IndicatorCode, Country);
    return indicatorDetail(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is IndicatorDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$indicatorDetailHash() => r'91b2fff1160d01156c8cf05673e52004a14aa6e7';

/// 지표 상세 정보 프로바이더
final class IndicatorDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<IndicatorDetail>,
          (IndicatorCode, Country)
        > {
  const IndicatorDetailFamily._()
    : super(
        retry: null,
        name: r'indicatorDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 지표 상세 정보 프로바이더
  IndicatorDetailProvider call(IndicatorCode indicatorCode, Country country) =>
      IndicatorDetailProvider._(argument: (indicatorCode, country), from: this);

  @override
  String toString() => r'indicatorDetailProvider';
}

/// 지표 메타데이터 프로바이더
@ProviderFor(indicatorMetadata)
const indicatorMetadataProvider = IndicatorMetadataFamily._();

/// 지표 메타데이터 프로바이더
final class IndicatorMetadataProvider
    extends
        $FunctionalProvider<
          IndicatorDetailMetadata,
          IndicatorDetailMetadata,
          IndicatorDetailMetadata
        >
    with $Provider<IndicatorDetailMetadata> {
  /// 지표 메타데이터 프로바이더
  const IndicatorMetadataProvider._({
    required IndicatorMetadataFamily super.from,
    required IndicatorCode super.argument,
  }) : super(
         retry: null,
         name: r'indicatorMetadataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$indicatorMetadataHash();

  @override
  String toString() {
    return r'indicatorMetadataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<IndicatorDetailMetadata> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IndicatorDetailMetadata create(Ref ref) {
    final argument = this.argument as IndicatorCode;
    return indicatorMetadata(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IndicatorDetailMetadata value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IndicatorDetailMetadata>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IndicatorMetadataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$indicatorMetadataHash() => r'65bada9cfc1a8f721ee587d710cc10313d6800d0';

/// 지표 메타데이터 프로바이더
final class IndicatorMetadataFamily extends $Family
    with $FunctionalFamilyOverride<IndicatorDetailMetadata, IndicatorCode> {
  const IndicatorMetadataFamily._()
    : super(
        retry: null,
        name: r'indicatorMetadataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 지표 메타데이터 프로바이더
  IndicatorMetadataProvider call(IndicatorCode indicatorCode) =>
      IndicatorMetadataProvider._(argument: indicatorCode, from: this);

  @override
  String toString() => r'indicatorMetadataProvider';
}

/// 북마크 관리 뷰모델
@ProviderFor(BookmarkViewModel)
const bookmarkViewModelProvider = BookmarkViewModelProvider._();

/// 북마크 관리 뷰모델
final class BookmarkViewModelProvider
    extends $NotifierProvider<BookmarkViewModel, Set<String>> {
  /// 북마크 관리 뷰모델
  const BookmarkViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarkViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarkViewModelHash();

  @$internal
  @override
  BookmarkViewModel create() => BookmarkViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$bookmarkViewModelHash() => r'a86aa7838d485b285e4a8e655101850ce9a97f54';

abstract class _$BookmarkViewModel extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 지표 비교 뷰모델
@ProviderFor(IndicatorComparisonViewModel)
const indicatorComparisonViewModelProvider =
    IndicatorComparisonViewModelProvider._();

/// 지표 비교 뷰모델
final class IndicatorComparisonViewModelProvider
    extends
        $NotifierProvider<IndicatorComparisonViewModel, List<IndicatorCode>> {
  /// 지표 비교 뷰모델
  const IndicatorComparisonViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indicatorComparisonViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indicatorComparisonViewModelHash();

  @$internal
  @override
  IndicatorComparisonViewModel create() => IndicatorComparisonViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IndicatorCode> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IndicatorCode>>(value),
    );
  }
}

String _$indicatorComparisonViewModelHash() =>
    r'bd58f5e68f075c040e59712e164fbb3b8dd85a73';

abstract class _$IndicatorComparisonViewModel
    extends $Notifier<List<IndicatorCode>> {
  List<IndicatorCode> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<IndicatorCode>, List<IndicatorCode>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<IndicatorCode>, List<IndicatorCode>>,
              List<IndicatorCode>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 최근 본 지표 뷰모델
@ProviderFor(RecentIndicatorsViewModel)
const recentIndicatorsViewModelProvider = RecentIndicatorsViewModelProvider._();

/// 최근 본 지표 뷰모델
final class RecentIndicatorsViewModelProvider
    extends
        $NotifierProvider<RecentIndicatorsViewModel, List<RecentIndicator>> {
  /// 최근 본 지표 뷰모델
  const RecentIndicatorsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentIndicatorsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentIndicatorsViewModelHash();

  @$internal
  @override
  RecentIndicatorsViewModel create() => RecentIndicatorsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RecentIndicator> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RecentIndicator>>(value),
    );
  }
}

String _$recentIndicatorsViewModelHash() =>
    r'74a043c93a411e076381dadf1da9d111a2fcd720';

abstract class _$RecentIndicatorsViewModel
    extends $Notifier<List<RecentIndicator>> {
  List<RecentIndicator> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<RecentIndicator>, List<RecentIndicator>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<RecentIndicator>, List<RecentIndicator>>,
              List<RecentIndicator>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
