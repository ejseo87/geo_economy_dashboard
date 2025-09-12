import '../models/indicator_comparison.dart';

class ComparisonService {
  // 자동 추천 비교 데이터 생성
  static RecommendedComparison generateRecommendedComparison() {
    final comparisons = [
      _generateGDPComparison(),
      _generateUnemploymentComparison(),
    ];

    return RecommendedComparison(
      comparisons: comparisons,
      selectionReason:
          '한국의 핵심 경제지표 중 OECD 내 상대적 위치가 명확하고 정책적 관심도가 높은 지표들을 선별했습니다.',
      lastUpdated: DateTime.now(),
    );
  }

  static IndicatorComparison _generateGDPComparison() {
    // 실제 환경에서는 외부 API나 데이터베이스에서 가져올 데이터
    final oecdStats = OECDStatistics(
      median: 2.4,
      q1: 1.2,
      q3: 3.8,
      min: -0.5,
      max: 7.2,
      mean: 2.6,
      totalCountries: 38,
    );

    final koreaValue = 3.1;
    final performance = oecdStats.getKoreaPerformance(koreaValue);

    return IndicatorComparison(
      indicatorCode: 'NY.GDP.MKTP.KD.ZG',
      indicatorName: 'GDP 성장률',
      unit: '%',
      year: DateTime.now().year - 1,
      selectedCountry: CountryData(
        countryCode: 'KOR',
        countryName: '대한민국',
        value: koreaValue,
        rank: 15,
        flagEmoji: '🇰🇷',
      ),
      oecdStats: oecdStats,
      similarCountries: [
        CountryData(
          countryCode: 'JPN',
          countryName: '일본',
          value: 1.9,
          rank: 22,
          flagEmoji: '🇯🇵',
        ),
        CountryData(
          countryCode: 'DEU',
          countryName: '독일',
          value: -0.3,
          rank: 32,
          flagEmoji: '🇩🇪',
        ),
        CountryData(
          countryCode: 'FRA',
          countryName: '프랑스',
          value: 0.9,
          rank: 28,
          flagEmoji: '🇫🇷',
        ),
      ],
      insight: ComparisonInsight(
        performance: performance,
        summary: '한국의 GDP 성장률은 OECD 미디안보다 높아 상위 40% 수준입니다.',
        detailedAnalysis:
            '''
한국의 ${DateTime.now().year - 1}년 GDP 성장률 3.1%는 OECD 미디안 2.4%를 0.7%p 상회하며, 
38개국 중 15위를 기록했습니다. 이는 주요 선진국 대비 양호한 성과로, 
특히 독일(-0.3%), 일본(1.9%) 등 주요 경제대국을 상회했습니다.
        '''
                .trim(),
        keyFindings: [
          'OECD 미디안 대비 +0.7%p 높은 성장률',
          '주요 선진국(독일, 일본) 대비 우수한 성과',
          '38개국 중 상위 40% 수준 유지',
        ],
        isOutlier: false,
      ),
    );
  }

  static IndicatorComparison _generateUnemploymentComparison() {
    final oecdStats = OECDStatistics(
      median: 5.8,
      q1: 3.5,
      q3: 8.2,
      min: 2.1,
      max: 12.8,
      mean: 6.1,
      totalCountries: 38,
    );

    final koreaValue = 2.9;
    final performance = _getUnemploymentPerformance(koreaValue, oecdStats);

    return IndicatorComparison(
      indicatorCode: 'SL.UEM.TOTL.ZS',
      indicatorName: '실업률',
      unit: '%',
      year: DateTime.now().year - 1,
      selectedCountry: CountryData(
        countryCode: 'KOR',
        countryName: '대한민국',
        value: koreaValue,
        rank: 4,
        flagEmoji: '🇰🇷',
      ),
      oecdStats: oecdStats,
      similarCountries: [
        CountryData(
          countryCode: 'JPN',
          countryName: '일본',
          value: 2.6,
          rank: 3,
          flagEmoji: '🇯🇵',
        ),
        CountryData(
          countryCode: 'DEU',
          countryName: '독일',
          value: 3.0,
          rank: 5,
          flagEmoji: '🇩🇪',
        ),
        CountryData(
          countryCode: 'USA',
          countryName: '미국',
          value: 3.7,
          rank: 8,
          flagEmoji: '🇺🇸',
        ),
      ],
      insight: ComparisonInsight(
        performance: performance,
        summary: '한국의 실업률은 OECD 최상위 수준으로 매우 우수합니다.',
        detailedAnalysis:
            '''
한국의 ${DateTime.now().year - 1}년 실업률 2.9%는 OECD 미디안 5.8%를 크게 하회하며, 
38개국 중 4위의 우수한 성과를 기록했습니다. 이는 일본(2.6%), 
독일(3.0%)과 함께 OECD 최상위 그룹에 속하는 수준입니다.
        '''
                .trim(),
        keyFindings: [
          'OECD 미디안 대비 -2.9%p 낮은 실업률',
          '38개국 중 4위의 최상위 수준',
          '주요 선진국과 함께 우수 그룹 형성',
        ],
        isOutlier: false,
      ),
    );
  }

  // 실업률은 낮을수록 좋으므로 별도 계산
  static PerformanceLevel _getUnemploymentPerformance(
    double value,
    OECDStatistics stats,
  ) {
    if (value <= stats.q1) return PerformanceLevel.excellent;
    if (value <= stats.median) return PerformanceLevel.good;
    if (value <= stats.q3) return PerformanceLevel.average;
    return PerformanceLevel.poor;
  }
}
