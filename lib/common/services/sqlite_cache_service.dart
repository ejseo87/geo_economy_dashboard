import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../logger.dart';

class SQLiteCacheService {
  static SQLiteCacheService? _instance;
  static Database? _database;

  SQLiteCacheService._();

  static SQLiteCacheService get instance {
    _instance ??= SQLiteCacheService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'geo_economy_cache.db');
      
      AppLogger.info('[SQLiteCache] Initializing database at: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to initialize database', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    try {
      AppLogger.info('[SQLiteCache] Creating database tables...');

      // 지표 데이터 캐시 테이블
      await db.execute('''
        CREATE TABLE indicator_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          country_code TEXT NOT NULL,
          indicator_code TEXT NOT NULL,
          year INTEGER NOT NULL,
          value REAL,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL,
          UNIQUE(country_code, indicator_code, year)
        )
      ''');

      // OECD 통계 캐시 테이블
      await db.execute('''
        CREATE TABLE oecd_stats_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          indicator_code TEXT NOT NULL,
          year INTEGER NOT NULL,
          stats_json TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL,
          UNIQUE(indicator_code, year)
        )
      ''');

      // 국가 요약 캐시 테이블
      await db.execute('''
        CREATE TABLE country_summary_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          country_code TEXT NOT NULL UNIQUE,
          summary_json TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL
        )
      ''');

      // 메타데이터 캐시 테이블
      await db.execute('''
        CREATE TABLE metadata_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cache_key TEXT NOT NULL UNIQUE,
          data_json TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL
        )
      ''');

      // 인덱스 생성
      await db.execute('CREATE INDEX idx_indicator_cache_lookup ON indicator_cache(country_code, indicator_code, year)');
      await db.execute('CREATE INDEX idx_indicator_cache_expires ON indicator_cache(expires_at)');
      await db.execute('CREATE INDEX idx_oecd_stats_expires ON oecd_stats_cache(expires_at)');
      await db.execute('CREATE INDEX idx_country_summary_expires ON country_summary_cache(expires_at)');
      await db.execute('CREATE INDEX idx_metadata_expires ON metadata_cache(expires_at)');

      AppLogger.info('[SQLiteCache] Database tables created successfully');
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to create tables', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('[SQLiteCache] Upgrading database from version $oldVersion to $newVersion');
    // 향후 스키마 변경 시 사용
  }

  /// 지표 데이터 캐싱
  Future<void> cacheIndicatorData({
    required String countryCode,
    required String indicatorCode,
    required int year,
    required double value,
    Duration cacheDuration = const Duration(hours: 6),
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = DateTime.now().add(cacheDuration).millisecondsSinceEpoch;

      await db.insert(
        'indicator_cache',
        {
          'country_code': countryCode,
          'indicator_code': indicatorCode,
          'year': year,
          'value': value,
          'created_at': now,
          'expires_at': expiresAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.debug('[SQLiteCache] Cached indicator data: $countryCode/$indicatorCode/$year = $value');
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to cache indicator data', e, stackTrace);
    }
  }

  /// 지표 데이터 조회
  Future<double?> getCachedIndicatorData({
    required String countryCode,
    required String indicatorCode,
    required int year,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final result = await db.query(
        'indicator_cache',
        where: 'country_code = ? AND indicator_code = ? AND year = ? AND expires_at > ?',
        whereArgs: [countryCode, indicatorCode, year, now],
      );

      if (result.isNotEmpty) {
        final value = result.first['value'] as double?;
        AppLogger.debug('[SQLiteCache] Retrieved cached indicator data: $countryCode/$indicatorCode/$year = $value');
        return value;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to get cached indicator data', e, stackTrace);
      return null;
    }
  }

  /// OECD 통계 캐싱
  Future<void> cacheOECDStats({
    required String indicatorCode,
    required int year,
    required Map<String, dynamic> stats,
    Duration cacheDuration = const Duration(hours: 12),
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = DateTime.now().add(cacheDuration).millisecondsSinceEpoch;

      await db.insert(
        'oecd_stats_cache',
        {
          'indicator_code': indicatorCode,
          'year': year,
          'stats_json': jsonEncode(stats),
          'created_at': now,
          'expires_at': expiresAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.debug('[SQLiteCache] Cached OECD stats: $indicatorCode/$year');
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to cache OECD stats', e, stackTrace);
    }
  }

  /// OECD 통계 조회
  Future<Map<String, dynamic>?> getCachedOECDStats({
    required String indicatorCode,
    required int year,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final result = await db.query(
        'oecd_stats_cache',
        where: 'indicator_code = ? AND year = ? AND expires_at > ?',
        whereArgs: [indicatorCode, year, now],
      );

      if (result.isNotEmpty) {
        final statsJson = result.first['stats_json'] as String;
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        AppLogger.debug('[SQLiteCache] Retrieved cached OECD stats: $indicatorCode/$year');
        return stats;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to get cached OECD stats', e, stackTrace);
      return null;
    }
  }

  /// 국가 요약 캐싱
  Future<void> cacheCountrySummary({
    required String countryCode,
    required Map<String, dynamic> summary,
    Duration cacheDuration = const Duration(hours: 3),
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = DateTime.now().add(cacheDuration).millisecondsSinceEpoch;

      await db.insert(
        'country_summary_cache',
        {
          'country_code': countryCode,
          'summary_json': jsonEncode(summary),
          'created_at': now,
          'expires_at': expiresAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.debug('[SQLiteCache] Cached country summary: $countryCode');
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to cache country summary', e, stackTrace);
    }
  }

  /// 국가 요약 조회
  Future<Map<String, dynamic>?> getCachedCountrySummary({
    required String countryCode,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final result = await db.query(
        'country_summary_cache',
        where: 'country_code = ? AND expires_at > ?',
        whereArgs: [countryCode, now],
      );

      if (result.isNotEmpty) {
        final summaryJson = result.first['summary_json'] as String;
        final summary = jsonDecode(summaryJson) as Map<String, dynamic>;
        AppLogger.debug('[SQLiteCache] Retrieved cached country summary: $countryCode');
        return summary;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to get cached country summary', e, stackTrace);
      return null;
    }
  }

  /// 범용 메타데이터 캐싱
  Future<void> cacheMetadata({
    required String key,
    required Map<String, dynamic> data,
    Duration cacheDuration = const Duration(days: 1),
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = DateTime.now().add(cacheDuration).millisecondsSinceEpoch;

      await db.insert(
        'metadata_cache',
        {
          'cache_key': key,
          'data_json': jsonEncode(data),
          'created_at': now,
          'expires_at': expiresAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.debug('[SQLiteCache] Cached metadata: $key');
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to cache metadata', e, stackTrace);
    }
  }

  /// 범용 메타데이터 조회
  Future<Map<String, dynamic>?> getCachedMetadata({
    required String key,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final result = await db.query(
        'metadata_cache',
        where: 'cache_key = ? AND expires_at > ?',
        whereArgs: [key, now],
      );

      if (result.isNotEmpty) {
        final dataJson = result.first['data_json'] as String;
        final data = jsonDecode(dataJson) as Map<String, dynamic>;
        AppLogger.debug('[SQLiteCache] Retrieved cached metadata: $key');
        return data;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to get cached metadata', e, stackTrace);
      return null;
    }
  }

  /// 만료된 캐시 삭제
  Future<void> clearExpiredCache() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final indicatorDeleted = await db.delete('indicator_cache', where: 'expires_at <= ?', whereArgs: [now]);
      final oecdDeleted = await db.delete('oecd_stats_cache', where: 'expires_at <= ?', whereArgs: [now]);
      final summaryDeleted = await db.delete('country_summary_cache', where: 'expires_at <= ?', whereArgs: [now]);
      final metadataDeleted = await db.delete('metadata_cache', where: 'expires_at <= ?', whereArgs: [now]);

      final totalDeleted = indicatorDeleted + oecdDeleted + summaryDeleted + metadataDeleted;
      if (totalDeleted > 0) {
        AppLogger.info('[SQLiteCache] Cleared $totalDeleted expired cache entries');
      }
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to clear expired cache', e, stackTrace);
    }
  }

  /// 특정 국가의 캐시 삭제
  Future<void> clearCountryCache(String countryCode) async {
    try {
      final db = await database;

      await db.delete('indicator_cache', where: 'country_code = ?', whereArgs: [countryCode]);
      await db.delete('country_summary_cache', where: 'country_code = ?', whereArgs: [countryCode]);

      AppLogger.info('[SQLiteCache] Cleared cache for country: $countryCode');
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to clear country cache', e, stackTrace);
    }
  }

  /// 전체 캐시 삭제
  Future<void> clearAllCache() async {
    try {
      final db = await database;

      await db.delete('indicator_cache');
      await db.delete('oecd_stats_cache');
      await db.delete('country_summary_cache');
      await db.delete('metadata_cache');

      AppLogger.info('[SQLiteCache] Cleared all cache');
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to clear all cache', e, stackTrace);
    }
  }

  /// 캐시 통계 조회
  Future<Map<String, int>> getCacheStats() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final indicators = await db.rawQuery('SELECT COUNT(*) as count FROM indicator_cache WHERE expires_at > ?', [now]);
      final oecd = await db.rawQuery('SELECT COUNT(*) as count FROM oecd_stats_cache WHERE expires_at > ?', [now]);
      final summaries = await db.rawQuery('SELECT COUNT(*) as count FROM country_summary_cache WHERE expires_at > ?', [now]);
      final metadata = await db.rawQuery('SELECT COUNT(*) as count FROM metadata_cache WHERE expires_at > ?', [now]);

      return {
        'indicators': indicators.first['count'] as int,
        'oecd_stats': oecd.first['count'] as int,
        'summaries': summaries.first['count'] as int,
        'metadata': metadata.first['count'] as int,
      };
    } catch (e, stackTrace) {
      AppLogger.error('[SQLiteCache] Failed to get cache stats', e, stackTrace);
      return {};
    }
  }

  /// 캐시 크기 조회 (MB 단위)
  Future<double> getCacheSizeInMB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'geo_economy_cache.db');
      final file = await File(path).stat();
      return file.size / (1024 * 1024); // Convert to MB
    } catch (e) {
      AppLogger.error('[SQLiteCache] Failed to get cache size', e);
      return 0.0;
    }
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.info('[SQLiteCache] Database closed');
    }
  }
}