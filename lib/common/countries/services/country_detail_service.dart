import '../../../features/worldbank/services/integrated_data_service.dart';
import '../../logger.dart';

/// 국가 상세 화면용 데이터 서비스
class CountryDetailService {
  static final CountryDetailService _instance = CountryDetailService._internal();
  factory CountryDetailService() => _instance;
  CountryDetailService._internal();

  static CountryDetailService get instance => _instance;

  final _dataService = IntegratedDataService();

  /// GDP 성장률 히스토리컬 데이터 가져오기 (10년)
  Future<List<GdpDataPoint>> getGdpGrowthHistory(String countryCode) async {
    try {
      AppLogger.info('[CountryDetailService] Loading GDP growth history for $countryCode');
      
      final indicatorData = await _dataService.getCountryIndicator(
        countryCode: countryCode,
        indicatorCode: 'NY.GDP.MKTP.KD.ZG', // GDP 성장률 코드
        forceRefresh: false,
      );

      final dataPoints = <GdpDataPoint>[];
      final currentYear = DateTime.now().year;
      final startYear = currentYear - 10; // 10년간 데이터

      // 시계열 데이터에서 년도별 데이터 추출
      if (indicatorData != null && indicatorData.recentData.isNotEmpty) {
        for (final dataPoint in indicatorData.recentData) {
          if (dataPoint.year >= startYear && dataPoint.year <= currentYear - 1) {
            dataPoints.add(GdpDataPoint(
              year: dataPoint.year,
              value: dataPoint.value,
              xIndex: dataPoint.year - startYear, // 차트용 인덱스
            ));
          }
        }
      }

      AppLogger.info('[CountryDetailService] Found ${dataPoints.length} GDP data points');
      return dataPoints;

    } catch (error) {
      AppLogger.error('[CountryDetailService] Error loading GDP history: $error');
      return [];
    }
  }

  /// OECD 비교 데이터 가져오기 (3개 주요 지표)
  Future<List<OecdComparisonData>> getOecdComparisonData(String countryCode) async {
    try {
      AppLogger.info('[CountryDetailService] Loading OECD comparison for $countryCode');

      final indicators = [
        {'code': 'NY.GDP.MKTP.KD.ZG', 'name': 'GDP 성장률'},
        {'code': 'SL.UEM.TOTL.ZS', 'name': '실업률'},
        {'code': 'FP.CPI.TOTL.ZG', 'name': 'CPI 인플레이션'},
      ];

      final comparisonData = <OecdComparisonData>[];

      for (int i = 0; i < indicators.length; i++) {
        final indicator = indicators[i];
        
        try {
          final indicatorData = await _dataService.getCountryIndicator(
            countryCode: countryCode,
            indicatorCode: indicator['code']!,
            forceRefresh: false,
          );

          if (indicatorData != null) {
            comparisonData.add(OecdComparisonData(
              indicatorName: indicator['name']!,
              countryValue: indicatorData.latestValue ?? 0.0,
              oecdAverage: indicatorData.oecdStats?.mean ?? 0.0,
              xIndex: i,
              year: indicatorData.latestYear ?? DateTime.now().year - 1,
            ));
          } else {
            // 데이터가 없을 때 기본값
            comparisonData.add(OecdComparisonData(
              indicatorName: indicator['name']!,
              countryValue: 0.0,
              oecdAverage: 0.0,
              xIndex: i,
              year: DateTime.now().year - 1,
            ));
          }

        } catch (error) {
          AppLogger.warning('[CountryDetailService] Failed to load ${indicator['name']}: $error');
          // 데이터 로드 실패 시 기본값 추가
          comparisonData.add(OecdComparisonData(
            indicatorName: indicator['name']!,
            countryValue: 0.0,
            oecdAverage: 0.0,
            xIndex: i,
            year: DateTime.now().year - 1,
          ));
        }
      }

      AppLogger.info('[CountryDetailService] Loaded ${comparisonData.length} OECD comparison data points');
      return comparisonData;

    } catch (error) {
      AppLogger.error('[CountryDetailService] Error loading OECD comparison: $error');
      return [];
    }
  }

  /// 국가별 다중 지표 성과 데이터 가져오기 (6개 지표)
  Future<List<CountryIndicatorSummary>> getCountryIndicatorsSummary(String countryCode) async {
    try {
      AppLogger.info('[CountryDetailService] Loading indicators summary for $countryCode');

      final indicators = [
        {'code': 'NY.GDP.MKTP.KD.ZG', 'name': 'GDP 성장률', 'unit': '%'},
        {'code': 'SL.UEM.TOTL.ZS', 'name': '실업률', 'unit': '%'},
        {'code': 'FP.CPI.TOTL.ZG', 'name': 'CPI 인플레이션', 'unit': '%'},
        {'code': 'BN.CAB.XOKA.GD.ZS', 'name': '경상수지', 'unit': '% of GDP'},
        {'code': 'NY.GDP.PCAP.PP.CD', 'name': '1인당 GDP (PPP)', 'unit': 'USD'},
        {'code': 'SL.EMP.TOTL.SP.ZS', 'name': '고용률', 'unit': '%'},
      ];

      final summaries = <CountryIndicatorSummary>[];

      for (final indicator in indicators) {
        try {
          final indicatorData = await _dataService.getCountryIndicator(
            countryCode: countryCode,
            indicatorCode: indicator['code']!,
            forceRefresh: false,
          );

          if (indicatorData != null) {
            summaries.add(CountryIndicatorSummary(
              code: indicator['code']!,
              name: indicator['name']!,
              unit: indicator['unit']!,
              value: indicatorData.latestValue ?? 0.0,
              rank: indicatorData.oecdRanking ?? 0,
              totalCountries: indicatorData.oecdStats?.totalCountries ?? 38,
              year: indicatorData.latestYear ?? DateTime.now().year - 1,
            ));
          }

        } catch (error) {
          AppLogger.warning('[CountryDetailService] Failed to load ${indicator['name']}: $error');
        }
      }

      AppLogger.info('[CountryDetailService] Loaded ${summaries.length} indicator summaries');
      return summaries;

    } catch (error) {
      AppLogger.error('[CountryDetailService] Error loading indicators summary: $error');
      return [];
    }
  }
}

/// GDP 데이터 포인트
class GdpDataPoint {
  final int year;
  final double value;
  final int xIndex; // 차트용 X축 인덱스

  const GdpDataPoint({
    required this.year,
    required this.value,
    required this.xIndex,
  });
}

/// OECD 비교 데이터
class OecdComparisonData {
  final String indicatorName;
  final double countryValue;
  final double oecdAverage;
  final int xIndex; // 차트용 X축 인덱스
  final int year;

  const OecdComparisonData({
    required this.indicatorName,
    required this.countryValue,
    required this.oecdAverage,
    required this.xIndex,
    required this.year,
  });
}

/// 국가별 지표 요약
class CountryIndicatorSummary {
  final String code;
  final String name;
  final String unit;
  final double value;
  final int rank;
  final int totalCountries;
  final int year;

  const CountryIndicatorSummary({
    required this.code,
    required this.name,
    required this.unit,
    required this.value,
    required this.rank,
    required this.totalCountries,
    required this.year,
  });
}