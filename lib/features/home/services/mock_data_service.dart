import 'package:geo_economy_dashboard/features/home/models/simple_indicator_data.dart';

class MockDataService {
  // 한국의 주요 5개 지표 Mock 데이터
  static CountrySummary getKoreaSummary() {
    return CountrySummary(
      countryCode: 'KOR',
      countryName: '대한민국',
      lastUpdated: DateTime.now().subtract(const Duration(days: 7)),
      topIndicators: [
        // 1. GDP 성장률 - 중위권
        IndicatorData(
          code: 'NY.GDP.MKTP.KD.ZG',
          name: 'GDP 성장률',
          unit: '%',
          value: 3.1,
          year: 2023,
          previousValue: 2.6,
          ranking: const OECDRanking(
            rank: 15,
            totalCountries: 38,
            percentile: 60.5,
            tier: RankingTier.upper,
          ),
          trend: TrendDirection.up,
        ),
        
        // 2. 실업률 - 상위권 (낮은 실업률이 좋음)
        IndicatorData(
          code: 'SL.UEM.TOTL.ZS',
          name: '실업률',
          unit: '%',
          value: 2.9,
          year: 2023,
          previousValue: 3.1,
          ranking: const OECDRanking(
            rank: 4,
            totalCountries: 38,
            percentile: 89.5,
            tier: RankingTier.top,
          ),
          trend: TrendDirection.down, // 실업률 감소는 좋음
        ),
        
        // 3. 1인당 GDP - 중위권
        IndicatorData(
          code: 'NY.GDP.PCAP.PP.CD',
          name: '1인당 GDP (PPP)',
          unit: 'USD',
          value: 47847,
          year: 2023,
          previousValue: 46062,
          ranking: const OECDRanking(
            rank: 19,
            totalCountries: 38,
            percentile: 50.0,
            tier: RankingTier.upper,
          ),
          trend: TrendDirection.up,
        ),
        
        // 4. 출산율 - 최하위
        IndicatorData(
          code: 'SP.DYN.TFRT.IN',
          name: '출산율',
          unit: '명',
          value: 0.78,
          year: 2023,
          previousValue: 0.81,
          ranking: const OECDRanking(
            rank: 38,
            totalCountries: 38,
            percentile: 2.6,
            tier: RankingTier.bottom,
          ),
          trend: TrendDirection.down,
        ),
        
        // 5. 경상수지 - 상위권
        IndicatorData(
          code: 'BN.CAB.XOKA.GD.ZS',
          name: '경상수지 (GDP 대비)',
          unit: '%',
          value: 3.2,
          year: 2023,
          previousValue: 2.8,
          ranking: const OECDRanking(
            rank: 7,
            totalCountries: 38,
            percentile: 81.6,
            tier: RankingTier.top,
          ),
          trend: TrendDirection.up,
        ),
      ],
    );
  }

  // 지표별 OECD 평균 데이터
  static Map<String, double> getOECDAverages() {
    return {
      'NY.GDP.MKTP.KD.ZG': 2.4,    // GDP 성장률 평균
      'SL.UEM.TOTL.ZS': 5.8,       // 실업률 평균
      'NY.GDP.PCAP.PP.CD': 42500,  // 1인당 GDP 평균
      'SP.DYN.TFRT.IN': 1.58,      // 출산율 평균
      'BN.CAB.XOKA.GD.ZS': 0.4,    // 경상수지 평균
    };
  }

  // 순위별 국가 분포 (참고용)
  static Map<RankingTier, int> getRankingDistribution() {
    return {
      RankingTier.top: 9,      // 1-9위 (상위 25%)
      RankingTier.upper: 10,   // 10-19위 (상위 26-50%)
      RankingTier.lower: 10,   // 20-29위 (하위 51-75%)
      RankingTier.bottom: 9,   // 30-38위 (하위 76-100%)
    };
  }
}