import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/country_summary.dart';
import '../services/country_summary_service.dart';
import '../../countries/view_models/selected_country_provider.dart';

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

  Future<void> loadCountrySummary() async {
    state = const AsyncValue.loading();

    try {
      final selectedCountry = ref.read(selectedCountryProvider);
      AppLogger.debug(
        '[CountrySummaryViewModel] Loading country summary for ${selectedCountry.code}...',
      );

      final service = CountrySummaryService();
      final summary = await service.generateCountrySummary(
        countryCode: selectedCountry.code,
      );

      state = AsyncValue.data(summary);
      AppLogger.debug(
        '[CountrySummaryViewModel] Successfully loaded summary for ${selectedCountry.nameKo}',
      );

      service.dispose();
    } catch (error, stackTrace) {
      AppLogger.error(
        '[CountrySummaryViewModel] Error loading summary: $error',
      );
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshSummary() async {
    await loadCountrySummary();
  }
}
