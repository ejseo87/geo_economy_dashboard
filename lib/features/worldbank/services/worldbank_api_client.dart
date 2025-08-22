import 'package:dio/dio.dart';
import 'package:geo_economy_dashboard/common/logger.dart';
import '../models/worldbank_response.dart';
import '../models/indicator_codes.dart';

/// World Bank API 클라이언트
class WorldBankApiClient {
  static const String baseUrl = 'https://api.worldbank.org/v2';
  
  final Dio _dio;

  WorldBankApiClient({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  static Dio _createDefaultDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'GeoEconomyDashboard/1.0',
      },
    ));

    // 로깅 인터셉터 추가 (디버그 모드에서만)
    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (obj) => AppLogger.debug('[WorldBank API] $obj'),
    ));

    // 에러 처리 인터셉터
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        AppLogger.error('[WorldBank API Error] ${error.message}');
        handler.next(error);
      },
    ));

    return dio;
  }

  /// 특정 국가의 지표 데이터 조회
  /// 
  /// [countryCode] ISO3 국가 코드 (예: 'KOR', 'USA')
  /// [indicatorCode] 지표 코드 (예: 'NY.GDP.MKTP.KD.ZG')
  /// [dateRange] 날짜 범위 (예: '2018:2023', '2020')
  /// [perPage] 페이지당 결과 수 (기본값: 100)
  Future<List<WorldBankIndicatorData>> getIndicatorData({
    required String countryCode,
    required String indicatorCode,
    String? dateRange,
    int perPage = 100,
  }) async {
    try {
      final path = '/country/$countryCode/indicator/$indicatorCode';
      final queryParams = {
        'format': 'json',
        'per_page': perPage.toString(),
        if (dateRange != null) 'date': dateRange,
      };

      final response = await _dio.get(path, queryParameters: queryParams);
      
      if (response.data == null || response.data is! List) {
        throw WorldBankApiException('Invalid response format');
      }

      final apiResponse = WorldBankApiResponse.fromJson(response.data);
      return apiResponse.data;
    } on DioException catch (e) {
      throw WorldBankApiException.fromDioError(e);
    } catch (e) {
      throw WorldBankApiException('Unexpected error: $e');
    }
  }

  /// 여러 국가의 동일 지표 데이터 조회 (OECD 비교용)
  /// 
  /// [countryCodes] 국가 코드 리스트
  /// [indicatorCode] 지표 코드
  /// [year] 특정 연도 (기본값: 최신년도)
  Future<List<WorldBankIndicatorData>> getMultiCountryIndicatorData({
    required List<String> countryCodes,
    required String indicatorCode,
    String? year,
    int perPage = 500,
  }) async {
    try {
      final countryString = countryCodes.join(';');
      final path = '/country/$countryString/indicator/$indicatorCode';
      final queryParams = {
        'format': 'json',
        'per_page': perPage.toString(),
        if (year != null) 'date': year,
        'mrnev': '1', // 가장 최신 값 우선
      };

      final response = await _dio.get(path, queryParameters: queryParams);
      
      if (response.data == null || response.data is! List) {
        throw WorldBankApiException('Invalid response format');
      }

      final apiResponse = WorldBankApiResponse.fromJson(response.data);
      return apiResponse.data;
    } on DioException catch (e) {
      throw WorldBankApiException.fromDioError(e);
    } catch (e) {
      throw WorldBankApiException('Unexpected error: $e');
    }
  }

  /// OECD 38개국의 특정 지표 데이터 조회
  Future<List<WorldBankIndicatorData>> getOECDIndicatorData({
    required String indicatorCode,
    String? year,
  }) async {
    return getMultiCountryIndicatorData(
      countryCodes: IndicatorCode.oecdCountries,
      indicatorCode: indicatorCode,
      year: year,
    );
  }

  /// 국가 메타데이터 조회
  Future<List<WorldBankCountry>> getCountries({
    List<String>? countryCodes,
    int perPage = 300,
  }) async {
    try {
      final path = countryCodes != null 
          ? '/country/${countryCodes.join(';')}'
          : '/country';
      
      final queryParams = {
        'format': 'json',
        'per_page': perPage.toString(),
      };

      final response = await _dio.get(path, queryParameters: queryParams);
      
      if (response.data == null || response.data is! List || response.data.length < 2) {
        throw WorldBankApiException('Invalid response format');
      }

      final dataList = response.data[1] as List<dynamic>;
      return dataList
          .where((item) => item != null)
          .map((item) => WorldBankCountry.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw WorldBankApiException.fromDioError(e);
    } catch (e) {
      throw WorldBankApiException('Unexpected error: $e');
    }
  }

  /// 지표 메타데이터 조회
  Future<List<WorldBankIndicatorMeta>> getIndicatorMetadata({
    List<String>? indicatorCodes,
    int perPage = 100,
  }) async {
    try {
      final path = indicatorCodes != null 
          ? '/indicator/${indicatorCodes.join(';')}'
          : '/indicator';
      
      final queryParams = {
        'format': 'json',
        'per_page': perPage.toString(),
      };

      final response = await _dio.get(path, queryParameters: queryParams);
      
      if (response.data == null || response.data is! List || response.data.length < 2) {
        throw WorldBankApiException('Invalid response format');
      }

      final dataList = response.data[1] as List<dynamic>;
      return dataList
          .where((item) => item != null)
          .map((item) => WorldBankIndicatorMeta.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw WorldBankApiException.fromDioError(e);
    } catch (e) {
      throw WorldBankApiException('Unexpected error: $e');
    }
  }

  /// 리소스 정리
  void dispose() {
    _dio.close();
  }
}

/// World Bank API 예외 클래스
class WorldBankApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  WorldBankApiException(this.message, {this.statusCode, this.errorCode});

  factory WorldBankApiException.fromDioError(DioException dioError) {
    String message;
    int? statusCode = dioError.response?.statusCode;

    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout. The server is taking too long to respond.';
        break;
      case DioExceptionType.badResponse:
        message = 'Server error ($statusCode). ${dioError.message}';
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error. Please check your internet connection.';
        break;
      case DioExceptionType.unknown:
      default:
        message = 'Unknown error occurred: ${dioError.message}';
        break;
    }

    return WorldBankApiException(
      message,
      statusCode: statusCode,
      errorCode: dioError.type.name,
    );
  }

  @override
  String toString() => 'WorldBankApiException: $message';
}