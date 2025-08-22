import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../common/logger.dart';
import '../models/sparkline_data.dart';
import '../services/sparkline_service.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../countries/view_models/selected_country_provider.dart';

part 'sparkline_view_model.g.dart';

/// 스파크라인 차트 상태
class SparklineState {
  final bool isLoading;
  final List<SparklineData> sparklines;
  final String? error;
  final DateTime? lastUpdated;

  const SparklineState({
    this.isLoading = false,
    this.sparklines = const [],
    this.error,
    this.lastUpdated,
  });

  SparklineState copyWith({
    bool? isLoading,
    List<SparklineData>? sparklines,
    String? error,
    DateTime? lastUpdated,
  }) {
    return SparklineState(
      isLoading: isLoading ?? this.isLoading,
      sparklines: sparklines ?? this.sparklines,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 스파크라인 뷰모델
@riverpod
class SparklineViewModel extends _$SparklineViewModel {
  SparklineService? _service;
  
  @override
  SparklineState build() {
    _service = SparklineService();
    return const SparklineState();
  }

  void dispose() {
    _service?.dispose();
  }

  /// Top 5 지표 스파크라인 로드
  Future<void> loadTop5Sparklines() async {
    if (state.isLoading) return;

    final countryCode = ref.read(selectedCountryProvider).code;
    if (countryCode == null) {
      AppLogger.warning('[SparklineViewModel] No country selected');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.debug('[SparklineViewModel] Loading Top 5 sparklines for $countryCode');
      
      final sparklines = await _service!.generateTop5Sparklines(
        countryCode: countryCode,
      );

      state = state.copyWith(
        isLoading: false,
        sparklines: sparklines,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('[SparklineViewModel] Loaded ${sparklines.length} sparklines');
      
    } catch (error) {
      AppLogger.error('[SparklineViewModel] Error loading sparklines: $error');
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// 특정 지표들의 스파크라인 로드
  Future<void> loadSparklines(List<IndicatorCode> indicators) async {
    if (state.isLoading) return;

    final countryCode = ref.read(selectedCountryProvider).code;
    if (countryCode == null) {
      AppLogger.warning('[SparklineViewModel] No country selected');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.debug('[SparklineViewModel] Loading ${indicators.length} sparklines for $countryCode');
      
      final sparklines = await _service!.generateMultipleSparklines(
        indicators: indicators,
        countryCode: countryCode,
      );

      state = state.copyWith(
        isLoading: false,
        sparklines: sparklines,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('[SparklineViewModel] Loaded ${sparklines.length} sparklines');
      
    } catch (error) {
      AppLogger.error('[SparklineViewModel] Error loading sparklines: $error');
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// 단일 지표 스파크라인 로드
  Future<SparklineData?> loadSingleSparkline(IndicatorCode indicator) async {
    final countryCode = ref.read(selectedCountryProvider).code;
    if (countryCode == null) return null;

    try {
      AppLogger.debug('[SparklineViewModel] Loading sparkline for ${indicator.name}');
      
      final sparkline = await _service!.generateSparklineData(
        indicatorCode: indicator,
        countryCode: countryCode,
      );

      AppLogger.debug('[SparklineViewModel] Loaded sparkline for ${indicator.name}');
      return sparkline;
      
    } catch (error) {
      AppLogger.error('[SparklineViewModel] Error loading sparkline for ${indicator.name}: $error');
      return null;
    }
  }

  /// 국가 변경 시 새로고침
  Future<void> refreshOnCountryChange() async {
    if (state.sparklines.isNotEmpty) {
      // 기존 데이터가 있으면 다시 로드
      await loadTop5Sparklines();
    }
  }

  /// 에러 상태 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 특정 지표 코드로 스파크라인 데이터 찾기
  SparklineData? getSparklineByCode(String indicatorCode) {
    try {
      return state.sparklines.firstWhere(
        (sparkline) => sparkline.indicatorCode == indicatorCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// 트렌드별 스파크라인 필터링
  List<SparklineData> getSparklinesByTrend(SparklineTrend trend) {
    return state.sparklines
        .where((sparkline) => sparkline.trend == trend)
        .toList();
  }

  /// 상승 트렌드 개수
  int get risingTrendsCount => 
      state.sparklines.where((s) => s.trend == SparklineTrend.rising).length;

  /// 하락 트렌드 개수  
  int get fallingTrendsCount => 
      state.sparklines.where((s) => s.trend == SparklineTrend.falling).length;

  /// 안정 트렌드 개수
  int get stableTrendsCount => 
      state.sparklines.where((s) => s.trend == SparklineTrend.stable).length;

  /// 변동성 높은 트렌드 개수
  int get volatileTrendsCount => 
      state.sparklines.where((s) => s.trend == SparklineTrend.volatile).length;
}

/// 국가별 스파크라인 프로바이더 (자동 갱신)
@riverpod
class CountrySparklineViewModel extends _$CountrySparklineViewModel {
  @override
  FutureOr<List<SparklineData>> build() async {
    final country = ref.watch(selectedCountryProvider);
    if (country == null) return [];

    final service = SparklineService();
    try {
      final sparklines = await service.generateTop5Sparklines(
        countryCode: country.code,
      );
      return sparklines;
    } finally {
      service.dispose();
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}