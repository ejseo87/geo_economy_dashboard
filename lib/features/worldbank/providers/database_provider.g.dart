// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseManagerHash() => r'2dc4bcf01de4a172f3375db4f7fd4126ab5b63e4';

/// SQLite 데이터베이스 초기화 및 관리 Provider
///
/// Copied from [DatabaseManager].
@ProviderFor(DatabaseManager)
final databaseManagerProvider =
    AutoDisposeNotifierProvider<DatabaseManager, AsyncValue<bool>>.internal(
      DatabaseManager.new,
      name: r'databaseManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$databaseManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DatabaseManager = AutoDisposeNotifier<AsyncValue<bool>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
