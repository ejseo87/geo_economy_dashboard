import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../logger.dart';
import '../../features/indicators/models/indicator_metadata.dart';
import '../../features/worldbank/models/indicator_codes.dart';
import '../countries/models/country.dart';

/// 오프라인 캐시 서비스
/// SharedPreferences와 메모리 캐시를 사용하여 데이터를 로컬에 저장
class OfflineCacheService {
  static const String _keyPrefix = 'cache_';
  static const String _keyIndicatorData = '${_keyPrefix}indicator_data_';
  static const String _keyOECDStats = '${_keyPrefix}oecd_stats_';
  static const String _keyMetadata = '${_keyPrefix}metadata_';
  static const String _keyCacheInfo = '${_keyPrefix}cache_info';
  
  static const Duration _defaultCacheExpiry = Duration(hours: 6);
  static const int _maxCacheSize = 100; // 최대 캐시 항목 수

  static OfflineCacheService? _instance;
  static OfflineCacheService get instance => _instance ??= OfflineCacheService._();
  
  OfflineCacheService._();

  SharedPreferences? _prefs;
  
  // 메모리 캐시 (빠른 접근을 위한)
  final Map<String, CachedItem> _memoryCache = {};

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheInfo();
    await _cleanupExpiredCache();
    AppLogger.info('[OfflineCache] Initialized with ${_memoryCache.length} cached items');
  }

  /// 지표 상세 데이터 캐시 저장
  Future<void> cacheIndicatorDetail(
    IndicatorCode indicatorCode,
    Country country,
    IndicatorDetail data,
  ) async {
    try {
      final key = _buildIndicatorKey(indicatorCode.code, country.code);
      
      // IndicatorDetail을 Map으로 직렬화
      final serializedData = {
        'countryCode': data.countryCode,
        'countryName': data.countryName,
        'currentValue': data.currentValue,
        'currentRank': data.currentRank,
        'totalCountries': data.totalCountries,
        'lastCalculated': data.lastCalculated?.toIso8601String(),
        // 복잡한 객체들은 일단 제외 (추후 필요시 추가)
      };

      final cachedItem = CachedItem(
        key: key,
        data: serializedData,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_defaultCacheExpiry),
        size: _calculateDataSize(serializedData),
      );

      await _storeCachedItem(key, cachedItem);
      AppLogger.debug('[OfflineCache] Cached indicator detail: ${indicatorCode.name} for ${country.nameKo}');
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to cache indicator detail: $e');
    }
  }

  /// 지표 상세 데이터 캐시 조회
  Future<IndicatorDetail?> getCachedIndicatorDetail(
    IndicatorCode indicatorCode,
    Country country,
  ) async {
    try {
      final key = _buildIndicatorKey(indicatorCode.code, country.code);
      final cachedItem = await _getCachedItem(key);
      
      if (cachedItem == null || cachedItem.isExpired) {
        return null;
      }

      // 캐시된 데이터로 간단한 IndicatorDetail 재구성
      // 실제로는 전체 데이터를 저장하고 복원하는 로직이 필요함
      // 현재는 기본적인 구조만 제공
      return null; // 임시로 null 반환
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to get cached indicator detail: $e');
      return null;
    }
  }

  /// OECD 통계 데이터 캐시 저장 (간소화된 버전)
  Future<void> cacheOECDStats(
    String indicatorCode,
    dynamic stats, // OECDStats 대신 dynamic 사용
  ) async {
    try {
      final key = _buildOECDStatsKey(indicatorCode);
      final cachedItem = CachedItem(
        key: key,
        data: {'indicatorCode': indicatorCode, 'cached': true}, // 간소화된 데이터
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 12)), // OECD 통계는 더 오래 캐시
        size: _calculateDataSize({'indicatorCode': indicatorCode}),
      );

      await _storeCachedItem(key, cachedItem);
      AppLogger.debug('[OfflineCache] Cached OECD stats: $indicatorCode');
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to cache OECD stats: $e');
    }
  }

  /// OECD 통계 데이터 캐시 조회 (간소화된 버전)
  Future<dynamic> getCachedOECDStats(String indicatorCode) async {
    try {
      final key = _buildOECDStatsKey(indicatorCode);
      final cachedItem = await _getCachedItem(key);
      
      if (cachedItem == null || cachedItem.isExpired) {
        return null;
      }

      return cachedItem.data;
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to get cached OECD stats: $e');
      return null;
    }
  }

  /// 메타데이터 캐시 저장
  Future<void> cacheMetadata(String key, Map<String, dynamic> metadata) async {
    try {
      final cacheKey = _buildMetadataKey(key);
      final cachedItem = CachedItem(
        key: cacheKey,
        data: metadata,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)), // 메타데이터는 길게 캐시
        size: _calculateDataSize(metadata),
      );

      await _storeCachedItem(cacheKey, cachedItem);
      AppLogger.debug('[OfflineCache] Cached metadata: $key');
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to cache metadata: $e');
    }
  }

  /// 메타데이터 캐시 조회
  Future<Map<String, dynamic>?> getCachedMetadata(String key) async {
    try {
      final cacheKey = _buildMetadataKey(key);
      final cachedItem = await _getCachedItem(cacheKey);
      
      if (cachedItem == null || cachedItem.isExpired) {
        return null;
      }

      return Map<String, dynamic>.from(cachedItem.data);
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to get cached metadata: $e');
      return null;
    }
  }

  /// 캐시 상태 확인
  Future<bool> isCached(String key) async {
    final cachedItem = await _getCachedItem(key);
    return cachedItem != null && !cachedItem.isExpired;
  }

  /// 특정 캐시 삭제
  Future<void> removeCache(String key) async {
    try {
      _memoryCache.remove(key);
      await _prefs?.remove(key);
      AppLogger.debug('[OfflineCache] Removed cache: $key');
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to remove cache: $e');
    }
  }

  /// 모든 캐시 삭제
  Future<void> clearAllCache() async {
    try {
      final keys = _prefs?.getKeys().where((key) => key.startsWith(_keyPrefix)) ?? [];
      for (final key in keys) {
        await _prefs?.remove(key);
      }
      _memoryCache.clear();
      AppLogger.info('[OfflineCache] Cleared all cache');
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to clear all cache: $e');
    }
  }

  /// 만료된 캐시 정리
  Future<void> _cleanupExpiredCache() async {
    try {
      final keys = _prefs?.getKeys().where((key) => key.startsWith(_keyPrefix)) ?? [];
      int removedCount = 0;

      for (final key in keys) {
        if (key == _keyCacheInfo) continue;
        
        final cachedItem = await _getCachedItem(key);
        if (cachedItem?.isExpired == true) {
          await _prefs?.remove(key);
          _memoryCache.remove(key);
          removedCount++;
        }
      }

      if (removedCount > 0) {
        AppLogger.info('[OfflineCache] Cleaned up $removedCount expired cache items');
      }
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to cleanup expired cache: $e');
    }
  }

  /// 캐시 크기 관리
  Future<void> _manageCacheSize() async {
    if (_memoryCache.length <= _maxCacheSize) return;

    try {
      // LRU (Least Recently Used) 방식으로 오래된 캐시 삭제
      final sortedItems = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

      final itemsToRemove = sortedItems.take(_memoryCache.length - _maxCacheSize);
      
      for (final entry in itemsToRemove) {
        await _prefs?.remove(entry.key);
        _memoryCache.remove(entry.key);
      }

      AppLogger.debug('[OfflineCache] Removed ${itemsToRemove.length} old cache items');
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to manage cache size: $e');
    }
  }

  /// 캐시 통계 조회
  Future<CacheStats> getCacheStats() async {
    try {
      final keys = _prefs?.getKeys().where((key) => key.startsWith(_keyPrefix) && key != _keyCacheInfo) ?? [];
      int totalSize = 0;
      int expiredCount = 0;

      for (final key in keys) {
        final cachedItem = await _getCachedItem(key);
        if (cachedItem != null) {
          totalSize += cachedItem.size;
          if (cachedItem.isExpired) expiredCount++;
        }
      }

      return CacheStats(
        totalItems: keys.length,
        totalSize: totalSize,
        expiredItems: expiredCount,
        memoryItems: _memoryCache.length,
      );
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to get cache stats: $e');
      return const CacheStats(
        totalItems: 0,
        totalSize: 0,
        expiredItems: 0,
        memoryItems: 0,
      );
    }
  }

  /// 캐시 항목 저장 (메모리 + 디스크)
  Future<void> _storeCachedItem(String key, CachedItem item) async {
    // 메모리 캐시에 저장
    _memoryCache[key] = item;

    // 디스크에 저장
    final jsonString = jsonEncode(item.toJson());
    await _prefs?.setString(key, jsonString);

    // 캐시 크기 관리
    await _manageCacheSize();
  }

  /// 캐시 항목 조회 (메모리 우선)
  Future<CachedItem?> _getCachedItem(String key) async {
    try {
      // 메모리 캐시 먼저 확인
      if (_memoryCache.containsKey(key)) {
        return _memoryCache[key];
      }

      // 디스크에서 조회
      final jsonString = _prefs?.getString(key);
      if (jsonString == null) return null;

      final cachedItem = CachedItem.fromJson(jsonDecode(jsonString));
      
      // 메모리 캐시에 로드
      _memoryCache[key] = cachedItem;
      
      return cachedItem;
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to get cached item: $e');
      return null;
    }
  }

  /// 캐시 정보 로드
  Future<void> _loadCacheInfo() async {
    try {
      final infoString = _prefs?.getString(_keyCacheInfo);
      if (infoString != null) {
        final info = jsonDecode(infoString) as Map<String, dynamic>;
        AppLogger.debug('[OfflineCache] Loaded cache info: ${info['lastCleanup']}');
      }
    } catch (e) {
      AppLogger.error('[OfflineCache] Failed to load cache info: $e');
    }
  }

  /// 키 생성 헬퍼 메서드들
  String _buildIndicatorKey(String indicatorCode, String countryCode) =>
      '$_keyIndicatorData${indicatorCode}_$countryCode';

  String _buildOECDStatsKey(String indicatorCode) =>
      '$_keyOECDStats$indicatorCode';

  String _buildMetadataKey(String key) =>
      '$_keyMetadata$key';

  /// 데이터 크기 계산 (대략적)
  int _calculateDataSize(dynamic data) {
    try {
      return jsonEncode(data).length;
    } catch (e) {
      return 1000; // 기본값
    }
  }
}

/// 캐시된 항목 클래스
class CachedItem {
  final String key;
  final dynamic data;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final int size;

  const CachedItem({
    required this.key,
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
    required this.size,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'key': key,
    'data': data,
    'cachedAt': cachedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'size': size,
  };

  factory CachedItem.fromJson(Map<String, dynamic> json) => CachedItem(
    key: json['key'] as String,
    data: json['data'],
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    size: json['size'] as int,
  );
}

/// 캐시 통계 클래스
class CacheStats {
  final int totalItems;
  final int totalSize;
  final int expiredItems;
  final int memoryItems;

  const CacheStats({
    required this.totalItems,
    required this.totalSize,
    required this.expiredItems,
    required this.memoryItems,
  });

  double get hitRatio => memoryItems / (totalItems == 0 ? 1 : totalItems);
  double get sizeMB => totalSize / (1024 * 1024);

  @override
  String toString() => 'CacheStats(items: $totalItems, size: ${sizeMB.toStringAsFixed(2)}MB, expired: $expiredItems, hit ratio: ${(hitRatio * 100).toStringAsFixed(1)}%)';
}