import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/country_summary.dart';
import '../models/indicator_comparison.dart';
import '../../worldbank/models/core_indicators.dart';
import '../../worldbank/services/integrated_data_service.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';

part 'country_summary_view_model.g.dart';

@riverpod
class CountrySummaryViewModel extends _$CountrySummaryViewModel {
  @override
  AsyncValue<CountrySummary> build() {
    // 선택된 국가가 변경될 때 자동으로 새로고침
    ref.listen(selectedCountryProvider, (previous, next) {
      if (previous != null && previous.code != next.code) {
        AppLogger.debug(
          '[CountrySummaryViewModel] Country changed from ${previous.code} to ${next.code}, refreshing...',
        );
        loadCountrySummary();
      }
    });

    return const AsyncValue.loading();
  }

  Future<void> loadCountrySummary({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();

    try {
      final selectedCountry = ref.read(selectedCountryProvider);
      AppLogger.debug(
        '[CountrySummaryViewModel] Loading country summary for ${selectedCountry.code}... (forceRefresh: $forceRefresh)',
      );

      final dataService = IntegratedDataService();

      // PRD v1.1 - Top 5 지표 데이터 가져오기 (SQLite -> Firestore -> API 순서)
      final countryIndicators = await dataService.getTop5Indicators(
        countryCode: selectedCountry.code,
        forceRefresh: forceRefresh,
      );

      // CountrySummary 모델로 변환
      final topIndicators = countryIndicators.map((countryIndicator) {
        final coreIndicator = CoreIndicators.findByCode(
          countryIndicator.indicatorCode,
        );
        final performance = _getPerformanceFromPercentile(
          countryIndicator.oecdPercentile ?? 50.0,
        );

        return KeyIndicator(
          code: countryIndicator.indicatorCode,
          name: countryIndicator.indicatorName,
          value: countryIndicator.latestValue ?? 0.0,
          unit: countryIndicator.unit,
          rank: countryIndicator.oecdRanking ?? 0,
          totalCountries: countryIndicator.oecdStats?.totalCountries ?? 38,
          percentile: countryIndicator.oecdPercentile ?? 50.0,
          performance: performance,
          direction: _getDirection(coreIndicator),
          sparklineEmoji: _getSparklineEmoji(performance),
          dataYear: countryIndicator.latestYear ?? DateTime.now().year,
        );
      }).toList();

      final summary = CountrySummary(
        countryCode: selectedCountry.code,
        countryName: selectedCountry.nameKo,
        flagEmoji: selectedCountry.flagEmoji,
        overallRanking: _calculateOverallRanking(topIndicators),
        topIndicators: topIndicators,
        lastUpdated: DateTime.now(),
      );

      state = AsyncValue.data(summary);
      AppLogger.debug(
        '[CountrySummaryViewModel] Successfully loaded summary for ${selectedCountry.nameKo}',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        '[CountrySummaryViewModel] Error loading summary: $error',
      );
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshSummary() async {
    await loadCountrySummary(forceRefresh: true);
  }

  /// 성과 레벨에 따른 스파크라인 이모지 반환
  String _getSparklineEmoji(PerformanceLevel performance) {
    switch (performance) {
      case PerformanceLevel.excellent:
        return '🔥';
      case PerformanceLevel.good:
        return '📈';
      case PerformanceLevel.average:
        return '📊';
      case PerformanceLevel.poor:
        return '📉';
    }
  }

  /// 백분위에서 성과 레벨 계산
  PerformanceLevel _getPerformanceFromPercentile(double percentile) {
    if (percentile >= 75) return PerformanceLevel.excellent;
    if (percentile >= 50) return PerformanceLevel.good;
    if (percentile >= 25) return PerformanceLevel.average;
    return PerformanceLevel.poor;
  }

  /// CoreIndicator에서 방향성 추출
  String _getDirection(CoreIndicator? coreIndicator) {
    if (coreIndicator?.isPositive == true) return 'higher';
    if (coreIndicator?.isPositive == false) return 'lower';
    return 'neutral';
  }



  /// 전체 순위 계산
  String _calculateOverallRanking(List<KeyIndicator> indicators) {
    if (indicators.isEmpty) return '중위권';

    final excellentCount = indicators
        .where((i) => i.performance == PerformanceLevel.excellent)
        .length;
    final goodCount = indicators
        .where((i) => i.performance == PerformanceLevel.good)
        .length;
    final poorCount = indicators
        .where((i) => i.performance == PerformanceLevel.poor)
        .length;

    if (excellentCount >= 3) return '상위권';
    if (goodCount >= 3) return '중상위권';
    if (poorCount >= 3) return '하위권';
    return '중위권';
  }
}
