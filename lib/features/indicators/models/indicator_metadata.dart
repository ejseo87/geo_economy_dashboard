/// 지표 상세 메타데이터
class IndicatorDetailMetadata {
  final String code;
  final String name;
  final String nameEn;
  final String description;
  final String unit;
  final String category;
  final DataSource source;
  final UpdateFrequency updateFrequency;
  final String methodology;
  final String limitations;
  final List<String> relatedIndicators;
  final bool isHigherBetter;
  final String? emoji;
  final DateTime? lastUpdated;
  final DateTime? nextUpdate;

  const IndicatorDetailMetadata({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.unit,
    required this.category,
    required this.source,
    required this.updateFrequency,
    required this.methodology,
    required this.limitations,
    required this.relatedIndicators,
    required this.isHigherBetter,
    this.emoji,
    this.lastUpdated,
    this.nextUpdate,
  });
}

/// 데이터 출처 정보
class DataSource {
  final String name;
  final String nameEn;
  final String url;
  final String description;
  final String license;
  final String contact;
  final DateTime? lastAccessed;

  const DataSource({
    required this.name,
    required this.nameEn,
    required this.url,
    required this.description,
    required this.license,
    required this.contact,
    this.lastAccessed,
  });
}

/// 업데이트 주기
enum UpdateFrequency {
  monthly('월간', 'Monthly', 30),
  quarterly('분기', 'Quarterly', 90),
  yearly('연간', 'Yearly', 365),
  irregular('불규칙', 'Irregular', -1);

  const UpdateFrequency(this.labelKr, this.labelEn, this.daysBetween);
  
  final String labelKr;
  final String labelEn;
  final int daysBetween;

  String get description {
    switch (this) {
      case UpdateFrequency.monthly:
        return '매월 말일 기준으로 갱신됩니다';
      case UpdateFrequency.quarterly:
        return '분기말 (3, 6, 9, 12월) 기준으로 갱신됩니다';
      case UpdateFrequency.yearly:
        return '연말 기준으로 갱신됩니다';
      case UpdateFrequency.irregular:
        return '불규칙적으로 갱신됩니다';
    }
  }
}

/// 지표 상세 데이터 (히스토리컬 데이터 포함)
class IndicatorDetail {
  final IndicatorDetailMetadata metadata;
  final String countryCode;
  final String countryName;
  final List<IndicatorDataPoint> historicalData;
  final double? currentValue;
  final int? currentRank;
  final int totalCountries;
  final OECDStats oecdStats;
  final TrendAnalysis trendAnalysis;
  final DateTime? lastCalculated;

  const IndicatorDetail({
    required this.metadata,
    required this.countryCode,
    required this.countryName,
    required this.historicalData,
    required this.currentValue,
    required this.currentRank,
    required this.totalCountries,
    required this.oecdStats,
    required this.trendAnalysis,
    this.lastCalculated,
  });
}

/// 히스토리컬 데이터 포인트
class IndicatorDataPoint {
  final int year;
  final double value;
  final bool isEstimated;
  final bool isProjected;
  final String? note;

  const IndicatorDataPoint({
    required this.year,
    required this.value,
    required this.isEstimated,
    required this.isProjected,
    this.note,
  });
}

/// OECD 통계 정보
class OECDStats {
  final double median;
  final double mean;
  final double standardDeviation;
  final double q1;
  final double q3;
  final double min;
  final double max;
  final int totalCountries;
  final List<CountryRanking> rankings;

  const OECDStats({
    required this.median,
    required this.mean,
    required this.standardDeviation,
    required this.q1,
    required this.q3,
    required this.min,
    required this.max,
    required this.totalCountries,
    required this.rankings,
  });
}

/// 국가별 순위 정보
class CountryRanking {
  final String countryCode;
  final String countryName;
  final double value;
  final int rank;

  const CountryRanking({
    required this.countryCode,
    required this.countryName,
    required this.value,
    required this.rank,
  });

  CountryRanking copyWith({
    String? countryCode,
    String? countryName,
    double? value,
    int? rank,
  }) {
    return CountryRanking(
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      value: value ?? this.value,
      rank: rank ?? this.rank,
    );
  }
}

/// 트렌드 분석 정보
class TrendAnalysis {
  final TrendDirection shortTerm; // 1년
  final TrendDirection mediumTerm; // 3년
  final TrendDirection longTerm; // 5년
  final double volatility;
  final double correlation;
  final List<String> insights;
  final String summary;

  const TrendAnalysis({
    required this.shortTerm,
    required this.mediumTerm,
    required this.longTerm,
    required this.volatility,
    required this.correlation,
    required this.insights,
    required this.summary,
  });
}

/// 트렌드 방향
enum TrendDirection {
  up('상승', '↗️'),
  down('하락', '↘️'),
  stable('안정', '→'),
  volatile('변동', '↕️');

  const TrendDirection(this.label, this.emoji);
  
  final String label;
  final String emoji;
}

/// 지표 카테고리별 메타데이터 팩토리
class IndicatorDetailMetadataFactory {
  static IndicatorDetailMetadata createGDPRealGrowth() {
    return IndicatorDetailMetadata(
      code: 'NY.GDP.MKTP.KD.ZG',
      name: 'GDP 실질성장률',
      nameEn: 'GDP Real Growth Rate',
      description: '전년 대비 실질 국내총생산(GDP) 증가율로, 물가 상승 효과를 제거한 실제 경제성장 정도를 나타냅니다. 경제의 건전성과 성장 동력을 판단하는 핵심 지표입니다.',
      unit: '%',
      category: '성장/활동',
      source: DataSourceFactory.worldBank(),
      updateFrequency: UpdateFrequency.yearly,
      methodology: '전년 대비 불변가격 GDP 증가율을 계산합니다. GDP는 한 나라에서 일정 기간 생산된 모든 재화와 서비스의 시장가치 총합입니다.',
      limitations: '분기별 데이터의 계절성 조정이 필요하며, 비공식 경제 활동은 포함되지 않습니다. 또한 소득분배나 환경비용은 반영되지 않습니다.',
      relatedIndicators: ['NY.GDP.PCAP.PP.KD', 'NE.GDI.TOTL.ZS', 'NV.AGR.TOTL.ZS'],
      isHigherBetter: true,
      emoji: '📈',
    );
  }

  static IndicatorDetailMetadata createUnemploymentRate() {
    return IndicatorDetailMetadata(
      code: 'SL.UEM.TOTL.ZS',
      name: '실업률',
      nameEn: 'Unemployment Rate',
      description: '경제활동인구(15세 이상) 중 실업자가 차지하는 비율입니다. 노동시장의 건전성과 경제정책의 효과성을 평가하는 중요한 지표입니다.',
      unit: '%',
      category: '고용/노동',
      source: DataSourceFactory.worldBank(),
      updateFrequency: UpdateFrequency.monthly,
      methodology: 'ILO 기준에 따라 지난 4주간 구직활동을 한 사람 중 일자리가 없는 사람의 비율을 계산합니다.',
      limitations: '구직포기자나 불완전취업자는 포함되지 않으며, 국가별 조사 방법론의 차이가 있을 수 있습니다.',
      relatedIndicators: ['SL.EMP.TOTL.SP.ZS', 'SL.TLF.CACT.ZS'],
      isHigherBetter: false,
      emoji: '👥',
    );
  }

  static IndicatorDetailMetadata createInflationCPI() {
    return IndicatorDetailMetadata(
      code: 'FP.CPI.TOTL.ZG',
      name: '소비자물가상승률',
      nameEn: 'CPI Inflation Rate',
      description: '소비자가 구매하는 상품과 서비스의 가격 변화율입니다. 통화정책의 목표 설정과 실질구매력 평가에 핵심적인 지표입니다.',
      unit: '%',
      category: '물가/통화',
      source: DataSourceFactory.worldBank(),
      updateFrequency: UpdateFrequency.monthly,
      methodology: '대표 상품바구니 가격의 전년 동월 대비 변화율을 계산합니다. 가중평균을 적용하여 소비패턴을 반영합니다.',
      limitations: '상품 구성의 정기적 개편이 필요하며, 품질 개선 효과나 지역별 가격차이 반영에 한계가 있습니다.',
      relatedIndicators: ['NY.GDP.DEFL.ZG', 'FR.INR.RINR'],
      isHigherBetter: false,
      emoji: '🛒',
    );
  }
}

class DataSourceFactory {
  static DataSource worldBank() {
    return const DataSource(
      name: 'World Bank',
      nameEn: 'World Bank Group',
      url: 'https://data.worldbank.org',
      description: '세계은행이 제공하는 국제개발 및 경제 통계 데이터베이스',
      license: 'CC BY 4.0',
      contact: 'data@worldbank.org',
    );
  }

  static DataSource oecd() {
    return const DataSource(
      name: 'OECD',
      nameEn: 'Organisation for Economic Co-operation and Development',
      url: 'https://data.oecd.org',
      description: '경제협력개발기구가 제공하는 회원국 경제사회 통계',
      license: 'CC BY-NC 4.0',
      contact: 'stats.contact@oecd.org',
    );
  }

  static DataSource imf() {
    return const DataSource(
      name: 'IMF',
      nameEn: 'International Monetary Fund',
      url: 'https://data.imf.org',
      description: '국제통화기금이 제공하는 국제금융 및 거시경제 통계',
      license: 'Custom License',
      contact: 'statistics@imf.org',
    );
  }
}