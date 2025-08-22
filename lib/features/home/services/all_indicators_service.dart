import 'package:geo_economy_dashboard/common/logger.dart';
import '../models/indicator_comparison.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../worldbank/repositories/indicator_repository.dart';

/// 모든 20개 지표 데이터를 관리하는 서비스
class AllIndicatorsService {
  final IndicatorRepository _repository;

  AllIndicatorsService({IndicatorRepository? repository})
      : _repository = repository ?? IndicatorRepository();

  /// 핵심 20지표 정의 (PRD 기준)
  static const List<IndicatorCode> allIndicators = [
    // 성장/활동 (4개)
    IndicatorCode.gdpRealGrowth,      // GDP 성장률
    IndicatorCode.gdpPppPerCapita,    // 1인당 GDP (PPP)
    IndicatorCode.manufShare,         // 제조업 부가가치 비중
    IndicatorCode.grossFixedCapital,  // 총고정자본형성
    
    // 물가/통화 (2개)
    IndicatorCode.cpiInflation,       // CPI 인플레이션
    IndicatorCode.m2Money,            // M2 통화량
    
    // 고용/노동 (3개)
    IndicatorCode.unemployment,       // 실업률
    IndicatorCode.laborParticipation, // 노동참가율
    IndicatorCode.employmentRate,     // 고용률
    
    // 재정/정부 (3개)
    IndicatorCode.govExpenditure,     // 정부최종소비지출
    IndicatorCode.taxRevenue,         // 조세수입
    IndicatorCode.govDebt,            // 정부부채
    
    // 대외/거시건전성 (4개)
    IndicatorCode.currentAccount,     // 경상수지
    IndicatorCode.exportsShare,       // 수출 비중
    IndicatorCode.importsShare,       // 수입 비중
    IndicatorCode.reservesMonths,     // 외환보유액
    
    // 분배/사회 (2개)
    IndicatorCode.gini,               // 지니계수
    IndicatorCode.povertyNat,         // 빈곤율
    
    // 환경/에너지 (2개)
    IndicatorCode.co2PerCapita,       // CO₂ 배출
    IndicatorCode.renewablesShare,    // 재생에너지 비중
  ];

  /// 카테고리별 지표 그룹화
  static const Map<String, List<IndicatorCode>> indicatorsByCategory = {
    '성장/활동': [
      IndicatorCode.gdpRealGrowth,
      IndicatorCode.gdpPppPerCapita,
      IndicatorCode.manufShare,
      IndicatorCode.grossFixedCapital,
    ],
    '물가/통화': [
      IndicatorCode.cpiInflation,
      IndicatorCode.m2Money,
    ],
    '고용/노동': [
      IndicatorCode.unemployment,
      IndicatorCode.laborParticipation,
      IndicatorCode.employmentRate,
    ],
    '재정/정부': [
      IndicatorCode.govExpenditure,
      IndicatorCode.taxRevenue,
      IndicatorCode.govDebt,
    ],
    '대외/거시건전성': [
      IndicatorCode.currentAccount,
      IndicatorCode.exportsShare,
      IndicatorCode.importsShare,
      IndicatorCode.reservesMonths,
    ],
    '분배/사회': [
      IndicatorCode.gini,
      IndicatorCode.povertyNat,
    ],
    '환경/에너지': [
      IndicatorCode.co2PerCapita,
      IndicatorCode.renewablesShare,
    ],
  };

  /// 특정 국가의 모든 지표 데이터 가져오기
  Future<Map<IndicatorCode, IndicatorComparison?>> getAllIndicatorsForCountry({
    required String countryCode,
    int? year,
  }) async {
    final results = <IndicatorCode, IndicatorComparison?>{};
    
    AppLogger.debug('[AllIndicatorsService] Loading all 20 indicators for $countryCode...');
    
    // 병렬로 모든 지표 데이터 가져오기
    final futures = allIndicators.map((indicator) async {
      try {
        final comparison = await _repository.generateIndicatorComparison(
          indicatorCode: indicator,
          countryCode: countryCode,
          year: year,
        );
        return MapEntry(indicator, comparison);
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
  Future<Map<String, List<IndicatorComparison>>> getIndicatorsByCategory({
    required String countryCode,
    int? year,
  }) async {
    final allData = await getAllIndicatorsForCountry(
      countryCode: countryCode, 
      year: year,
    );
    
    final categoryResults = <String, List<IndicatorComparison>>{};
    
    for (final category in indicatorsByCategory.keys) {
      final categoryIndicators = indicatorsByCategory[category]!;
      final categoryData = <IndicatorComparison>[];
      
      for (final indicator in categoryIndicators) {
        final data = allData[indicator];
        if (data != null) {
          categoryData.add(data);
        }
      }
      
      if (categoryData.isNotEmpty) {
        categoryResults[category] = categoryData;
      }
    }
    
    return categoryResults;
  }

  /// 특정 카테고리의 성과 요약
  Future<CategoryPerformanceSummary> getCategoryPerformance({
    required String countryCode,
    required String category,
    int? year,
  }) async {
    final indicators = indicatorsByCategory[category];
    if (indicators == null || indicators.isEmpty) {
      throw Exception('Unknown category: $category');
    }

    final results = <IndicatorComparison>[];
    var excellentCount = 0;
    var goodCount = 0;
    var averageCount = 0;
    var poorCount = 0;

    for (final indicator in indicators) {
      try {
        final comparison = await _repository.generateIndicatorComparison(
          indicatorCode: indicator,
          countryCode: countryCode,
          year: year,
        );
        
        results.add(comparison);
        
        // 성과별 카운트
        switch (comparison.insight.performance) {
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
      } catch (e) {
        AppLogger.error('[AllIndicatorsService] Error loading ${indicator.name}: $e');
      }
    }

    final totalCount = results.length;
    if (totalCount == 0) {
      throw Exception('No data available for category: $category');
    }

    // 카테고리 전체 성과 계산
    final overallPerformance = _calculateOverallPerformance(
      excellentCount, goodCount, averageCount, poorCount, totalCount,
    );

    return CategoryPerformanceSummary(
      category: category,
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

  /// 리소스 정리
  void dispose() {
    _repository.dispose();
  }
}

/// 카테고리 성과 요약
class CategoryPerformanceSummary {
  final String category;
  final List<IndicatorComparison> indicators;
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