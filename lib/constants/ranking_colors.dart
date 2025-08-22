import 'package:flutter/material.dart';
import 'package:geo_economy_dashboard/features/home/models/simple_indicator_data.dart';

class RankingColors {
  // 순위 티어별 색상
  static const Map<RankingTier, Color> tierColors = {
    RankingTier.top: Color(0xFF1E88E5),     // 파랑 - 상위
    RankingTier.upper: Color(0xFF26A69A),   // 청록 - 중상위
    RankingTier.lower: Color(0xFFFF7043),   // 주황 - 중하위
    RankingTier.bottom: Color(0xFFE53935),  // 빨강 - 하위
  };

  // 순위 티어별 배경 색상 (연한 버전)
  static const Map<RankingTier, Color> tierBackgroundColors = {
    RankingTier.top: Color(0xFFE3F2FD),     // 연한 파랑
    RankingTier.upper: Color(0xFFE0F2F1),   // 연한 청록
    RankingTier.lower: Color(0xFFFBE9E7),   // 연한 주황
    RankingTier.bottom: Color(0xFFFFEBEE),  // 연한 빨강
  };

  // 트렌드 방향별 색상 (지표 성격에 따라 다름)
  static Color getTrendColor(TrendDirection trend, bool isPositiveIndicator) {
    switch (trend) {
      case TrendDirection.up:
        return isPositiveIndicator ? tierColors[RankingTier.top]! : tierColors[RankingTier.bottom]!;
      case TrendDirection.down:
        return isPositiveIndicator ? tierColors[RankingTier.bottom]! : tierColors[RankingTier.top]!;
      case TrendDirection.stable:
        return Colors.grey[600]!;
    }
  }

  // 지표별 성격 정의 (상승이 좋은지 나쁜지)
  static const Map<String, bool> indicatorPositivity = {
    'NY.GDP.MKTP.KD.ZG': true,    // GDP 성장률 - 상승 좋음
    'NY.GDP.PCAP.PP.CD': true,    // 1인당 GDP - 상승 좋음
    'SL.UEM.TOTL.ZS': false,      // 실업률 - 상승 나쁨
    'FP.CPI.TOTL.ZG': false,      // 인플레이션 - 상승 나쁨
    'BN.CAB.XOKA.GD.ZS': true,    // 경상수지 - 상승 좋음
    'SL.TLF.CACT.ZS': true,       // 노동참가율 - 상승 좋음
    'NE.CON.GOVT.ZS': false,      // 정부지출 - 중립 (상황에 따라)
    'GC.DOD.TOTL.GD.ZS': false,   // 정부부채 - 상승 나쁨
    'EN.ATM.CO2E.PC': false,      // CO2 배출 - 상승 나쁨
    'EG.FEC.RNEW.ZS': true,       // 재생에너지 - 상승 좋음
  };

  static bool isPositiveIndicator(String indicatorCode) {
    return indicatorPositivity[indicatorCode] ?? true;
  }

  static Color getTierColor(RankingTier tier) {
    return tierColors[tier] ?? Colors.grey;
  }

  static Color getTierBackgroundColor(RankingTier tier) {
    return tierBackgroundColors[tier] ?? Colors.grey[100]!;
  }
}