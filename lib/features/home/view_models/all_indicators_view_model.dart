import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/all_indicators_service.dart';
import '../../worldbank/models/core_indicators.dart';
import '../../worldbank/models/country_indicator.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';

part 'all_indicators_view_model.g.dart';

@riverpod
class AllIndicatorsViewModel extends _$AllIndicatorsViewModel {
  @override
  AsyncValue<Map<CoreIndicatorCategory, List<CountryIndicator>>> build() {
    // 선택된 국가가 변경될 때 자동으로 새로고침
    ref.listen(selectedCountryProvider, (previous, next) {
      if (previous != null && previous.code != next.code) {
        AppLogger.debug('[AllIndicatorsViewModel] Country changed from ${previous.code} to ${next.code}, refreshing...');
        loadAllIndicators();
      }
    });
    
    return const AsyncValue.loading();
  }

  Future<void> loadAllIndicators() async {
    state = const AsyncValue.loading();
    
    try {
      final selectedCountry = ref.read(selectedCountryProvider);
      AppLogger.debug('[AllIndicatorsViewModel] Loading all 20 indicators for ${selectedCountry.code}...');
      
      final service = AllIndicatorsService();
      final categoryData = await service.getIndicatorsByCategory(
        countryCode: selectedCountry.code,
      );
      
      state = AsyncValue.data(categoryData);
      
      final totalIndicators = categoryData.values
          .map((list) => list.length)
          .fold(0, (sum, count) => sum + count);
      
      AppLogger.debug('[AllIndicatorsViewModel] Successfully loaded $totalIndicators indicators for ${selectedCountry.nameKo}');
      
      service.dispose();
    } catch (error, stackTrace) {
      AppLogger.error('[AllIndicatorsViewModel] Error loading indicators: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshIndicators() async {
    await loadAllIndicators();
  }
}

/// 특정 카테고리 성과 요약 프로바이더
@riverpod
Future<CategoryPerformanceSummary> categoryPerformance(
  Ref ref,
  CoreIndicatorCategory category,
) async {
  final selectedCountry = ref.watch(selectedCountryProvider);
  
  final service = AllIndicatorsService();
  try {
    final summary = await service.getCategoryPerformance(
      countryCode: selectedCountry.code,
      category: category,
    );
    return summary;
  } finally {
    service.dispose();
  }
}

/// 단일 지표 데이터 프로바이더 (개선된 버전)
@riverpod
Future<CountryIndicator> singleIndicatorData(
  Ref ref,
  String indicatorCode,
) async {
  final selectedCountry = ref.watch(selectedCountryProvider);
  
  final service = AllIndicatorsService();
  try {
    final countryIndicator = await service.getIndicatorData(
      countryCode: selectedCountry.code,
      indicatorCode: indicatorCode,
    );
    if (countryIndicator == null) {
      throw Exception('No data available for indicator: $indicatorCode');
    }
    return countryIndicator;
  } finally {
    service.dispose();
  }
}