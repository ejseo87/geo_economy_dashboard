import 'package:geo_economy_dashboard/common/logger.dart';
import '../models/indicator_comparison.dart';
import '../../worldbank/models/core_indicators.dart';
import '../../worldbank/models/country_indicator.dart';
import '../../worldbank/services/integrated_data_service.dart';

/// 모든 20개 지표 데이터를 관리하는 서비스
class AllIndicatorsService {
  final IntegratedDataService _dataService;

  AllIndicatorsService({IntegratedDataService? dataService})
      : _dataService = dataService ?? IntegratedDataService();

  /// 핵심 20지표 정의 (PRD v1.1 기준 - CoreIndicators 사용)
  static List<CoreIndicator> get allIndicators => CoreIndicators.indicators;

  /// 카테고리별 지표 그룹화 (PRD v1.1)
  static Map<CoreIndicatorCategory, List<CoreIndicator>> get indicatorsByCategory {
    final categoryMap = <CoreIndicatorCategory, List<CoreIndicator>>{};
    
    for (final category in CoreIndicatorCategory.values) {
      categoryMap[category] = CoreIndicators.getIndicatorsByCategory(category);
    }
    
    return categoryMap;
  }

  /// 특정 국가의 모든 지표 데이터 가져오기
  Future<Map<CoreIndicator, CountryIndicator?>> getAllIndicatorsForCountry({
    required String countryCode,
    bool forceRefresh = false,
  }) async {
    final results = <CoreIndicator, CountryIndicator?>{};
    
    AppLogger.debug('[AllIndicatorsService] Loading all 20 indicators for $countryCode...');
    
    // 병렬로 모든 지표 데이터 가져오기
    final futures = allIndicators.map((indicator) async {
      try {
        final countryIndicator = await _dataService.getCountryIndicator(
          countryCode: countryCode,
          indicatorCode: indicator.code,
          forceRefresh: forceRefresh,
        );
        return MapEntry(indicator, countryIndicator);
      } catch (e) {
        AppLogger.error('[AllIndicatorsService] Error loading ${indicator.name}: $e');
        return MapEntry(indicator, null);
      }
    }).toList();

    final completedFutures = await Future.wait(futures);
    
    for (final entry in completedFutures) {
      results[entry.key] = entry.value;
    }

    final successCount = results.values.where((v) => v != null).length;
    AppLogger.debug('[AllIndicatorsService] Successfully loaded $successCount/${allIndicators.length} indicators');
    
    return results;
  }

  /// 카테고리별 지표 데이터 가져오기  
  Future<Map<CoreIndicatorCategory, List<CountryIndicator>>> getIndicatorsByCategory({
    required String countryCode,
    bool forceRefresh = false,
  }) async {
    AppLogger.debug('[AllIndicatorsService] Loading indicators by category for $countryCode...');
    
    // IntegratedDataService의 getCore20Indicators 사용 (이미 카테고리별로 그룹화됨)
    final categoryResults = await _dataService.getCore20Indicators(
      countryCode: countryCode,
      forceRefresh: forceRefresh,
    );
    
    AppLogger.debug('[AllIndicatorsService] Loaded ${categoryResults.length} categories');
    return categoryResults;
  }

  /// 특정 카테고리의 성과 요약
  Future<CategoryPerformanceSummary> getCategoryPerformance({
    required String countryCode,
    required CoreIndicatorCategory category,
    bool forceRefresh = false,
  }) async {
    AppLogger.debug('[AllIndicatorsService] Getting performance for category: ${category.nameKo}');
    
    final indicators = CoreIndicators.getIndicatorsByCategory(category);
    if (indicators.isEmpty) {
      throw Exception('No indicators found for category: ${category.nameKo}');
    }

    final results = <CountryIndicator>[];
    var excellentCount = 0;
    var goodCount = 0;
    var averageCount = 0;
    var poorCount = 0;

    for (final indicator in indicators) {
      try {
        final countryIndicator = await _dataService.getCountryIndicator(
          countryCode: countryCode,
          indicatorCode: indicator.code,
          forceRefresh: forceRefresh,
        );
        
        if (countryIndicator != null) {
          results.add(countryIndicator);
          
          // OECD 백분위수로 성과 레벨 계산
          final percentile = countryIndicator.oecdPercentile ?? 50.0;
          final performance = _getPerformanceFromPercentile(percentile);
          
          // 성과별 카운트
          switch (performance) {
            case PerformanceLevel.excellent:
              excellentCount++;
              break;
            case PerformanceLevel.good:
              goodCount++;
              break;
            case PerformanceLevel.average:
              averageCount++;
              break;
            case PerformanceLevel.poor:
              poorCount++;
              break;
          }
        }
      } catch (e) {
        AppLogger.error('[AllIndicatorsService] Error loading ${indicator.name}: $e');
      }
    }

    final totalCount = results.length;
    if (totalCount == 0) {
      throw Exception('No data available for category: ${category.nameKo}');
    }

    // 카테고리 전체 성과 계산
    final overallPerformance = _calculateOverallPerformance(
      excellentCount, goodCount, averageCount, poorCount, totalCount,
    );

    return CategoryPerformanceSummary(
      category: category.nameKo,
      indicators: results,
      excellentCount: excellentCount,
      goodCount: goodCount,
      averageCount: averageCount,
      poorCount: poorCount,
      totalCount: totalCount,
      overallPerformance: overallPerformance,
    );
  }

  /// 전체 카테고리 성과 계산
  PerformanceLevel _calculateOverallPerformance(
    int excellentCount,
    int goodCount,
    int averageCount,
    int poorCount,
    int totalCount,
  ) {
    final excellentRatio = excellentCount / totalCount;
    final goodRatio = (excellentCount + goodCount) / totalCount;
    final poorRatio = poorCount / totalCount;

    if (excellentRatio >= 0.5) return PerformanceLevel.excellent;
    if (goodRatio >= 0.6) return PerformanceLevel.good;
    if (poorRatio >= 0.5) return PerformanceLevel.poor;
    return PerformanceLevel.average;
  }

  /// 단일 지표 데이터 가져오기
  Future<CountryIndicator?> getIndicatorData({
    required String countryCode,
    required String indicatorCode,
    bool forceRefresh = false,
  }) async {
    try {
      final countryIndicator = await _dataService.getCountryIndicator(
        countryCode: countryCode,
        indicatorCode: indicatorCode,
        forceRefresh: forceRefresh,
      );
      return countryIndicator;
    } catch (e) {
      AppLogger.error('[AllIndicatorsService] Error loading $indicatorCode: $e');
      return null;
    }
  }

  /// 백분위수로 성과 레벨 계산
  PerformanceLevel _getPerformanceFromPercentile(double percentile) {
    if (percentile >= 75) return PerformanceLevel.excellent;
    if (percentile >= 50) return PerformanceLevel.good;
    if (percentile >= 25) return PerformanceLevel.average;
    return PerformanceLevel.poor;
  }

  /// 리소스 정리 (IntegratedDataService는 dispose가 필요 없음)
  void dispose() {
    // IntegratedDataService에는 dispose 메서드가 없음
  }
}

/// 카테고리 성과 요약
class CategoryPerformanceSummary {
  final String category;
  final List<CountryIndicator> indicators;
  final int excellentCount;
  final int goodCount;
  final int averageCount;
  final int poorCount;
  final int totalCount;
  final PerformanceLevel overallPerformance;

  const CategoryPerformanceSummary({
    required this.category,
    required this.indicators,
    required this.excellentCount,
    required this.goodCount,
    required this.averageCount,
    required this.poorCount,
    required this.totalCount,
    required this.overallPerformance,
  });

  /// 성과 분포 비율
  double get excellentRatio => excellentCount / totalCount;
  double get goodRatio => goodCount / totalCount;
  double get averageRatio => averageCount / totalCount;
  double get poorRatio => poorCount / totalCount;
}