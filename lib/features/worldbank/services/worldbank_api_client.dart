import 'package:dio/dio.dart';
import '../models/country_indicator.dart';
import '../models/indicator_series.dart' show IndicatorDataPoint;
import '../models/core_indicators.dart';
import '../../../common/logger.dart';

/// PRD v1.1 World Bank API 클라이언트
/// 실시간 경제 데이터 수집 및 OECD 통계 계산
class WorldBankApiClient {
  static const String _baseUrl = 'https://api.worldbank.org/v2';
  static const int _timeoutSeconds = 30;
  static const int _maxRetries = 3;
  
  final Dio _dio;
  
  // OECD 38개국 코드 리스트
  static const List<String> _oecdCountryCodes = [
    'AUS', 'AUT', 'BEL', 'CAN', 'CHL', 'COL', 'CZE', 'DNK', 'EST', 'FIN',
    'FRA', 'DEU', 'GRC', 'HUN', 'ISL', 'IRL', 'ISR', 'ITA', 'JPN', 'KOR',
    'LVA', 'LTU', 'LUX', 'MEX', 'NLD', 'NZL', 'NOR', 'POL', 'PRT', 'SVK',
    'SVN', 'ESP', 'SWE', 'CHE', 'TUR', 'GBR', 'USA', 'CRI'
  ];

  WorldBankApiClient({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(seconds: _timeoutSeconds),
      receiveTimeout: Duration(seconds: _timeoutSeconds),
      headers: {
        'User-Agent': 'GeoEconomyDashboard/1.0',
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => AppLogger.debug('[WorldBankAPI] $obj'),
    ));

    return dio;
  }

  /// 특정 국가의 지표 데이터 가져오기 (최근 10년)
  Future<CountryIndicator?> getCountryIndicator({
    required String countryCode,
    required String indicatorCode,
    int startYear = 2014,
    int? endYear,
  }) async {
    try {
      final currentYear = DateTime.now().year;
      final actualEndYear = endYear ?? currentYear;
      
      AppLogger.debug('[WorldBankAPI] Fetching $countryCode:$indicatorCode for $startYear-$actualEndYear');
      
      final response = await _retryRequest(() async {
        return await _dio.get(
          '/country/$countryCode/indicator/$indicatorCode',
          queryParameters: {
            'format': 'json',
            'date': '$startYear:$actualEndYear',
            'per_page': 100,
            'page': 1,
          },
        );
      });

      if (response.data == null || response.data is! List) {
        AppLogger.warning('[WorldBankAPI] Invalid response format for $countryCode:$indicatorCode');
        return null;
      }

      final List<dynamic> responseData = response.data as List<dynamic>;
      
      // World Bank API는 첫 번째 요소에 메타데이터, 두 번째 요소에 데이터를 반환
      if (responseData.length < 2 || responseData[1] is! List) {
        AppLogger.warning('[WorldBankAPI] No data available for $countryCode:$indicatorCode');
        return null;
      }

      final List<dynamic> dataPoints = responseData[1] as List<dynamic>;
      if (dataPoints.isEmpty) {
        AppLogger.warning('[WorldBankAPI] Empty data for $countryCode:$indicatorCode');
        return null;
      }

      // 데이터 파싱
      final recentData = <IndicatorDataPoint>[];
      double? latestValue;
      int? latestYear;

      for (final point in dataPoints) {
        if (point is! Map<String, dynamic>) continue;
        
        final year = int.tryParse(point['date']?.toString() ?? '');
        final value = _parseDoubleValue(point['value']);
        
        if (year != null && value != null) {
          recentData.add(IndicatorDataPoint(year: year, value: value));
          
          // 가장 최신 데이터 추출
          if (latestYear == null || year > latestYear) {
            latestYear = year;
            latestValue = value;
          }
        }
      }

      if (recentData.isEmpty || latestValue == null || latestYear == null) {
        AppLogger.warning('[WorldBankAPI] No valid data points for $countryCode:$indicatorCode');
        return null;
      }

      // OECD 통계 계산
      final oecdStats = await _calculateOECDStats(indicatorCode, latestYear);
      final oecdRanking = await _calculateOECDRanking(
        indicatorCode, 
        countryCode, 
        latestValue, 
        latestYear,
      );

      // Core indicator 정보 가져오기
      final coreIndicator = CoreIndicators.findByCode(indicatorCode);
      
      // YoY 변화율 계산
      final yearOverYearChange = _calculateYearOverYearChange(recentData);

      return CountryIndicator(
        countryCode: countryCode,
        indicatorCode: indicatorCode,
        countryName: dataPoints.first['country']?['value'] ?? '',
        indicatorName: coreIndicator?.name ?? dataPoints.first['indicator']?['value'] ?? '',
        unit: coreIndicator?.unit ?? '',
        latestValue: latestValue,
        latestYear: latestYear,
        recentData: recentData..sort((a, b) => a.year.compareTo(b.year)),
        oecdRanking: oecdRanking?.ranking,
        oecdPercentile: oecdRanking?.percentile,
        oecdStats: oecdStats,
        yearOverYearChange: yearOverYearChange,
        updatedAt: DateTime.now(),
        dataBadge: _generateDataBadge(latestYear),
      );
    } catch (error, stackTrace) {
      AppLogger.error('[WorldBankAPI] Error fetching $countryCode:$indicatorCode: $error', stackTrace);
      return null;
    }
  }

  /// 지표별 OECD 38개국 데이터 수집 및 통계 계산
  Future<OECDStats?> _calculateOECDStats(String indicatorCode, int year) async {
    try {
      AppLogger.debug('[WorldBankAPI] Calculating OECD stats for $indicatorCode:$year');
      
      final values = <double>[];
      
      // OECD 38개국 데이터 병렬 수집
      final futures = _oecdCountryCodes.map((countryCode) async {
        try {
          final response = await _dio.get(
            '/country/$countryCode/indicator/$indicatorCode',
            queryParameters: {
              'format': 'json',
              'date': '$year:$year',
              'per_page': 10,
            },
          );
          
          if (response.data is List && response.data.length > 1) {
            final dataPoints = response.data[1] as List<dynamic>;
            if (dataPoints.isNotEmpty) {
              final value = _parseDoubleValue(dataPoints.first['value']);
              if (value != null) return value;
            }
          }
        } catch (e) {
          // 개별 국가 오류는 무시
        }
        return null;
      });
      
      final results = await Future.wait(futures);
      
      for (final result in results) {
        if (result != null) values.add(result);
      }
      
      if (values.length < 10) {
        AppLogger.warning('[WorldBankAPI] Insufficient OECD data for $indicatorCode ($year): ${values.length}/38');
        return null;
      }
      
      values.sort();
      
      final median = _calculateMedian(values);
      final q1 = _calculatePercentile(values, 0.25);
      final q3 = _calculatePercentile(values, 0.75);
      final min = values.first;
      final max = values.last;
      final mean = values.reduce((a, b) => a + b) / values.length;
      
      AppLogger.debug('[WorldBankAPI] OECD stats calculated: median=$median, n=${values.length}');
      
      return OECDStats(
        median: median,
        q1: q1,
        q3: q3,
        min: min,
        max: max,
        mean: mean,
        totalCountries: values.length,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[WorldBankAPI] Error calculating OECD stats: $error', stackTrace);
      return null;
    }
  }

  /// 특정 국가의 OECD 순위 계산
  Future<({int ranking, double percentile})?> _calculateOECDRanking(
    String indicatorCode,
    String countryCode,
    double countryValue,
    int year,
  ) async {
    try {
      final oecdValues = <({String country, double value})>[];
      
      // OECD 데이터 수집
      for (final code in _oecdCountryCodes) {
        try {
          final response = await _dio.get(
            '/country/$code/indicator/$indicatorCode',
            queryParameters: {
              'format': 'json',
              'date': '$year:$year',
              'per_page': 5,
            },
          );
          
          if (response.data is List && response.data.length > 1) {
            final dataPoints = response.data[1] as List<dynamic>;
            if (dataPoints.isNotEmpty) {
              final value = _parseDoubleValue(dataPoints.first['value']);
              if (value != null) {
                oecdValues.add((country: code, value: value));
              }
            }
          }
        } catch (e) {
          // 개별 오류 무시
        }
      }
      
      if (oecdValues.length < 10) {
        AppLogger.warning('[WorldBankAPI] Insufficient ranking data: ${oecdValues.length}/38');
        return null;
      }
      
      // Core indicator 방향성 확인
      final coreIndicator = CoreIndicators.findByCode(indicatorCode);
      final isPositiveIndicator = coreIndicator?.isPositive ?? true;
      
      // 정렬 (높은 값이 좋은 경우 내림차순, 낮은 값이 좋은 경우 오름차순)
      oecdValues.sort((a, b) => isPositiveIndicator 
          ? b.value.compareTo(a.value) 
          : a.value.compareTo(b.value));
      
      // 순위 계산
      int ranking = 1;
      for (int i = 0; i < oecdValues.length; i++) {
        if (oecdValues[i].country == countryCode) {
          ranking = i + 1;
          break;
        }
        // 해당 국가가 OECD에 없는 경우, 값으로 순위 추정
        if (isPositiveIndicator ? countryValue > oecdValues[i].value : countryValue < oecdValues[i].value) {
          ranking = i + 1;
          break;
        }
        if (i == oecdValues.length - 1) {
          ranking = oecdValues.length + 1;
        }
      }
      
      final percentile = ((oecdValues.length - ranking + 1) / oecdValues.length) * 100;
      
      return (ranking: ranking, percentile: percentile);
    } catch (error, stackTrace) {
      AppLogger.error('[WorldBankAPI] Error calculating ranking: $error', stackTrace);
      return null;
    }
  }

  /// HTTP 요청 재시도 로직
  Future<Response<T>> _retryRequest<T>(Future<Response<T>> Function() request) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        return await request();
      } catch (error) {
        attempts++;
        if (attempts >= _maxRetries) rethrow;
        
        AppLogger.warning('[WorldBankAPI] Request failed (attempt $attempts), retrying...');
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// 유틸리티 메서드들
  double? _parseDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _calculateMedian(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final n = sorted.length;
    return n.isOdd 
        ? sorted[n ~/ 2] 
        : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
  }

  double _calculatePercentile(List<double> values, double percentile) {
    final sorted = List<double>.from(values)..sort();
    final index = percentile * (sorted.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    
    if (lower == upper) {
      return sorted[lower];
    }
    
    final weight = index - lower;
    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
  }

  double? _calculateYearOverYearChange(List<IndicatorDataPoint> data) {
    if (data.length < 2) return null;
    
    final sortedData = List<IndicatorDataPoint>.from(data)
        ..sort((a, b) => b.year.compareTo(a.year)); // 최신순
    
    final latest = sortedData.first.value;
    final previous = sortedData[1].value;
    
    if (previous == 0) return null;
    return ((latest - previous) / previous) * 100;
  }

  String? _generateDataBadge(int year) {
    final currentYear = DateTime.now().year;
    final diff = currentYear - year;
    
    if (diff <= 1) return 'Latest';
    if (diff <= 2) return 'Recent';
    return 'Outdated';
  }
}