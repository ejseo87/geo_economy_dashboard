import 'dart:math' as math;
import 'package:geo_economy_dashboard/common/logger.dart';
import '../models/sparkline_data.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../worldbank/repositories/indicator_repository.dart';

/// 스파크라인 차트 데이터 서비스
class SparklineService {
  final IndicatorRepository _repository;

  SparklineService({IndicatorRepository? repository})
      : _repository = repository ?? IndicatorRepository();

  /// 5년 트렌드 데이터 생성
  Future<SparklineData> generateSparklineData({
    required IndicatorCode indicatorCode,
    required String countryCode,
    int yearCount = 5,
  }) async {
    try {
      AppLogger.debug('[SparklineService] Generating 5-year trend for ${indicatorCode.name} in $countryCode');

      // 최근 5년 데이터 가져오기
      final currentYear = DateTime.now().year;
      final startYear = currentYear - yearCount + 1;
      
      final indicatorData = await _repository.getIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCode,
      );

      if (indicatorData == null) {
        throw Exception('No data available for ${indicatorCode.name}');
      }

      // 5년간 데이터 포인트 수집
      final points = <SparklinePoint>[];
      for (int year = startYear; year <= currentYear; year++) {
        final value = indicatorData.getValueForYear(year);
        if (value != null && value.isFinite) {
          points.add(SparklinePoint(
            year: year,
            value: value,
            isEstimated: year >= currentYear - 1, // 최근 2년은 추정값으로 간주
          ));
        }
      }

      if (points.isEmpty) {
        throw Exception('No valid data points found for the last $yearCount years');
      }

      // 트렌드 계산
      final trend = _calculateTrend(points);
      
      // 변화율 계산
      final changePercentage = _calculateChangePercentage(points);

      final sparklineData = SparklineData(
        indicatorCode: indicatorCode.code,
        indicatorName: indicatorCode.name,
        unit: indicatorCode.unit,
        countryCode: countryCode,
        points: points,
        trend: trend,
        changePercentage: changePercentage,
        lastUpdated: DateTime.now(),
      );

      AppLogger.debug('[SparklineService] Generated sparkline with ${points.length} points, trend: ${trend.name}');
      return sparklineData;

    } catch (error) {
      AppLogger.error('[SparklineService] Error generating sparkline: $error');
      rethrow;
    }
  }

  /// 여러 지표의 스파크라인 데이터 생성 (병렬 처리)
  Future<List<SparklineData>> generateMultipleSparklines({
    required List<IndicatorCode> indicators,
    required String countryCode,
    int yearCount = 5,
  }) async {
    AppLogger.debug('[SparklineService] Generating ${indicators.length} sparklines for $countryCode');

    final futures = indicators.map((indicator) async {
      try {
        return await generateSparklineData(
          indicatorCode: indicator,
          countryCode: countryCode,
          yearCount: yearCount,
        );
      } catch (e) {
        AppLogger.error('[SparklineService] Failed to generate sparkline for ${indicator.name}: $e');
        return null;
      }
    }).toList();

    final results = await Future.wait(futures);
    final validResults = results.whereType<SparklineData>().toList();

    AppLogger.debug('[SparklineService] Successfully generated ${validResults.length}/${indicators.length} sparklines');
    return validResults;
  }

  /// Top 5 지표의 스파크라인 데이터 생성
  Future<List<SparklineData>> generateTop5Sparklines({
    required String countryCode,
  }) async {
    final topIndicators = [
      IndicatorCode.gdpRealGrowth,      // GDP 성장률
      IndicatorCode.unemployment,       // 실업률
      IndicatorCode.gdpPppPerCapita,    // 1인당 GDP
      IndicatorCode.cpiInflation,       // CPI 인플레이션
      IndicatorCode.currentAccount,     // 경상수지
    ];

    return generateMultipleSparklines(
      indicators: topIndicators,
      countryCode: countryCode,
    );
  }

  /// 트렌드 방향 계산
  SparklineTrend _calculateTrend(List<SparklinePoint> points) {
    if (points.length < 3) return SparklineTrend.stable;

    // 연도순 정렬
    final sorted = List<SparklinePoint>.from(points)
      ..sort((a, b) => a.year.compareTo(b.year));

    // 선형 회귀를 통한 트렌드 계산 (간단한 방식)
    final n = sorted.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble(); // 인덱스를 x로 사용
      final y = sorted[i].value;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    // 변동성 계산
    final values = sorted.map((p) => p.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final coefficientOfVariation = math.sqrt(variance) / mean.abs();

    // 트렌드 결정
    if (coefficientOfVariation > 0.2) { // 변동계수가 20% 이상이면 변동성 높음
      return SparklineTrend.volatile;
    } else if (slope.abs() < 0.1) { // 기울기가 작으면 안정적
      return SparklineTrend.stable;
    } else if (slope > 0) {
      return SparklineTrend.rising;
    } else {
      return SparklineTrend.falling;
    }
  }

  /// 5년간 변화율 계산
  double? _calculateChangePercentage(List<SparklinePoint> points) {
    if (points.length < 2) return null;

    final sorted = List<SparklinePoint>.from(points)
      ..sort((a, b) => a.year.compareTo(b.year));

    final firstValue = sorted.first.value;
    final lastValue = sorted.last.value;

    if (firstValue == 0) return null;

    return ((lastValue - firstValue) / firstValue.abs()) * 100;
  }

  /// 스파크라인 메타데이터 가져오기
  SparklineMetadata getSparklineMetadata(IndicatorCode indicatorCode) {
    switch (indicatorCode) {
      case IndicatorCode.gdpRealGrowth:
        return const SparklineMetadata(
          title: 'GDP 성장률',
          subtitle: '실질 GDP 성장률 (%)',
          description: '경제 성장의 핵심 지표로, 높을수록 경제가 빠르게 성장하고 있음을 의미합니다.',
          isHigherBetter: true,
          emoji: '📈',
        );
      case IndicatorCode.unemployment:
        return const SparklineMetadata(
          title: '실업률',
          subtitle: '전체 노동력 대비 실업자 비율 (%)',
          description: '낮을수록 고용 상황이 좋으며, 경제 건전성을 나타내는 중요한 지표입니다.',
          isHigherBetter: false,
          emoji: '👥',
        );
      case IndicatorCode.gdpPppPerCapita:
        return const SparklineMetadata(
          title: '1인당 GDP',
          subtitle: '구매력 기준 1인당 GDP (USD)',
          description: '국민의 생활 수준을 나타내는 지표로, 높을수록 경제적 풍요도가 높습니다.',
          isHigherBetter: true,
          emoji: '💰',
        );
      case IndicatorCode.cpiInflation:
        return const SparklineMetadata(
          title: '소비자물가상승률',
          subtitle: 'CPI 인플레이션 (%)',
          description: '물가 안정성을 나타내며, 적정 수준(2-3%)이 이상적입니다.',
          isHigherBetter: false,
          emoji: '🛒',
        );
      case IndicatorCode.currentAccount:
        return const SparklineMetadata(
          title: '경상수지',
          subtitle: 'GDP 대비 경상수지 (%)',
          description: '대외 거래에서의 수지 상황을 나타내며, 국가의 대외 경쟁력을 반영합니다.',
          isHigherBetter: true,
          emoji: '⚖️',
        );
      default:
        return SparklineMetadata(
          title: indicatorCode.name,
          subtitle: indicatorCode.unit,
          description: '경제 지표의 5년간 변화 추이를 보여줍니다.',
          isHigherBetter: true,
          emoji: '📊',
        );
    }
  }

  /// 리소스 정리
  void dispose() {
    _repository.dispose();
  }
}