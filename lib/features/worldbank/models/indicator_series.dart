import 'package:cloud_firestore/cloud_firestore.dart';

/// PRD v1.1 - 정규화된 지표 중심 저장 모델
/// Firestore 경로: /indicators/{indicatorCode}/series/{countryCode}
class IndicatorSeries {
  final String indicatorCode;     // World Bank 지표 코드
  final String countryCode;       // ISO3 국가 코드
  final String indicatorName;     // 지표명
  final String countryName;       // 국가명
  final String unit;              // 단위
  final Map<int, double?> timeSeries;  // 연도별 데이터 {2020: 1.5, 2021: 2.1, ...}
  final double? latestValue;      // 최신값
  final int? latestYear;          // 최신값의 연도
  final DateTime fetchedAt;       // 수집 시간
  final DateTime updatedAt;       // 업데이트 시간
  final String? source;           // 데이터 출처

  IndicatorSeries({
    required this.indicatorCode,
    required this.countryCode,
    required this.indicatorName,
    required this.countryName,
    required this.unit,
    required this.timeSeries,
    this.latestValue,
    this.latestYear,
    required this.fetchedAt,
    required this.updatedAt,
    this.source,
  });

  /// Firestore 문서 ID 생성
  static String generateDocId(String countryCode) => countryCode;

  /// Firestore 컬렉션 경로
  static String getCollectionPath(String indicatorCode) => 
      'indicators/$indicatorCode/series';

  /// 전체 문서 경로
  String get documentPath => 
      'indicators/$indicatorCode/series/$countryCode';

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'indicatorCode': indicatorCode,
      'countryCode': countryCode,
      'indicatorName': indicatorName,
      'countryName': countryName,
      'unit': unit,
      'timeSeries': timeSeries.map((year, value) => 
          MapEntry(year.toString(), value)),
      'latestValue': latestValue,
      'latestYear': latestYear,
      'fetchedAt': Timestamp.fromDate(fetchedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'source': source,
    };
  }

  /// Firestore에서 객체 생성
  factory IndicatorSeries.fromFirestore(
    Map<String, dynamic> data,
    String indicatorCode,
    String countryCode,
  ) {
    final timeSeriesMap = data['timeSeries'] as Map<String, dynamic>? ?? {};
    final timeSeries = <int, double?>{};
    
    timeSeriesMap.forEach((yearStr, value) {
      final year = int.tryParse(yearStr);
      if (year != null) {
        timeSeries[year] = value is num ? value.toDouble() : null;
      }
    });

    return IndicatorSeries(
      indicatorCode: indicatorCode,
      countryCode: countryCode,
      indicatorName: data['indicatorName'] ?? '',
      countryName: data['countryName'] ?? '',
      unit: data['unit'] ?? '',
      timeSeries: timeSeries,
      latestValue: data['latestValue'] is num ? 
          (data['latestValue'] as num).toDouble() : null,
      latestYear: data['latestYear'] as int?,
      fetchedAt: (data['fetchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: data['source'] as String?,
    );
  }

  /// 시계열 데이터 가져오기 (정렬된)
  List<IndicatorDataPoint> getTimeSeriesData() {
    final points = <IndicatorDataPoint>[];
    
    timeSeries.entries
        .where((entry) => entry.value != null)
        .forEach((entry) {
      points.add(IndicatorDataPoint(
        year: entry.key,
        value: entry.value!,
      ));
    });
    
    points.sort((a, b) => a.year.compareTo(b.year));
    return points;
  }

  /// 최근 N년 데이터
  List<IndicatorDataPoint> getRecentYears(int years) {
    final allData = getTimeSeriesData();
    return allData.length > years 
        ? allData.sublist(allData.length - years)
        : allData;
  }

  /// 전년 대비 변화율 계산
  double? getYearOverYearChange() {
    final sortedData = getTimeSeriesData();
    if (sortedData.length < 2) return null;
    
    final latest = sortedData.last.value;
    final previous = sortedData[sortedData.length - 2].value;
    
    if (previous == 0) return null;
    return ((latest - previous) / previous) * 100;
  }

  /// 복사본 생성
  IndicatorSeries copyWith({
    String? indicatorCode,
    String? countryCode,
    String? indicatorName,
    String? countryName,
    String? unit,
    Map<int, double?>? timeSeries,
    double? latestValue,
    int? latestYear,
    DateTime? fetchedAt,
    DateTime? updatedAt,
    String? source,
  }) {
    return IndicatorSeries(
      indicatorCode: indicatorCode ?? this.indicatorCode,
      countryCode: countryCode ?? this.countryCode,
      indicatorName: indicatorName ?? this.indicatorName,
      countryName: countryName ?? this.countryName,
      unit: unit ?? this.unit,
      timeSeries: timeSeries ?? this.timeSeries,
      latestValue: latestValue ?? this.latestValue,
      latestYear: latestYear ?? this.latestYear,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
    );
  }
}

/// 지표 데이터 포인트
class IndicatorDataPoint {
  final int year;
  final double value;

  IndicatorDataPoint({
    required this.year,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicatorDataPoint &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          value == other.value;

  @override
  int get hashCode => year.hashCode ^ value.hashCode;
}