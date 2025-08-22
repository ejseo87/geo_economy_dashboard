/// 스파크라인 데이터 포인트
class SparklinePoint {
  final int year;
  final double value;
  final bool isEstimated; // 추정값 여부

  const SparklinePoint({
    required this.year,
    required this.value,
    this.isEstimated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'value': value,
      'isEstimated': isEstimated,
    };
  }

  factory SparklinePoint.fromJson(Map<String, dynamic> json) {
    return SparklinePoint(
      year: json['year'] as int,
      value: (json['value'] as num).toDouble(),
      isEstimated: json['isEstimated'] as bool? ?? false,
    );
  }
}

/// 스파크라인 차트 데이터
class SparklineData {
  final String indicatorCode;
  final String indicatorName;
  final String unit;
  final String countryCode;
  final List<SparklinePoint> points;
  final SparklineTrend trend;
  final double? changePercentage; // 5년간 변화율
  final DateTime lastUpdated;

  const SparklineData({
    required this.indicatorCode,
    required this.indicatorName,
    required this.unit,
    required this.countryCode,
    required this.points,
    required this.trend,
    this.changePercentage,
    required this.lastUpdated,
  });

  /// 최신값 (가장 최근 연도)
  SparklinePoint? get latestPoint {
    if (points.isEmpty) return null;
    return points.reduce((a, b) => a.year > b.year ? a : b);
  }

  /// 최댓값
  double get maxValue {
    if (points.isEmpty) return 0;
    return points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }

  /// 최솟값
  double get minValue {
    if (points.isEmpty) return 0;
    return points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }

  /// 5년간 변화량 (절대값)
  double? get changeValue {
    if (points.length < 2) return null;
    final sorted = List<SparklinePoint>.from(points)..sort((a, b) => a.year.compareTo(b.year));
    return sorted.last.value - sorted.first.value;
  }

  /// 유효한 데이터 포인트 개수
  int get validPointsCount => points.length;

  Map<String, dynamic> toJson() {
    return {
      'indicatorCode': indicatorCode,
      'indicatorName': indicatorName,
      'unit': unit,
      'countryCode': countryCode,
      'points': points.map((p) => p.toJson()).toList(),
      'trend': trend.name,
      'changePercentage': changePercentage,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SparklineData.fromJson(Map<String, dynamic> json) {
    return SparklineData(
      indicatorCode: json['indicatorCode'] as String,
      indicatorName: json['indicatorName'] as String,
      unit: json['unit'] as String,
      countryCode: json['countryCode'] as String,
      points: (json['points'] as List)
          .map((p) => SparklinePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      trend: SparklineTrend.values.firstWhere(
        (t) => t.name == json['trend'],
        orElse: () => SparklineTrend.stable,
      ),
      changePercentage: json['changePercentage'] as double?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// 스파크라인 트렌드 방향
enum SparklineTrend {
  rising,     // 상승 트렌드
  falling,    // 하락 트렌드
  stable,     // 안정적
  volatile;   // 변동성 높음

  /// 트렌드에 따른 색상 결정 (지표 방향성 고려)
  bool isPositiveTrend(bool isHigherBetter) {
    switch (this) {
      case SparklineTrend.rising:
        return isHigherBetter; // 높을수록 좋은 지표면 상승이 긍정적
      case SparklineTrend.falling:
        return !isHigherBetter; // 낮을수록 좋은 지표면 하락이 긍정적
      case SparklineTrend.stable:
      case SparklineTrend.volatile:
        return true; // 중립적
    }
  }
}

/// 스파크라인 메타데이터
class SparklineMetadata {
  final String title;
  final String subtitle;
  final String description;
  final bool isHigherBetter; // 높을수록 좋은 지표인지
  final String? emoji; // 지표 대표 이모지

  const SparklineMetadata({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isHigherBetter,
    this.emoji,
  });
}