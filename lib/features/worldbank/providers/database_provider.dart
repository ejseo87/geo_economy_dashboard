import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/sqlite_database.dart';
import '../../../common/logger.dart';

part 'database_provider.g.dart';

/// SQLite 데이터베이스 초기화 및 관리 Provider
@riverpod
class DatabaseManager extends _$DatabaseManager {
  @override
  AsyncValue<bool> build() {
    // 자동으로 초기화 시작
    _initialize();
    return const AsyncValue.loading();
  }

  /// 내부 초기화 메소드
  void _initialize() {
    Future.microtask(() async {
      try {
        AppLogger.debug('[DatabaseManager] Initializing SQLite database...');
        
        final database = SQLiteDatabase();
        
        // 데이터베이스 연결 테스트
        await database.database;
        AppLogger.debug('[DatabaseManager] Database connection established');
        
        // 만료된 캐시 정리
        final cleanedCount = await database.cleanupExpiredCache();
        if (cleanedCount > 0) {
          AppLogger.debug('[DatabaseManager] Cleaned up $cleanedCount expired cache entries');
        }
        
        // 캐시 통계 로깅
        final stats = await database.getCacheStats();
        AppLogger.debug('[DatabaseManager] Cache stats: $stats');
        
        state = const AsyncValue.data(true);
        AppLogger.debug('[DatabaseManager] Database initialization completed');
      } catch (error, stackTrace) {
        AppLogger.error('[DatabaseManager] Database initialization failed: $error', stackTrace);
        state = AsyncValue.error(error, stackTrace);
      }
    });
  }

  /// 데이터베이스 재초기화
  Future<void> reinitialize() async {
    state = const AsyncValue.loading();
    _initialize();
  }

  /// 캐시 통계 가져오기
  Future<Map<String, int>> getCacheStats() async {
    try {
      final database = SQLiteDatabase();
      return await database.getCacheStats();
    } catch (error) {
      AppLogger.error('[DatabaseManager] Error getting cache stats: $error');
      return {};
    }
  }

  /// 전체 캐시 초기화
  Future<void> clearAllCache() async {
    try {
      AppLogger.debug('[DatabaseManager] Clearing all cache...');
      
      final database = SQLiteDatabase();
      await database.clearAllCache();
      
      AppLogger.debug('[DatabaseManager] All cache cleared');
    } catch (error, stackTrace) {
      AppLogger.error('[DatabaseManager] Error clearing cache: $error', stackTrace);
    }
  }

  /// 만료된 캐시 정리
  Future<int> cleanupExpiredCache() async {
    try {
      final database = SQLiteDatabase();
      return await database.cleanupExpiredCache();
    } catch (error) {
      AppLogger.error('[DatabaseManager] Error cleaning up cache: $error');
      return 0;
    }
  }
}