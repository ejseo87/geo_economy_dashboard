import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/country_summary.dart';
import '../services/all_indicators_service.dart';
import '../models/indicator_comparison.dart';
import '../../worldbank/models/indicator_codes.dart';
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

      final service = AllIndicatorsService();
      
      // AllIndicatorsService에서 Top 5 지표 데이터 가져오기
      final topIndicatorCodes = [
        IndicatorCode.gdpRealGrowth,
        IndicatorCode.unemployment,
        IndicatorCode.cpiInflation,
        IndicatorCode.currentAccount,
        IndicatorCode.gdpPppPerCapita,
      ];
      
      final indicatorResults = <IndicatorComparison>[];
      for (final code in topIndicatorCodes) {
        final comparison = await service.getIndicatorComparison(
          countryCode: selectedCountry.code,
          indicatorCode: code,
        );
        if (comparison != null) {
          indicatorResults.add(comparison);
        }
      }
      
      // CountrySummary 모델로 변환
      final topIndicators = indicatorResults.map((comparison) => KeyIndicator(
        code: comparison.indicatorCode,
        name: comparison.indicatorName,
        value: comparison.selectedCountry.value,
        unit: comparison.unit,
        rank: comparison.selectedCountry.rank,
        totalCountries: comparison.oecdStats.totalCountries,
        percentile: _calculatePercentile(comparison.selectedCountry.rank, comparison.oecdStats.totalCountries),
        performance: comparison.insight.performance,
        direction: 'higher', // 기본값 설정
        sparklineEmoji: _getSparklineEmoji(comparison.insight.performance),
      )).toList();
      
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
        return '📈';
      case PerformanceLevel.good:
        return '📊';
      case PerformanceLevel.average:
        return '📉';
      case PerformanceLevel.poor:
        return '⚠️';
    }
  }

  /// 백분위 계산 (순위 기반)
  double _calculatePercentile(int rank, int totalCountries) {
    if (totalCountries <= 1) return 50.0;
    return ((totalCountries - rank) / (totalCountries - 1)) * 100;
  }

  /// 전체 순위 계산
  String _calculateOverallRanking(List<KeyIndicator> indicators) {
    if (indicators.isEmpty) return '중위권';
    
    final excellentCount = indicators.where((i) => i.performance == PerformanceLevel.excellent).length;
    final goodCount = indicators.where((i) => i.performance == PerformanceLevel.good).length;
    final poorCount = indicators.where((i) => i.performance == PerformanceLevel.poor).length;
    
    if (excellentCount >= 3) return '상위권';
    if (goodCount >= 3) return '중상위권';
    if (poorCount >= 3) return '하위권';
    return '중위권';
  }
}
