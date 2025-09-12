import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../common/logger.dart';

/// PRD v1.1 SQLite 로컬 캐싱 데이터베이스
/// 우선순위: SQLite → Firestore → World Bank API
class SQLiteDatabase {
  static const String _databaseName = 'geo_economy_cache.db';
  static const int _databaseVersion = 1;
  
  // 테이블 이름
  static const String _tableCountryIndicators = 'country_indicators';
  static const String _tableIndicatorSeries = 'indicator_series';
  static const String _tableCacheMetadata = 'cache_metadata';
  
  static Database? _database;
  static final SQLiteDatabase _instance = SQLiteDatabase._internal();
  
  factory SQLiteDatabase() => _instance;
  SQLiteDatabase._internal();

  /// 데이터베이스 인스턴스 가져오기
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      AppLogger.debug('[SQLiteDatabase] Initializing database at: $path');
      
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[SQLiteDatabase] Failed to initialize database: $error', stackTrace);
      rethrow;
    }
  }

  /// 테이블 생성
  Future<void> _createTables(Database db, int version) async {
    try {
      AppLogger.debug('[SQLiteDatabase] Creating tables...');
      
      // 1. 국가 지표 캐시 테이블 (비정규화된 데이터)
      await db.execute('''
        CREATE TABLE $_tableCountryIndicators (
          id TEXT PRIMARY KEY,
          country_code TEXT NOT NULL,
          indicator_code TEXT NOT NULL,
          country_name TEXT,
          indicator_name TEXT,
          unit TEXT,
          latest_value REAL,
          latest_year INTEGER,
          recent_data TEXT, -- JSON string
          oecd_ranking INTEGER,
          oecd_percentile REAL,
          oecd_stats TEXT, -- JSON string
          year_over_year_change REAL,
          updated_at INTEGER NOT NULL,
          data_badge TEXT,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL,
          UNIQUE(country_code, indicator_code)
        )
      ''');

      // 2. 지표 시계열 캐시 테이블 (정규화된 데이터)
      await db.execute('''
        CREATE TABLE $_tableIndicatorSeries (
          id TEXT PRIMARY KEY,
          indicator_code TEXT NOT NULL,
          country_code TEXT NOT NULL,
          indicator_name TEXT,
          country_name TEXT,
          unit TEXT,
          time_series TEXT NOT NULL, -- JSON string
          latest_value REAL,
          latest_year INTEGER,
          fetched_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          source TEXT,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL,
          UNIQUE(indicator_code, country_code)
        )
      ''');

      // 3. 캐시 메타데이터 테이블
      await db.execute('''
        CREATE TABLE $_tableCacheMetadata (
          key TEXT PRIMARY KEY,
          value TEXT,
          updated_at INTEGER NOT NULL,
          expires_at INTEGER
        )
      ''');

      // 인덱스 생성 (성능 최적화)
      await db.execute('CREATE INDEX idx_country_indicators_country ON $_tableCountryIndicators(country_code)');
      await db.execute('CREATE INDEX idx_country_indicators_indicator ON $_tableCountryIndicators(indicator_code)');
      await db.execute('CREATE INDEX idx_country_indicators_expires ON $_tableCountryIndicators(expires_at)');
      
      await db.execute('CREATE INDEX idx_indicator_series_indicator ON $_tableIndicatorSeries(indicator_code)');
      await db.execute('CREATE INDEX idx_indicator_series_country ON $_tableIndicatorSeries(country_code)');
      await db.execute('CREATE INDEX idx_indicator_series_expires ON $_tableIndicatorSeries(expires_at)');
      
      AppLogger.debug('[SQLiteDatabase] Tables created successfully');
    } catch (error, stackTrace) {
      AppLogger.error('[SQLiteDatabase] Failed to create tables: $error', stackTrace);
      rethrow;
    }
  }

  /// 데이터베이스 업그레이드
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.debug('[SQLiteDatabase] Upgrading database from $oldVersion to $newVersion');
    
    // 향후 스키마 변경 시 마이그레이션 로직 구현
    if (oldVersion < 2) {
      // 예시: 새로운 컬럼 추가
      // await db.execute('ALTER TABLE $_tableCountryIndicators ADD COLUMN new_column TEXT');
    }
  }

  /// 만료된 캐시 데이터 정리
  Future<int> cleanupExpiredCache() async {
    try {
      final db = await database;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      final countryIndicatorsDeleted = await db.delete(
        _tableCountryIndicators,
        where: 'expires_at < ?',
        whereArgs: [currentTime],
      );
      
      final indicatorSeriesDeleted = await db.delete(
        _tableIndicatorSeries,
        where: 'expires_at < ?',
        whereArgs: [currentTime],
      );
      
      final metadataDeleted = await db.delete(
        _tableCacheMetadata,
        where: 'expires_at IS NOT NULL AND expires_at < ?',
        whereArgs: [currentTime],
      );
      
      final totalDeleted = countryIndicatorsDeleted + indicatorSeriesDeleted + metadataDeleted;
      
      if (totalDeleted > 0) {
        AppLogger.debug('[SQLiteDatabase] Cleaned up $totalDeleted expired cache entries');
      }
      
      return totalDeleted;
    } catch (error, stackTrace) {
      AppLogger.error('[SQLiteDatabase] Failed to cleanup expired cache: $error', stackTrace);
      return 0;
    }
  }

  /// 캐시 통계 정보 가져오기
  Future<Map<String, int>> getCacheStats() async {
    try {
      final db = await database;
      
      final countryIndicatorsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableCountryIndicators')
      ) ?? 0;
      
      final indicatorSeriesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableIndicatorSeries')
      ) ?? 0;
      
      final metadataCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableCacheMetadata')
      ) ?? 0;
      
      return {
        'country_indicators': countryIndicatorsCount,
        'indicator_series': indicatorSeriesCount,
        'metadata': metadataCount,
        'total': countryIndicatorsCount + indicatorSeriesCount + metadataCount,
      };
    } catch (error, stackTrace) {
      AppLogger.error('[SQLiteDatabase] Failed to get cache stats: $error', stackTrace);
      return {};
    }
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.debug('[SQLiteDatabase] Database closed');
    }
  }

  /// 전체 캐시 초기화
  Future<void> clearAllCache() async {
    try {
      final db = await database;
      
      await db.delete(_tableCountryIndicators);
      await db.delete(_tableIndicatorSeries);
      await db.delete(_tableCacheMetadata);
      
      AppLogger.debug('[SQLiteDatabase] All cache cleared');
    } catch (error, stackTrace) {
      AppLogger.error('[SQLiteDatabase] Failed to clear cache: $error', stackTrace);
    }
  }

  /// 테이블 이름 접근자
  String get tableCountryIndicators => _tableCountryIndicators;
  String get tableIndicatorSeries => _tableIndicatorSeries;
  String get tableCacheMetadata => _tableCacheMetadata;
}