import 'dart:math' as math;
import 'package:geo_economy_dashboard/common/logger.dart';
import '../models/indicator_metadata.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../worldbank/repositories/indicator_repository.dart';
import '../../countries/models/country.dart';

/// 지표 상세 정보 서비스
class IndicatorDetailService {
  final IndicatorRepository _repository;

  IndicatorDetailService({IndicatorRepository? repository})
      : _repository = repository ?? IndicatorRepository();

  /// 지표 상세 정보 생성
  Future<IndicatorDetail> getIndicatorDetail({
    required IndicatorCode indicatorCode,
    required Country country,
    int historyYears = 10,
  }) async {
    try {
      AppLogger.debug('[IndicatorDetailService] Loading detail for ${indicatorCode.name} in ${country.nameKo}');

      // 메타데이터 생성
      final metadata = _getIndicatorMetadata(indicatorCode);

      // 히스토리컬 데이터 수집
      final historicalData = await _getHistoricalData(indicatorCode, country.code, historyYears);

      // 현재값과 순위 계산
      final currentValue = historicalData.isNotEmpty ? historicalData.last.value : null;
      final (currentRank, totalCountries) = await _getCurrentRanking(indicatorCode, country.code);

      // OECD 통계 계산
      final oecdStats = await _calculateOECDStats(indicatorCode);

      // 트렌드 분석
      final trendAnalysis = _analyzeTrends(historicalData, metadata.isHigherBetter);

      final detail = IndicatorDetail(
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

      AppLogger.info('[IndicatorDetailService] Generated detail with ${historicalData.length} data points');
      return detail;

    } catch (error) {
      AppLogger.error('[IndicatorDetailService] Error generating detail: $error');
      rethrow;
    }
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

  /// 현재 순위 계산
  Future<(int?, int)> _getCurrentRanking(IndicatorCode indicatorCode, String countryCode) async {
    try {
      // OECD 38개국 데이터 수집
      const oecdCountries = [
        'AUS', 'AUT', 'BEL', 'CAN', 'CHL', 'COL', 'CRI', 'CZE', 'DNK', 'EST',
        'FIN', 'FRA', 'DEU', 'GRC', 'HUN', 'ISL', 'IRL', 'ISR', 'ITA', 'JPN',
        'KOR', 'LVA', 'LTU', 'LUX', 'MEX', 'NLD', 'NZL', 'NOR', 'POL', 'PRT',
        'SVK', 'SVN', 'ESP', 'SWE', 'CHE', 'TUR', 'GBR', 'USA'
      ];

      final countryValues = <String, double>{};
      
      for (final country in oecdCountries) {
        final indicatorData = await _repository.getIndicatorData(
          countryCode: country,
          indicatorCode: indicatorCode,
        );
        
        if (indicatorData != null) {
          final currentYear = DateTime.now().year;
          for (int year = currentYear; year >= currentYear - 3; year--) {
            final value = indicatorData.getValueForYear(year);
            if (value != null && value.isFinite) {
              countryValues[country] = value;
              break;
            }
          }
        }
      }

      if (countryValues.isEmpty) return (null, 0);

      // 순위 계산 (높을수록 좋은 지표인지에 따라 정렬)
      final isHigherBetter = _isHigherBetter(indicatorCode);
      final sortedEntries = countryValues.entries.toList()
        ..sort((a, b) => isHigherBetter 
            ? b.value.compareTo(a.value)
            : a.value.compareTo(b.value));

      // 해당 국가 순위 찾기
      int? rank;
      for (int i = 0; i < sortedEntries.length; i++) {
        if (sortedEntries[i].key == countryCode) {
          rank = i + 1;
          break;
        }
      }

      return (rank, sortedEntries.length);
      
    } catch (error) {
      AppLogger.error('[IndicatorDetailService] Error calculating ranking: $error');
      return (null, 0);
    }
  }

  /// OECD 통계 계산
  Future<OECDStats> _calculateOECDStats(IndicatorCode indicatorCode) async {
    const oecdCountries = [
      'AUS', 'AUT', 'BEL', 'CAN', 'CHL', 'COL', 'CRI', 'CZE', 'DNK', 'EST',
      'FIN', 'FRA', 'DEU', 'GRC', 'HUN', 'ISL', 'IRL', 'ISR', 'ITA', 'JPN',
      'KOR', 'LVA', 'LTU', 'LUX', 'MEX', 'NLD', 'NZL', 'NOR', 'POL', 'PRT',
      'SVK', 'SVN', 'ESP', 'SWE', 'CHE', 'TUR', 'GBR', 'USA'
    ];

    final rankings = <CountryRanking>[];
    
    for (final countryCode in oecdCountries) {
      final indicatorData = await _repository.getIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCode,
      );
      
      if (indicatorData != null) {
        final currentYear = DateTime.now().year;
        for (int year = currentYear; year >= currentYear - 3; year--) {
          final value = indicatorData.getValueForYear(year);
          if (value != null && value.isFinite) {
            rankings.add(CountryRanking(
              countryCode: countryCode,
              countryName: _getCountryName(countryCode),
              value: value,
              rank: 0, // 나중에 계산
            ));
            break;
          }
        }
      }
    }

    if (rankings.isEmpty) {
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

    // 값 기준으로 정렬 및 순위 할당
    final isHigherBetter = _isHigherBetter(indicatorCode);
    rankings.sort((a, b) => isHigherBetter 
        ? b.value.compareTo(a.value)
        : a.value.compareTo(b.value));
    
    for (int i = 0; i < rankings.length; i++) {
      rankings[i] = rankings[i].copyWith(rank: i + 1);
    }

    // 통계 계산
    final values = rankings.map((r) => r.value).toList()..sort();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final standardDeviation = math.sqrt(variance);
    
    final median = values.length % 2 == 0
        ? (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2
        : values[values.length ~/ 2];
    
    final q1Index = (values.length * 0.25).floor();
    final q3Index = (values.length * 0.75).floor();
    
    return OECDStats(
      median: median,
      mean: mean,
      standardDeviation: standardDeviation,
      q1: values[q1Index],
      q3: values[q3Index],
      min: values.first,
      max: values.last,
      totalCountries: values.length,
      rankings: rankings,
    );
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

  /// 리소스 정리
  void dispose() {
    _repository.dispose();
  }
}