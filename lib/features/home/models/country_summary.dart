import '../models/indicator_comparison.dart'; // PerformanceLevel import

/// 국가 요약 정보를 담는 모델
class CountrySummary {
  final String countryCode;
  final String countryName;
  final String flagEmoji;
  final List<KeyIndicator> topIndicators;
  final String overallRanking; // '상위권', '중위권', '하위권'
  final DateTime lastUpdated;

  const CountrySummary({
    required this.countryCode,
    required this.countryName,
    required this.flagEmoji,
    required this.topIndicators,
    required this.overallRanking,
    required this.lastUpdated,
  });
}

/// 핵심 지표 정보
class KeyIndicator {
  final String code;
  final String name;
  final String unit;
  final double value;
  final int rank;
  final int totalCountries;
  final double percentile;
  final PerformanceLevel performance; // indicator_comparison.dart에서 import
  final String direction; // 'higher', 'lower', 'neutral'
  final String? sparklineEmoji; // 트렌드를 나타내는 이모지

  const KeyIndicator({
    required this.code,
    required this.name,
    required this.unit,
    required this.value,
    required this.rank,
    required this.totalCountries,
    required this.percentile,
    required this.performance,
    required this.direction,
    this.sparklineEmoji,
  });

  /// 순위 기반 배지 텍스트
  String get rankBadge {
    if (percentile >= 90) return 'TOP 10%';
    if (percentile >= 75) return 'Q1';
    if (percentile >= 50) return 'Q2';
    if (percentile >= 25) return 'Q3';
    return 'Q4';
  }

  /// 성과 레벨 이모지
  String get performanceEmoji {
    return performance.emoji;
  }
}