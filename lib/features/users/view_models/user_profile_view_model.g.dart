// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isAdminUserHash() => r'd73b02e852e59c2c91200a01636908cc3c878456';

/// 관리자 권한 체크 Provider
///
/// Copied from [isAdminUser].
@ProviderFor(isAdminUser)
final isAdminUserProvider = AutoDisposeFutureProvider<bool>.internal(
  isAdminUser,
  name: r'isAdminUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAdminUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAdminUserRef = AutoDisposeFutureProviderRef<bool>;
String _$subscriptionStatusHash() =>
    r'df03888a3ddaec210f3a31f3592da2a1aa392dec';

/// 구독 상태 Provider
///
/// Copied from [subscriptionStatus].
@ProviderFor(subscriptionStatus)
final subscriptionStatusProvider =
    AutoDisposeFutureProvider<SubscriptionStatus>.internal(
      subscriptionStatus,
      name: r'subscriptionStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$subscriptionStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubscriptionStatusRef =
    AutoDisposeFutureProviderRef<SubscriptionStatus>;
String _$hasUserPermissionHash() => r'032af4b4d2f1d51c7d94f64c0e7afdf5a084150e';

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

/// 특정 권한 체크 Provider
///
/// Copied from [hasUserPermission].
@ProviderFor(hasUserPermission)
const hasUserPermissionProvider = HasUserPermissionFamily();

/// 특정 권한 체크 Provider
///
/// Copied from [hasUserPermission].
class HasUserPermissionFamily extends Family<AsyncValue<bool>> {
  /// 특정 권한 체크 Provider
  ///
  /// Copied from [hasUserPermission].
  const HasUserPermissionFamily();

  /// 특정 권한 체크 Provider
  ///
  /// Copied from [hasUserPermission].
  HasUserPermissionProvider call(String permission) {
    return HasUserPermissionProvider(permission);
  }

  @override
  HasUserPermissionProvider getProviderOverride(
    covariant HasUserPermissionProvider provider,
  ) {
    return call(provider.permission);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'hasUserPermissionProvider';
}

/// 특정 권한 체크 Provider
///
/// Copied from [hasUserPermission].
class HasUserPermissionProvider extends AutoDisposeFutureProvider<bool> {
  /// 특정 권한 체크 Provider
  ///
  /// Copied from [hasUserPermission].
  HasUserPermissionProvider(String permission)
    : this._internal(
        (ref) => hasUserPermission(ref as HasUserPermissionRef, permission),
        from: hasUserPermissionProvider,
        name: r'hasUserPermissionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$hasUserPermissionHash,
        dependencies: HasUserPermissionFamily._dependencies,
        allTransitiveDependencies:
            HasUserPermissionFamily._allTransitiveDependencies,
        permission: permission,
      );

  HasUserPermissionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.permission,
  }) : super.internal();

  final String permission;

  @override
  Override overrideWith(
    FutureOr<bool> Function(HasUserPermissionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasUserPermissionProvider._internal(
        (ref) => create(ref as HasUserPermissionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        permission: permission,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _HasUserPermissionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasUserPermissionProvider && other.permission == permission;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, permission.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HasUserPermissionRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `permission` of this provider.
  String get permission;
}

class _HasUserPermissionProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with HasUserPermissionRef {
  _HasUserPermissionProviderElement(super.provider);

  @override
  String get permission => (origin as HasUserPermissionProvider).permission;
}

String _$checkPermissionWithLimitsHash() =>
    r'362821e05bff06ebedfefe4f9d70a4050a79448f';

/// 권한과 제한 체크 Provider
///
/// Copied from [checkPermissionWithLimits].
@ProviderFor(checkPermissionWithLimits)
const checkPermissionWithLimitsProvider = CheckPermissionWithLimitsFamily();

/// 권한과 제한 체크 Provider
///
/// Copied from [checkPermissionWithLimits].
class CheckPermissionWithLimitsFamily
    extends Family<AsyncValue<PermissionResult>> {
  /// 권한과 제한 체크 Provider
  ///
  /// Copied from [checkPermissionWithLimits].
  const CheckPermissionWithLimitsFamily();

  /// 권한과 제한 체크 Provider
  ///
  /// Copied from [checkPermissionWithLimits].
  CheckPermissionWithLimitsProvider call(String permission) {
    return CheckPermissionWithLimitsProvider(permission);
  }

  @override
  CheckPermissionWithLimitsProvider getProviderOverride(
    covariant CheckPermissionWithLimitsProvider provider,
  ) {
    return call(provider.permission);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'checkPermissionWithLimitsProvider';
}

/// 권한과 제한 체크 Provider
///
/// Copied from [checkPermissionWithLimits].
class CheckPermissionWithLimitsProvider
    extends AutoDisposeFutureProvider<PermissionResult> {
  /// 권한과 제한 체크 Provider
  ///
  /// Copied from [checkPermissionWithLimits].
  CheckPermissionWithLimitsProvider(String permission)
    : this._internal(
        (ref) => checkPermissionWithLimits(
          ref as CheckPermissionWithLimitsRef,
          permission,
        ),
        from: checkPermissionWithLimitsProvider,
        name: r'checkPermissionWithLimitsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$checkPermissionWithLimitsHash,
        dependencies: CheckPermissionWithLimitsFamily._dependencies,
        allTransitiveDependencies:
            CheckPermissionWithLimitsFamily._allTransitiveDependencies,
        permission: permission,
      );

  CheckPermissionWithLimitsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.permission,
  }) : super.internal();

  final String permission;

  @override
  Override overrideWith(
    FutureOr<PermissionResult> Function(CheckPermissionWithLimitsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CheckPermissionWithLimitsProvider._internal(
        (ref) => create(ref as CheckPermissionWithLimitsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        permission: permission,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PermissionResult> createElement() {
    return _CheckPermissionWithLimitsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CheckPermissionWithLimitsProvider &&
        other.permission == permission;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, permission.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CheckPermissionWithLimitsRef
    on AutoDisposeFutureProviderRef<PermissionResult> {
  /// The parameter `permission` of this provider.
  String get permission;
}

class _CheckPermissionWithLimitsProviderElement
    extends AutoDisposeFutureProviderElement<PermissionResult>
    with CheckPermissionWithLimitsRef {
  _CheckPermissionWithLimitsProviderElement(super.provider);

  @override
  String get permission =>
      (origin as CheckPermissionWithLimitsProvider).permission;
}

String _$userProfileViewModelHash() =>
    r'8559eb9ff1d8cd49af377c10c9ea2d632a94fbe9';

/// 사용자 프로필 상태
///
/// Copied from [UserProfileViewModel].
@ProviderFor(UserProfileViewModel)
final userProfileViewModelProvider =
    AutoDisposeAsyncNotifierProvider<
      UserProfileViewModel,
      UserProfile?
    >.internal(
      UserProfileViewModel.new,
      name: r'userProfileViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userProfileViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserProfileViewModel = AutoDisposeAsyncNotifier<UserProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
