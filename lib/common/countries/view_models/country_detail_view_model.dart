import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../logger.dart';
import '../models/country.dart';
import '../services/country_detail_service.dart';

part 'country_detail_view_model.g.dart';

/// 국가상세화면 데이터 상태
class CountryDetailState {
  final List<GdpDataPoint> gdpHistory;
  final List<OecdComparisonData> oecdComparison;
  final List<CountryIndicatorSummary> indicatorsSummary;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const CountryDetailState({
    this.gdpHistory = const [],
    this.oecdComparison = const [],
    this.indicatorsSummary = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  CountryDetailState copyWith({
    List<GdpDataPoint>? gdpHistory,
    List<OecdComparisonData>? oecdComparison,
    List<CountryIndicatorSummary>? indicatorsSummary,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return CountryDetailState(
      gdpHistory: gdpHistory ?? this.gdpHistory,
      oecdComparison: oecdComparison ?? this.oecdComparison,
      indicatorsSummary: indicatorsSummary ?? this.indicatorsSummary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 데이터가 로드되었는지 확인
  bool get hasData => 
      gdpHistory.isNotEmpty || 
      oecdComparison.isNotEmpty || 
      indicatorsSummary.isNotEmpty;

  /// GDP 데이터 년도 범위
  String get gdpYearRange {
    if (gdpHistory.isEmpty) return '';
    final startYear = gdpHistory.first.year;
    final endYear = gdpHistory.last.year;
    return '$startYear-$endYear';
  }

  /// OECD 비교 데이터 년도
  int? get oecdDataYear {
    if (oecdComparison.isEmpty) return null;
    return oecdComparison.first.year;
  }
}

/// 국가상세화면 뷰모델
@riverpod
class CountryDetailViewModel extends _$CountryDetailViewModel {
  late final CountryDetailService _service;

  @override
  CountryDetailState build(Country country) {
    _service = CountryDetailService.instance;
    return const CountryDetailState();
  }

  /// 국가 상세 데이터 로드
  Future<void> loadCountryDetail() async {
    final countryCode = country.code;
    
    AppLogger.info('[CountryDetailViewModel] Loading country detail for ${country.nameKo}');
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 병렬로 모든 데이터 로드
      final results = await Future.wait([
        _service.getGdpGrowthHistory(countryCode),
        _service.getOecdComparisonData(countryCode),
        _service.getCountryIndicatorsSummary(countryCode),
      ]);

      final gdpHistory = results[0] as List<GdpDataPoint>;
      final oecdComparison = results[1] as List<OecdComparisonData>;
      final indicatorsSummary = results[2] as List<CountryIndicatorSummary>;

      state = state.copyWith(
        gdpHistory: gdpHistory,
        oecdComparison: oecdComparison,
        indicatorsSummary: indicatorsSummary,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info(
        '[CountryDetailViewModel] Loaded country detail: '
        '${gdpHistory.length} GDP points, '
        '${oecdComparison.length} OECD comparisons, '
        '${indicatorsSummary.length} indicator summaries'
      );

    } catch (error) {
      AppLogger.error('[CountryDetailViewModel] Error loading country detail: $error');
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// 데이터 새로고침
  Future<void> refreshData() async {
    AppLogger.info('[CountryDetailViewModel] Refreshing country detail data');
    await loadCountryDetail();
  }

  /// 특정 지표 데이터만 다시 로드
  Future<void> reloadGdpHistory() async {
    try {
      AppLogger.info('[CountryDetailViewModel] Reloading GDP history');
      final gdpHistory = await _service.getGdpGrowthHistory(country.code);
      
      state = state.copyWith(
        gdpHistory: gdpHistory,
        lastUpdated: DateTime.now(),
      );
      
    } catch (error) {
      AppLogger.error('[CountryDetailViewModel] Error reloading GDP history: $error');
      state = state.copyWith(error: error.toString());
    }
  }

  /// OECD 비교 데이터만 다시 로드
  Future<void> reloadOecdComparison() async {
    try {
      AppLogger.info('[CountryDetailViewModel] Reloading OECD comparison');
      final oecdComparison = await _service.getOecdComparisonData(country.code);
      
      state = state.copyWith(
        oecdComparison: oecdComparison,
        lastUpdated: DateTime.now(),
      );
      
    } catch (error) {
      AppLogger.error('[CountryDetailViewModel] Error reloading OECD comparison: $error');
      state = state.copyWith(error: error.toString());
    }
  }
}