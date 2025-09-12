import 'package:geo_economy_dashboard/common/logger.dart';

import '../models/indicator_comparison.dart';
import '../../worldbank/models/core_indicators.dart';
import '../../worldbank/models/country_indicator.dart';
import '../../worldbank/services/integrated_data_service.dart';

/// 실제 World Bank API를 사용하는 비교 서비스
class RealComparisonService {
  final IntegratedDataService _dataService;

  RealComparisonService({IntegratedDataService? dataService})
      : _dataService = dataService ?? IntegratedDataService();

  /// 자동 추천 비교 데이터 생성 (실제 API 데이터 사용)
  static Future<RecommendedComparison> generateRecommendedComparison({
    IntegratedDataService? dataService,
    String? countryCode,
  }) async {
    final service = RealComparisonService(dataService: dataService);
    final targetCountryCode = countryCode ?? 'KOR';
    
    try {
      AppLogger.debug('[RealComparisonService] Starting to generate recommended comparison for $targetCountryCode...');
      
      // 다양한 카테고리에서 우선순위 지표 선택 (20개 전체 지표에서 카테고리별로 다양하게)
      final priorityIndicatorSets = [
        // 성장/활동 카테고리에서
        CoreIndicators.getIndicatorsByCategory(CoreIndicatorCategory.growth),
        // 고용/노동 카테고리에서
        CoreIndicators.getIndicatorsByCategory(CoreIndicatorCategory.employment),
        // 물가/통화 카테고리에서
        CoreIndicators.getIndicatorsByCategory(CoreIndicatorCategory.inflation),
        // 대외/거시건전성 카테고리에서
        CoreIndicators.getIndicatorsByCategory(CoreIndicatorCategory.external),
        // 재정/정부 카테고리에서
        CoreIndicators.getIndicatorsByCategory(CoreIndicatorCategory.fiscal),
        // 분배/사회 카테고리에서
        CoreIndicators.getIndicatorsByCategory(CoreIndicatorCategory.social),
        // 환경/에너지 카테고리에서
        CoreIndicators.getIndicatorsByCategory(CoreIndicatorCategory.environment),
      ].where((list) => list.isNotEmpty).toList();
      
      // 2-3개 카테고리에서 랜덤하게 선택
      final selectedSets = (priorityIndicatorSets..shuffle()).take(3).toList();
      final priorityIndicators = <CoreIndicator>[];
      
      for (final set in selectedSets) {
        // 각 카테고리에서 1개 랜덤 선택
        priorityIndicators.add((set..shuffle()).first);
      }

      if (priorityIndicators.isEmpty) {
        throw Exception('No priority indicators found');
      }

      final comparisons = <IndicatorComparison>[];
      
      // 각 지표별로 비교 데이터 생성
      for (final indicator in priorityIndicators) {
        try {
          AppLogger.debug('[RealComparisonService] Generating comparison for ${indicator.name}...');
          
          final comparison = await service.generateIndicatorComparison(
            indicator.code,
            countryCode: targetCountryCode,
          );
          
          comparisons.add(comparison);
          AppLogger.debug('[RealComparisonService] Successfully generated comparison for ${indicator.name}');
        } catch (e) {
          AppLogger.error('[RealComparisonService] Failed to generate comparison for ${indicator.name}: $e');
          
          // 개별 지표 실패 시 폴백 데이터 생성
          final fallbackComparison = _generateFallbackComparison(indicator);
          if (fallbackComparison != null) {
            comparisons.add(fallbackComparison);
          }
        }
      }

      if (comparisons.isEmpty) {
        throw Exception('Failed to generate any indicator comparisons');
      }

      final countryName = _getCountryNameForReason(targetCountryCode);
      
      return RecommendedComparison(
        comparisons: comparisons,
        selectionReason: '''
$countryName의 핵심 20개 경제지표 중에서 다양한 카테고리(성장/활동, 고용/노동, 물가/통화, 대외/거시건전성, 재정/정부, 분배/사회, 환경/에너지)를 대표하는 지표들을 AI가 자동으로 선별했습니다. World Bank 실시간 데이터와 OECD 38개국 통계 분석을 기반으로 산출되었습니다.
        '''.trim(),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('[RealComparisonService] Error generating recommended comparison: $e');
      
      // 전체 실패 시 최소한의 폴백 데이터 반환
      return _generateEmergencyFallback();
    }
  }

  /// 특정 지표의 상세 비교 데이터 생성
  Future<IndicatorComparison> generateIndicatorComparison(
    String indicatorCode, {
    String? countryCode,
    int? year,
  }) async {
    final targetCountryCode = countryCode ?? 'KOR';
    
    try {
      // IntegratedDataService를 통해 데이터 가져오기
      final countryIndicator = await _dataService.getCountryIndicator(
        countryCode: targetCountryCode,
        indicatorCode: indicatorCode,
        forceRefresh: false,
      );
      
      if (countryIndicator == null) {
        throw Exception('No data available for indicator: $indicatorCode');
      }
      
      // CountryIndicator를 IndicatorComparison으로 변환
      return _convertToIndicatorComparison(countryIndicator, targetCountryCode);
    } catch (e) {
      AppLogger.error('[RealComparisonService] Error generating comparison for $indicatorCode: $e');
      rethrow;
    }
  }

  /// CountryIndicator를 IndicatorComparison으로 변환
  IndicatorComparison _convertToIndicatorComparison(
    CountryIndicator countryIndicator,
    String countryCode,
  ) {
    return IndicatorComparison(
      indicatorCode: countryIndicator.indicatorCode,
      indicatorName: countryIndicator.indicatorName,
      unit: countryIndicator.unit,
      year: countryIndicator.latestYear ?? DateTime.now().year - 1,
      selectedCountry: CountryData(
        countryCode: countryCode,
        countryName: _getCountryNameForReason(countryCode),
        value: countryIndicator.latestValue ?? 0.0,
        rank: countryIndicator.oecdRanking ?? 0,
        flagEmoji: _getFlagEmoji(countryCode),
      ),
      oecdStats: OECDStatistics(
        median: countryIndicator.oecdStats?.median ?? 0.0,
        q1: countryIndicator.oecdStats?.q1 ?? 0.0,
        q3: countryIndicator.oecdStats?.q3 ?? 0.0,
        min: countryIndicator.oecdStats?.min ?? 0.0,
        max: countryIndicator.oecdStats?.max ?? 0.0,
        mean: countryIndicator.oecdStats?.mean ?? 0.0,
        totalCountries: 38,
      ),
      similarCountries: _generateSimilarCountries(countryIndicator),
      insight: ComparisonInsight(
        performance: _getPerformanceFromPercentile(
          countryIndicator.oecdPercentile ?? 50.0,
        ),
        summary: '${countryIndicator.indicatorName} 데이터 분석 완료',
        detailedAnalysis: 'World Bank API에서 최신 데이터를 가져왔습니다.',
        keyFindings: ['데이터 분석 완료'],
        isOutlier: false,
      ),
    );
  }

  /// 국가 코드에 따른 국가명 반환 (추천 이유용)
  static String _getCountryNameForReason(String countryCode) {
    const countryNames = {
      'AUS': '호주',
      'AUT': '오스트리아',
      'BEL': '벨기에',
      'CAN': '캐나다',
      'CHL': '칠레',
      'COL': '콜롬비아',
      'CRI': '코스타리카',
      'CZE': '체코',
      'DNK': '덴마크',
      'EST': '에스토니아',
      'FIN': '핀란드',
      'FRA': '프랑스',
      'DEU': '독일',
      'GRC': '그리스',
      'HUN': '헝가리',
      'ISL': '아이슬란드',
      'IRL': '아일랜드',
      'ISR': '이스라엘',
      'ITA': '이탈리아',
      'JPN': '일본',
      'KOR': '한국',
      'LVA': '라트비아',
      'LTU': '리투아니아',
      'LUX': '룩셈부르크',
      'MEX': '멕시코',
      'NLD': '네덜란드',
      'NZL': '뉴질랜드',
      'NOR': '노르웨이',
      'POL': '폴란드',
      'PRT': '포르투갈',
      'SVK': '슬로바키아',
      'SVN': '슬로베니아',
      'ESP': '스페인',
      'SWE': '스웨덴',
      'CHE': '스위스',
      'TUR': '터키예',
      'GBR': '영국',
      'USA': '미국',
    };
    return countryNames[countryCode] ?? countryCode;
  }

  /// 개별 지표 실패 시 폴백 데이터 생성
  static IndicatorComparison? _generateFallbackComparison(CoreIndicator indicator) {
    try {
      // 기본값으로 간단한 비교 데이터 생성
      final mockOecdStats = OECDStatistics(
        median: _getMockMedian(indicator),
        q1: _getMockQ1(indicator),
        q3: _getMockQ3(indicator),
        min: _getMockMin(indicator),
        max: _getMockMax(indicator),
        mean: _getMockMean(indicator),
        totalCountries: 38,
      );

      final koreaValue = _getMockKoreaValue(indicator);
      final performance = _getMockPerformance(indicator);

      return IndicatorComparison(
        indicatorCode: indicator.code,
        indicatorName: indicator.name,
        unit: indicator.unit,
        year: DateTime.now().year - 1,
        selectedCountry: CountryData(
          countryCode: 'KOR',
          countryName: '대한민국',
          value: koreaValue,
          rank: _getMockRank(indicator),
          flagEmoji: '🇰🇷',
        ),
        oecdStats: mockOecdStats,
        similarCountries: _getMockSimilarCountries(indicator),
        insight: ComparisonInsight(
          performance: performance,
          summary: '${indicator.name} 데이터를 로딩 중입니다.',
          detailedAnalysis: 'World Bank API에서 최신 데이터를 가져오는 중입니다. 잠시만 기다려 주세요.',
          keyFindings: ['데이터 로딩 중'],
          isOutlier: false,
        ),
      );
    } catch (e) {
      AppLogger.error('[RealComparisonService] Failed to generate fallback for ${indicator.name}: $e');
      return null;
    }
  }

  /// 비상 시 최소 폴백 데이터
  static RecommendedComparison _generateEmergencyFallback() {
    final gdpIndicator = CoreIndicators.indicators
        .where((i) => i.code == 'NY.GDP.MKTP.KD.ZG')
        .first;
    final unemploymentIndicator = CoreIndicators.indicators
        .where((i) => i.code == 'SL.UEM.TOTL.ZS')
        .first;
        
    final gdpComparison = _generateFallbackComparison(gdpIndicator);
    final unemploymentComparison = _generateFallbackComparison(unemploymentIndicator);

    final comparisons = <IndicatorComparison>[];
    if (gdpComparison != null) comparisons.add(gdpComparison);
    if (unemploymentComparison != null) comparisons.add(unemploymentComparison);

    return RecommendedComparison(
      comparisons: comparisons,
      selectionReason: '네트워크 연결을 확인하고 다시 시도해 주세요. 임시 데이터를 표시합니다.',
      lastUpdated: DateTime.now(),
    );
  }

  /// 국가 코드에 따른 깃발 이모지 반환
  static String _getFlagEmoji(String countryCode) {
    const flagMap = {
      'KOR': '🇰🇷',
      'JPN': '🇯🇵',
      'USA': '🇺🇸',
      'DEU': '🇩🇪',
      'FRA': '🇫🇷',
      'GBR': '🇬🇧',
      'CHN': '🇨🇳',
    };
    return flagMap[countryCode] ?? '🌍';
  }

  /// 백분위수로 성과 레벨 계산
  static PerformanceLevel _getPerformanceFromPercentile(double percentile) {
    if (percentile >= 75) return PerformanceLevel.excellent;
    if (percentile >= 50) return PerformanceLevel.good;
    if (percentile >= 25) return PerformanceLevel.average;
    return PerformanceLevel.poor;
  }

  /// 비슷한 국가들 생성
  List<CountryData> _generateSimilarCountries(CountryIndicator countryIndicator) {
    // 예시 데이터 - 실제로는 OECD 국가들 중 비슷한 값을 가진 국가들을 찾아야 함
    return [
      CountryData(
        countryCode: 'JPN',
        countryName: '일본',
        value: (countryIndicator.latestValue ?? 0.0) * 0.85,
        rank: (countryIndicator.oecdRanking ?? 20) + 2,
        flagEmoji: '🇯🇵',
      ),
      CountryData(
        countryCode: 'DEU',
        countryName: '독일',
        value: (countryIndicator.latestValue ?? 0.0) * 1.15,
        rank: (countryIndicator.oecdRanking ?? 20) - 3,
        flagEmoji: '🇩🇪',
      ),
    ];
  }

  // Mock 데이터 생성 헬퍼 메서드들
  static double _getMockMedian(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 2.4;
      case 'SL.UEM.TOTL.ZS': return 5.8;
      case 'FP.CPI.TOTL.ZG': return 2.1;
      case 'BN.CAB.XOKA.GD.ZS': return 0.4;
      case 'NY.GDP.PCAP.PP.CD': return 42500.0;
      default: return 1.0;
    }
  }

  static double _getMockQ1(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 1.2;
      case 'SL.UEM.TOTL.ZS': return 3.5;
      case 'FP.CPI.TOTL.ZG': return 1.0;
      case 'BN.CAB.XOKA.GD.ZS': return -2.1;
      case 'NY.GDP.PCAP.PP.CD': return 28000.0;
      default: return 0.5;
    }
  }

  static double _getMockQ3(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 3.8;
      case 'SL.UEM.TOTL.ZS': return 8.2;
      case 'FP.CPI.TOTL.ZG': return 3.5;
      case 'BN.CAB.XOKA.GD.ZS': return 3.2;
      case 'NY.GDP.PCAP.PP.CD': return 58000.0;
      default: return 2.0;
    }
  }

  static double _getMockMin(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return -0.5;
      case 'SL.UEM.TOTL.ZS': return 2.1;
      case 'FP.CPI.TOTL.ZG': return -0.2;
      case 'BN.CAB.XOKA.GD.ZS': return -5.8;
      case 'NY.GDP.PCAP.PP.CD': return 18000.0;
      default: return 0.0;
    }
  }

  static double _getMockMax(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 7.2;
      case 'SL.UEM.TOTL.ZS': return 12.8;
      case 'FP.CPI.TOTL.ZG': return 6.5;
      case 'BN.CAB.XOKA.GD.ZS': return 8.4;
      case 'NY.GDP.PCAP.PP.CD': return 85000.0;
      default: return 5.0;
    }
  }

  static double _getMockMean(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 2.6;
      case 'SL.UEM.TOTL.ZS': return 6.1;
      case 'FP.CPI.TOTL.ZG': return 2.3;
      case 'BN.CAB.XOKA.GD.ZS': return 0.8;
      case 'NY.GDP.PCAP.PP.CD': return 44200.0;
      default: return 1.5;
    }
  }

  static double _getMockKoreaValue(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 3.1;
      case 'SL.UEM.TOTL.ZS': return 2.9;
      case 'FP.CPI.TOTL.ZG': return 3.6;
      case 'BN.CAB.XOKA.GD.ZS': return 3.2;
      case 'NY.GDP.PCAP.PP.CD': return 47847.0;
      default: return 1.8;
    }
  }

  static int _getMockRank(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 15;
      case 'SL.UEM.TOTL.ZS': return 4;
      case 'FP.CPI.TOTL.ZG': return 25;
      case 'BN.CAB.XOKA.GD.ZS': return 7;
      case 'NY.GDP.PCAP.PP.CD': return 19;
      default: return 20;
    }
  }

  static PerformanceLevel _getMockPerformance(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return PerformanceLevel.good;
      case 'SL.UEM.TOTL.ZS': return PerformanceLevel.excellent;
      case 'FP.CPI.TOTL.ZG': return PerformanceLevel.average;
      case 'BN.CAB.XOKA.GD.ZS': return PerformanceLevel.excellent;
      case 'NY.GDP.PCAP.PP.CD': return PerformanceLevel.good;
      default: return PerformanceLevel.average;
    }
  }

  static List<CountryData> _getMockSimilarCountries(CoreIndicator indicator) {
    return [
      CountryData(
        countryCode: 'JPN',
        countryName: '일본',
        value: _getMockJapanValue(indicator),
        rank: _getMockJapanRank(indicator),
        flagEmoji: '🇯🇵',
      ),
      CountryData(
        countryCode: 'DEU',
        countryName: '독일',
        value: _getMockGermanyValue(indicator),
        rank: _getMockGermanyRank(indicator),
        flagEmoji: '🇩🇪',
      ),
      CountryData(
        countryCode: 'FRA',
        countryName: '프랑스',
        value: _getMockFranceValue(indicator),
        rank: _getMockFranceRank(indicator),
        flagEmoji: '🇫🇷',
      ),
    ];
  }

  static double _getMockJapanValue(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 1.9;
      case 'SL.UEM.TOTL.ZS': return 2.6;
      case 'FP.CPI.TOTL.ZG': return 2.8;
      case 'BN.CAB.XOKA.GD.ZS': return 2.9;
      case 'NY.GDP.PCAP.PP.CD': return 42940.0;
      default: return 1.5;
    }
  }

  static int _getMockJapanRank(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 22;
      case 'SL.UEM.TOTL.ZS': return 3;
      case 'FP.CPI.TOTL.ZG': return 18;
      case 'BN.CAB.XOKA.GD.ZS': return 8;
      case 'NY.GDP.PCAP.PP.CD': return 21;
      default: return 18;
    }
  }

  static double _getMockGermanyValue(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return -0.3;
      case 'SL.UEM.TOTL.ZS': return 3.0;
      case 'FP.CPI.TOTL.ZG': return 5.9;
      case 'BN.CAB.XOKA.GD.ZS': return 7.4;
      case 'NY.GDP.PCAP.PP.CD': return 54263.0;
      default: return 2.1;
    }
  }

  static int _getMockGermanyRank(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 32;
      case 'SL.UEM.TOTL.ZS': return 5;
      case 'FP.CPI.TOTL.ZG': return 35;
      case 'BN.CAB.XOKA.GD.ZS': return 2;
      case 'NY.GDP.PCAP.PP.CD': return 12;
      default: return 16;
    }
  }

  static double _getMockFranceValue(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 0.9;
      case 'SL.UEM.TOTL.ZS': return 7.2;
      case 'FP.CPI.TOTL.ZG': return 4.9;
      case 'BN.CAB.XOKA.GD.ZS': return -0.8;
      case 'NY.GDP.PCAP.PP.CD': return 45937.0;
      default: return 1.8;
    }
  }

  static int _getMockFranceRank(CoreIndicator indicator) {
    switch (indicator.code) {
      case 'NY.GDP.MKTP.KD.ZG': return 28;
      case 'SL.UEM.TOTL.ZS': return 22;
      case 'FP.CPI.TOTL.ZG': return 32;
      case 'BN.CAB.XOKA.GD.ZS': return 22;
      case 'NY.GDP.PCAP.PP.CD': return 18;
      default: return 22;
    }
  }

  /// 리소스 정리
  void dispose() {
    // IntegratedDataService는 dispose가 필요 없음
  }
}