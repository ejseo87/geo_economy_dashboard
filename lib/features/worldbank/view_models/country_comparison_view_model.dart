import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/core_indicators.dart';
import '../models/country_indicator.dart';
import '../services/integrated_data_service.dart';
import '../../../common/logger.dart';
import '../../../common/countries/models/country.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';

part 'country_comparison_view_model.g.dart';

/// PRD v1.1 - 국가간 비교 또는 지표별 전체 국가 비교를 위한 ViewModel
@riverpod
class CountryComparisonViewModel extends _$CountryComparisonViewModel {
  @override
  AsyncValue<CountryComparisonResult?> build() {
    return const AsyncValue.data(null);
  }

  /// 방식1: 국가 vs 국가 비교 (Top 5 지표)
  Future<void> compareCountries({
    required Country country1,
    required Country country2,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      AppLogger.debug('[CountryComparisonViewModel] Comparing ${country1.code} vs ${country2.code}');
      
      final dataService = IntegratedDataService();
      
      // 두 국가의 Top 5 지표 데이터 가져오기 (통합 데이터 서비스 사용)
      final country1Indicators = await dataService.getTop5Indicators(
        countryCode: country1.code,
      );
      final country2Indicators = await dataService.getTop5Indicators(
        countryCode: country2.code,
      );
      
      final result = CountryComparisonResult(
        type: ComparisonType.countryVsCountry,
        country1: country1,
        country2: country2,
        country1Indicators: country1Indicators,
        country2Indicators: country2Indicators,
        selectedIndicator: null,
        allCountriesData: [],
        lastUpdated: DateTime.now(),
      );
      
      state = AsyncValue.data(result);
      AppLogger.debug('[CountryComparisonViewModel] Country comparison completed');
    } catch (error, stackTrace) {
      AppLogger.error('[CountryComparisonViewModel] Error comparing countries: $error', stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 방식2: 지표별 전체 OECD 국가 비교
  Future<void> compareIndicatorAcrossCountries({
    required CoreIndicator indicator,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      AppLogger.debug('[CountryComparisonViewModel] Comparing indicator ${indicator.code} across all countries');
      
      // TODO: 실제로는 OECD 38개국 리스트를 가져와서 비교해야 함
      // 현재는 선택된 국가의 데이터만 가져옴
      final selectedCountry = ref.read(selectedCountryProvider);
      final dataService = IntegratedDataService();
      
      final selectedCountryIndicator = await dataService.getCountryIndicator(
        countryCode: selectedCountry.code,
        indicatorCode: indicator.code,
      );
      
      final result = CountryComparisonResult(
        type: ComparisonType.indicatorAcrossCountries,
        country1: selectedCountry,
        country2: null,
        country1Indicators: selectedCountryIndicator != null ? [selectedCountryIndicator] : [],
        country2Indicators: [],
        selectedIndicator: indicator,
        allCountriesData: [], // TODO: 모든 OECD 국가 데이터 로드
        lastUpdated: DateTime.now(),
      );
      
      state = AsyncValue.data(result);
      AppLogger.debug('[CountryComparisonViewModel] Indicator comparison completed');
    } catch (error, stackTrace) {
      AppLogger.error('[CountryComparisonViewModel] Error comparing indicator: $error', stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// AI 추천 비교 (다양한 카테고리에서 2-3개 지표 선별)
  Future<void> loadAIRecommendedComparison() async {
    state = const AsyncValue.loading();
    
    try {
      AppLogger.debug('[CountryComparisonViewModel] Loading AI recommended comparison');
      
      final selectedCountry = ref.read(selectedCountryProvider);
      final dataService = IntegratedDataService();
      
      // AI 추천 로직: 카테고리 다양성 보장 (지능형 선별)
      final selectedIndicators = await dataService.getAIRecommendedIndicators(
        countryCode: selectedCountry.code,
        maxCount: 3,
      );
      
      final result = CountryComparisonResult(
        type: ComparisonType.aiRecommended,
        country1: selectedCountry,
        country2: null,
        country1Indicators: selectedIndicators,
        country2Indicators: [],
        selectedIndicator: null,
        allCountriesData: [],
        lastUpdated: DateTime.now(),
      );
      
      state = AsyncValue.data(result);
      AppLogger.debug('[CountryComparisonViewModel] AI recommended comparison completed');
    } catch (error, stackTrace) {
      AppLogger.error('[CountryComparisonViewModel] Error loading AI recommended: $error', stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }


  void clearComparison() {
    state = const AsyncValue.data(null);
  }
}

/// 비교 결과 데이터 모델
class CountryComparisonResult {
  final ComparisonType type;
  final Country country1;
  final Country? country2;
  final List<CountryIndicator> country1Indicators;
  final List<CountryIndicator> country2Indicators;
  final CoreIndicator? selectedIndicator;
  final List<CountryIndicator> allCountriesData;
  final DateTime lastUpdated;

  CountryComparisonResult({
    required this.type,
    required this.country1,
    this.country2,
    required this.country1Indicators,
    required this.country2Indicators,
    this.selectedIndicator,
    required this.allCountriesData,
    required this.lastUpdated,
  });
}

/// 비교 방식 타입
enum ComparisonType {
  countryVsCountry,        // 국가 vs 국가 (Top 5 지표)
  indicatorAcrossCountries, // 지표별 전체 국가 비교
  aiRecommended,           // AI 추천 비교 (다양한 카테고리)
}