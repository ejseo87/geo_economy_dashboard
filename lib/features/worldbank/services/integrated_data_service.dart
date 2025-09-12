import '../models/country_indicator.dart';
import '../models/core_indicators.dart';
import '../repositories/country_indicator_repository.dart';
import '../database/country_indicator_cache.dart';
import '../database/sqlite_database.dart';
import 'worldbank_api_client.dart';
import '../../../common/logger.dart';

/// PRD v1.1 통합 데이터 서비스
/// 데이터 우선순위: SQLite → Firestore → World Bank API
/// 캐싱 전략: 성공적인 조회 시 상위 계층에 자동 캐싱
class IntegratedDataService {
  final CountryIndicatorCache _sqliteCache;
  final CountryIndicatorRepository _firestoreRepository;
  final WorldBankApiClient _apiClient;
  
  // 캐시 만료 시간 설정
  static const Duration _sqliteCacheExpiry = Duration(hours: 6);
  static const Duration _firestoreCacheExpiry = Duration(days: 1);
  
  IntegratedDataService({
    CountryIndicatorCache? sqliteCache,
    CountryIndicatorRepository? firestoreRepository,
    WorldBankApiClient? apiClient,
  }) : _sqliteCache = sqliteCache ?? CountryIndicatorCache(),
        _firestoreRepository = firestoreRepository ?? CountryIndicatorRepository(),
        _apiClient = apiClient ?? WorldBankApiClient();

  /// 단일 국가 지표 데이터 가져오기 (3단계 우선순위)
  Future<CountryIndicator?> getCountryIndicator({
    required String countryCode,
    required String indicatorCode,
    bool forceRefresh = false,
  }) async {
    try {
      AppLogger.debug('[IntegratedDataService] Getting $countryCode:$indicatorCode (forceRefresh: $forceRefresh)');
      
      // 강제 새로고침이 아닌 경우 캐시 확인
      if (!forceRefresh) {
        // 1단계: SQLite 로컬 캐시 확인
        final cachedData = await _sqliteCache.get(
          countryCode: countryCode,
          indicatorCode: indicatorCode,
        );
        
        if (cachedData != null) {
          AppLogger.debug('[IntegratedDataService] SQLite cache hit for $countryCode:$indicatorCode');
          return cachedData;
        }
      }
      
      // 2단계: Firestore 원격 캐시 확인
      final firestoreData = await _firestoreRepository.getCountryIndicator(
        countryCode: countryCode,
        indicatorCode: indicatorCode,
      );
      
      if (firestoreData != null) {
        AppLogger.debug('[IntegratedDataService] Firestore hit for $countryCode:$indicatorCode');
        
        // SQLite에 캐싱
        await _sqliteCache.put(
          indicator: firestoreData,
          cacheExpiry: _sqliteCacheExpiry,
        );
        
        return firestoreData;
      }
      
      // 3단계: World Bank API 호출
      AppLogger.debug('[IntegratedDataService] Calling World Bank API for $countryCode:$indicatorCode');
      
      final apiData = await _apiClient.getCountryIndicator(
        countryCode: countryCode,
        indicatorCode: indicatorCode,
      );
      
      if (apiData != null) {
        AppLogger.debug('[IntegratedDataService] World Bank API success for $countryCode:$indicatorCode');
        
        // Firestore에 저장 (중장기 캐싱)
        await _firestoreRepository.saveCountryIndicator(apiData);
        
        // SQLite에 저장 (단기 캐싱)
        await _sqliteCache.put(
          indicator: apiData,
          cacheExpiry: _sqliteCacheExpiry,
        );
        
        return apiData;
      }
      
      AppLogger.warning('[IntegratedDataService] All data sources exhausted for $countryCode:$indicatorCode');
      return null;
    } catch (error, stackTrace) {
      AppLogger.error('[IntegratedDataService] Error getting country indicator: $error', stackTrace);
      return null;
    }
  }

  /// Top 5 지표 데이터 가져오기 (배치 최적화)
  Future<List<CountryIndicator>> getTop5Indicators({
    required String countryCode,
    bool forceRefresh = false,
  }) async {
    try {
      AppLogger.debug('[IntegratedDataService] Getting top 5 indicators for $countryCode');
      
      List<CountryIndicator> results = [];
      
      if (!forceRefresh) {
        // 1단계: SQLite에서 모든 Top 5 지표 확인
        results = await _sqliteCache.getTop5(countryCode: countryCode);
        
        if (results.length == 5) {
          AppLogger.debug('[IntegratedDataService] Complete top 5 from SQLite cache for $countryCode');
          return results;
        }
      }
      
      // 2단계: Firestore에서 누락된 지표들 가져오기
      final top5Codes = CoreIndicators.top5Indicators.map((i) => i.code).toList();
      final cachedCodes = results.map((i) => i.indicatorCode).toSet();
      final missingCodes = top5Codes.where((code) => !cachedCodes.contains(code)).toList();
      
      if (missingCodes.isNotEmpty) {
        final firestoreResults = <CountryIndicator>[];
        
        for (final code in missingCodes) {
          final indicator = await _firestoreRepository.getCountryIndicator(
            countryCode: countryCode,
            indicatorCode: code,
          );
          if (indicator != null) {
            firestoreResults.add(indicator);
          }
        }
        
        if (firestoreResults.isNotEmpty) {
          AppLogger.debug('[IntegratedDataService] Retrieved ${firestoreResults.length} indicators from Firestore');
          
          // SQLite에 배치 캐싱
          await _sqliteCache.putBatch(
            indicators: firestoreResults,
            cacheExpiry: _sqliteCacheExpiry,
          );
          
          results.addAll(firestoreResults);
        }
      }
      
      // 우선순위 순서로 정렬
      results.sort((a, b) {
        final aIndicator = CoreIndicators.findByCode(a.indicatorCode);
        final bIndicator = CoreIndicators.findByCode(b.indicatorCode);
        
        final aPriority = aIndicator?.priority ?? 999;
        final bPriority = bIndicator?.priority ?? 999;
        
        return aPriority.compareTo(bPriority);
      });
      
      AppLogger.debug('[IntegratedDataService] Retrieved ${results.length}/5 top indicators for $countryCode');
      return results;
    } catch (error, stackTrace) {
      AppLogger.error('[IntegratedDataService] Error getting top 5 indicators: $error', stackTrace);
      return [];
    }
  }

  /// 핵심 20개 지표 데이터 가져오기
  Future<Map<CoreIndicatorCategory, List<CountryIndicator>>> getCore20Indicators({
    required String countryCode,
    bool forceRefresh = false,
  }) async {
    try {
      AppLogger.debug('[IntegratedDataService] Getting core 20 indicators for $countryCode');
      
      final resultMap = <CoreIndicatorCategory, List<CountryIndicator>>{};
      
      // 카테고리별로 데이터 수집
      for (final category in CoreIndicatorCategory.values) {
        final categoryResults = <CountryIndicator>[];
        final categoryIndicators = CoreIndicators.getIndicatorsByCategory(category);
        
        for (final coreIndicator in categoryIndicators) {
          final indicator = await getCountryIndicator(
            countryCode: countryCode,
            indicatorCode: coreIndicator.code,
            forceRefresh: forceRefresh,
          );
          
          if (indicator != null) {
            categoryResults.add(indicator);
          }
        }
        
        // 우선순위 순서로 정렬
        categoryResults.sort((a, b) {
          final aIndicator = CoreIndicators.findByCode(a.indicatorCode);
          final bIndicator = CoreIndicators.findByCode(b.indicatorCode);
          
          final aPriority = aIndicator?.priority ?? 999;
          final bPriority = bIndicator?.priority ?? 999;
          
          return aPriority.compareTo(bPriority);
        });
        
        if (categoryResults.isNotEmpty) {
          resultMap[category] = categoryResults;
        }
      }
      
      final totalCount = resultMap.values.fold(0, (sum, list) => sum + list.length);
      AppLogger.debug('[IntegratedDataService] Retrieved $totalCount/20 core indicators for $countryCode');
      
      return resultMap;
    } catch (error, stackTrace) {
      AppLogger.error('[IntegratedDataService] Error getting core 20 indicators: $error', stackTrace);
      return {};
    }
  }

  /// AI 추천 지표 가져오기 (카테고리 다양성 보장)
  Future<List<CountryIndicator>> getAIRecommendedIndicators({
    required String countryCode,
    int maxCount = 3,
    bool forceRefresh = false,
  }) async {
    try {
      AppLogger.debug('[IntegratedDataService] Getting AI recommended indicators for $countryCode');
      
      final results = <CountryIndicator>[];
      final usedCategories = <CoreIndicatorCategory>{};
      
      // 우선순위가 높은 카테고리부터 선택
      final priorityCategories = [
        CoreIndicatorCategory.growth,
        CoreIndicatorCategory.employment, 
        CoreIndicatorCategory.external,
        CoreIndicatorCategory.inflation,
        CoreIndicatorCategory.fiscal,
      ];
      
      for (final category in priorityCategories) {
        if (results.length >= maxCount) break;
        
        final categoryIndicators = CoreIndicators.getIndicatorsByCategory(category);
        if (categoryIndicators.isEmpty) continue;
        
        // 해당 카테고리에서 우선순위가 가장 높은 지표 선택
        categoryIndicators.sort((a, b) => a.priority.compareTo(b.priority));
        final selectedIndicator = categoryIndicators.first;
        
        final indicator = await getCountryIndicator(
          countryCode: countryCode,
          indicatorCode: selectedIndicator.code,
          forceRefresh: forceRefresh,
        );
        
        if (indicator != null) {
          results.add(indicator);
          usedCategories.add(category);
        }
      }
      
      AppLogger.debug('[IntegratedDataService] AI selected ${results.length} indicators from ${usedCategories.length} categories');
      return results;
    } catch (error, stackTrace) {
      AppLogger.error('[IntegratedDataService] Error getting AI recommended indicators: $error', stackTrace);
      return [];
    }
  }

  /// 캐시 통계 및 상태 정보
  Future<Map<String, dynamic>> getCacheStatus() async {
    try {
      // SQLite 캐시 통계
      final database = SQLiteDatabase();
      final sqliteStats = await database.getCacheStats();
      
      return {
        'sqlite': sqliteStats,
        'cache_strategy': 'SQLite -> Firestore -> World Bank API',
        'sqlite_expiry': '${_sqliteCacheExpiry.inHours} hours',
        'firestore_expiry': '${_firestoreCacheExpiry.inDays} days',
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (error, stackTrace) {
      AppLogger.error('[IntegratedDataService] Error getting cache status: $error', stackTrace);
      return {};
    }
  }

  /// 전체 캐시 초기화
  Future<void> clearAllCache() async {
    try {
      AppLogger.debug('[IntegratedDataService] Clearing all cache');
      
      final database = SQLiteDatabase();
      await database.clearAllCache();
      
      AppLogger.debug('[IntegratedDataService] All cache cleared');
    } catch (error, stackTrace) {
      AppLogger.error('[IntegratedDataService] Error clearing cache: $error', stackTrace);
    }
  }

  /// 만료된 캐시 정리
  Future<int> cleanupExpiredCache() async {
    try {
      final database = SQLiteDatabase();
      return await database.cleanupExpiredCache();
    } catch (error, stackTrace) {
      AppLogger.error('[IntegratedDataService] Error cleaning up cache: $error', stackTrace);
      return 0;
    }
  }
}