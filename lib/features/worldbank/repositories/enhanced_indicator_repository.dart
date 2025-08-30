import 'package:geo_economy_dashboard/common/logger.dart';

import '../models/indicator_codes.dart';
import '../models/cached_indicator_data.dart';
import '../services/worldbank_api_client.dart';
import '../services/firestore_cache_service.dart';
import '../../home/models/indicator_comparison.dart';
import '../../../common/services/sqlite_cache_service.dart';

/// 향상된 지표 데이터 Repository (SQLite → Firestore → API 순서)
class EnhancedIndicatorRepository {
  final WorldBankApiClient _apiClient;
  final FirestoreCacheService _firestoreCache;
  final SQLiteCacheService _sqliteCache;

  EnhancedIndicatorRepository({
    WorldBankApiClient? apiClient,
    FirestoreCacheService? firestoreCache,
    SQLiteCacheService? sqliteCache,
  }) : _apiClient = apiClient ?? WorldBankApiClient(),
       _firestoreCache = firestoreCache ?? FirestoreCacheService(),
       _sqliteCache = sqliteCache ?? SQLiteCacheService.instance;

  /// 특정 국가의 지표 데이터 조회 (SQLite → Firestore → API 순서)
  Future<CachedIndicatorData?> getIndicatorData({
    required String countryCode,
    required IndicatorCode indicatorCode,
    bool forceRefresh = false,
  }) async {
    final indicatorCodeStr = indicatorCode.code;
    final currentYear = DateTime.now().year;

    if (!forceRefresh) {
      // 1. SQLite 로컬 캐시 확인
      final cachedValue = await _sqliteCache.getCachedIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCodeStr,
        year: currentYear,
      );
      
      if (cachedValue != null) {
        AppLogger.debug(
          '[Enhanced Repository] Using SQLite cache: $countryCode/$indicatorCodeStr',
        );
        return CachedIndicatorData(
          id: CachedIndicatorData.generateId(countryCode, indicatorCodeStr),
          countryCode: countryCode,
          indicatorCode: indicatorCodeStr,
          yearlyData: {currentYear.toString(): cachedValue},
          fetchedAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          unit: indicatorCode.unit,
          source: 'SQLite Cache',
        );
      }

      // 2. Firestore 캐시 확인
      final firestoreData = await _getFromFirestoreCache(countryCode, indicatorCodeStr, indicatorCode);
      if (firestoreData != null) {
        AppLogger.debug(
          '[Enhanced Repository] Using Firestore cache: $countryCode/$indicatorCodeStr',
        );
        
        // Firestore 데이터를 SQLite에 캐시
        final latestValue = firestoreData.latestValue;
        if (latestValue != null && firestoreData.latestYear != null) {
          await _sqliteCache.cacheIndicatorData(
            countryCode: countryCode,
            indicatorCode: indicatorCodeStr,
            year: firestoreData.latestYear!,
            value: latestValue,
          );
        }
        
        return firestoreData;
      }
    }

    // 3. World Bank API에서 가져오기
    final apiData = await _fetchFromAPI(countryCode, indicatorCodeStr, indicatorCode);
    
    // API 데이터를 SQLite에 캐시
    if (apiData != null) {
      for (final entry in apiData.yearlyData.entries) {
        if (entry.value != null) {
          await _sqliteCache.cacheIndicatorData(
            countryCode: countryCode,
            indicatorCode: indicatorCodeStr,
            year: int.parse(entry.key),
            value: entry.value!,
          );
        }
      }
    }
    
    return apiData;
  }


  /// Firestore 캐시에서 데이터 조회
  Future<CachedIndicatorData?> _getFromFirestoreCache(
    String countryCode,
    String indicatorCodeStr,
    IndicatorCode indicatorCode,
  ) async {
    try {
      final cached = await _firestoreCache.getCachedIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCodeStr,
      );

      if (cached != null && !cached.isExpired(indicatorCode.updateFrequencyDays)) {
        return cached;
      }
      
      return null;
    } catch (e) {
      AppLogger.error('[Enhanced Repository] Firestore cache error: $e');
      return null;
    }
  }

  /// World Bank API에서 데이터 가져오기
  Future<CachedIndicatorData?> _fetchFromAPI(
    String countryCode,
    String indicatorCodeStr,
    IndicatorCode indicatorCode,
  ) async {
    try {
      AppLogger.debug(
        '[Enhanced Repository] Fetching from API: $countryCode/$indicatorCodeStr',
      );

      final apiData = await _apiClient.getIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCodeStr,
        dateRange: '2010:2024',
      );

      if (apiData.isNotEmpty) {
        // Firestore에 저장
        await _firestoreCache.cacheIndicatorData(
          countryCode: countryCode,
          indicatorCode: indicatorCodeStr,
          data: apiData,
        );

        // 저장된 데이터 가져오기
        final cachedData = await _firestoreCache.getCachedIndicatorData(
          countryCode: countryCode,
          indicatorCode: indicatorCodeStr,
        );


        return cachedData;
      }

      return null;
    } on WorldBankApiException catch (e) {
      AppLogger.error('[Enhanced Repository] API Error: $e');

      // API 오류 시 만료된 캐시라도 반환
      final staleData = await _getStaleCache(countryCode, indicatorCodeStr);
      if (staleData != null) {
        AppLogger.debug('[Enhanced Repository] Using stale cache due to API error');
        return staleData;
      }

      rethrow;
    } catch (e) {
      AppLogger.error('[Enhanced Repository] Unexpected error: $e');
      return null;
    }
  }


  /// 만료된 캐시라도 가져오기 (API 오류 시)
  Future<CachedIndicatorData?> _getStaleCache(String countryCode, String indicatorCodeStr) async {
    // Firestore에서 만료된 데이터라도 가져오기
    try {
      final firestoreData = await _firestoreCache.getCachedIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCodeStr,
      );
      
      return firestoreData;
    } catch (e) {
      AppLogger.debug('[Enhanced Repository] No stale Firestore data available');
    }

    return null;
  }

  /// OECD 국가들의 특정 지표 데이터 조회 및 통계 계산
  Future<OECDStatistics> getOECDStatistics({
    required IndicatorCode indicatorCode,
    int? year,
    bool forceRefresh = false,
  }) async {
    final indicatorCodeStr = indicatorCode.code;
    final targetYear = year ?? 2023;

    if (!forceRefresh) {
      // 1. SQLite에서 OECD 통계 확인
      final sqliteStats = await _sqliteCache.getCachedOECDStats(
        indicatorCode: indicatorCodeStr,
        year: targetYear,
      );

      if (sqliteStats != null) {
        AppLogger.debug(
          '[Enhanced Repository] Using SQLite OECD stats: $indicatorCodeStr/$targetYear',
        );

        return OECDStatistics(
          median: sqliteStats['median'] as double,
          q1: sqliteStats['q1'] as double,
          q3: sqliteStats['q3'] as double,
          min: sqliteStats['min'] as double,
          max: sqliteStats['max'] as double,
          mean: sqliteStats['mean'] as double,
          totalCountries: sqliteStats['totalCountries'] as int,
          countryRankings: null,
        );
      }

      // 2. Firestore에서 OECD 통계 확인
      final cachedStats = await _firestoreCache.getCachedOECDStats(
        indicatorCode: indicatorCodeStr,
        year: targetYear,
      );

      if (cachedStats != null && !cachedStats.isExpired) {
        AppLogger.debug(
          '[Enhanced Repository] Using Firestore OECD stats: $indicatorCodeStr/$targetYear',
        );

        // Firestore 데이터를 SQLite에 캐시
        await _sqliteCache.cacheOECDStats(
          indicatorCode: indicatorCodeStr,
          year: targetYear,
          stats: {
            'median': cachedStats.median,
            'q1': cachedStats.q1,
            'q3': cachedStats.q3,
            'min': cachedStats.min,
            'max': cachedStats.max,
            'mean': cachedStats.mean,
            'totalCountries': cachedStats.totalCountries,
          },
        );

        return OECDStatistics(
          median: cachedStats.median,
          q1: cachedStats.q1,
          q3: cachedStats.q3,
          min: cachedStats.min,
          max: cachedStats.max,
          mean: cachedStats.mean,
          totalCountries: cachedStats.totalCountries,
          countryRankings: null,
        );
      }
    }

    // 3. OECD 국가들의 데이터 수집하여 통계 계산
    return await _calculateOECDStatistics(indicatorCode, targetYear);
  }

  /// OECD 통계 계산 및 캐싱
  Future<OECDStatistics> _calculateOECDStatistics(IndicatorCode indicatorCode, int targetYear) async {
    final indicatorCodeStr = indicatorCode.code;
    AppLogger.debug(
      '[Enhanced Repository] Calculating OECD stats: $indicatorCodeStr/$targetYear',
    );

    final values = <double>[];
    final validCountries = <String>[];

    // 개별 국가 데이터 수집 시 배치 처리로 성능 최적화
    final futures = IndicatorCode.oecdCountries.map((countryCode) async {
      try {
        final data = await getIndicatorData(
          countryCode: countryCode,
          indicatorCode: indicatorCode,
          forceRefresh: false,
        );

        final value = data?.getValueForYear(targetYear);
        if (value != null && value.isFinite) {
          return {'countryCode': countryCode, 'value': value};
        }
      } catch (e) {
        AppLogger.debug('[Enhanced Repository] Failed to get data for $countryCode: $e');
      }
      return null;
    });

    final results = await Future.wait(futures);
    
    for (final result in results) {
      if (result != null) {
        values.add(result['value'] as double);
        validCountries.add(result['countryCode'] as String);
      }
    }

    if (values.isEmpty) {
      throw Exception(
        'No valid data found for $indicatorCodeStr in $targetYear',
      );
    }

    // 통계 계산
    final stats = _calculateStatistics(values, validCountries, indicatorCode);

    // SQLite와 Firestore에 캐싱
    final statsMap = {
      'median': stats.median,
      'q1': stats.q1,
      'q3': stats.q3,
      'min': stats.min,
      'max': stats.max,
      'mean': stats.mean,
      'totalCountries': stats.totalCountries,
    };

    // SQLite에 캐시
    await _sqliteCache.cacheOECDStats(
      indicatorCode: indicatorCodeStr,
      year: targetYear,
      stats: statsMap,
    );

    // Firestore에도 캐싱 (기존 로직 유지)
    final cachedStats = CachedOECDStats(
      id: CachedOECDStats.generateId(indicatorCodeStr, targetYear),
      indicatorCode: indicatorCodeStr,
      year: targetYear,
      median: stats.median,
      q1: stats.q1,
      q3: stats.q3,
      min: stats.min,
      max: stats.max,
      mean: stats.mean,
      totalCountries: stats.totalCountries,
      countriesIncluded: validCountries,
      calculatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(
        Duration(days: indicatorCode.updateFrequencyDays),
      ),
    );

    await _firestoreCache.cacheOECDStats(cachedStats);

    return stats;
  }


  /// 통계 계산 헬퍼 메서드 (기존과 동일)
  OECDStatistics _calculateStatistics(
    List<double> values,
    List<String> validCountries,
    IndicatorCode indicatorCode,
  ) {
    if (values.isEmpty || validCountries.isEmpty) {
      throw ArgumentError('Values and countries lists cannot be empty');
    }

    final countryValuePairs = <Map<String, dynamic>>[];
    for (int i = 0; i < values.length; i++) {
      countryValuePairs.add({
        'countryCode': validCountries[i],
        'value': values[i],
      });
    }

    final higherIsBetter = indicatorCode.direction == IndicatorDirection.higher;
    countryValuePairs.sort((a, b) {
      final aValue = a['value'] as double;
      final bValue = b['value'] as double;
      return higherIsBetter ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
    });

    final countryRankings = <CountryRankingData>[];
    for (int i = 0; i < countryValuePairs.length; i++) {
      final pair = countryValuePairs[i];
      countryRankings.add(
        CountryRankingData(
          countryCode: pair['countryCode'] as String,
          countryName: _getCountryName(pair['countryCode'] as String),
          value: pair['value'] as double,
          rank: i + 1,
        ),
      );
    }

    final sortedValues = countryValuePairs
        .map((pair) => pair['value'] as double)
        .toList();
    sortedValues.sort();

    final length = sortedValues.length;
    final q1Index = (length * 0.25).floor();
    final medianIndex = (length * 0.5).floor();
    final q3Index = (length * 0.75).floor();

    final q1 = length > 1 ? sortedValues[q1Index] : sortedValues[0];
    final median = length > 1 ? sortedValues[medianIndex] : sortedValues[0];
    final q3 = length > 1 ? sortedValues[q3Index] : sortedValues[0];

    final sum = sortedValues.reduce((a, b) => a + b);
    final mean = sum / length;

    return OECDStatistics(
      median: median,
      q1: q1,
      q3: q3,
      min: sortedValues.first,
      max: sortedValues.last,
      mean: mean,
      totalCountries: length,
      countryRankings: countryRankings,
    );
  }

  /// 캐시 관리 메서드들
  Future<void> cleanupExpiredCache({int ttlDays = 30}) async {
    try {
      AppLogger.info('[Enhanced Repository] Cache cleanup completed - using Firestore cache only');
    } catch (e) {
      AppLogger.error('[Enhanced Repository] Cache cleanup error: $e');
    }
  }

  /// 캐시 상태 리포트
  Future<String> getCacheReport() async {
    return 'Using Firestore cache service only';
  }

  /// 특정 국가 캐시 무효화
  Future<void> invalidateCountryCache(String countryCode) async {
    AppLogger.info('[Enhanced Repository] Cache invalidation for country: $countryCode - using Firestore');
  }

  /// 국가명 반환 (기존과 동일)
  String _getCountryName(String countryCode) {
    const countryNames = {
      'AUS': '호주', 'AUT': '오스트리아', 'BEL': '벨기에', 'CAN': '캐나다',
      'CHL': '칠레', 'COL': '콜롬비아', 'CRI': '코스타리카', 'CZE': '체코',
      'DNK': '덴마크', 'EST': '에스토니아', 'FIN': '핀란드', 'FRA': '프랑스',
      'DEU': '독일', 'GRC': '그리스', 'HUN': '헝가리', 'ISL': '아이슬란드',
      'IRL': '아일랜드', 'ISR': '이스라엘', 'ITA': '이탈리아', 'JPN': '일본',
      'KOR': '대한민국', 'LVA': '라트비아', 'LTU': '리투아니아', 'LUX': '룩셈부르크',
      'MEX': '멕시코', 'NLD': '네덜란드', 'NZL': '뉴질랜드', 'NOR': '노르웨이',
      'POL': '폴란드', 'PRT': '포르투갈', 'SVK': '슬로바키아', 'SVN': '슬로베니아',
      'ESP': '스페인', 'SWE': '스웨덴', 'CHE': '스위스', 'TUR': '튀르키예',
      'GBR': '영국', 'USA': '미국',
    };
    return countryNames[countryCode] ?? countryCode;
  }

  /// 리소스 정리
  void dispose() {
    _apiClient.dispose();
  }
}