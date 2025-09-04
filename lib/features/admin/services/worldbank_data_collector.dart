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
    'AUS', 'AUT', 'BEL', 'CAN', 'CHL', 'COL', 'CRI', 'CZE', 'DNK', 'EST',
    'FIN', 'FRA', 'DEU', 'GRC', 'HUN', 'ISL', 'IRL', 'ISR', 'ITA', 'JPN',
    'KOR', 'LVA', 'LTU', 'LUX', 'MEX', 'NLD', 'NZL', 'NOR', 'POL', 'PRT',
    'SVK', 'SVN', 'ESP', 'SWE', 'CHE', 'TUR', 'GBR', 'USA'
  ];

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
          results['successfullyProcessed'] = (results['successfullyProcessed'] as int) + 1;
        } else {
          results['errors'].add('${indicator.name}: ${indicatorResult['error']}');
        }

        // API 호출 제한을 위한 지연
        await Future.delayed(Duration(milliseconds: 500));
      }

      results['endTime'] = DateTime.now().toIso8601String();
      AppLogger.info('[WorldBankDataCollector] Collection completed: ${results['successfullyProcessed']}/${results['totalProcessed']} indicators');
      
    } catch (e) {
      results['error'] = e.toString();
      AppLogger.error('[WorldBankDataCollector] Collection failed: $e');
    }

    return results;
  }

  /// 특정 지표 데이터 수집
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
          result['dataPoints'] = (result['dataPoints'] as int) + countryData.length;
        }

        // 각 국가마다 작은 지연
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Firestore에 저장
      await _saveIndicatorDataToFirestore(indicator, result['countries']);
      
      result['success'] = true;
      AppLogger.info('[WorldBankDataCollector] ${indicator.name}: ${result['dataPoints']} data points collected');

    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error('[WorldBankDataCollector] Failed to collect ${indicator.name}: $e');
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
        final url = '$_baseUrl/countries/$countryCode/indicators/$indicatorCode'
                   '?date=$startYear:$endYear&format=json&per_page=1000';

        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'GeoEconomyDashboard/1.0'},
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          
          if (jsonData is List && jsonData.length > 1) {
            final dataList = jsonData[1] as List;
            
            return dataList
                .where((item) => item['value'] != null)
                .map((item) => {
                  'year': int.parse(item['date']),
                  'value': (item['value'] as num).toDouble(),
                })
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
          AppLogger.warning('[WorldBankDataCollector] Max retries exceeded for $countryCode/$indicatorCode: $e');
        } else {
          await Future.delayed(_retryDelay);
        }
      }
    }

    return [];
  }

  /// Firestore에 지표 데이터 저장
  Future<void> _saveIndicatorDataToFirestore(
    IndicatorCode indicator,
    Map<String, dynamic> countriesData,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('indicator_data');

      for (final entry in countriesData.entries) {
        final countryCode = entry.key;
        final dataPoints = entry.value as List<Map<String, dynamic>>;

        final docRef = collection.doc('${indicator.code}_$countryCode');
        
        final docData = {
          'indicatorCode': indicator.code,
          'indicatorName': indicator.name,
          'countryCode': countryCode,
          'data': dataPoints,
          'lastUpdated': FieldValue.serverTimestamp(),
          'unit': indicator.unit ?? '',
        };

        batch.set(docRef, docData, SetOptions(merge: true));
      }

      await batch.commit();
      AppLogger.debug('[WorldBankDataCollector] Saved ${indicator.name} to Firestore');

    } catch (e) {
      AppLogger.error('[WorldBankDataCollector] Failed to save ${indicator.name}: $e');
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

      AppLogger.info('[WorldBankDataCollector] OECD stats calculated for year $targetYear');

    } catch (e) {
      AppLogger.error('[WorldBankDataCollector] Failed to calculate OECD stats: $e');
      rethrow;
    }
  }

  /// 개별 지표 통계 계산
  Future<void> _calculateIndicatorStats(IndicatorCode indicator, int year) async {
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
      countryRankings.sort((a, b) => 
        indicator.direction == IndicatorDirection.higher
          ? (b['value'] as double).compareTo(a['value'] as double)
          : (a['value'] as double).compareTo(b['value'] as double)
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
      AppLogger.error('[WorldBankDataCollector] Failed to calculate stats for ${indicator.name}: $e');
    }
  }

  /// 기본 통계 계산
  Map<String, double> _calculateStatistics(List<double> values) {
    if (values.isEmpty) return {};

    final sum = values.reduce((a, b) => a + b);
    final mean = sum / values.length;
    
    final sortedValues = List<double>.from(values)..sort();
    final median = sortedValues.length % 2 == 0
        ? (sortedValues[sortedValues.length ~/ 2 - 1] + sortedValues[sortedValues.length ~/ 2]) / 2
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