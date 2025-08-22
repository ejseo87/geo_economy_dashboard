import 'package:geo_economy_dashboard/common/logger.dart';

import '../models/country_summary.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../worldbank/repositories/indicator_repository.dart';
import '../../countries/models/country.dart';
import '../models/indicator_comparison.dart';

/// 국가 요약 정보를 생성하는 서비스
class CountrySummaryService {
  final IndicatorRepository _repository;

  CountrySummaryService({IndicatorRepository? repository})
    : _repository = repository ?? IndicatorRepository();

  /// 핵심 20지표 정의 (PRD 기준)
  static const List<IndicatorCode> _allIndicators = [
    // 성장/활동
    IndicatorCode.gdpRealGrowth, // GDP 성장률
    IndicatorCode.gdpPppPerCapita, // 1인당 GDP (PPP)
    IndicatorCode.manufShare, // 제조업 부가가치 비중
    IndicatorCode.grossFixedCapital, // 총고정자본형성
    // 물가/통화
    IndicatorCode.cpiInflation, // CPI 인플레이션
    IndicatorCode.m2Money, // M2 통화량
    // 고용/노동
    IndicatorCode.unemployment, // 실업률
    IndicatorCode.laborParticipation, // 노동참가율
    IndicatorCode.employmentRate, // 고용률
    // 재정/정부
    IndicatorCode.govExpenditure, // 정부최종소비지출
    IndicatorCode.taxRevenue, // 조세수입
    IndicatorCode.govDebt, // 정부부채
    // 대외/거시건전성
    IndicatorCode.currentAccount, // 경상수지
    IndicatorCode.exportsShare, // 수출 비중
    IndicatorCode.importsShare, // 수입 비중
    IndicatorCode.reservesMonths, // 외환보유액
    // 분배/사회
    IndicatorCode.gini, // 지니계수
    IndicatorCode.povertyNat, // 빈곤율
    // 환경/에너지
    IndicatorCode.co2PerCapita, // CO₂ 배출
    IndicatorCode.renewablesShare, // 재생에너지 비중
  ];

  /// Top 5 우선순위 지표 (요약카드용)
  static const List<IndicatorCode> _topIndicators = [
    IndicatorCode.gdpRealGrowth, // GDP 성장률
    IndicatorCode.unemployment, // 실업률
    IndicatorCode.gdpPppPerCapita, // 1인당 GDP (PPP)
    IndicatorCode.cpiInflation, // CPI 인플레이션
    IndicatorCode.currentAccount, // 경상수지
  ];

  /// 국가 요약 정보 생성
  Future<CountrySummary> generateCountrySummary({
    required String countryCode,
  }) async {
    try {
      AppLogger.debug(
        '[CountrySummaryService] Generating summary for $countryCode...',
      );

      final country = OECDCountries.findByCode(countryCode);
      if (country == null) {
        throw Exception('Country not found: $countryCode');
      }

      final indicators = <KeyIndicator>[];
      var excellentCount = 0;
      var goodCount = 0;
      var averageCount = 0;
      var poorCount = 0;

      // 각 핵심 지표에 대해 데이터 수집
      for (final indicatorCode in _topIndicators) {
        try {
          AppLogger.debug(
            '[CountrySummaryService] Processing ${indicatorCode.name}...',
          );

          // 지표 데이터 가져오기
          final data = await _repository.getIndicatorData(
            countryCode: countryCode,
            indicatorCode: indicatorCode,
          );

          if (data == null) {
            AppLogger.debug(
              '[CountrySummaryService] No data for ${indicatorCode.name}',
            );
            continue;
          }

          // 최신 데이터 찾기
          double? value;
          int? year;
          for (final candidateYear in [2023, 2022, 2021, 2020]) {
            final yearValue = data.getValueForYear(candidateYear);
            if (yearValue != null && yearValue.isFinite) {
              value = yearValue;
              year = candidateYear;
              break;
            }
          }

          if (value == null || year == null) {
            AppLogger.debug(
              '[CountrySummaryService] No recent data for ${indicatorCode.name}',
            );
            continue;
          }

          // OECD 통계 가져오기
          final oecdStats = await _repository.getOECDStatistics(
            indicatorCode: indicatorCode,
            year: year,
          );

          // 성과 레벨 계산
          final performance = _getPerformanceLevel(
            value,
            oecdStats,
            indicatorCode.direction,
          );

          // 순위 및 백분위 계산
          final rank = oecdStats.getRankForCountry(countryCode) ??
              oecdStats.calculateRankForValue(
                value,
                indicatorCode.direction == IndicatorDirection.higher,
              );
          final percentile = oecdStats.calculatePercentile(value);

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

          indicators.add(
            KeyIndicator(
              code: indicatorCode.code,
              name: indicatorCode.name,
              unit: indicatorCode.unit,
              value: value,
              rank: rank,
              totalCountries: oecdStats.totalCountries,
              percentile: percentile,
              performance: performance,
              direction: indicatorCode.direction.toString().split('.').last,
              sparklineEmoji: _getTrendEmoji(indicatorCode),
            ),
          );
        } catch (e) {
          AppLogger.error(
            '[CountrySummaryService] Error processing ${indicatorCode.name}: $e',
          );
          // 개별 지표 오류는 무시하고 계속 진행
        }
      }

      if (indicators.isEmpty) {
        throw Exception('No indicator data available for $countryCode');
      }

      // 전체 순위 결정
      final overallRanking = _calculateOverallRanking(
        excellentCount,
        goodCount,
        averageCount,
        poorCount,
        indicators.length,
      );

      AppLogger.debug(
        '[CountrySummaryService] Generated summary with ${indicators.length} indicators',
      );

      return CountrySummary(
        countryCode: countryCode,
        countryName: country.nameKo,
        flagEmoji: country.flagEmoji,
        topIndicators: indicators,
        overallRanking: overallRanking,
        lastUpdated: DateTime.now(),
      );
    } catch (error) {
      AppLogger.error(
        '[CountrySummaryService] Error generating summary: $error',
      );
      rethrow;
    }
  }

  /// 성과 레벨 계산
  PerformanceLevel _getPerformanceLevel(
    double value,
    OECDStatistics stats,
    IndicatorDirection direction,
  ) {
    switch (direction) {
      case IndicatorDirection.higher:
        // 높을수록 좋은 지표
        if (value >= stats.q3) return PerformanceLevel.excellent;
        if (value >= stats.median) return PerformanceLevel.good;
        if (value >= stats.q1) return PerformanceLevel.average;
        return PerformanceLevel.poor;

      case IndicatorDirection.lower:
        // 낮을수록 좋은 지표
        if (value <= stats.q1) return PerformanceLevel.excellent;
        if (value <= stats.median) return PerformanceLevel.good;
        if (value <= stats.q3) return PerformanceLevel.average;
        return PerformanceLevel.poor;

      case IndicatorDirection.neutral:
        // 중립적 지표 (미디안 근처가 좋음)
        final distanceFromMedian = (value - stats.median).abs();
        final iqr = stats.q3 - stats.q1;

        if (distanceFromMedian <= iqr * 0.25) return PerformanceLevel.excellent;
        if (distanceFromMedian <= iqr * 0.5) return PerformanceLevel.good;
        if (distanceFromMedian <= iqr) return PerformanceLevel.average;
        return PerformanceLevel.poor;
    }
  }


  /// 전체 순위 계산
  String _calculateOverallRanking(
    int excellentCount,
    int goodCount,
    int averageCount,
    int poorCount,
    int totalCount,
  ) {
    final excellentRatio = excellentCount / totalCount;
    final goodRatio = (excellentCount + goodCount) / totalCount;
    final poorRatio = poorCount / totalCount;

    if (excellentRatio >= 0.6) return '상위권';
    if (goodRatio >= 0.6) return '중상위권';
    if (poorRatio >= 0.6) return '하위권';
    return '중위권';
  }

  /// 트렌드 이모지 (임시)
  String _getTrendEmoji(IndicatorCode indicator) {
    switch (indicator) {
      case IndicatorCode.gdpRealGrowth:
        return '📈';
      case IndicatorCode.unemployment:
        return '📉';
      case IndicatorCode.gdpPppPerCapita:
        return '💰';
      case IndicatorCode.cpiInflation:
        return '📊';
      case IndicatorCode.currentAccount:
        return '⚖️';
      default:
        return '📊';
    }
  }

  /// 리소스 정리
  void dispose() {
    _repository.dispose();
  }
}

// OECDStatistics는 indicator_comparison.dart에서 import
