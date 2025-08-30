class IndicatorComparison {
  final String indicatorCode;
  final String indicatorName;
  final String unit;
  final int year;
  final CountryData selectedCountry;
  final OECDStatistics oecdStats;
  final List<CountryData> similarCountries;
  final ComparisonInsight insight;

  const IndicatorComparison({
    required this.indicatorCode,
    required this.indicatorName,
    required this.unit,
    required this.year,
    required this.selectedCountry,
    required this.oecdStats,
    required this.similarCountries,
    required this.insight,
  });

  Map<String, dynamic> toJson() {
    return {
      'indicatorCode': indicatorCode,
      'indicatorName': indicatorName,
      'unit': unit,
      'year': year,
      'selectedCountry': selectedCountry.toJson(),
      'oecdStats': oecdStats.toJson(),
      'similarCountries': similarCountries.map((e) => e.toJson()).toList(),
      'insight': insight.toJson(),
    };
  }

  factory IndicatorComparison.fromJson(Map<String, dynamic> json) {
    return IndicatorComparison(
      indicatorCode: json['indicatorCode'] as String,
      indicatorName: json['indicatorName'] as String,
      unit: json['unit'] as String,
      year: json['year'] as int,
      selectedCountry: CountryData.fromJson(json['selectedCountry'] as Map<String, dynamic>),
      oecdStats: OECDStatistics.fromJson(json['oecdStats'] as Map<String, dynamic>),
      similarCountries: (json['similarCountries'] as List)
          .map((e) => CountryData.fromJson(e as Map<String, dynamic>))
          .toList(),
      insight: ComparisonInsight.fromJson(json['insight'] as Map<String, dynamic>),
    );
  }
}

class CountryData {
  final String countryCode;
  final String countryName;
  final double value;
  final int rank;
  final String? flagEmoji;

  const CountryData({
    required this.countryCode,
    required this.countryName,
    required this.value,
    required this.rank,
    this.flagEmoji,
  });

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'value': value,
      'rank': rank,
      'flagEmoji': flagEmoji,
    };
  }

  factory CountryData.fromJson(Map<String, dynamic> json) {
    return CountryData(
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      value: (json['value'] as num).toDouble(),
      rank: json['rank'] as int,
      flagEmoji: json['flagEmoji'] as String?,
    );
  }
}

class OECDStatistics {
  final double median;
  final double q1; // 1사분위수 (25백분위수)
  final double q3; // 3사분위수 (75백분위수)
  final double min;
  final double max;
  final double mean;
  final int totalCountries;
  final List<CountryRankingData>? countryRankings; // 국가별 순위 데이터

  const OECDStatistics({
    required this.median,
    required this.q1,
    required this.q3,
    required this.min,
    required this.max,
    required this.mean,
    required this.totalCountries,
    this.countryRankings,
  });

  /// 특정 국가의 순위 조회
  int? getRankForCountry(String countryCode) {
    if (countryRankings == null) return null;
    
    final countryData = countryRankings!
        .firstWhere(
          (data) => data.countryCode == countryCode,
          orElse: () => throw Exception('Country $countryCode not found in rankings'),
        );
    return countryData.rank;
  }

  /// 특정 값에 대한 정확한 순위 계산 (기존 데이터 기반)
  int calculateRankForValue(double value, bool higherIsBetter) {
    if (countryRankings == null || countryRankings!.isEmpty) {
      // 기존 방식으로 근사치 계산
      final percentile = calculatePercentile(value);
      return higherIsBetter 
          ? ((100 - percentile) / 100 * totalCountries).round() + 1
          : (percentile / 100 * totalCountries).round() + 1;
    }

    // 정확한 순위 계산: 현재 값보다 좋은 성과를 낸 국가 수 + 1
    int betterCount = 0;
    for (final countryData in countryRankings!) {
      if (higherIsBetter) {
        if (countryData.value > value) betterCount++;
      } else {
        if (countryData.value < value) betterCount++;
      }
    }
    return betterCount + 1;
  }

  /// 백분위 계산
  double calculatePercentile(double value) {
    if (value <= min) return 0;
    if (value >= max) return 100;
    if (value <= q1) {
      return 25 * (value - min) / (q1 - min);
    }
    if (value <= median) {
      return 25 + 25 * (value - q1) / (median - q1);
    }
    if (value <= q3) {
      return 50 + 25 * (value - median) / (q3 - median);
    }
    return 75 + 25 * (value - q3) / (max - q3);
  }

  Map<String, dynamic> toJson() {
    return {
      'median': median,
      'q1': q1,
      'q3': q3,
      'min': min,
      'max': max,
      'mean': mean,
      'totalCountries': totalCountries,
      'countryRankings': countryRankings?.map((e) => e.toJson()).toList(),
    };
  }

  factory OECDStatistics.fromJson(Map<String, dynamic> json) {
    return OECDStatistics(
      median: (json['median'] as num).toDouble(),
      q1: (json['q1'] as num).toDouble(),
      q3: (json['q3'] as num).toDouble(),
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      mean: (json['mean'] as num).toDouble(),
      totalCountries: json['totalCountries'] as int,
      countryRankings: json['countryRankings'] != null
          ? (json['countryRankings'] as List)
              .map((e) => CountryRankingData.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

/// 국가별 순위 데이터
class CountryRankingData {
  final String countryCode;
  final String countryName;
  final double value;
  final int rank;

  const CountryRankingData({
    required this.countryCode,
    required this.countryName,
    required this.value,
    required this.rank,
  });

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'value': value,
      'rank': rank,
    };
  }

  factory CountryRankingData.fromJson(Map<String, dynamic> json) {
    return CountryRankingData(
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      value: (json['value'] as num).toDouble(),
      rank: json['rank'] as int,
    );
  }
}

extension OECDStatisticsExtension on OECDStatistics {
  double get iqr => q3 - q1;
  double get lowerBound => median - iqr;
  double get upperBound => median + iqr;
  
  bool isKoreaInNormalRange(double koreaValue) {
    return koreaValue >= lowerBound && koreaValue <= upperBound;
  }
  
  PerformanceLevel getKoreaPerformance(double koreaValue) {
    if (koreaValue >= q3) return PerformanceLevel.excellent;
    if (koreaValue >= median) return PerformanceLevel.good;
    if (koreaValue >= q1) return PerformanceLevel.average;
    return PerformanceLevel.poor;
  }
}

class ComparisonInsight {
  final PerformanceLevel performance;
  final String summary;
  final String detailedAnalysis;
  final List<String> keyFindings;
  final bool isOutlier;

  const ComparisonInsight({
    required this.performance,
    required this.summary,
    required this.detailedAnalysis,
    required this.keyFindings,
    this.isOutlier = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'performance': performance.name,
      'summary': summary,
      'detailedAnalysis': detailedAnalysis,
      'keyFindings': keyFindings,
      'isOutlier': isOutlier,
    };
  }

  factory ComparisonInsight.fromJson(Map<String, dynamic> json) {
    return ComparisonInsight(
      performance: PerformanceLevel.values.firstWhere(
        (e) => e.name == json['performance'],
      ),
      summary: json['summary'] as String,
      detailedAnalysis: json['detailedAnalysis'] as String,
      keyFindings: (json['keyFindings'] as List).cast<String>(),
      isOutlier: json['isOutlier'] as bool? ?? false,
    );
  }
}

enum PerformanceLevel {
  excellent, // 상위 25% (Q4)
  good,      // 상위 50% (Q3)
  average,   // 하위 50% (Q2)
  poor;      // 하위 25% (Q1)

  String get label {
    switch (this) {
      case PerformanceLevel.excellent:
        return '우수';
      case PerformanceLevel.good:
        return '양호';
      case PerformanceLevel.average:
        return '보통';
      case PerformanceLevel.poor:
        return '개선필요';
    }
  }

  String get emoji {
    switch (this) {
      case PerformanceLevel.excellent:
        return '🏆';
      case PerformanceLevel.good:
        return '👍';
      case PerformanceLevel.average:
        return '📊';
      case PerformanceLevel.poor:
        return '📉';
    }
  }
}

class RecommendedComparison {
  final List<IndicatorComparison> comparisons;
  final String selectionReason;
  final DateTime lastUpdated;

  const RecommendedComparison({
    required this.comparisons,
    required this.selectionReason,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'comparisons': comparisons.map((e) => e.toJson()).toList(),
      'selectionReason': selectionReason,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory RecommendedComparison.fromJson(Map<String, dynamic> json) {
    return RecommendedComparison(
      comparisons: (json['comparisons'] as List)
          .map((e) => IndicatorComparison.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectionReason: json['selectionReason'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}