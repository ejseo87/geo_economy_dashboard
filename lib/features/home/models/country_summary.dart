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

  /// JSON으로 직렬화
  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'flagEmoji': flagEmoji,
      'topIndicators': topIndicators
          .map((indicator) => indicator.toJson())
          .toList(),
      'overallRanking': overallRanking,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// JSON에서 역직렬화
  factory CountrySummary.fromJson(Map<String, dynamic> json) {
    return CountrySummary(
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      flagEmoji: json['flagEmoji'] as String,
      topIndicators: (json['topIndicators'] as List)
          .map(
            (indicator) =>
                KeyIndicator.fromJson(indicator as Map<String, dynamic>),
          )
          .toList(),
      overallRanking: json['overallRanking'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
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
    if (percentile >= 90) return '~10%';
    if (percentile >= 75) return '10~25%';
    if (percentile >= 50) return '25~50%';
    if (percentile >= 25) return '50~75%';
    return '75~100%';
  }

  /// 성과 레벨 이모지
  String get performanceEmoji {
    return performance.emoji;
  }

  /// JSON으로 직렬화
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'unit': unit,
      'value': value,
      'rank': rank,
      'totalCountries': totalCountries,
      'percentile': percentile,
      'performance': performance.toString().split('.').last,
      'direction': direction,
      'sparklineEmoji': sparklineEmoji,
    };
  }

  /// JSON에서 역직렬화
  factory KeyIndicator.fromJson(Map<String, dynamic> json) {
    return KeyIndicator(
      code: json['code'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      value: (json['value'] as num).toDouble(),
      rank: json['rank'] as int,
      totalCountries: json['totalCountries'] as int,
      percentile: (json['percentile'] as num).toDouble(),
      performance: PerformanceLevel.values.firstWhere(
        (level) => level.toString().split('.').last == json['performance'],
        orElse: () => PerformanceLevel.average,
      ),
      direction: json['direction'] as String,
      sparklineEmoji: json['sparklineEmoji'] as String?,
    );
  }
}
