import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/indicator_comparison.dart';
import '../services/real_comparison_service.dart';
import '../../worldbank/services/integrated_data_service.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';

part 'comparison_view_model.g.dart';

@riverpod
class ComparisonViewModel extends _$ComparisonViewModel {
  @override
  AsyncValue<RecommendedComparison> build() {
    // 선택된 국가가 변경될 때 자동으로 새로고침
    ref.listen(selectedCountryProvider, (previous, next) {
      if (previous != null && previous.code != next.code) {
        AppLogger.debug(
          '[ComparisonViewModel] Country changed from ${previous.code} to ${next.code}, refreshing...',
        );
        loadRecommendedComparison();
      }
    });

    return const AsyncValue.loading();
  }

  Future<void> loadRecommendedComparison() async {
    state = const AsyncValue.loading();

    try {
      final selectedCountry = ref.read(selectedCountryProvider);
      AppLogger.debug(
        '[ComparisonViewModel] Loading recommended comparison for ${selectedCountry.code} from World Bank API...',
      );

      // IntegratedDataService를 사용하여 실제 World Bank API 데이터 로드
      final comparison =
          await RealComparisonService.generateRecommendedComparison(
            dataService: IntegratedDataService(),
            countryCode: selectedCountry.code,
          );

      state = AsyncValue.data(comparison);
      AppLogger.debug(
        '[ComparisonViewModel] Successfully loaded ${comparison.comparisons.length} comparisons for ${selectedCountry.nameKo}',
      );
    } catch (error, stackTrace) {
      AppLogger.error('[ComparisonViewModel] Error loading comparison: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshComparison() async {
    await loadRecommendedComparison();
  }
}

// IntegratedDataService 프로바이더
@riverpod
IntegratedDataService integratedDataService(Ref ref) {
  return IntegratedDataService();
}

// 개별 지표 비교를 위한 프로바이더
@riverpod
Future<IndicatorComparison> indicatorComparison(
  Ref ref,
  String indicatorCode,
) async {
  try {
    final dataService = ref.read(integratedDataServiceProvider);
    final selectedCountry = ref.read(selectedCountryProvider);

    // RealComparisonService를 사용하여 실제 World Bank API 데이터 가져오기
    final service = RealComparisonService(dataService: dataService);

    return await service.generateIndicatorComparison(
      indicatorCode,
      countryCode: selectedCountry.code,
    );
  } catch (error) {
    AppLogger.error('[indicatorComparison] Error: $error');
    rethrow;
  }
}
