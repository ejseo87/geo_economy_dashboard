import 'dart:math' as math;
import 'package:geo_economy_dashboard/common/logger.dart';
import '../models/indicator_metadata.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../worldbank/repositories/indicator_repository.dart';
import '../../../common/countries/models/country.dart';
import '../../../common/countries/services/countries_service.dart';
import '../../home/models/indicator_comparison.dart';

/// 지표 상세 정보 서비스
class IndicatorDetailService {
  final IndicatorRepository _repository;

  IndicatorDetailService({
    IndicatorRepository? repository,
  }) : _repository = repository ?? IndicatorRepository();

  /// 지표 상세 정보 생성
  Future<IndicatorDetail> getIndicatorDetail({
    required IndicatorCode indicatorCode,
    required Country country,
    int historyYears = 10,
  }) async {
    try {
      AppLogger.debug('[IndicatorDetailService] Loading detail for ${indicatorCode.name} in ${country.nameKo}');

      final detail = await _generateIndicatorDetail(indicatorCode, country, historyYears);

      AppLogger.info('[IndicatorDetailService] Generated detail with ${detail.historicalData.length} data points');
      return detail;

    } catch (error) {
      AppLogger.error('[IndicatorDetailService] Error generating detail: $error');
      rethrow;
    }
  }

  /// 실제 지표 상세 정보 생성 (기존 로직)
  Future<IndicatorDetail> _generateIndicatorDetail(
    IndicatorCode indicatorCode,
    Country country,
    int historyYears,
  ) async {
    // 메타데이터 생성
    final metadata = _getIndicatorMetadata(indicatorCode);

    // 다른 화면들과 동일한 데이터 소스 사용
    final comparison = await _repository.generateIndicatorComparison(
      indicatorCode: indicatorCode,
      countryCode: country.code,
    );

    // 히스토리컬 데이터 수집 (기존 방식 유지)
    final historicalData = await _getHistoricalData(indicatorCode, country.code, historyYears);

    // comparison 데이터에서 현재값과 순위 가져오기
    final currentValue = comparison.selectedCountry.value;
    final currentRank = comparison.selectedCountry.rank;
    final totalCountries = comparison.oecdStats.totalCountries;

    // OECD 통계를 OECDStats 형식으로 변환
    final oecdStats = OECDStats(
      mean: comparison.oecdStats.mean,
      median: comparison.oecdStats.median,
      standardDeviation: _calculateStandardDeviation(comparison.oecdStats),
      min: comparison.oecdStats.min,
      max: comparison.oecdStats.max,
      q1: comparison.oecdStats.q1,
      q3: comparison.oecdStats.q3,
      totalCountries: comparison.oecdStats.totalCountries,
      rankings: _convertToCountryRankings(comparison.oecdStats.countryRankings),
    );

    // 트렌드 분석
    final trendAnalysis = _analyzeTrends(historicalData, metadata.isHigherBetter);

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
    );
  }


  /// 메타데이터 생성
  IndicatorDetailMetadata _getIndicatorMetadata(IndicatorCode indicatorCode) {
    switch (indicatorCode) {
      case IndicatorCode.gdpRealGrowth:
        return IndicatorDetailMetadataFactory.createGDPRealGrowth();
      case IndicatorCode.unemployment:
        return IndicatorDetailMetadataFactory.createUnemploymentRate();
      case IndicatorCode.cpiInflation:
        return IndicatorDetailMetadataFactory.createInflationCPI();
      default:
        return _createGenericMetadata(indicatorCode);
    }
  }

  /// 범용 메타데이터 생성
  IndicatorDetailMetadata _createGenericMetadata(IndicatorCode indicatorCode) {
    return IndicatorDetailMetadata(
      code: indicatorCode.code,
      name: indicatorCode.name,
      nameEn: indicatorCode.name,
      description: '${indicatorCode.name}에 대한 상세 분석 정보입니다.',
      unit: indicatorCode.unit,
      category: _getCategoryForIndicator(indicatorCode),
      source: DataSourceFactory.worldBank(),
      updateFrequency: UpdateFrequency.yearly,
      methodology: 'World Bank 표준 방법론을 따라 계산됩니다.',
      limitations: '데이터 수집 방법론과 국가별 차이로 인한 제약이 있을 수 있습니다.',
      relatedIndicators: [],
      isHigherBetter: _isHigherBetter(indicatorCode),
    );
  }

  /// 히스토리컬 데이터 수집
  Future<List<IndicatorDataPoint>> _getHistoricalData(
    IndicatorCode indicatorCode, 
    String countryCode, 
    int years
  ) async {
    final indicatorData = await _repository.getIndicatorData(
      countryCode: countryCode,
      indicatorCode: indicatorCode,
    );

    if (indicatorData == null) {
      return [];
    }

    final currentYear = DateTime.now().year;
    final startYear = currentYear - years + 1;
    final dataPoints = <IndicatorDataPoint>[];

    for (int year = startYear; year <= currentYear; year++) {
      final value = indicatorData.getValueForYear(year);
      if (value != null && value.isFinite) {
        dataPoints.add(IndicatorDataPoint(
          year: year,
          value: value,
          isEstimated: year >= currentYear - 1, // 최근 2년은 추정값
          isProjected: year > currentYear - 1, // 미래 예측값
        ));
      }
    }

    return dataPoints..sort((a, b) => a.year.compareTo(b.year));
  }

  /// 표준편차 계산 (Q1, Q3로부터 추정)
  double _calculateStandardDeviation(OECDStatistics stats) {
    // IQR을 이용한 표준편차 추정: σ ≈ IQR / 1.35
    final iqr = stats.q3 - stats.q1;
    return iqr / 1.35;
  }

  /// CountryRankingData를 CountryRanking으로 변환
  List<CountryRanking> _convertToCountryRankings(List<CountryRankingData>? rankingData) {
    if (rankingData == null) return [];
    
    return rankingData.map((data) => CountryRanking(
      countryCode: data.countryCode,
      countryName: data.countryName,
      value: data.value,
      rank: data.rank,
    )).toList();
  }

  /// 실제 OECD 순위 데이터 가져오기
  Future<List<Map<String, dynamic>>> getRealRankingData({
    required IndicatorCode indicatorCode,
    required Country currentCountry,
    int maxCountries = 15,
  }) async {
    try {
      AppLogger.debug('[IndicatorDetailService] Loading real ranking data for ${indicatorCode.name}');
      
      // 최근 3년간 데이터가 있는 연도 찾기
      final currentYear = DateTime.now().year;
      final candidateYears = [currentYear - 1, currentYear - 2, currentYear - 3];
      
      OECDStatistics? oecdStats;
      int? usedYear;
      
      for (final year in candidateYears) {
        try {
          oecdStats = await _repository.getOECDStatistics(
            indicatorCode: indicatorCode,
            year: year,
          );
          if (oecdStats.totalCountries > 0 && 
              oecdStats.countryRankings != null && 
              oecdStats.countryRankings!.isNotEmpty) {
            usedYear = year;
            break;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (oecdStats?.countryRankings == null || usedYear == null) {
        AppLogger.warning('[IndicatorDetailService] No ranking data available');
        return await _getFallbackRankingData(indicatorCode, currentCountry);
      }
      
      // 순위순으로 정렬하고 상위 maxCountries개 선택
      final rankings = List<CountryRanking>.from(oecdStats!.countryRankings!)
        ..sort((a, b) => a.rank.compareTo(b.rank));
      
      final rankingData = <Map<String, dynamic>>[];
      int addedCount = 0;
      bool currentCountryIncluded = false;
      
      // OECD 국가 정보 가져오기
      final oecdCountries = CountriesService.instance.countries;
      final countryMap = {for (var c in oecdCountries) c.code: c};
      
      // 상위 순위부터 추가
      for (final ranking in rankings) {
        if (addedCount >= maxCountries && currentCountryIncluded) break;
        
        final country = countryMap[ranking.countryCode];
        if (country != null) {
          rankingData.add({
            'rank': ranking.rank,
            'country': country.nameKo,
            'countryCode': ranking.countryCode,
            'flag': country.flagEmoji,
            'value': ranking.value,
          });
          
          if (ranking.countryCode == currentCountry.code) {
            currentCountryIncluded = true;
          }
          
          addedCount++;
        }
      }
      
      // 현재 국가가 포함되지 않았고 순위가 있다면 추가
      if (!currentCountryIncluded) {
        final currentRanking = rankings.firstWhere(
          (r) => r.countryCode == currentCountry.code,
          orElse: () => CountryRanking(
            countryCode: currentCountry.code,
            countryName: currentCountry.nameKo,
            rank: 0,
            value: 0.0,
          ),
        );
        
        if (currentRanking.rank > 0) {
          final country = countryMap[currentCountry.code];
          if (country != null) {
            // 현재 국가를 적절한 위치에 삽입
            rankingData.add({
              'rank': currentRanking.rank,
              'country': country.nameKo,
              'countryCode': currentCountry.code,
              'flag': country.flagEmoji,
              'value': currentRanking.value,
            });
          }
        }
      }
      
      // 순위순으로 최종 정렬
      rankingData.sort((a, b) => (a['rank'] as int).compareTo(b['rank'] as int));
      
      AppLogger.info('[IndicatorDetailService] Generated ${rankingData.length} real ranking entries');
      return rankingData;
      
    } catch (error) {
      AppLogger.error('[IndicatorDetailService] Error loading real ranking data: $error');
      return await _getFallbackRankingData(indicatorCode, currentCountry);
    }
  }
  
  /// Fallback 순위 데이터 생성 (실제 데이터가 없을 때)
  Future<List<Map<String, dynamic>>> _getFallbackRankingData(IndicatorCode indicatorCode, Country currentCountry) async {
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

  /// 통계 정보를 사용하여 순위 추정
  int _calculateRankFromStats(double countryValue, OECDStatistics stats, IndicatorCode indicatorCode) {
    final isHigherBetter = _isHigherBetter(indicatorCode);
    final totalCountries = stats.totalCountries;
    
    // 백분위수 기반 순위 추정
    if (isHigherBetter) {
      // 높을수록 좋은 지표
      if (countryValue >= stats.max) return 1;
      if (countryValue >= stats.q3) return (totalCountries * 0.25).round();
      if (countryValue >= stats.median) return (totalCountries * 0.5).round();
      if (countryValue >= stats.q1) return (totalCountries * 0.75).round();
      return totalCountries;
    } else {
      // 낮을수록 좋은 지표
      if (countryValue <= stats.min) return 1;
      if (countryValue <= stats.q1) return (totalCountries * 0.25).round();
      if (countryValue <= stats.median) return (totalCountries * 0.5).round();
      if (countryValue <= stats.q3) return (totalCountries * 0.75).round();
      return totalCountries;
    }
  }

  /// OECD 통계 계산 (개선된 버전)
  Future<OECDStats> _calculateOECDStats(IndicatorCode indicatorCode) async {
    try {
      final currentYear = DateTime.now().year;
      final candidateYears = [currentYear - 1, currentYear - 2, currentYear - 3];
      
      // Enhanced Repository를 사용하여 OECD 통계 가져오기
      for (final year in candidateYears) {
        try {
          final oecdStats = await _repository.getOECDStatistics(
            indicatorCode: indicatorCode,
            year: year,
          );
          
          if (oecdStats.totalCountries > 0) {
            // OECDStatistics를 OECDStats로 변환
            return OECDStats(
              median: oecdStats.median,
              mean: oecdStats.mean,
              standardDeviation: math.sqrt(((oecdStats.max - oecdStats.min) / 4)), // 근사치
              q1: oecdStats.q1,
              q3: oecdStats.q3,
              min: oecdStats.min,
              max: oecdStats.max,
              totalCountries: oecdStats.totalCountries,
              rankings: _convertToCountryRankings(oecdStats.countryRankings),
            );
          }
        } catch (e) {
          AppLogger.debug('[IndicatorDetailService] Failed to get OECD stats for year $year: $e');
          continue;
        }
      }
      
      // 모든 연도에서 데이터를 찾지 못한 경우 기본값 반환
      AppLogger.warning('[IndicatorDetailService] No OECD statistics available for any year');
      return const OECDStats(
        median: 0,
        mean: 0,
        standardDeviation: 0,
        q1: 0,
        q3: 0,
        min: 0,
        max: 0,
        totalCountries: 0,
        rankings: [],
      );
      
    } catch (error) {
      AppLogger.error('[IndicatorDetailService] Error calculating OECD stats: $error');
      return const OECDStats(
        median: 0,
        mean: 0,
        standardDeviation: 0,
        q1: 0,
        q3: 0,
        min: 0,
        max: 0,
        totalCountries: 0,
        rankings: [],
      );
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

  /// 지표별 카테고리 분류
  String _getCategoryForIndicator(IndicatorCode indicatorCode) {
    switch (indicatorCode) {
      case IndicatorCode.gdpRealGrowth:
      case IndicatorCode.gdpPppPerCapita:
      // case IndicatorCode.manufacturing:
      //   return '성장/활동';
      case IndicatorCode.unemployment:
        return '고용/노동';
      case IndicatorCode.cpiInflation:
        return '물가/통화';
      case IndicatorCode.currentAccount:
        return '대외/거시건전성';
      default:
        return '기타';
    }
  }

  /// 높을수록 좋은 지표인지 판단
  bool _isHigherBetter(IndicatorCode indicatorCode) {
    switch (indicatorCode) {
      case IndicatorCode.gdpRealGrowth:
      case IndicatorCode.gdpPppPerCapita:
      // case IndicatorCode.manufacturing:
      //   return true;
      case IndicatorCode.unemployment:
      case IndicatorCode.cpiInflation:
        return false;
      case IndicatorCode.currentAccount:
        return true;
      default:
        return true;
    }
  }

  /// 국가 이름 반환
  String _getCountryName(String countryCode) {
    const countryNames = {
      'KOR': '한국', 'USA': '미국', 'JPN': '일본', 'DEU': '독일', 'GBR': '영국',
      'FRA': '프랑스', 'ITA': '이탈리아', 'CAN': '캐나다', 'AUS': '호주', 'ESP': '스페인',
      'NLD': '네덜란드', 'BEL': '벨기에', 'CHE': '스위스', 'AUT': '오스트리아', 'SWE': '스웨덴',
      'NOR': '노르웨이', 'DNK': '덴마크', 'FIN': '핀란드', 'POL': '폴란드', 'CZE': '체코',
      'HUN': '헝가리', 'SVK': '슬로바키아', 'SVN': '슬로베니아', 'EST': '에스토니아',
      'LVA': '라트비아', 'LTU': '리투아니아', 'PRT': '포르투갈', 'GRC': '그리스',
      'TUR': '튀르키예', 'MEX': '멕시코', 'CHL': '칠레', 'COL': '콜롬비아', 'CRI': '코스타리카',
      'ISL': '아이슬란드', 'IRL': '아일랜드', 'ISR': '이스라엘', 'LUX': '룩셈부르크',
      'NZL': '뉴질랜드',
    };
    return countryNames[countryCode] ?? countryCode;
  }

  /// 캐시 새로고침
  Future<IndicatorDetail> refreshIndicatorDetail({
    required IndicatorCode indicatorCode,
    required Country country,
    int historyYears = 10,
  }) async {
    AppLogger.debug('[IndicatorDetailService] Force refreshing detail for ${indicatorCode.name}');
    return getIndicatorDetail(
      indicatorCode: indicatorCode,
      country: country,
      historyYears: historyYears,
    );
  }

  /// 리소스 정리
  void dispose() {
    _repository.dispose();
  }
}