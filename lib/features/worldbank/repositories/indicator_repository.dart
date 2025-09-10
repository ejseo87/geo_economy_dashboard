import 'package:geo_economy_dashboard/common/logger.dart';

import '../models/indicator_codes.dart';
import '../models/cached_indicator_data.dart';
import '../services/worldbank_api_client.dart';
import '../services/firestore_cache_service.dart';
import '../../home/models/indicator_comparison.dart';

/// 지표 데이터 Repository (캐싱 전략 포함)
class IndicatorRepository {
  final WorldBankApiClient _apiClient;
  final FirestoreCacheService _cacheService;

  IndicatorRepository({
    WorldBankApiClient? apiClient,
    FirestoreCacheService? cacheService,
  }) : _apiClient = apiClient ?? WorldBankApiClient(),
       _cacheService = cacheService ?? FirestoreCacheService();

  /// 특정 국가의 지표 데이터 조회 (캐시 우선)
  Future<CachedIndicatorData?> getIndicatorData({
    required String countryCode,
    required IndicatorCode indicatorCode,
    bool forceRefresh = false,
  }) async {
    final indicatorCodeStr = indicatorCode.code;

    // 1. 강제 새로고침이 아닌 경우 캐시 확인
    if (!forceRefresh) {
      final cached = await _cacheService.getCachedIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCodeStr,
      );

      if (cached != null &&
          !cached.isExpired(indicatorCode.updateFrequencyDays)) {
        AppLogger.debug(
          '[Repository] Using cached data: $countryCode/$indicatorCodeStr',
        );
        return cached;
      }
    }

    // 2. API에서 새 데이터 가져오기
    try {
      AppLogger.debug(
        '[Repository] Fetching from API: $countryCode/$indicatorCodeStr',
      );
      final currentYear = DateTime.now().year;
      final endYear = currentYear - 1; // 작년까지의 데이터
      final apiData = await _apiClient.getIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCodeStr,
        dateRange: '2010:$endYear', // 최근 15년 데이터
      );

      // 3. 캐시에 저장
      if (apiData.isNotEmpty) {
        await _cacheService.cacheIndicatorData(
          countryCode: countryCode,
          indicatorCode: indicatorCodeStr,
          data: apiData,
        );

        // 4. 저장된 캐시 데이터 반환
        return await _cacheService.getCachedIndicatorData(
          countryCode: countryCode,
          indicatorCode: indicatorCodeStr,
        );
      }

      return null;
    } on WorldBankApiException catch (e) {
      AppLogger.error('[Repository] API Error: $e');

      // API 오류 시 만료된 캐시라도 반환
      final cached = await _cacheService.getCachedIndicatorData(
        countryCode: countryCode,
        indicatorCode: indicatorCodeStr,
      );

      if (cached != null) {
        AppLogger.debug('[Repository] Using stale cache due to API error');
        return cached;
      }

      rethrow;
    }
  }

  /// OECD 국가들의 특정 지표 데이터 조회 및 통계 계산
  Future<OECDStatistics> getOECDStatistics({
    required IndicatorCode indicatorCode,
    int? year,
    bool forceRefresh = false,
  }) async {
    final indicatorCodeStr = indicatorCode.code;
    final currentYear = DateTime.now().year;
    final targetYear = year ?? (currentYear - 1); // 기본값을 작년으로 동적 설정

    // 1. 캐시된 OECD 통계 확인
    if (!forceRefresh) {
      final cachedStats = await _cacheService.getCachedOECDStats(
        indicatorCode: indicatorCodeStr,
        year: targetYear,
      );

      if (cachedStats != null && !cachedStats.isExpired) {
        AppLogger.debug(
          '[Repository] Using cached OECD stats: $indicatorCodeStr/$targetYear',
        );
        return OECDStatistics(
          median: cachedStats.median,
          q1: cachedStats.q1,
          q3: cachedStats.q3,
          min: cachedStats.min,
          max: cachedStats.max,
          mean: cachedStats.mean,
          totalCountries: cachedStats.totalCountries,
          countryRankings: null, // 캐시에서는 순위 정보 없음, 근사치 계산 사용
        );
      }
    }

    // 2. OECD 국가들의 데이터 수집
    AppLogger.debug(
      '[Repository] Calculating OECD stats: $indicatorCodeStr/$targetYear',
    );
    final values = <double>[];
    final validCountries = <String>[];

    for (final countryCode in IndicatorCode.oecdCountries) {
      try {
        final data = await getIndicatorData(
          countryCode: countryCode,
          indicatorCode: indicatorCode,
          forceRefresh: false, // 개별 국가 데이터는 캐시 우선
        );

        final value = data?.getValueForYear(targetYear);
        if (value != null && value.isFinite) {
          values.add(value);
          validCountries.add(countryCode);
        }
      } catch (e) {
        AppLogger.error('[Repository] Failed to get data for $countryCode: $e');
        // 개별 국가 오류는 무시하고 계속 진행
      }
    }

    if (values.isEmpty) {
      throw Exception(
        'No valid data found for $indicatorCodeStr in $targetYear',
      );
    }

    // 3. 통계 계산
    final stats = _calculateStatistics(values, validCountries, indicatorCode);

    // 4. 계산된 통계를 캐시에 저장
    final cachedStats = CachedOECDStats(
      id: CachedOECDStats.generateId(indicatorCodeStr, targetYear),
      indicatorCode: indicatorCodeStr,
      year: targetYear,
      median: stats.median,
      q1: stats.q1,
      q3: stats.q3,
      min: stats.min,
      max: stats.max,
      mean: stats.mean,
      totalCountries: stats.totalCountries,
      countriesIncluded: validCountries,
      calculatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(
        Duration(days: indicatorCode.updateFrequencyDays),
      ),
    );

    await _cacheService.cacheOECDStats(cachedStats);

    return stats;
  }

  /// 특정 국가와 유사국들의 지표 비교 데이터 생성
  Future<IndicatorComparison> generateIndicatorComparison({
    required IndicatorCode indicatorCode,
    String? countryCode,
    int? year,
  }) async {
    // 최신 데이터가 있는 년도를 찾기 위해 몇 년도 시도
    final currentYear = DateTime.now().year;
    final candidateYears = year != null
        ? [year]
        : [currentYear - 1, currentYear - 2, currentYear - 3, currentYear - 4]; // 작년부터 4년 전까지 시도
    final indicatorCodeStr = indicatorCode.code;
    final targetCountryCode = countryCode ?? 'KOR';

    // 1. 선택된 국가 데이터 조회 및 사용 가능한 최신 년도 찾기
    final countryData = await getIndicatorData(
      countryCode: targetCountryCode,
      indicatorCode: indicatorCode,
    );

    double? countryValue;
    int? targetYear;

    // 후보 년도들 중에서 데이터가 있는 가장 최신 년도 찾기
    for (final candidateYear in candidateYears) {
      final value = countryData?.getValueForYear(candidateYear);
      if (value != null && value.isFinite) {
        countryValue = value;
        targetYear = candidateYear;
        break;
      }
    }

    if (countryValue == null || targetYear == null) {
      throw Exception(
        'No $targetCountryCode data found for $indicatorCodeStr in recent years: ${candidateYears.join(', ')}',
      );
    }

    AppLogger.debug(
      '[Repository] Using data from year $targetYear for $indicatorCodeStr',
    );

    // 2. OECD 통계 조회
    final oecdStats = await getOECDStatistics(
      indicatorCode: indicatorCode,
      year: targetYear,
    );

    // 3. 유사국 데이터 조회
    final similarCountryCodes =
        IndicatorCode.similarCountries[targetCountryCode] ??
        ['JPN', 'DEU', 'FRA'];
    final similarCountries = <CountryData>[];

    for (final countryCode in similarCountryCodes.take(3)) {
      try {
        final countryData = await getIndicatorData(
          countryCode: countryCode,
          indicatorCode: indicatorCode,
        );

        final value = countryData?.getValueForYear(targetYear);
        if (value != null) {
          // 실제 순위 계산
          final rank = oecdStats.getRankForCountry(countryCode) ??
              oecdStats.calculateRankForValue(
                value,
                indicatorCode.direction == IndicatorDirection.higher,
              );

          similarCountries.add(
            CountryData(
              countryCode: countryCode,
              countryName: _getCountryName(countryCode),
              value: value,
              rank: rank,
              flagEmoji: _getCountryFlag(countryCode),
            ),
          );
        }
      } catch (e) {
        AppLogger.error(
          '[Repository] Failed to get similar country data for $countryCode: $e',
        );
      }
    }

    // 4. 선택된 국가 성과 분석
    final performance = _getPerformanceLevel(
      countryValue,
      oecdStats,
      indicatorCode.direction,
    );
    final countryRank = oecdStats.getRankForCountry(targetCountryCode) ??
        oecdStats.calculateRankForValue(
          countryValue,
          indicatorCode.direction == IndicatorDirection.higher,
        );

    // 5. 인사이트 생성
    final insight = _generateInsight(
      countryValue: countryValue,
      countryCode: targetCountryCode,
      oecdStats: oecdStats,
      performance: performance,
      indicatorCode: indicatorCode,
      countryRank: countryRank,
    );

    return IndicatorComparison(
      indicatorCode: indicatorCodeStr,
      indicatorName: indicatorCode.name,
      unit: indicatorCode.unit,
      year: targetYear,
      selectedCountry: CountryData(
        countryCode: targetCountryCode,
        countryName: _getCountryName(targetCountryCode),
        value: countryValue,
        rank: countryRank,
        flagEmoji: _getCountryFlag(targetCountryCode),
      ),
      oecdStats: oecdStats,
      similarCountries: similarCountries,
      insight: insight,
    );
  }

  /// 통계 계산 헬퍼 메서드 (순위 정보 포함)
  OECDStatistics _calculateStatistics(
    List<double> values,
    List<String> validCountries,
    IndicatorCode indicatorCode,
  ) {
    if (values.isEmpty || validCountries.isEmpty) {
      throw ArgumentError('Values and countries lists cannot be empty');
    }

    // 값과 국가코드를 함께 묶어서 정렬
    final countryValuePairs = <Map<String, dynamic>>[];
    for (int i = 0; i < values.length; i++) {
      countryValuePairs.add({
        'countryCode': validCountries[i],
        'value': values[i],
      });
    }

    // 지표 방향에 따라 정렬 (높을수록 좋은 지표는 내림차순, 낮을수록 좋은 지표는 오름차순)
    final higherIsBetter = indicatorCode.direction == IndicatorDirection.higher;
    countryValuePairs.sort((a, b) {
      final aValue = a['value'] as double;
      final bValue = b['value'] as double;
      return higherIsBetter ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
    });

    // 순위 정보 생성
    final countryRankings = <CountryRankingData>[];
    for (int i = 0; i < countryValuePairs.length; i++) {
      final pair = countryValuePairs[i];
      countryRankings.add(
        CountryRankingData(
          countryCode: pair['countryCode'] as String,
          countryName: _getCountryName(pair['countryCode'] as String),
          value: pair['value'] as double,
          rank: i + 1, // 순위는 1부터 시작
        ),
      );
    }

    // 통계 계산용 값들 (정렬된 순서)
    final sortedValues = countryValuePairs
        .map((pair) => pair['value'] as double)
        .toList();
    sortedValues.sort(); // 통계 계산을 위해 오름차순으로 다시 정렬

    final length = sortedValues.length;

    // 백분위수 계산
    final q1Index = (length * 0.25).floor();
    final medianIndex = (length * 0.5).floor();
    final q3Index = (length * 0.75).floor();

    final q1 = length > 1 ? sortedValues[q1Index] : sortedValues[0];
    final median = length > 1 ? sortedValues[medianIndex] : sortedValues[0];
    final q3 = length > 1 ? sortedValues[q3Index] : sortedValues[0];

    final sum = sortedValues.reduce((a, b) => a + b);
    final mean = sum / length;

    return OECDStatistics(
      median: median,
      q1: q1,
      q3: q3,
      min: sortedValues.first,
      max: sortedValues.last,
      mean: mean,
      totalCountries: length,
      countryRankings: countryRankings,
    );
  }

  /// 성과 레벨 계산
  PerformanceLevel _getPerformanceLevel(
    double value,
    OECDStatistics stats,
    IndicatorDirection direction,
  ) {
    switch (direction) {
      case IndicatorDirection.higher:
        // 높을수록 좋은 지표
        if (value >= stats.q3) return PerformanceLevel.excellent;
        if (value >= stats.median) return PerformanceLevel.good;
        if (value >= stats.q1) return PerformanceLevel.average;
        return PerformanceLevel.poor;

      case IndicatorDirection.lower:
        // 낮을수록 좋은 지표
        if (value <= stats.q1) return PerformanceLevel.excellent;
        if (value <= stats.median) return PerformanceLevel.good;
        if (value <= stats.q3) return PerformanceLevel.average;
        return PerformanceLevel.poor;

      case IndicatorDirection.neutral:
        // 중립적 지표 (미디안 근처가 좋음)
        final distanceFromMedian = (value - stats.median).abs();
        final iqr = stats.q3 - stats.q1;

        if (distanceFromMedian <= iqr * 0.25) return PerformanceLevel.excellent;
        if (distanceFromMedian <= iqr * 0.5) return PerformanceLevel.good;
        if (distanceFromMedian <= iqr) return PerformanceLevel.average;
        return PerformanceLevel.poor;
    }
  }


  /// 인사이트 생성
  ComparisonInsight _generateInsight({
    required double countryValue,
    required String countryCode,
    required OECDStatistics oecdStats,
    required PerformanceLevel performance,
    required IndicatorCode indicatorCode,
    required int countryRank,
  }) {
    final countryName = _getCountryName(countryCode);
    final medianDiff = countryValue - oecdStats.median;
    final percentile = oecdStats.calculatePercentile(countryValue);

    String summary;
    switch (performance) {
      case PerformanceLevel.excellent:
        summary = '$countryName의 ${indicatorCode.name}은 OECD 최상위 수준입니다.';
        break;
      case PerformanceLevel.good:
        summary = '$countryName의 ${indicatorCode.name}은 OECD 평균보다 우수합니다.';
        break;
      case PerformanceLevel.average:
        summary = '$countryName의 ${indicatorCode.name}은 OECD 평균 수준입니다.';
        break;
      case PerformanceLevel.poor:
        summary = '$countryName의 ${indicatorCode.name}은 OECD 평균보다 낮습니다.';
        break;
    }

    final detailedAnalysis =
        '''
$countryName의 ${indicatorCode.name} ${countryValue.toStringAsFixed(1)}${indicatorCode.unit}는 
OECD 미디안 ${oecdStats.median.toStringAsFixed(1)}${indicatorCode.unit}와 비교하여 
${medianDiff >= 0 ? '+' : ''}${medianDiff.toStringAsFixed(1)}${indicatorCode.unit} 차이를 보이며,
${oecdStats.totalCountries}개국 중 $countryRank위(상위 ${(100 - percentile).toStringAsFixed(1)}%)를 기록했습니다.
    '''
            .trim();

    final keyFindings = <String>[
      'OECD 미디안 대비 ${medianDiff >= 0 ? '+' : ''}${medianDiff.toStringAsFixed(1)}${indicatorCode.unit}',
      '${oecdStats.totalCountries}개국 중 $countryRank위',
      '상위 ${(100 - percentile).toStringAsFixed(1)}% 수준',
    ];

    // IQR 범위를 벗어나는 경우 이상치로 판단
    final iqr = oecdStats.q3 - oecdStats.q1;
    final isOutlier =
        countryValue < (oecdStats.q1 - 1.5 * iqr) ||
        countryValue > (oecdStats.q3 + 1.5 * iqr);

    return ComparisonInsight(
      performance: performance,
      summary: summary,
      detailedAnalysis: detailedAnalysis,
      keyFindings: keyFindings,
      isOutlier: isOutlier,
    );
  }

  /// 국가명 반환
  String _getCountryName(String countryCode) {
    const countryNames = {
      'AUS': '호주',
      'AUT': '오스트리아',
      'BEL': '벨기에',
      'CAN': '캐나다',
      'CHL': '칠레',
      'COL': '콜롬비아',
      'CRI': '코스타리카',
      'CZE': '체코',
      'DNK': '덴마크',
      'EST': '에스토니아',
      'FIN': '핀란드',
      'FRA': '프랑스',
      'DEU': '독일',
      'GRC': '그리스',
      'HUN': '헝가리',
      'ISL': '아이슬란드',
      'IRL': '아일랜드',
      'ISR': '이스라엘',
      'ITA': '이탈리아',
      'JPN': '일본',
      'KOR': '대한민국',
      'LVA': '라트비아',
      'LTU': '리투아니아',
      'LUX': '룩셈부르크',
      'MEX': '멕시코',
      'NLD': '네덜란드',
      'NZL': '뉴질랜드',
      'NOR': '노르웨이',
      'POL': '폴란드',
      'PRT': '포르투갈',
      'SVK': '슬로바키아',
      'SVN': '슬로베니아',
      'ESP': '스페인',
      'SWE': '스웨덴',
      'CHE': '스위스',
      'TUR': '튀르키예',
      'GBR': '영국',
      'USA': '미국',
    };
    return countryNames[countryCode] ?? countryCode;
  }

  /// 국기 이모지 반환
  String _getCountryFlag(String countryCode) {
    const countryFlags = {
      'AUS': '🇦🇺',
      'AUT': '🇦🇹',
      'BEL': '🇧🇪',
      'CAN': '🇨🇦',
      'CHL': '🇨🇱',
      'COL': '🇨🇴',
      'CRI': '🇨🇷',
      'CZE': '🇨🇿',
      'DNK': '🇩🇰',
      'EST': '🇪🇪',
      'FIN': '🇫🇮',
      'FRA': '🇫🇷',
      'DEU': '🇩🇪',
      'GRC': '🇬🇷',
      'HUN': '🇭🇺',
      'ISL': '🇮🇸',
      'IRL': '🇮🇪',
      'ISR': '🇮🇱',
      'ITA': '🇮🇹',
      'JPN': '🇯🇵',
      'KOR': '🇰🇷',
      'LVA': '🇱🇻',
      'LTU': '🇱🇹',
      'LUX': '🇱🇺',
      'MEX': '🇲🇽',
      'NLD': '🇳🇱',
      'NZL': '🇳🇿',
      'NOR': '🇳🇴',
      'POL': '🇵🇱',
      'PRT': '🇵🇹',
      'SVK': '🇸🇰',
      'SVN': '🇸🇮',
      'ESP': '🇪🇸',
      'SWE': '🇸🇪',
      'CHE': '🇨🇭',
      'TUR': '🇹🇷',
      'GBR': '🇬🇧',
      'USA': '🇺🇸',
    };
    return countryFlags[countryCode] ?? '🏳️';
  }

  /// 리소스 정리
  void dispose() {
    _apiClient.dispose();
  }
}
