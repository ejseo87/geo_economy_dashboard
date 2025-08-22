/// Firestore에 저장될 캐시된 지표 데이터 모델
class CachedIndicatorData {
  final String id; // Firestore 문서 ID
  final String countryCode; // ISO3 국가 코드
  final String indicatorCode; // 지표 코드
  final Map<String, double?> yearlyData; // 연도별 데이터 Map
  final DateTime fetchedAt; // 데이터 수집 시간
  final DateTime lastUpdated; // 마지막 업데이트 시간
  final String? eTag; // HTTP ETag for 조건부 요청
  final int? latestYear; // 가장 최신 데이터 연도
  final String? unit; // 지표 단위
  final String? source; // 데이터 출처

  CachedIndicatorData({
    required this.id,
    required this.countryCode,
    required this.indicatorCode,
    required this.yearlyData,
    required this.fetchedAt,
    required this.lastUpdated,
    this.eTag,
    this.latestYear,
    this.unit,
    this.source,
  });

  /// Firestore 문서 ID 생성
  static String generateId(String countryCode, String indicatorCode) {
    return '${countryCode}_$indicatorCode';
  }

  /// Map으로 변환 (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'countryCode': countryCode,
      'indicatorCode': indicatorCode,
      'yearlyData': yearlyData.map((year, value) => MapEntry(year, value)),
      'fetchedAt': fetchedAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'eTag': eTag,
      'latestYear': latestYear,
      'unit': unit,
      'source': source,
    };
  }

  /// Map에서 생성 (Firestore 조회용)
  factory CachedIndicatorData.fromMap(Map<String, dynamic> map) {
    return CachedIndicatorData(
      id: map['id'] as String,
      countryCode: map['countryCode'] as String,
      indicatorCode: map['indicatorCode'] as String,
      yearlyData: Map<String, double?>.from(
        (map['yearlyData'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as double?),
        ),
      ),
      fetchedAt: DateTime.parse(map['fetchedAt'] as String),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      eTag: map['eTag'] as String?,
      latestYear: map['latestYear'] as int?,
      unit: map['unit'] as String?,
      source: map['source'] as String?,
    );
  }

  /// 데이터가 만료되었는지 확인
  bool isExpired(int ttlDays) {
    final now = DateTime.now();
    final expiryDate = fetchedAt.add(Duration(days: ttlDays));
    return now.isAfter(expiryDate);
  }

  /// 최신 값 반환
  double? get latestValue {
    if (yearlyData.isEmpty) return null;
    
    // 연도를 내림차순으로 정렬하고 첫 번째 null이 아닌 값 반환
    final sortedYears = yearlyData.keys.toList()
      ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    
    for (final year in sortedYears) {
      final value = yearlyData[year];
      if (value != null) return value;
    }
    
    return null;
  }

  /// 특정 연도의 값 반환
  double? getValueForYear(int year) {
    return yearlyData[year.toString()];
  }

  /// 시계열 데이터를 연도 오름차순으로 반환
  List<MapEntry<int, double>> getTimeSeriesData() {
    final validData = yearlyData.entries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(int.parse(entry.key), entry.value!))
        .toList();
    
    validData.sort((a, b) => a.key.compareTo(b.key));
    return validData;
  }

  /// 전년 대비 증감률 계산
  double? getYearOverYearChange() {
    final timeSeries = getTimeSeriesData();
    if (timeSeries.length < 2) return null;
    
    final latest = timeSeries.last.value;
    final previous = timeSeries[timeSeries.length - 2].value;
    
    if (previous == 0) return null;
    return ((latest - previous) / previous) * 100;
  }

  /// 복사본 생성 (업데이트용)
  CachedIndicatorData copyWith({
    String? id,
    String? countryCode,
    String? indicatorCode,
    Map<String, double?>? yearlyData,
    DateTime? fetchedAt,
    DateTime? lastUpdated,
    String? eTag,
    int? latestYear,
    String? unit,
    String? source,
  }) {
    return CachedIndicatorData(
      id: id ?? this.id,
      countryCode: countryCode ?? this.countryCode,
      indicatorCode: indicatorCode ?? this.indicatorCode,
      yearlyData: yearlyData ?? this.yearlyData,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      eTag: eTag ?? this.eTag,
      latestYear: latestYear ?? this.latestYear,
      unit: unit ?? this.unit,
      source: source ?? this.source,
    );
  }
}

/// OECD 통계 캐시 모델
class CachedOECDStats {
  final String id; // 지표 코드
  final String indicatorCode;
  final int year; // 기준 연도
  final double median;
  final double q1;
  final double q3;
  final double min;
  final double max;
  final double mean;
  final int totalCountries;
  final List<String> countriesIncluded; // 포함된 국가 목록
  final DateTime calculatedAt; // 계산 시간
  final DateTime expiresAt; // 만료 시간

  CachedOECDStats({
    required this.id,
    required this.indicatorCode,
    required this.year,
    required this.median,
    required this.q1,
    required this.q3,
    required this.min,
    required this.max,
    required this.mean,
    required this.totalCountries,
    required this.countriesIncluded,
    required this.calculatedAt,
    required this.expiresAt,
  });

  /// Firestore 문서 ID 생성
  static String generateId(String indicatorCode, int year) {
    return '${indicatorCode}_$year';
  }

  /// Map으로 변환 (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'indicatorCode': indicatorCode,
      'year': year,
      'median': median,
      'q1': q1,
      'q3': q3,
      'min': min,
      'max': max,
      'mean': mean,
      'totalCountries': totalCountries,
      'countriesIncluded': countriesIncluded,
      'calculatedAt': calculatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// Map에서 생성 (Firestore 조회용)
  factory CachedOECDStats.fromMap(Map<String, dynamic> map) {
    return CachedOECDStats(
      id: map['id'] as String,
      indicatorCode: map['indicatorCode'] as String,
      year: map['year'] as int,
      median: (map['median'] as num).toDouble(),
      q1: (map['q1'] as num).toDouble(),
      q3: (map['q3'] as num).toDouble(),
      min: (map['min'] as num).toDouble(),
      max: (map['max'] as num).toDouble(),
      mean: (map['mean'] as num).toDouble(),
      totalCountries: map['totalCountries'] as int,
      countriesIncluded: List<String>.from(map['countriesIncluded'] as List),
      calculatedAt: DateTime.parse(map['calculatedAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  /// 캐시가 만료되었는지 확인
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// IQR 계산
  double get iqr => q3 - q1;

  /// 특정 값의 백분위 계산 (근사치)
  double calculatePercentile(double value) {
    if (value <= min) return 0;
    if (value >= max) return 100;
    if (value <= q1) return 25 * (value - min) / (q1 - min);
    if (value <= median) return 25 + 25 * (value - q1) / (median - q1);
    if (value <= q3) return 50 + 25 * (value - median) / (q3 - median);
    return 75 + 25 * (value - q3) / (max - q3);
  }
}