import 'dart:math' as math;
import 'package:geo_economy_dashboard/common/logger.dart';
import '../models/indicator_metadata.dart';
import '../../worldbank/models/core_indicators.dart';
import '../../worldbank/models/country_indicator.dart' as country_indicator;
import '../../worldbank/services/integrated_data_service.dart';
import '../../../common/countries/models/country.dart';
import '../../../common/countries/services/countries_service.dart';

/// 지표 상세 정보 서비스
class IndicatorDetailService {
  final IntegratedDataService _dataService;

  IndicatorDetailService({
    IntegratedDataService? dataService,
  }) : _dataService = dataService ?? IntegratedDataService();

  /// 지표 상세 정보 생성
  Future<IndicatorDetail> getIndicatorDetail({
    required String indicatorCode,
    required Country country,
    int historyYears = 10,
  }) async {
    try {
      final indicator = CoreIndicators.findByCode(indicatorCode);
      if (indicator == null) {
        throw Exception('Unknown indicator code: $indicatorCode');
      }

      AppLogger.debug('[IndicatorDetailService] Loading detail for ${indicator.name} in ${country.nameKo}');

      final detail = await _generateIndicatorDetail(indicator, country, historyYears);

      AppLogger.info('[IndicatorDetailService] Generated detail with ${detail.historicalData.length} data points');
      return detail;

    } catch (error) {
      AppLogger.error('[IndicatorDetailService] Error generating detail: $error');
      rethrow;
    }
  }

  /// 실제 지표 상세 정보 생성 (IntegratedDataService 사용)
  Future<IndicatorDetail> _generateIndicatorDetail(
    CoreIndicator coreIndicator,
    Country country,
    int historyYears,
  ) async {
    // 메타데이터 생성
    final metadata = _getIndicatorMetadata(coreIndicator);

    // IntegratedDataService를 통해 데이터 가져오기
    final countryIndicator = await _dataService.getCountryIndicator(
      countryCode: country.code,
      indicatorCode: coreIndicator.code,
      forceRefresh: false,
    );

    if (countryIndicator == null) {
      throw Exception('No data available for ${coreIndicator.name} in ${country.nameKo}');
    }

    // 히스토리컬 데이터는 CountryIndicator의 recentData 사용
    final historicalData = countryIndicator.recentData.map((point) => 
      IndicatorDataPoint(
        year: point.year,
        value: point.value,
        isEstimated: point.year >= DateTime.now().year - 1,
        isProjected: false,
      )
    ).toList();

    // 현재값과 순위
    final currentValue = countryIndicator.latestValue ?? 0.0;
    final currentRank = countryIndicator.oecdRanking ?? 0;
    final totalCountries = countryIndicator.oecdStats?.totalCountries ?? 38;

    // OECD 통계를 OECDStats 형식으로 변환
    final oecdStats = OECDStats(
      mean: countryIndicator.oecdStats?.mean ?? 0.0,
      median: countryIndicator.oecdStats?.median ?? 0.0,
      standardDeviation: _calculateStandardDeviation(countryIndicator.oecdStats),
      min: countryIndicator.oecdStats?.min ?? 0.0,
      max: countryIndicator.oecdStats?.max ?? 0.0,
      q1: countryIndicator.oecdStats?.q1 ?? 0.0,
      q3: countryIndicator.oecdStats?.q3 ?? 0.0,
      totalCountries: totalCountries,
      rankings: [], // 실제 랭킹 데이터는 별도 메서드에서 처리
    );

    // 트렌드 분석
    final trendAnalysis = _analyzeTrends(historicalData, coreIndicator.isPositive == true);

    return IndicatorDetail(
      metadata: metadata,
      countryCode: country.code,
      countryName: country.nameKo,
      historicalData: historicalData,
      currentValue: currentValue,
      currentRank: currentRank,
      totalCountries: totalCountries,
      oecdStats: oecdStats,
      trendAnalysis: trendAnalysis,
      lastCalculated: DateTime.now(),
      dataYear: countryIndicator.latestYear ?? DateTime.now().year - 1,
    );
  }

  /// 메타데이터 생성 (CoreIndicator 기반)
  IndicatorDetailMetadata _getIndicatorMetadata(CoreIndicator coreIndicator) {
    return IndicatorDetailMetadata(
      code: coreIndicator.code,
      name: coreIndicator.name,
      nameEn: coreIndicator.nameEn,
      description: coreIndicator.description,
      unit: coreIndicator.unit,
      category: coreIndicator.category.nameKo,
      source: DataSourceFactory.worldBank(),
      updateFrequency: UpdateFrequency.yearly,
      methodology: 'World Bank 표준 방법론을 따라 계산됩니다.',
      limitations: '데이터 수집 방법론과 국가별 차이로 인한 제약이 있을 수 있습니다.',
      relatedIndicators: _getRelatedIndicators(coreIndicator),
      isHigherBetter: coreIndicator.isPositive == true,
    );
  }

  /// 관련 지표 찾기
  List<String> _getRelatedIndicators(CoreIndicator coreIndicator) {
    // 같은 카테고리의 다른 지표들 반환
    final relatedIndicators = CoreIndicators.getIndicatorsByCategory(coreIndicator.category)
        .where((indicator) => indicator.code != coreIndicator.code)
        .map((indicator) => indicator.name)
        .take(3)
        .toList();
    
    return relatedIndicators;
  }

  /// 표준편차 계산 (OECDStats로부터)
  double _calculateStandardDeviation(country_indicator.OECDStats? stats) {
    if (stats == null) return 0.0;
    
    // IQR을 이용한 표준편차 추정: σ ≈ IQR / 1.35
    final iqr = stats.q3 - stats.q1;
    return iqr / 1.35;
  }

  /// 실제 OECD 순위 데이터 가져오기 (IntegratedDataService 사용)
  Future<List<Map<String, dynamic>>> getRealRankingData({
    required String indicatorCode,
    required Country currentCountry,
    int maxCountries = 15,
  }) async {
    try {
      AppLogger.debug('[IndicatorDetailService] Loading real ranking data for $indicatorCode');
      
      // 현재는 Top 5 OECD 국가들의 데이터를 가져와서 순위 생성
      final oecdCountries = ['USA', 'DEU', 'JPN', 'GBR', 'FRA', 'KOR', 'ITA', 'CAN', 'AUS', 'ESP'];
      final rankingData = <Map<String, dynamic>>[];
      
      final countriesService = CountriesService.instance;
      final countryMap = {for (var c in countriesService.countries) c.code: c};
      
      int rank = 1;
      for (final countryCode in oecdCountries) {
        if (rank > maxCountries) break;
        
        final country = countryMap[countryCode];
        if (country != null) {
          try {
            final countryIndicator = await _dataService.getCountryIndicator(
              countryCode: countryCode,
              indicatorCode: indicatorCode,
              forceRefresh: false,
            );
            
            if (countryIndicator != null && countryIndicator.latestValue != null) {
              rankingData.add({
                'rank': rank,
                'country': country.nameKo,
                'countryCode': countryCode,
                'flag': country.flagEmoji,
                'value': countryIndicator.latestValue,
              });
              rank++;
            }
          } catch (e) {
            // 개별 국가 데이터 로딩 실패 시 계속 진행
            AppLogger.debug('[IndicatorDetailService] Failed to load data for $countryCode: $e');
          }
        }
      }
      
      // 데이터가 있는 경우 실제 값으로 정렬
      if (rankingData.isNotEmpty && rankingData.any((item) => item['value'] != null)) {
        final coreIndicator = CoreIndicators.findByCode(indicatorCode);
        final isHigherBetter = coreIndicator?.isPositive == true;
        
        rankingData.sort((a, b) {
          final valueA = (a['value'] as double?) ?? 0.0;
          final valueB = (b['value'] as double?) ?? 0.0;
          
          return isHigherBetter ? valueB.compareTo(valueA) : valueA.compareTo(valueB);
        });
        
        // 순위 재계산
        for (int i = 0; i < rankingData.length; i++) {
          rankingData[i]['rank'] = i + 1;
        }
      }
      
      AppLogger.info('[IndicatorDetailService] Generated ${rankingData.length} real ranking entries');
      return rankingData;
      
    } catch (error) {
      AppLogger.error('[IndicatorDetailService] Error loading real ranking data: $error');
      return await _getFallbackRankingData(indicatorCode, currentCountry);
    }
  }
  
  /// Fallback 순위 데이터 생성 (실제 데이터가 없을 때)
  Future<List<Map<String, dynamic>>> _getFallbackRankingData(String indicatorCode, Country currentCountry) async {
    AppLogger.warning('[IndicatorDetailService] Using fallback ranking data');
    
    try {
      // OECD 국가 목록에서 상위 10개국과 현재 국가 선택
      final oecdCountries = CountriesService.instance.countries;
      
      // 주요 경제대국들을 우선 선택
      final priorityCountries = ['USA', 'DEU', 'JPN', 'GBR', 'FRA', 'ITA', 'CAN', 'AUS', 'ESP', 'NLD'];
      final selectedCountries = <Country>[];
      
      // 우선순위 국가들 추가
      for (final code in priorityCountries) {
        final country = oecdCountries.firstWhere(
          (c) => c.code == code,
          orElse: () => Country(code: code, name: code, nameKo: code, flagEmoji: '🏳️', region: 'OECD'),
        );
        selectedCountries.add(country);
      }
      
      // 현재 국가가 목록에 없다면 추가
      if (!selectedCountries.any((c) => c.code == currentCountry.code)) {
        selectedCountries.add(currentCountry);
      }
      
      return selectedCountries.asMap().entries.map((entry) {
        return {
          'rank': entry.key + 1,
          'country': entry.value.nameKo,
          'countryCode': entry.value.code,
          'flag': entry.value.flagEmoji,
          'value': 0.0, // 실제 값이 없으므로 0
        };
      }).toList();
      
    } catch (error) {
      AppLogger.error('[IndicatorDetailService] Error creating fallback data: $error');
      
      // 최후의 수단: 하드코딩된 기본 데이터
      return [
        {'rank': 1, 'country': '미국', 'countryCode': 'USA', 'flag': '🇺🇸', 'value': 0.0},
        {'rank': 2, 'country': '독일', 'countryCode': 'DEU', 'flag': '🇩🇪', 'value': 0.0},
        {'rank': 3, 'country': '일본', 'countryCode': 'JPN', 'flag': '🇯🇵', 'value': 0.0},
        {'rank': 4, 'country': currentCountry.nameKo, 'countryCode': currentCountry.code, 'flag': currentCountry.flagEmoji, 'value': 0.0},
      ];
    }
  }

  /// 트렌드 분석
  TrendAnalysis _analyzeTrends(List<IndicatorDataPoint> data, bool isHigherBetter) {
    if (data.length < 3) {
      return const TrendAnalysis(
        shortTerm: TrendDirection.stable,
        mediumTerm: TrendDirection.stable,
        longTerm: TrendDirection.stable,
        volatility: 0,
        correlation: 0,
        insights: [],
        summary: '충분한 데이터가 없어 트렌드를 분석할 수 없습니다.',
      );
    }

    final values = data.map((d) => d.value).toList();
    
    // 단기 트렌드 (최근 1년)
    final shortTerm = _calculateTrendDirection(values.take(2).toList(), isHigherBetter);
    
    // 중기 트렌드 (최근 3년)
    final mediumTerm = _calculateTrendDirection(
      values.length >= 3 ? values.take(3).toList() : values, 
      isHigherBetter
    );
    
    // 장기 트렌드 (전체)
    final longTerm = _calculateTrendDirection(values, isHigherBetter);
    
    // 변동성 계산 (변동계수)
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final volatility = math.sqrt(variance) / mean.abs();
    
    // 인사이트 생성
    final insights = _generateInsights(shortTerm, mediumTerm, longTerm, volatility, isHigherBetter);
    final summary = _generateSummary(shortTerm, mediumTerm, longTerm, volatility, isHigherBetter);

    return TrendAnalysis(
      shortTerm: shortTerm,
      mediumTerm: mediumTerm,
      longTerm: longTerm,
      volatility: volatility,
      correlation: 0, // 추후 구현
      insights: insights,
      summary: summary,
    );
  }

  /// 트렌드 방향 계산
  TrendDirection _calculateTrendDirection(List<double> values, bool isHigherBetter) {
    if (values.length < 2) return TrendDirection.stable;

    final firstValue = values.first;
    final lastValue = values.last;
    final changePercent = ((lastValue - firstValue) / firstValue.abs()) * 100;

    // 변동성 확인
    if (values.length >= 3) {
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
      final coefficientOfVariation = math.sqrt(variance) / mean.abs();
      
      if (coefficientOfVariation > 0.15) {
        return TrendDirection.volatile;
      }
    }

    if (changePercent.abs() < 2.0) {
      return TrendDirection.stable;
    } else if (changePercent > 0) {
      return TrendDirection.up;
    } else {
      return TrendDirection.down;
    }
  }

  /// 인사이트 생성
  List<String> _generateInsights(
    TrendDirection shortTerm,
    TrendDirection mediumTerm, 
    TrendDirection longTerm,
    double volatility,
    bool isHigherBetter,
  ) {
    final insights = <String>[];

    // 트렌드 일관성 분석
    if (shortTerm == mediumTerm && mediumTerm == longTerm) {
      if (shortTerm == TrendDirection.up) {
        insights.add(isHigherBetter ? '지속적인 개선 추세를 보이고 있습니다.' : '지속적인 악화 추세가 우려됩니다.');
      } else if (shortTerm == TrendDirection.down) {
        insights.add(isHigherBetter ? '지속적인 악화 추세가 우려됩니다.' : '지속적인 개선 추세를 보이고 있습니다.');
      } else {
        insights.add('안정적인 수준을 유지하고 있습니다.');
      }
    } else {
      insights.add('단기와 장기 트렌드에 차이가 있어 주의 깊은 관찰이 필요합니다.');
    }

    // 변동성 분석
    if (volatility > 0.2) {
      insights.add('높은 변동성으로 인해 예측이 어려운 상황입니다.');
    } else if (volatility < 0.05) {
      insights.add('안정적인 변화 패턴을 보이고 있습니다.');
    }

    return insights;
  }

  /// 요약 생성
  String _generateSummary(
    TrendDirection shortTerm,
    TrendDirection mediumTerm,
    TrendDirection longTerm,
    double volatility,
    bool isHigherBetter,
  ) {
    if (longTerm == TrendDirection.up) {
      return isHigherBetter 
          ? '장기적으로 개선되고 있는 긍정적인 지표입니다.'
          : '장기적으로 악화되고 있어 정책적 관심이 필요합니다.';
    } else if (longTerm == TrendDirection.down) {
      return isHigherBetter
          ? '장기적으로 악화되고 있어 정책적 관심이 필요합니다.'
          : '장기적으로 개선되고 있는 긍정적인 지표입니다.';
    } else if (longTerm == TrendDirection.volatile) {
      return '높은 변동성으로 인해 안정화 정책이 필요합니다.';
    } else {
      return '안정적인 수준을 유지하고 있습니다.';
    }
  }

  /// 캐시 새로고침
  Future<IndicatorDetail> refreshIndicatorDetail({
    required String indicatorCode,
    required Country country,
    int historyYears = 10,
  }) async {
    AppLogger.debug('[IndicatorDetailService] Force refreshing detail for $indicatorCode');
    return getIndicatorDetail(
      indicatorCode: indicatorCode,
      country: country,
      historyYears: historyYears,
    );
  }

  /// 리소스 정리
  void dispose() {
    // IntegratedDataService는 dispose가 필요 없음
  }
}