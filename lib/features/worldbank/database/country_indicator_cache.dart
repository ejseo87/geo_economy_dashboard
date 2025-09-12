import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/country_indicator.dart';
import '../models/indicator_series.dart' show IndicatorDataPoint;
import '../models/core_indicators.dart';
import 'sqlite_database.dart';
import '../../../common/logger.dart';

/// PRD v1.1 국가 지표 SQLite 캐시 저장소
/// 비정규화된 데이터 캐싱: /countries/{countryCode}/indicators/{indicatorCode}
class CountryIndicatorCache {
  final SQLiteDatabase _db;
  static const Duration _defaultCacheExpiry = Duration(hours: 6); // 6시간 캐시
  
  CountryIndicatorCache({SQLiteDatabase? database}) 
      : _db = database ?? SQLiteDatabase();

  /// 국가 지표 데이터를 캐시에서 가져오기
  Future<CountryIndicator?> get({
    required String countryCode,
    required String indicatorCode,
  }) async {
    try {
      final db = await _db.database;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      final results = await db.query(
        _db.tableCountryIndicators,
        where: 'country_code = ? AND indicator_code = ? AND expires_at > ?',
        whereArgs: [countryCode, indicatorCode, currentTime],
        limit: 1,
      );
      
      if (results.isEmpty) {
        AppLogger.debug('[CountryIndicatorCache] Cache miss for $countryCode:$indicatorCode');
        return null;
      }
      
      final data = results.first;
      AppLogger.debug('[CountryIndicatorCache] Cache hit for $countryCode:$indicatorCode');
      
      return _mapToCountryIndicator(data, countryCode, indicatorCode);
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorCache] Error getting cached data: $error', stackTrace);
      return null;
    }
  }

  /// Top 5 지표 데이터를 캐시에서 가져오기
  Future<List<CountryIndicator>> getTop5({
    required String countryCode,
  }) async {
    try {
      final db = await _db.database;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      final top5Codes = CoreIndicators.top5Indicators.map((i) => i.code).toList();
      final placeholders = top5Codes.map((_) => '?').join(',');
      
      final results = await db.query(
        _db.tableCountryIndicators,
        where: 'country_code = ? AND indicator_code IN ($placeholders) AND expires_at > ?',
        whereArgs: [countryCode, ...top5Codes, currentTime],
      );
      
      if (results.isEmpty) {
        AppLogger.debug('[CountryIndicatorCache] No top 5 cache data for $countryCode');
        return [];
      }
      
      final indicators = results.map((data) => _mapToCountryIndicator(
        data, 
        countryCode, 
        data['indicator_code'] as String,
      )).toList();
      
      AppLogger.debug('[CountryIndicatorCache] Retrieved ${indicators.length}/5 cached top indicators for $countryCode');
      return indicators;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorCache] Error getting top 5 cached data: $error', stackTrace);
      return [];
    }
  }

  /// 특정 국가의 모든 지표 데이터를 캐시에서 가져오기
  Future<List<CountryIndicator>> getAllForCountry({
    required String countryCode,
  }) async {
    try {
      final db = await _db.database;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      final results = await db.query(
        _db.tableCountryIndicators,
        where: 'country_code = ? AND expires_at > ?',
        whereArgs: [countryCode, currentTime],
        orderBy: 'indicator_code',
      );
      
      if (results.isEmpty) {
        AppLogger.debug('[CountryIndicatorCache] No cached indicators for $countryCode');
        return [];
      }
      
      final indicators = results.map((data) => _mapToCountryIndicator(
        data, 
        countryCode, 
        data['indicator_code'] as String,
      )).toList();
      
      AppLogger.debug('[CountryIndicatorCache] Retrieved ${indicators.length} cached indicators for $countryCode');
      return indicators;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorCache] Error getting all cached data: $error', stackTrace);
      return [];
    }
  }

  /// 국가 지표 데이터를 캐시에 저장
  Future<bool> put({
    required CountryIndicator indicator,
    Duration? cacheExpiry,
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final expiry = cacheExpiry ?? _defaultCacheExpiry;
      
      final data = _mapFromCountryIndicator(indicator, now, expiry);
      
      await db.insert(
        _db.tableCountryIndicators,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      AppLogger.debug('[CountryIndicatorCache] Cached ${indicator.countryCode}:${indicator.indicatorCode}');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorCache] Error caching data: $error', stackTrace);
      return false;
    }
  }

  /// 여러 국가 지표 데이터를 배치로 캐시에 저장
  Future<int> putBatch({
    required List<CountryIndicator> indicators,
    Duration? cacheExpiry,
  }) async {
    if (indicators.isEmpty) return 0;
    
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final expiry = cacheExpiry ?? _defaultCacheExpiry;
      
      final batch = db.batch();
      int successCount = 0;
      
      for (final indicator in indicators) {
        final data = _mapFromCountryIndicator(indicator, now, expiry);
        batch.insert(
          _db.tableCountryIndicators,
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      }
      
      await batch.commit(noResult: true);
      
      AppLogger.debug('[CountryIndicatorCache] Batch cached $successCount indicators');
      return successCount;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorCache] Error batch caching data: $error', stackTrace);
      return 0;
    }
  }

  /// 특정 국가 지표 캐시 삭제
  Future<bool> remove({
    required String countryCode,
    required String indicatorCode,
  }) async {
    try {
      final db = await _db.database;
      
      final rowsAffected = await db.delete(
        _db.tableCountryIndicators,
        where: 'country_code = ? AND indicator_code = ?',
        whereArgs: [countryCode, indicatorCode],
      );
      
      if (rowsAffected > 0) {
        AppLogger.debug('[CountryIndicatorCache] Removed cached data for $countryCode:$indicatorCode');
      }
      
      return rowsAffected > 0;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorCache] Error removing cached data: $error', stackTrace);
      return false;
    }
  }

  /// 특정 국가의 모든 캐시 삭제
  Future<int> removeAllForCountry({
    required String countryCode,
  }) async {
    try {
      final db = await _db.database;
      
      final rowsAffected = await db.delete(
        _db.tableCountryIndicators,
        where: 'country_code = ?',
        whereArgs: [countryCode],
      );
      
      if (rowsAffected > 0) {
        AppLogger.debug('[CountryIndicatorCache] Removed $rowsAffected cached indicators for $countryCode');
      }
      
      return rowsAffected;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorCache] Error removing country cache: $error', stackTrace);
      return 0;
    }
  }

  /// 캐시 데이터의 신선도 확인
  Future<bool> isExpired({
    required String countryCode,
    required String indicatorCode,
  }) async {
    try {
      final db = await _db.database;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      final results = await db.query(
        _db.tableCountryIndicators,
        columns: ['expires_at'],
        where: 'country_code = ? AND indicator_code = ?',
        whereArgs: [countryCode, indicatorCode],
        limit: 1,
      );
      
      if (results.isEmpty) return true; // 캐시 없음 = 만료됨
      
      final expiresAt = results.first['expires_at'] as int;
      return currentTime > expiresAt;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorCache] Error checking expiry: $error', stackTrace);
      return true; // 오류 시 만료로 간주
    }
  }

  /// SQLite 데이터를 CountryIndicator 모델로 변환
  CountryIndicator _mapToCountryIndicator(
    Map<String, dynamic> data,
    String countryCode,
    String indicatorCode,
  ) {
    // JSON 문자열 파싱
    List<IndicatorDataPoint> recentData = [];
    if (data['recent_data'] != null) {
      final recentDataJson = jsonDecode(data['recent_data'] as String) as List;
      recentData = recentDataJson.map((item) => IndicatorDataPoint(
        year: item['year'] as int,
        value: (item['value'] as num).toDouble(),
      )).toList();
    }
    
    OECDStats? oecdStats;
    if (data['oecd_stats'] != null) {
      final oecdStatsJson = jsonDecode(data['oecd_stats'] as String) as Map<String, dynamic>;
      oecdStats = OECDStats.fromMap(oecdStatsJson);
    }
    
    return CountryIndicator(
      countryCode: countryCode,
      indicatorCode: indicatorCode,
      countryName: data['country_name'] as String? ?? '',
      indicatorName: data['indicator_name'] as String? ?? '',
      unit: data['unit'] as String? ?? '',
      latestValue: data['latest_value'] as double?,
      latestYear: data['latest_year'] as int?,
      recentData: recentData,
      oecdRanking: data['oecd_ranking'] as int?,
      oecdPercentile: data['oecd_percentile'] as double?,
      oecdStats: oecdStats,
      yearOverYearChange: data['year_over_year_change'] as double?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updated_at'] as int),
      dataBadge: data['data_badge'] as String?,
    );
  }

  /// CountryIndicator 모델을 SQLite 저장용 Map으로 변환
  Map<String, dynamic> _mapFromCountryIndicator(
    CountryIndicator indicator,
    DateTime createdAt,
    Duration cacheExpiry,
  ) {
    final now = createdAt.millisecondsSinceEpoch;
    final expiresAt = createdAt.add(cacheExpiry).millisecondsSinceEpoch;
    
    return {
      'id': '${indicator.countryCode}_${indicator.indicatorCode}',
      'country_code': indicator.countryCode,
      'indicator_code': indicator.indicatorCode,
      'country_name': indicator.countryName,
      'indicator_name': indicator.indicatorName,
      'unit': indicator.unit,
      'latest_value': indicator.latestValue,
      'latest_year': indicator.latestYear,
      'recent_data': jsonEncode(indicator.recentData.map((point) => {
        'year': point.year,
        'value': point.value,
      }).toList()),
      'oecd_ranking': indicator.oecdRanking,
      'oecd_percentile': indicator.oecdPercentile,
      'oecd_stats': indicator.oecdStats != null ? jsonEncode(indicator.oecdStats!.toMap()) : null,
      'year_over_year_change': indicator.yearOverYearChange,
      'updated_at': indicator.updatedAt.millisecondsSinceEpoch,
      'data_badge': indicator.dataBadge,
      'created_at': now,
      'expires_at': expiresAt,
    };
  }
}