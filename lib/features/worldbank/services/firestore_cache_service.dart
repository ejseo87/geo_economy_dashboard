import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geo_economy_dashboard/common/logger.dart';
import '../models/cached_indicator_data.dart';
import '../models/worldbank_response.dart';

/// Firestore 기반 캐싱 서비스
class FirestoreCacheService {
  static const String indicatorDataCollection = 'indicator_data';
  static const String oecdStatsCollection = 'oecd_stats';
  static const String metadataCollection = 'metadata';

  final FirebaseFirestore _firestore;

  FirestoreCacheService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 지표 데이터 캐시 저장
  Future<void> cacheIndicatorData({
    required String countryCode,
    required String indicatorCode,
    required List<WorldBankIndicatorData> data,
    String? eTag,
  }) async {
    try {
      final id = CachedIndicatorData.generateId(countryCode, indicatorCode);
      
      // 연도별 데이터 맵 생성
      final yearlyData = <String, double?>{};
      String? unit;
      String? source;
      int? latestYear;

      for (final item in data) {
        if (item.date != null && item.value != null) {
          yearlyData[item.date!] = item.value;
          unit ??= item.unit;
          source ??= item.indicatorValue;
          
          final year = int.tryParse(item.date!);
          if (year != null && (latestYear == null || year > latestYear)) {
            latestYear = year;
          }
        }
      }

      final now = DateTime.now();
      final cachedData = CachedIndicatorData(
        id: id,
        countryCode: countryCode,
        indicatorCode: indicatorCode,
        yearlyData: yearlyData,
        fetchedAt: now,
        lastUpdated: now,
        eTag: eTag,
        latestYear: latestYear,
        unit: unit,
        source: source,
      );

      await _firestore
          .collection(indicatorDataCollection)
          .doc(id)
          .set(cachedData.toMap());

      AppLogger.debug('[Cache] Saved indicator data: $countryCode/$indicatorCode');
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to save indicator data: $e');
      rethrow;
    }
  }

  /// 지표 데이터 캐시 조회
  Future<CachedIndicatorData?> getCachedIndicatorData({
    required String countryCode,
    required String indicatorCode,
  }) async {
    try {
      final id = CachedIndicatorData.generateId(countryCode, indicatorCode);
      final doc = await _firestore
          .collection(indicatorDataCollection)
          .doc(id)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return CachedIndicatorData.fromMap(doc.data()!);
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to get cached indicator data: $e');
      return null;
    }
  }

  /// OECD 통계 캐시 저장
  Future<void> cacheOECDStats(CachedOECDStats stats) async {
    try {
      await _firestore
          .collection(oecdStatsCollection)
          .doc(stats.id)
          .set(stats.toMap());

      AppLogger.debug('[Cache] Saved OECD stats: ${stats.indicatorCode}/${stats.year}');
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to save OECD stats: $e');
      rethrow;
    }
  }

  /// OECD 통계 캐시 조회
  Future<CachedOECDStats?> getCachedOECDStats({
    required String indicatorCode,
    required int year,
  }) async {
    try {
      final id = CachedOECDStats.generateId(indicatorCode, year);
      final doc = await _firestore
          .collection(oecdStatsCollection)
          .doc(id)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final stats = CachedOECDStats.fromMap(doc.data()!);
      
      // 만료된 캐시인지 확인
      if (stats.isExpired) {
        // 만료된 캐시 삭제
        await _firestore
            .collection(oecdStatsCollection)
            .doc(id)
            .delete();
        return null;
      }

      return stats;
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to get cached OECD stats: $e');
      return null;
    }
  }

  /// 특정 국가의 모든 지표 데이터 조회
  Future<List<CachedIndicatorData>> getAllIndicatorDataForCountry(
      String countryCode) async {
    try {
      final query = await _firestore
          .collection(indicatorDataCollection)
          .where('countryCode', isEqualTo: countryCode)
          .get();

      return query.docs
          .map((doc) => CachedIndicatorData.fromMap(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to get all indicator data for country: $e');
      return [];
    }
  }

  /// 만료된 캐시 데이터 정리
  Future<void> cleanupExpiredCache() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // 만료된 지표 데이터 삭제
      final expiredIndicatorQuery = await _firestore
          .collection(indicatorDataCollection)
          .where('fetchedAt', isLessThan: thirtyDaysAgo.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredIndicatorQuery.docs) {
        batch.delete(doc.reference);
      }

      // 만료된 OECD 통계 삭제
      final now = DateTime.now();
      final expiredStatsQuery = await _firestore
          .collection(oecdStatsCollection)
          .where('expiresAt', isLessThan: now.toIso8601String())
          .get();

      for (final doc in expiredStatsQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.debug('[Cache] Cleanup completed: ${expiredIndicatorQuery.docs.length + expiredStatsQuery.docs.length} documents deleted');
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to cleanup expired cache: $e');
    }
  }

  /// 캐시 통계 조회
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final indicatorDataCount = await _firestore
          .collection(indicatorDataCollection)
          .count()
          .get();

      final oecdStatsCount = await _firestore
          .collection(oecdStatsCollection)
          .count()
          .get();

      return {
        'indicatorDataCount': indicatorDataCount.count,
        'oecdStatsCount': oecdStatsCount.count,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to get cache stats: $e');
      return {
        'indicatorDataCount': 0,
        'oecdStatsCount': 0,
        'error': e.toString(),
      };
    }
  }

  /// 특정 지표의 모든 국가 데이터 조회 (OECD 통계 계산용)
  Future<List<CachedIndicatorData>> getAllCountryDataForIndicator(
      String indicatorCode) async {
    try {
      final query = await _firestore
          .collection(indicatorDataCollection)
          .where('indicatorCode', isEqualTo: indicatorCode)
          .get();

      return query.docs
          .map((doc) => CachedIndicatorData.fromMap(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to get all country data for indicator: $e');
      return [];
    }
  }

  /// 메타데이터 저장 (지표 설명, 국가 정보 등)
  Future<void> saveMetadata(String key, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(metadataCollection)
          .doc(key)
          .set({
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to save metadata: $e');
    }
  }

  /// 메타데이터 조회
  Future<Map<String, dynamic>?> getMetadata(String key) async {
    try {
      final doc = await _firestore
          .collection(metadataCollection)
          .doc(key)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      AppLogger.error('[Cache Error] Failed to get metadata: $e');
      return null;
    }
  }

  /// 실시간 캐시 상태 리스너
  Stream<QuerySnapshot> watchCacheUpdates() {
    return _firestore
        .collection(indicatorDataCollection)
        .orderBy('lastUpdated', descending: true)
        .limit(10)
        .snapshots();
  }
}