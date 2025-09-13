import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/logger.dart';
import '../../worldbank/models/indicator_codes.dart';

/// World Bank API 데이터 수집 서비스
class WorldBankDataCollector {
  static const String _baseUrl = 'https://api.worldbank.org/v2';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  /// OECD 국가 코드 목록
  static const List<String> _oecdCountries = [
    'AUS',
    'AUT',
    'BEL',
    'CAN',
    'CHL',
    'COL',
    'CRI',
    'CZE',
    'DNK',
    'EST',
    'FIN',
    'FRA',
    'DEU',
    'GRC',
    'HUN',
    'ISL',
    'IRL',
    'ISR',
    'ITA',
    'JPN',
    'KOR',
    'LVA',
    'LTU',
    'LUX',
    'MEX',
    'NLD',
    'NZL',
    'NOR',
    'POL',
    'PRT',
    'SVK',
    'SVN',
    'ESP',
    'SWE',
    'CHE',
    'TUR',
    'GBR',
    'USA',
  ];

  /// 테스트용 제한된 데이터 수집 (3개국 × 3개 지표)
  Future<Map<String, dynamic>> collectTestData({
    int startYear = 2020,
    int? endYear,
    Function(String)? onProgress,
  }) async {
    final actualEndYear = endYear ?? DateTime.now().year;
    final results = <String, dynamic>{
      'startTime': DateTime.now().toIso8601String(),
      'indicators': <String, dynamic>{},
      'errors': <String>[],
      'totalProcessed': 0,
      'successfullyProcessed': 0,
    };

    try {
      // 테스트용: 3개 지표만
      final testIndicators = [
        IndicatorCode.gdpRealGrowth,
        IndicatorCode.unemployment,
        IndicatorCode.cpiInflation,
      ];

      // 테스트용: 3개 국가만 
      final testCountries = ['KOR', 'USA', 'JPN'];

      for (final indicator in testIndicators) {
        onProgress?.call('테스트 수집: ${indicator.name}');
        AppLogger.info('[TEST] Starting collection for ${indicator.name}');

        final indicatorResult = await _collectIndicatorDataForCountries(
          indicator,
          testCountries,
          startYear,
          actualEndYear,
        );

        results['indicators'][indicator.code] = indicatorResult;
        results['totalProcessed'] = (results['totalProcessed'] as int) + 1;

        if (indicatorResult['success'] == true) {
          results['successfullyProcessed'] =
              (results['successfullyProcessed'] as int) + 1;
          AppLogger.info('[TEST] Success: ${indicator.name} - ${indicatorResult['dataPoints']} points');
        } else {
          results['errors'].add(
            '${indicator.name}: ${indicatorResult['error']}',
          );
          AppLogger.error('[TEST] Failed: ${indicator.name} - ${indicatorResult['error']}');
        }

        // 더 긴 지연으로 API 제한 방지
        await Future.delayed(Duration(seconds: 1));
      }

      results['endTime'] = DateTime.now().toIso8601String();
      AppLogger.info(
        '[TEST] Collection completed: ${results['successfullyProcessed']}/${results['totalProcessed']} indicators',
      );
    } catch (e) {
      results['error'] = e.toString();
      AppLogger.error('[TEST] Collection failed: $e');
    }

    return results;
  }

  /// 모든 지표 데이터 수집
  Future<Map<String, dynamic>> collectAllIndicatorData({
    int startYear = 2015,
    int? endYear,
    Function(String)? onProgress,
  }) async {
    final actualEndYear = endYear ?? DateTime.now().year;
    final results = <String, dynamic>{
      'startTime': DateTime.now().toIso8601String(),
      'indicators': <String, dynamic>{},
      'errors': <String>[],
      'totalProcessed': 0,
      'successfullyProcessed': 0,
    };

    try {
      final allIndicators = [
        IndicatorCode.gdpRealGrowth,
        IndicatorCode.gdpPppPerCapita,
        IndicatorCode.manufShare,
        IndicatorCode.grossFixedCapital,
        IndicatorCode.cpiInflation,
        IndicatorCode.m2Money,
        IndicatorCode.unemployment,
        IndicatorCode.laborParticipation,
        IndicatorCode.employmentRate,
        IndicatorCode.govExpenditure,
        IndicatorCode.taxRevenue,
        IndicatorCode.govDebt,
        IndicatorCode.currentAccount,
        IndicatorCode.exportsShare,
        IndicatorCode.importsShare,
        IndicatorCode.reservesMonths,
        IndicatorCode.gini,
        IndicatorCode.povertyNat,
        IndicatorCode.co2PerCapita,
        IndicatorCode.renewablesShare,
      ];

      for (final indicator in allIndicators) {
        onProgress?.call('수집 중: ${indicator.name}');

        final indicatorResult = await _collectIndicatorData(
          indicator,
          startYear,
          actualEndYear,
        );

        results['indicators'][indicator.code] = indicatorResult;
        results['totalProcessed'] = (results['totalProcessed'] as int) + 1;

        if (indicatorResult['success'] == true) {
          results['successfullyProcessed'] =
              (results['successfullyProcessed'] as int) + 1;
        } else {
          results['errors'].add(
            '${indicator.name}: ${indicatorResult['error']}',
          );
        }

        // API 호출 제한을 위한 지연
        await Future.delayed(Duration(milliseconds: 500));
      }

      results['endTime'] = DateTime.now().toIso8601String();
      AppLogger.info(
        '[WorldBankDataCollector] Collection completed: ${results['successfullyProcessed']}/${results['totalProcessed']} indicators',
      );
    } catch (e) {
      results['error'] = e.toString();
      AppLogger.error('[WorldBankDataCollector] Collection failed: $e');
    }

    return results;
  }

  /// 특정 국가들만 대상으로 지표 데이터 수집
  Future<Map<String, dynamic>> _collectIndicatorDataForCountries(
    IndicatorCode indicator,
    List<String> countries,
    int startYear,
    int endYear,
  ) async {
    final result = <String, dynamic>{
      'success': false,
      'dataPoints': 0,
      'countries': <String, dynamic>{},
    };

    try {
      AppLogger.debug('[WorldBankDataCollector] Collecting ${indicator.name} for ${countries.length} countries');

      for (final countryCode in countries) {
        AppLogger.debug('[WorldBankDataCollector] Fetching $countryCode data for ${indicator.name}');
        
        final countryData = await _fetchCountryData(
          countryCode,
          indicator.code,
          startYear,
          endYear,
        );

        if (countryData.isNotEmpty) {
          result['countries'][countryCode] = countryData;
          result['dataPoints'] = (result['dataPoints'] as int) + countryData.length;
          AppLogger.debug('[WorldBankDataCollector] $countryCode: ${countryData.length} data points');
        } else {
          AppLogger.warning('[WorldBankDataCollector] No data for $countryCode/${indicator.code}');
        }

        // 각 국가마다 더 긴 지연
        await Future.delayed(Duration(milliseconds: 500));
      }

      // OECD 순위 계산 및 Firestore에 저장
      if (result['countries'].isNotEmpty) {
        AppLogger.debug('[WorldBankDataCollector] Calculating OECD rankings for ${indicator.name}...');
        final enrichedCountries = await _calculateOECDRankings(
          indicator, 
          result['countries'] as Map<String, dynamic>
        );
        
        AppLogger.debug('[WorldBankDataCollector] Saving ${indicator.name} with rankings to Firestore...');
        await _saveIndicatorDataToFirestore(indicator, enrichedCountries);
        AppLogger.info('[WorldBankDataCollector] Successfully saved ${indicator.name} with OECD rankings');
      }

      result['success'] = true;
      AppLogger.info(
        '[WorldBankDataCollector] ${indicator.name}: ${result['dataPoints']} data points collected',
      );
    } catch (e, stackTrace) {
      result['error'] = e.toString();
      AppLogger.error(
        '[WorldBankDataCollector] Failed to collect ${indicator.name}: $e',
        stackTrace,
      );
    }

    return result;
  }

  /// 특정 지표 데이터 수집 (모든 OECD 국가)
  Future<Map<String, dynamic>> _collectIndicatorData(
    IndicatorCode indicator,
    int startYear,
    int endYear,
  ) async {
    final result = <String, dynamic>{
      'success': false,
      'dataPoints': 0,
      'countries': <String, dynamic>{},
    };

    try {
      AppLogger.debug('[WorldBankDataCollector] Collecting ${indicator.name}');

      for (final countryCode in _oecdCountries) {
        final countryData = await _fetchCountryData(
          countryCode,
          indicator.code,
          startYear,
          endYear,
        );

        if (countryData.isNotEmpty) {
          result['countries'][countryCode] = countryData;
          result['dataPoints'] =
              (result['dataPoints'] as int) + countryData.length;
        }

        // 각 국가마다 작은 지연
        await Future.delayed(Duration(milliseconds: 100));
      }

      // OECD 순위 계산 및 Firestore에 저장
      if (result['countries'].isNotEmpty) {
        AppLogger.debug('[WorldBankDataCollector] Calculating OECD rankings for ${indicator.name}...');
        final enrichedCountries = await _calculateOECDRankings(
          indicator, 
          result['countries'] as Map<String, dynamic>
        );
        
        AppLogger.debug('[WorldBankDataCollector] Saving ${indicator.name} with rankings to Firestore...');
        await _saveIndicatorDataToFirestore(indicator, enrichedCountries);
        AppLogger.info('[WorldBankDataCollector] Successfully saved ${indicator.name} with OECD rankings');
      } else {
        await _saveIndicatorDataToFirestore(indicator, result['countries']);
      }

      result['success'] = true;
      AppLogger.info(
        '[WorldBankDataCollector] ${indicator.name}: ${result['dataPoints']} data points collected',
      );
    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error(
        '[WorldBankDataCollector] Failed to collect ${indicator.name}: $e',
      );
    }

    return result;
  }

  /// 국가별 데이터 가져오기
  Future<List<Map<String, dynamic>>> _fetchCountryData(
    String countryCode,
    String indicatorCode,
    int startYear,
    int endYear,
  ) async {
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        final url =
            '$_baseUrl/countries/$countryCode/indicators/$indicatorCode'
            '?date=$startYear:$endYear&format=json&per_page=1000';

        final response = await http
            .get(
              Uri.parse(url),
              headers: {'User-Agent': 'GeoEconomyDashboard/1.0'},
            )
            .timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);

          if (jsonData is List && jsonData.length > 1) {
            final dataList = jsonData[1] as List;

            return dataList
                .where((item) => item['value'] != null)
                .map(
                  (item) => {
                    'year': int.parse(item['date']),
                    'value': (item['value'] as num).toDouble(),
                  },
                )
                .toList();
          }
        } else if (response.statusCode == 429) {
          // Rate limit exceeded
          await Future.delayed(Duration(seconds: 10));
          retryCount++;
          continue;
        }

        break;
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          AppLogger.warning(
            '[WorldBankDataCollector] Max retries exceeded for $countryCode/$indicatorCode: $e',
          );
        } else {
          await Future.delayed(_retryDelay);
        }
      }
    }

    return [];
  }

  /// OECD 순위 계산 (연도별)
  Future<Map<String, dynamic>> _calculateOECDRankings(
    IndicatorCode indicator,
    Map<String, dynamic> countriesData,
  ) async {
    try {
      AppLogger.info('[RANKING] Starting OECD ranking calculation for ${indicator.name}');
      AppLogger.info('[RANKING] Input countries: ${countriesData.keys.join(', ')}');
      AppLogger.info('[RANKING] Input data type: ${countriesData.values.first.runtimeType}');
      
      // 지표별 정렬 방향 결정 (높을수록 좋음/낮을수록 좋음)
      final isLowerBetter = _isLowerBetterIndicator(indicator);
      
      // 연도별로 모든 국가 데이터를 모아서 순위 계산
      final yearlyData = <int, List<MapEntry<String, double>>>{};
      
      // 각 국가의 연도별 데이터 수집
      for (final entry in countriesData.entries) {
        final countryCode = entry.key;
        
        // 데이터 구조 확인: List 또는 Map with timeSeries
        List<Map<String, dynamic>> dataPoints;
        if (entry.value is List) {
          dataPoints = List<Map<String, dynamic>>.from(entry.value as List);
        } else if (entry.value is Map && (entry.value as Map).containsKey('timeSeries')) {
          dataPoints = List<Map<String, dynamic>>.from((entry.value as Map)['timeSeries'] as List);
        } else {
          AppLogger.warning('[WorldBankDataCollector] Invalid data structure for $countryCode');
          continue;
        }
        
        for (final point in dataPoints) {
          final year = point['year'] as int;
          final value = point['value'] as double;
          
          yearlyData.putIfAbsent(year, () => []);
          yearlyData[year]!.add(MapEntry(countryCode, value));
        }
      }
      
      // 연도별 순위 계산
      final enrichedData = <String, dynamic>{};
      
      for (final countryEntry in countriesData.entries) {
        final countryCode = countryEntry.key;
        
        // 데이터 구조 확인: List 또는 Map with timeSeries
        List<Map<String, dynamic>> dataPoints;
        if (countryEntry.value is List) {
          dataPoints = List<Map<String, dynamic>>.from(countryEntry.value as List);
        } else if (countryEntry.value is Map && (countryEntry.value as Map).containsKey('timeSeries')) {
          dataPoints = List<Map<String, dynamic>>.from((countryEntry.value as Map)['timeSeries'] as List);
        } else {
          AppLogger.warning('[WorldBankDataCollector] Invalid data structure for $countryCode in ranking calculation');
          continue;
        }
        
        // 연도별 순위 데이터 저장
        final rankingByYear = <String, Map<String, dynamic>>{};
        
        for (int i = 0; i < dataPoints.length; i++) {
          final year = dataPoints[i]['year'] as int;
          final value = dataPoints[i]['value'] as double;
          
          // 해당 연도의 모든 국가 데이터로 순위 계산
          if (yearlyData.containsKey(year)) {
            final yearData = List<MapEntry<String, double>>.from(yearlyData[year]!);
            
            // 정렬 (지표 특성에 따라)
            yearData.sort((a, b) {
              if (isLowerBetter) {
                return a.value.compareTo(b.value); // 오름차순
              } else {
                return b.value.compareTo(a.value); // 내림차순
              }
            });
            
            // 순위 찾기
            final ranking = yearData.indexWhere((entry) => entry.key == countryCode) + 1;
            final percentile = ((yearData.length - ranking + 1) / yearData.length) * 100;
            
            // 원본 데이터에 순위 정보 추가
            dataPoints[i]['ranking'] = ranking;
            dataPoints[i]['percentile'] = percentile.round();
            dataPoints[i]['totalCountries'] = yearData.length;
            
            // 연도별 순위 맵에도 저장
            rankingByYear[year.toString()] = {
              'ranking': ranking,
              'percentile': percentile.round(),
              'totalCountries': yearData.length,
            };
          }
        }
        
        // 최신 순위 정보 (가장 최근 연도)
        dataPoints.sort((a, b) => (b['year'] as int).compareTo(a['year'] as int));
        final latestData = dataPoints.first;
        
        enrichedData[countryCode] = {
          'timeSeries': dataPoints,
          'rankingByYear': rankingByYear,
          'latestRanking': latestData['ranking'],
          'latestPercentile': latestData['percentile'],
          'totalCountries': latestData['totalCountries'],
        };
      }
      
      AppLogger.info('[WorldBankDataCollector] OECD rankings calculated for ${indicator.name} (${enrichedData.length} countries)');
      return enrichedData;
      
    } catch (e, stackTrace) {
      AppLogger.error('[WorldBankDataCollector] Failed to calculate rankings for ${indicator.name}: $e', stackTrace);
      return countriesData; // 실패 시 원본 데이터 반환
    }
  }

  /// 지표별 낮을수록 좋은 성과인지 판단
  bool _isLowerBetterIndicator(IndicatorCode indicator) {
    switch (indicator) {
      case IndicatorCode.unemployment:       // 실업률
      case IndicatorCode.cpiInflation:       // 인플레이션
      case IndicatorCode.govDebt:           // 정부부채
      case IndicatorCode.gini:              // 지니계수 
      case IndicatorCode.povertyNat:        // 빈곤율
      case IndicatorCode.co2PerCapita:      // CO₂ 배출량
        return true;  // 낮을수록 좋음
      
      default:
        return false; // 높을수록 좋음
    }
  }

  /// PRD v1.1: 이중 구조로 Firestore에 지표 데이터 저장
  /// 1. /indicators/{indicatorCode}/series/{countryCode} (정규화)
  /// 2. /countries/{countryCode}/indicators/{indicatorCode} (비정규화)
  Future<void> _saveIndicatorDataToFirestore(
    IndicatorCode indicator,
    Map<String, dynamic> countriesData,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final firestore = FirebaseFirestore.instance;

      for (final entry in countriesData.entries) {
        final countryCode = entry.key;
        final countryData = entry.value as Map<String, dynamic>;
        final dataPoints = countryData['timeSeries'] as List<Map<String, dynamic>>? 
                          ?? entry.value as List<Map<String, dynamic>>;
        
        if (dataPoints.isEmpty) continue;

        // 최신 데이터 찾기
        dataPoints.sort((a, b) => (b['year'] as int).compareTo(a['year'] as int));
        final latestData = dataPoints.first;
        final latestValue = latestData['value'] as double;
        final latestYear = latestData['year'] as int;

        // 공통 데이터 구조 (순위 정보 포함)
        final commonData = {
          'countryCode': countryCode,
          'countryName': '', // TODO: 국가명 매핑 필요
          'indicatorCode': indicator.code,
          'indicatorName': indicator.name,
          'latestValue': latestValue,
          'latestYear': latestYear,
          'unit': indicator.unit,
          'timeSeries': dataPoints,
          'updatedAt': FieldValue.serverTimestamp(),
          'dataSource': 'World Bank API',
          
          // OECD 순위 데이터 추가
          'latestRanking': countryData['latestRanking'] ?? latestData['ranking'],
          'latestPercentile': countryData['latestPercentile'] ?? latestData['percentile'],
          'totalCountries': countryData['totalCountries'] ?? latestData['totalCountries'],
          'rankingByYear': countryData['rankingByYear'] ?? {},
        };

        // 1. 정규화 구조: /indicators/{indicatorCode}/series/{countryCode}
        final normalizedRef = firestore
            .collection('indicators')
            .doc(indicator.code)
            .collection('series')
            .doc(countryCode);

        batch.set(normalizedRef, commonData, SetOptions(merge: true));

        // 2. 비정규화 구조: /countries/{countryCode}/indicators/{indicatorCode}
        final denormalizedRef = firestore
            .collection('countries')
            .doc(countryCode)
            .collection('indicators')
            .doc(indicator.code);

        batch.set(denormalizedRef, commonData, SetOptions(merge: true));
      }

      // 지표 메타데이터도 저장
      final metadataRef = firestore
          .collection('indicators')
          .doc(indicator.code);

      final metadataDoc = {
        'code': indicator.code,
        'name': indicator.name,
        'unit': indicator.unit,
        'description': '', // TODO: 설명 추가
        'category': '', // TODO: 카테고리 매핑
        'lastCollectionUpdate': FieldValue.serverTimestamp(),
        'totalCountries': countriesData.length,
      };

      batch.set(metadataRef, metadataDoc, SetOptions(merge: true));

      await batch.commit();
      AppLogger.info(
        '[WorldBankDataCollector] PRD v1.1: Saved ${indicator.name} to both normalized and denormalized structures (${countriesData.length} countries)',
      );
    } catch (e) {
      AppLogger.error(
        '[WorldBankDataCollector] Failed to save ${indicator.name}: $e',
      );
      rethrow;
    }
  }

  /// OECD 통계 계산 및 저장
  Future<void> calculateAndSaveOECDStats({
    int? year,
    Function(String)? onProgress,
  }) async {
    final targetYear = year ?? DateTime.now().year - 1;

    try {
      onProgress?.call('OECD 통계 계산 중...');

      final indicators = [
        IndicatorCode.gdpRealGrowth,
        IndicatorCode.unemployment,
        IndicatorCode.cpiInflation,
        // 필요에 따라 더 추가
      ];

      for (final indicator in indicators) {
        onProgress?.call('통계 계산: ${indicator.name}');

        await _calculateIndicatorStats(indicator, targetYear);

        await Future.delayed(Duration(milliseconds: 200));
      }

      AppLogger.info(
        '[WorldBankDataCollector] OECD stats calculated for year $targetYear',
      );
    } catch (e) {
      AppLogger.error(
        '[WorldBankDataCollector] Failed to calculate OECD stats: $e',
      );
      rethrow;
    }
  }

  /// 개별 지표 통계 계산
  Future<void> _calculateIndicatorStats(
    IndicatorCode indicator,
    int year,
  ) async {
    try {
      final values = <double>[];
      final countryRankings = <Map<String, dynamic>>[];

      // 모든 OECD 국가 데이터 수집
      for (final countryCode in _oecdCountries) {
        final docRef = FirebaseFirestore.instance
            .collection('indicator_data')
            .doc('${indicator.code}_$countryCode');

        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data()!;
          final dataPoints = data['data'] as List<dynamic>;

          for (final point in dataPoints) {
            if (point['year'] == year && point['value'] != null) {
              values.add((point['value'] as num).toDouble());
              countryRankings.add({
                'countryCode': countryCode,
                'value': (point['value'] as num).toDouble(),
              });
              break;
            }
          }
        }
      }

      if (values.isEmpty) return;

      // 통계 계산
      values.sort();
      final stats = _calculateStatistics(values);

      // 순위 계산 (direction 사용)
      countryRankings.sort(
        (a, b) => indicator.direction == IndicatorDirection.higher
            ? (b['value'] as double).compareTo(a['value'] as double)
            : (a['value'] as double).compareTo(b['value'] as double),
      );

      for (int i = 0; i < countryRankings.length; i++) {
        countryRankings[i]['rank'] = i + 1;
      }

      // Firestore에 저장
      final statsDoc = FirebaseFirestore.instance
          .collection('oecd_stats')
          .doc('${indicator.code}_$year');

      await statsDoc.set({
        'indicatorCode': indicator.code,
        'indicatorName': indicator.name,
        'year': year,
        'statistics': stats,
        'countryRankings': countryRankings,
        'totalCountries': values.length,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error(
        '[WorldBankDataCollector] Failed to calculate stats for ${indicator.name}: $e',
      );
    }
  }

  /// 기본 통계 계산
  Map<String, double> _calculateStatistics(List<double> values) {
    if (values.isEmpty) return {};

    final sum = values.reduce((a, b) => a + b);
    final mean = sum / values.length;

    final sortedValues = List<double>.from(values)..sort();
    final median = sortedValues.length % 2 == 0
        ? (sortedValues[sortedValues.length ~/ 2 - 1] +
                  sortedValues[sortedValues.length ~/ 2]) /
              2
        : sortedValues[sortedValues.length ~/ 2];

    final q1Index = (sortedValues.length * 0.25).floor();
    final q3Index = (sortedValues.length * 0.75).floor();

    return {
      'mean': mean,
      'median': median,
      'min': sortedValues.first,
      'max': sortedValues.last,
      'q1': sortedValues[q1Index],
      'q3': sortedValues[q3Index],
    };
  }
}
