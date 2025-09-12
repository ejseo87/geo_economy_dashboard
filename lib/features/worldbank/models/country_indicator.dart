import 'package:cloud_firestore/cloud_firestore.dart';
import 'indicator_series.dart' show IndicatorDataPoint;

/// PRD v1.1 - 비정규화된 국가 중심 모델 (조회 가속)
/// Firestore 경로: /countries/{countryCode}/indicators/{indicatorCode}
class CountryIndicator {
  final String countryCode;       // ISO3 국가 코드
  final String indicatorCode;     // World Bank 지표 코드
  final String countryName;       // 국가명
  final String indicatorName;     // 지표명
  final String unit;              // 단위
  final double? latestValue;      // 최신값
  final int? latestYear;          // 최신값의 연도
  final List<IndicatorDataPoint> recentData;  // 최근 10년 데이터
  final int? oecdRanking;         // OECD 38개국 내 랭킹
  final double? oecdPercentile;   // OECD 백분위 (0-100)
  final OECDStats? oecdStats;     // OECD 통계
  final double? yearOverYearChange; // 전년 대비 변화율
  final DateTime updatedAt;       // 업데이트 시간
  final String? dataBadge;        // 데이터 뱃지 (최신도)

  CountryIndicator({
    required this.countryCode,
    required this.indicatorCode,
    required this.countryName,
    required this.indicatorName,
    required this.unit,
    this.latestValue,
    this.latestYear,
    this.recentData = const [],
    this.oecdRanking,
    this.oecdPercentile,
    this.oecdStats,
    this.yearOverYearChange,
    required this.updatedAt,
    this.dataBadge,
  });

  /// Firestore 문서 ID 생성
  static String generateDocId(String indicatorCode) => indicatorCode;

  /// Firestore 컬렉션 경로
  static String getCollectionPath(String countryCode) => 
      'countries/$countryCode/indicators';

  /// 전체 문서 경로
  String get documentPath => 
      'countries/$countryCode/indicators/$indicatorCode';

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'countryCode': countryCode,
      'indicatorCode': indicatorCode,
      'countryName': countryName,
      'indicatorName': indicatorName,
      'unit': unit,
      'latestValue': latestValue,
      'latestYear': latestYear,
      'recentData': recentData.map((point) => {
        'year': point.year,
        'value': point.value,
      }).toList(),
      'oecdRanking': oecdRanking,
      'oecdPercentile': oecdPercentile,
      'oecdStats': oecdStats?.toMap(),
      'yearOverYearChange': yearOverYearChange,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'dataBadge': dataBadge,
    };
  }

  /// Firestore에서 객체 생성
  factory CountryIndicator.fromFirestore(
    Map<String, dynamic> data,
    String countryCode,
    String indicatorCode,
  ) {
    final recentDataList = data['recentData'] as List? ?? [];
    final recentData = recentDataList.map((item) {
      final map = item as Map<String, dynamic>;
      return IndicatorDataPoint(
        year: map['year'] as int,
        value: (map['value'] as num).toDouble(),
      );
    }).toList();

    final oecdStatsMap = data['oecdStats'] as Map<String, dynamic>?;
    final oecdStats = oecdStatsMap != null 
        ? OECDStats.fromMap(oecdStatsMap)
        : null;

    return CountryIndicator(
      countryCode: countryCode,
      indicatorCode: indicatorCode,
      countryName: data['countryName'] ?? '',
      indicatorName: data['indicatorName'] ?? '',
      unit: data['unit'] ?? '',
      latestValue: data['latestValue'] is num ? 
          (data['latestValue'] as num).toDouble() : null,
      latestYear: data['latestYear'] as int?,
      recentData: recentData,
      oecdRanking: data['oecdRanking'] as int?,
      oecdPercentile: data['oecdPercentile'] is num ? 
          (data['oecdPercentile'] as num).toDouble() : null,
      oecdStats: oecdStats,
      yearOverYearChange: data['yearOverYearChange'] is num ? 
          (data['yearOverYearChange'] as num).toDouble() : null,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataBadge: data['dataBadge'] as String?,
    );
  }

  /// OECD 랭킹 뱃지 가져오기
  String getRankingBadge() {
    if (oecdRanking == null) return '';
    
    final percentage = (oecdRanking! / 38.0) * 100;
    
    if (percentage <= 10) {
      return 'Top 10%';
    } else if (percentage <= 25) {
      return 'Q1';
    } else if (percentage <= 75) {
      return 'Q2-Q3';
    } else {
      return 'Q4';
    }
  }

  /// 랭킹 뱃지 색상 가져오기
  String getRankingBadgeColor() {
    if (oecdRanking == null) return '#BDBDBD';
    
    final percentage = (oecdRanking! / 38.0) * 100;
    
    if (percentage <= 10) {
      return '#FFD700'; // 금색
    } else if (percentage <= 25) {
      return '#1E88E5'; // 파랑
    } else if (percentage <= 75) {
      return '#BDBDBD'; // 회색
    } else {
      return '#E53935'; // 빨강
    }
  }

  /// 데이터 신선도 뱃지 가져오기
  String getFreshnessBadge() {
    if (latestYear == null) return 'No Data';
    
    final currentYear = DateTime.now().year;
    final yearsDiff = currentYear - latestYear!;
    
    if (yearsDiff <= 1) {
      return 'Up to date';
    } else if (yearsDiff <= 2) {
      return 'Stale';
    } else {
      return 'Outdated';
    }
  }

  /// 신선도 뱃지 색상
  String getFreshnessBadgeColor() {
    if (latestYear == null) return '#BDBDBD';
    
    final currentYear = DateTime.now().year;
    final yearsDiff = currentYear - latestYear!;
    
    if (yearsDiff <= 1) {
      return '#1E88E5'; // 파랑
    } else if (yearsDiff <= 2) {
      return '#FF7043'; // 주황
    } else {
      return '#E53935'; // 빨강
    }
  }

  /// 복사본 생성
  CountryIndicator copyWith({
    String? countryCode,
    String? indicatorCode,
    String? countryName,
    String? indicatorName,
    String? unit,
    double? latestValue,
    int? latestYear,
    List<IndicatorDataPoint>? recentData,
    int? oecdRanking,
    double? oecdPercentile,
    OECDStats? oecdStats,
    double? yearOverYearChange,
    DateTime? updatedAt,
    String? dataBadge,
  }) {
    return CountryIndicator(
      countryCode: countryCode ?? this.countryCode,
      indicatorCode: indicatorCode ?? this.indicatorCode,
      countryName: countryName ?? this.countryName,
      indicatorName: indicatorName ?? this.indicatorName,
      unit: unit ?? this.unit,
      latestValue: latestValue ?? this.latestValue,
      latestYear: latestYear ?? this.latestYear,
      recentData: recentData ?? this.recentData,
      oecdRanking: oecdRanking ?? this.oecdRanking,
      oecdPercentile: oecdPercentile ?? this.oecdPercentile,
      oecdStats: oecdStats ?? this.oecdStats,
      yearOverYearChange: yearOverYearChange ?? this.yearOverYearChange,
      updatedAt: updatedAt ?? this.updatedAt,
      dataBadge: dataBadge ?? this.dataBadge,
    );
  }
}

/// 데이터 포인트 (재사용)

/// OECD 통계 정보
class OECDStats {
  final double median;      // 중위값
  final double q1;          // 1사분위
  final double q3;          // 3사분위
  final double min;         // 최솟값
  final double max;         // 최댓값
  final double mean;        // 평균값
  final int totalCountries; // 총 국가 수

  OECDStats({
    required this.median,
    required this.q1,
    required this.q3,
    required this.min,
    required this.max,
    required this.mean,
    required this.totalCountries,
  });

  Map<String, dynamic> toMap() {
    return {
      'median': median,
      'q1': q1,
      'q3': q3,
      'min': min,
      'max': max,
      'mean': mean,
      'totalCountries': totalCountries,
    };
  }

  factory OECDStats.fromMap(Map<String, dynamic> map) {
    return OECDStats(
      median: (map['median'] as num).toDouble(),
      q1: (map['q1'] as num).toDouble(),
      q3: (map['q3'] as num).toDouble(),
      min: (map['min'] as num).toDouble(),
      max: (map['max'] as num).toDouble(),
      mean: (map['mean'] as num).toDouble(),
      totalCountries: map['totalCountries'] as int,
    );
  }

  /// IQR 계산
  double get iqr => q3 - q1;
}