import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/logger.dart';

/// PRD v1.1 데이터 마이그레이션 서비스
class DataMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Old Structure → PRD v1.1 Structure 마이그레이션
  Future<Map<String, dynamic>> migrateToV11({
    bool dryRun = true,
    Function(String)? onProgress,
  }) async {
    final result = <String, dynamic>{
      'startTime': DateTime.now().toIso8601String(),
      'dryRun': dryRun,
      'migrated': <String, int>{
        'countries': 0,
        'indicators': 0,
        'series': 0,
      },
      'errors': <String>[],
      'skipped': 0,
    };
    
    try {
      onProgress?.call('📊 Old indicator_data 컬렉션 분석 중...');
      
      // 1. 기존 indicator_data 컬렉션에서 데이터 읽기
      final oldDataSnapshot = await _firestore
          .collection('indicator_data')
          .get();
      
      AppLogger.info('[DataMigration] Found ${oldDataSnapshot.docs.length} old documents');
      
      for (final doc in oldDataSnapshot.docs) {
        final data = doc.data();
        final countryCode = data['countryCode'] as String?;
        final indicatorCode = data['indicatorCode'] as String?;
        
        if (countryCode == null || indicatorCode == null) {
          result['skipped'] = (result['skipped'] as int) + 1;
          continue;
        }
        
        onProgress?.call('🔄 마이그레이션 중: $countryCode - $indicatorCode');
        
        try {
          // 2. Old → New 데이터 변환
          final migrationData = _convertOldToNew(data, countryCode, indicatorCode);
          
          if (!dryRun) {
            // 3a. 국가 중심 구조에 저장 (비정규화)
            final countryData = migrationData['country'];
            if (countryData != null) {
              await _saveToCountryStructure(countryData, countryCode, indicatorCode);
              final migrated = result['migrated'] as Map<String, dynamic>;
              migrated['countries'] = (migrated['countries'] as int? ?? 0) + 1;
            }
            
            // 3b. 지표 중심 구조에 저장 (정규화)
            final seriesData = migrationData['series'];
            if (seriesData != null) {
              await _saveToIndicatorStructure(seriesData, indicatorCode, countryCode);
              final migrated = result['migrated'] as Map<String, dynamic>;
              migrated['series'] = (migrated['series'] as int? ?? 0) + 1;
            }
          }
          
          final migrated = result['migrated'] as Map<String, dynamic>;
          migrated['indicators'] = (migrated['indicators'] as int? ?? 0) + 1;
          
        } catch (e) {
          final errors = result['errors'] as List<String>;
          errors.add('Error migrating $countryCode:$indicatorCode - $e');
          AppLogger.error('[DataMigration] Migration error: $e');
        }
      }
      
      result['endTime'] = DateTime.now().toIso8601String();
      final migrated = result['migrated'] as Map<String, dynamic>;
      AppLogger.info('[DataMigration] Migration completed: ${migrated['indicators']} indicators processed');
      
    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error('[DataMigration] Migration failed: $e');
    }
    
    return result;
  }
  
  /// Old 데이터를 New 구조로 변환
  Map<String, Map<String, dynamic>> _convertOldToNew(
    Map<String, dynamic> oldData,
    String countryCode,
    String indicatorCode,
  ) {
    // Old yearlyData → New recentData/timeSeries 변환
    final yearlyDataMap = oldData['yearlyData'] as Map<String, dynamic>? ?? {};
    final recentDataList = <Map<String, dynamic>>[];
    final timeSeriesMap = <int, double?>{};
    
    yearlyDataMap.forEach((yearStr, value) {
      final year = int.tryParse(yearStr);
      if (year != null && value is num) {
        final doubleValue = value.toDouble();
        recentDataList.add({'year': year, 'value': doubleValue});
        timeSeriesMap[year] = doubleValue;
      }
    });
    
    // 최신값 및 연도 계산
    double? latestValue;
    int? latestYear;
    if (timeSeriesMap.isNotEmpty) {
      final sortedYears = timeSeriesMap.keys.toList()..sort();
      latestYear = sortedYears.last;
      latestValue = timeSeriesMap[latestYear];
    }
    
    // CountryIndicator 데이터 (비정규화)
    final countryIndicatorData = {
      'countryCode': countryCode,
      'indicatorCode': indicatorCode,
      'countryName': oldData['countryName'] ?? '',
      'indicatorName': oldData['source'] ?? oldData['indicatorName'] ?? '',
      'unit': oldData['unit'] ?? '',
      'latestValue': latestValue,
      'latestYear': latestYear,
      'recentData': recentDataList,
      'updatedAt': oldData['lastUpdated'] ?? oldData['fetchedAt'] ?? FieldValue.serverTimestamp(),
      // OECD 데이터는 별도 로직으로 계산 필요
      'oecdRanking': null,
      'oecdPercentile': null,
      'oecdStats': null,
      'yearOverYearChange': null,
      'dataBadge': null,
    };
    
    // IndicatorSeries 데이터 (정규화)
    final indicatorSeriesData = {
      'indicatorCode': indicatorCode,
      'countryCode': countryCode,
      'indicatorName': oldData['source'] ?? oldData['indicatorName'] ?? '',
      'countryName': oldData['countryName'] ?? '',
      'unit': oldData['unit'] ?? '',
      'timeSeries': timeSeriesMap.map((year, value) => MapEntry(year.toString(), value)),
      'latestValue': latestValue,
      'latestYear': latestYear,
      'fetchedAt': oldData['fetchedAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': oldData['lastUpdated'] ?? oldData['fetchedAt'] ?? FieldValue.serverTimestamp(),
      'source': 'World Bank',
    };
    
    return {
      'country': countryIndicatorData,
      'series': indicatorSeriesData,
    };
  }
  
  /// 국가 중심 구조에 저장
  Future<void> _saveToCountryStructure(
    Map<String, dynamic> data,
    String countryCode,
    String indicatorCode,
  ) async {
    await _firestore
        .collection('countries')
        .doc(countryCode)
        .collection('indicators')
        .doc(indicatorCode)
        .set(data);
  }
  
  /// 지표 중심 구조에 저장  
  Future<void> _saveToIndicatorStructure(
    Map<String, dynamic> data,
    String indicatorCode,
    String countryCode,
  ) async {
    await _firestore
        .collection('indicators')
        .doc(indicatorCode)
        .collection('series')
        .doc(countryCode)
        .set(data);
  }
  
  /// 마이그레이션 검증
  Future<Map<String, dynamic>> validateMigration() async {
    final validation = {
      'oldStructure': <String, int>{},
      'newStructure': <String, int>{},
      'missingData': <String>[],
      'isValid': false,
    };
    
    try {
      // Old 구조 카운트
      final oldIndicatorData = await _firestore.collection('indicator_data').get();
      final oldStructure = validation['oldStructure'] as Map<String, int>;
      oldStructure['indicator_data'] = oldIndicatorData.docs.length;
      
      // New 구조 카운트
      final countriesSnapshot = await _firestore.collection('countries').get();
      int totalCountryIndicators = 0;
      
      for (final countryDoc in countriesSnapshot.docs) {
        final indicatorsSnapshot = await countryDoc.reference.collection('indicators').get();
        totalCountryIndicators += indicatorsSnapshot.docs.length;
      }
      
      final newStructure = validation['newStructure'] as Map<String, int>;
      newStructure['countries'] = countriesSnapshot.docs.length;
      newStructure['country_indicators'] = totalCountryIndicators;
      
      final indicatorsSnapshot = await _firestore.collection('indicators').get();
      newStructure['indicators'] = indicatorsSnapshot.docs.length;
      
      // 검증
      validation['isValid'] = (oldStructure['indicator_data'] ?? 0) == totalCountryIndicators;
      
      final isValid = validation['isValid'] as bool? ?? false;
      AppLogger.info('[DataMigration] Validation: ${isValid ? 'PASSED' : 'FAILED'}');
      
    } catch (e) {
      validation['error'] = e.toString();
      AppLogger.error('[DataMigration] Validation failed: $e');
    }
    
    return validation;
  }
  
  /// Old 데이터 백업 및 삭제 (신중하게!)
  Future<Map<String, dynamic>> cleanupOldData({
    bool createBackup = true,
    bool deleteOld = false,
  }) async {
    final result = {
      'backupCreated': false,
      'oldDataDeleted': false,
      'backedUpDocuments': 0,
      'deletedDocuments': 0,
      'errors': <String>[],
    };
    
    try {
      if (createBackup) {
        // 백업 생성
        final oldDataSnapshot = await _firestore.collection('indicator_data').get();
        
        final batch = _firestore.batch();
        for (final doc in oldDataSnapshot.docs) {
          final backupRef = _firestore.collection('indicator_data_backup').doc(doc.id);
          batch.set(backupRef, {
            ...doc.data(),
            'backupCreatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        result['backupCreated'] = true;
        result['backedUpDocuments'] = oldDataSnapshot.docs.length;
        
        AppLogger.info('[DataMigration] Backup created: ${oldDataSnapshot.docs.length} documents');
      }
      
      if (deleteOld && createBackup) {
        // 백업 후에만 삭제 허용
        final oldDataSnapshot = await _firestore.collection('indicator_data').get();
        
        final batch = _firestore.batch();
        for (final doc in oldDataSnapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        result['oldDataDeleted'] = true;
        result['deletedDocuments'] = oldDataSnapshot.docs.length;
        
        AppLogger.info('[DataMigration] Old data deleted: ${oldDataSnapshot.docs.length} documents');
      }
      
    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error('[DataMigration] Cleanup failed: $e');
    }
    
    return result;
  }
}