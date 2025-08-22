import 'package:flutter/material.dart';
import '../features/worldbank/models/indicator_codes.dart';
import '../features/home/models/indicator_comparison.dart';

/// 성과별 색상 정의
class PerformanceColors {
  // 기본 성과 색상
  static const Color excellent = Color(0xFF1E88E5); // 파란색 - 우수
  static const Color good = Color(0xFF26A69A);      // 청록색 - 양호
  static const Color average = Color(0xFF7E57C2);   // 보라색 - 보통
  static const Color poor = Color(0xFFE53935);      // 빨간색 - 미흡

  // 황금 배지 (Top 10%)
  static const Color gold = Color(0xFFFFD700);
  static const Color goldAccent = Color(0xFFB8860B);

  // 연한 배경색 (카드용)
  static const Color excellentLight = Color(0xFFE3F2FD);
  static const Color goodLight = Color(0xFFE0F2F1);
  static const Color averageLight = Color(0xFFF3E5F5);
  static const Color poorLight = Color(0xFFFFEBEE);

  /// 성과 레벨에 따른 메인 색상
  static Color getPerformanceColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return excellent;
      case PerformanceLevel.good:
        return good;
      case PerformanceLevel.average:
        return average;
      case PerformanceLevel.poor:
        return poor;
    }
  }

  /// 성과 레벨에 따른 배경 색상
  static Color getPerformanceBackgroundColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return excellentLight;
      case PerformanceLevel.good:
        return goodLight;
      case PerformanceLevel.average:
        return averageLight;
      case PerformanceLevel.poor:
        return poorLight;
    }
  }

  /// 백분위에 따른 배지 색상
  static Color getRankBadgeColor(double percentile) {
    if (percentile >= 90) return gold;
    if (percentile >= 75) return excellent;
    if (percentile >= 50) return good;
    if (percentile >= 25) return average;
    return poor;
  }

  /// 백분위에 따른 배지 배경 색상
  static Color getRankBadgeBackgroundColor(double percentile) {
    if (percentile >= 90) return const Color(0xFFFFF8E1);
    if (percentile >= 75) return excellentLight;
    if (percentile >= 50) return goodLight;
    if (percentile >= 25) return averageLight;
    return poorLight;
  }

  /// 트렌드 색상 (지표 방향성 고려)
  static Color getTrendColor(
    double changeValue,
    IndicatorDirection direction,
  ) {
    final bool isPositiveChange = changeValue > 0;
    
    switch (direction) {
      case IndicatorDirection.higher:
        // 높을수록 좋은 지표: 상승=좋음(파란색), 하락=나쁨(빨간색)
        return isPositiveChange ? excellent : poor;
      case IndicatorDirection.lower:
        // 낮을수록 좋은 지표: 하락=좋음(파란색), 상승=나쁨(빨간색)
        return isPositiveChange ? poor : excellent;
      case IndicatorDirection.neutral:
        // 중립적 지표: 회색
        return const Color(0xFF757575);
    }
  }
}

/// 지표별 색상 매핑
class IndicatorColors {
  // 긍정적 지표 (높을수록 좋음)
  static const Color positive = Color(0xFF1E88E5);
  static const Color positiveLight = Color(0xFF90CAF9);
  
  // 부정적 지표 (낮을수록 좋음)  
  static const Color negative = Color(0xFFE53935);
  static const Color negativeLight = Color(0xFFFFAB91);
  
  // 중립적 지표
  static const Color neutral = Color(0xFF26A69A);
  static const Color neutralLight = Color(0xFF80CBC4);

  /// 지표 방향성에 따른 기본 색상
  static Color getIndicatorBaseColor(IndicatorDirection direction) {
    switch (direction) {
      case IndicatorDirection.higher:
        return positive;
      case IndicatorDirection.lower:
        return negative;
      case IndicatorDirection.neutral:
        return neutral;
    }
  }

  /// 지표 방향성에 따른 연한 색상
  static Color getIndicatorLightColor(IndicatorDirection direction) {
    switch (direction) {
      case IndicatorDirection.higher:
        return positiveLight;
      case IndicatorDirection.lower:
        return negativeLight;
      case IndicatorDirection.neutral:
        return neutralLight;
    }
  }
}