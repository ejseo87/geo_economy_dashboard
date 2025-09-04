import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/logger.dart';

/// Firestore 데이터 관리 서비스
class FirestoreDataManager {
  static const Duration _oldDataThreshold = Duration(days: 365 * 2); // 2년
  
  /// 데이터 감사 수행
  Future<Map<String, dynamic>> performDataAudit({
    Function(String)? onProgress,
  }) async {
    final auditResult = <String, dynamic>{
      'startTime': DateTime.now().toIso8601String(),
      'collections': <String, dynamic>{},
      'issues': <String>[],
      'totalDocuments': 0,
      'duplicateDocuments': 0,
      'oldDocuments': 0,
      'orphanedDocuments': 0,
    };

    try {
      // 주요 컬렉션들 감사
      final collections = [
        'indicator_data',
        'oecd_stats', 
        'oecd_countries',
        'admin_users',
        'audit_logs',
      ];

      for (final collectionName in collections) {
        onProgress?.call('감사 중: $collectionName');
        
        final collectionAudit = await _auditCollection(collectionName);
        auditResult['collections'][collectionName] = collectionAudit;
        
        auditResult['totalDocuments'] = 
            (auditResult['totalDocuments'] as int) + (collectionAudit['documentCount'] as int);
        auditResult['duplicateDocuments'] = 
            (auditResult['duplicateDocuments'] as int) + (collectionAudit['duplicates'] as int);
        auditResult['oldDocuments'] = 
            (auditResult['oldDocuments'] as int) + (collectionAudit['oldDocuments'] as int);
        auditResult['orphanedDocuments'] = 
            (auditResult['orphanedDocuments'] as int) + (collectionAudit['orphanedDocuments'] as int);
      }

      // 데이터 정합성 검사
      onProgress?.call('데이터 정합성 검사 중...');
      final integrityIssues = await _checkDataIntegrity();
      auditResult['issues'].addAll(integrityIssues);

      auditResult['endTime'] = DateTime.now().toIso8601String();
      
      // 감사 로그 저장
      await _saveAuditLog(auditResult);

      AppLogger.info('[FirestoreDataManager] Audit completed: ${auditResult['totalDocuments']} documents checked');

    } catch (e) {
      auditResult['error'] = e.toString();
      AppLogger.error('[FirestoreDataManager] Audit failed: $e');
    }

    return auditResult;
  }

  /// 개별 컬렉션 감사
  Future<Map<String, dynamic>> _auditCollection(String collectionName) async {
    final result = <String, dynamic>{
      'documentCount': 0,
      'duplicates': 0,
      'oldDocuments': 0,
      'orphanedDocuments': 0,
      'sizeEstimate': 0,
      'issues': <String>[],
    };

    try {
      final collection = FirebaseFirestore.instance.collection(collectionName);
      final snapshot = await collection.get();
      
      result['documentCount'] = snapshot.docs.length;
      
      final documentIds = <String>{};
      final cutoffDate = DateTime.now().subtract(_oldDataThreshold);
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // 중복 검사
        if (documentIds.contains(doc.id)) {
          result['duplicates'] = (result['duplicates'] as int) + 1;
        } else {
          documentIds.add(doc.id);
        }
        
        // 오래된 데이터 검사
        if (data.containsKey('lastUpdated')) {
          final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
          if (lastUpdated.isBefore(cutoffDate)) {
            result['oldDocuments'] = (result['oldDocuments'] as int) + 1;
          }
        }
        
        // 크기 추정
        final jsonString = data.toString();
        result['sizeEstimate'] = (result['sizeEstimate'] as int) + jsonString.length;
        
        // 컬렉션별 특별 검사
        await _performCollectionSpecificChecks(collectionName, doc, result);
      }

    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error('[FirestoreDataManager] Collection audit failed for $collectionName: $e');
    }

    return result;
  }

  /// 컬렉션별 특별 검사
  Future<void> _performCollectionSpecificChecks(
    String collectionName,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> result,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    
    switch (collectionName) {
      case 'indicator_data':
        // 지표 데이터 무결성 검사
        if (!data.containsKey('indicatorCode') || !data.containsKey('countryCode')) {
          (result['issues'] as List<String>).add('Missing required fields in ${doc.id}');
        }
        
        if (data.containsKey('data')) {
          final dataPoints = data['data'] as List<dynamic>;
          if (dataPoints.isEmpty) {
            (result['issues'] as List<String>).add('Empty data array in ${doc.id}');
          }
        }
        break;
        
      case 'oecd_stats':
        // OECD 통계 무결성 검사
        if (!data.containsKey('year') || !data.containsKey('statistics')) {
          (result['issues'] as List<String>).add('Missing statistics in ${doc.id}');
        }
        break;
        
      case 'oecd_countries':
        // 국가 데이터 무결성 검사
        if (!data.containsKey('code') || !data.containsKey('name')) {
          (result['issues'] as List<String>).add('Missing country info in ${doc.id}');
        }
        break;
    }
  }

  /// 데이터 정합성 검사
  Future<List<String>> _checkDataIntegrity() async {
    final issues = <String>[];

    try {
      // 지표 데이터와 OECD 통계 간 정합성 검사
      final indicatorDataSnapshot = await FirebaseFirestore.instance
          .collection('indicator_data')
          .get();
          
      final oecdStatsSnapshot = await FirebaseFirestore.instance
          .collection('oecd_stats')
          .get();

      final indicatorCodes = <String>{};
      for (final doc in indicatorDataSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('indicatorCode')) {
          indicatorCodes.add(data['indicatorCode'] as String);
        }
      }

      final statsCodes = <String>{};
      for (final doc in oecdStatsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('indicatorCode')) {
          statsCodes.add(data['indicatorCode'] as String);
        }
      }

      // 통계는 있지만 데이터가 없는 지표
      for (final code in statsCodes) {
        if (!indicatorCodes.contains(code)) {
          issues.add('OECD stats exists but no indicator data for: $code');
        }
      }

    } catch (e) {
      issues.add('Data integrity check failed: $e');
      AppLogger.error('[FirestoreDataManager] Integrity check failed: $e');
    }

    return issues;
  }

  /// 오래된 데이터 삭제
  Future<Map<String, dynamic>> deleteOldData({
    Duration? olderThan,
    bool dryRun = true,
    Function(String)? onProgress,
  }) async {
    final cutoffDuration = olderThan ?? _oldDataThreshold;
    final cutoffDate = DateTime.now().subtract(cutoffDuration);
    
    final result = <String, dynamic>{
      'startTime': DateTime.now().toIso8601String(),
      'dryRun': dryRun,
      'cutoffDate': cutoffDate.toIso8601String(),
      'deletedDocuments': 0,
      'collections': <String, int>{},
      'errors': <String>[],
    };

    try {
      final collections = ['indicator_data', 'oecd_stats', 'audit_logs'];
      
      for (final collectionName in collections) {
        onProgress?.call('처리 중: $collectionName');
        
        final deletedCount = await _deleteOldDataFromCollection(
          collectionName,
          cutoffDate,
          dryRun,
        );
        
        result['collections'][collectionName] = deletedCount;
        result['deletedDocuments'] = (result['deletedDocuments'] as int) + deletedCount;
      }

      result['endTime'] = DateTime.now().toIso8601String();
      
      if (!dryRun) {
        await _saveAuditLog({
          'action': 'delete_old_data',
          'result': result,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      AppLogger.info('[FirestoreDataManager] Old data deletion ${dryRun ? '(dry run)' : ''}: ${result['deletedDocuments']} documents');

    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error('[FirestoreDataManager] Delete old data failed: $e');
    }

    return result;
  }

  /// 컬렉션에서 오래된 데이터 삭제
  Future<int> _deleteOldDataFromCollection(
    String collectionName,
    DateTime cutoffDate,
    bool dryRun,
  ) async {
    int deletedCount = 0;

    try {
      final collection = FirebaseFirestore.instance.collection(collectionName);
      
      // lastUpdated 필드가 있는 문서들 조회
      final query = collection.where('lastUpdated', isLessThan: Timestamp.fromDate(cutoffDate));
      final snapshot = await query.get();

      if (!dryRun && snapshot.docs.isNotEmpty) {
        // 배치로 삭제 (최대 500개씩)
        final batch = FirebaseFirestore.instance.batch();
        int batchCount = 0;

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          batchCount++;
          deletedCount++;

          if (batchCount >= 500) {
            await batch.commit();
            // 새 배치 생성하여 계속 처리
            // final newBatch = FirebaseFirestore.instance.batch();
            batchCount = 0;
          }
        }

        if (batchCount > 0) {
          await batch.commit();
        }
      } else {
        deletedCount = snapshot.docs.length;
      }

    } catch (e) {
      AppLogger.error('[FirestoreDataManager] Failed to delete old data from $collectionName: $e');
    }

    return deletedCount;
  }

  /// 중복 데이터 제거
  Future<Map<String, dynamic>> removeDuplicateData({
    bool dryRun = true,
    Function(String)? onProgress,
  }) async {
    final result = <String, dynamic>{
      'startTime': DateTime.now().toIso8601String(),
      'dryRun': dryRun,
      'removedDocuments': 0,
      'collections': <String, int>{},
      'errors': <String>[],
    };

    try {
      // indicator_data 컬렉션의 중복 제거
      onProgress?.call('중복 제거 중: indicator_data');
      final removedCount = await _removeDuplicatesFromIndicatorData(dryRun);
      
      result['collections']['indicator_data'] = removedCount;
      result['removedDocuments'] = removedCount;

      result['endTime'] = DateTime.now().toIso8601String();

      if (!dryRun) {
        await _saveAuditLog({
          'action': 'remove_duplicates',
          'result': result,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      AppLogger.info('[FirestoreDataManager] Duplicate removal ${dryRun ? '(dry run)' : ''}: ${result['removedDocuments']} documents');

    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error('[FirestoreDataManager] Remove duplicates failed: $e');
    }

    return result;
  }

  /// indicator_data 컬렉션 중복 제거
  Future<int> _removeDuplicatesFromIndicatorData(bool dryRun) async {
    int removedCount = 0;

    try {
      final collection = FirebaseFirestore.instance.collection('indicator_data');
      final snapshot = await collection.get();
      
      // 같은 indicatorCode + countryCode 조합 찾기
      final documentGroups = <String, List<QueryDocumentSnapshot>>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final key = '${data['indicatorCode']}_${data['countryCode']}';
        
        if (!documentGroups.containsKey(key)) {
          documentGroups[key] = [];
        }
        documentGroups[key]!.add(doc);
      }

      // 중복된 그룹 처리
      for (final group in documentGroups.values) {
        if (group.length > 1) {
          // 가장 최근 업데이트된 문서 유지
          group.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = (aData?['lastUpdated'] as Timestamp? ?? Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0))).millisecondsSinceEpoch;
            final bTime = (bData?['lastUpdated'] as Timestamp? ?? Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0))).millisecondsSinceEpoch;
            return bTime.compareTo(aTime);
          });

          // 첫 번째(최신) 제외하고 나머지 삭제
          for (int i = 1; i < group.length; i++) {
            if (!dryRun) {
              await group[i].reference.delete();
            }
            removedCount++;
          }
        }
      }

    } catch (e) {
      AppLogger.error('[FirestoreDataManager] Failed to remove duplicates from indicator_data: $e');
    }

    return removedCount;
  }

  /// 감사 로그 저장
  Future<void> _saveAuditLog(Map<String, dynamic> logData) async {
    try {
      await FirebaseFirestore.instance
          .collection('audit_logs')
          .add({
        ...logData,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'data_management',
      });
    } catch (e) {
      AppLogger.error('[FirestoreDataManager] Failed to save audit log: $e');
    }
  }

  /// 전체 데이터베이스 통계
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    final stats = <String, dynamic>{
      'collections': <String, dynamic>{},
      'totalDocuments': 0,
      'estimatedSize': 0,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    try {
      final collections = [
        'indicator_data',
        'oecd_stats',
        'oecd_countries', 
        'admin_users',
        'audit_logs',
      ];

      for (final collectionName in collections) {
        final collection = FirebaseFirestore.instance.collection(collectionName);
        final snapshot = await collection.get();
        
        final collectionStats = {
          'documents': snapshot.docs.length,
          'estimatedSize': snapshot.docs.fold<int>(
            0, 
            (total, doc) => total + doc.data().toString().length
          ),
        };

        stats['collections'][collectionName] = collectionStats;
        stats['totalDocuments'] = (stats['totalDocuments'] as int) + (collectionStats['documents'] as int);
        stats['estimatedSize'] = (stats['estimatedSize'] as int) + (collectionStats['estimatedSize'] as int);
      }

    } catch (e) {
      stats['error'] = e.toString();
      AppLogger.error('[FirestoreDataManager] Failed to get database statistics: $e');
    }

    return stats;
  }
}