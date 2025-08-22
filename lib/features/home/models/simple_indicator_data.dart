// 간단한 데이터 클래스 (Freezed 없이)
class IndicatorData {
  final String code;
  final String name;
  final String unit;
  final double value;
  final int year;
  final OECDRanking ranking;
  final TrendDirection trend;
  final double? previousValue;

  const IndicatorData({
    required this.code,
    required this.name,
    required this.unit,
    required this.value,
    required this.year,
    required this.ranking,
    required this.trend,
    this.previousValue,
  });
}

class OECDRanking {
  final int rank;
  final int totalCountries;
  final double percentile;
  final RankingTier tier;

  const OECDRanking({
    required this.rank,
    required this.totalCountries,
    required this.percentile,
    required this.tier,
  });
}

class CountrySummary {
  final String countryCode;
  final String countryName;
  final List<IndicatorData> topIndicators;
  final DateTime lastUpdated;

  const CountrySummary({
    required this.countryCode,
    required this.countryName,
    required this.topIndicators,
    required this.lastUpdated,
  });
}

enum RankingTier {
  top, // 상위 25%
  upper, // 상위 26-50%
  lower, // 하위 51-75%
  bottom; // 하위 76-100%

  String get label {
    switch (this) {
      case RankingTier.top:
        return '상위';
      case RankingTier.upper:
        return '중상위';
      case RankingTier.lower:
        return '중하위';
      case RankingTier.bottom:
        return '하위';
    }
  }

  String get badgeText {
    switch (this) {
      case RankingTier.top:
        return 'TOP 25%';
      case RankingTier.upper:
        return 'Q2';
      case RankingTier.lower:
        return 'Q3';
      case RankingTier.bottom:
        return 'Q4';
    }
  }
}

enum TrendDirection {
  up,
  down,
  stable;

  String get icon {
    switch (this) {
      case TrendDirection.up:
        return '↗';
      case TrendDirection.down:
        return '↘';
      case TrendDirection.stable:
        return '→';
    }
  }
}
