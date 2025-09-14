import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:geo_economy_dashboard/features/admin/services/admin_audit_service.dart';
import 'package:geo_economy_dashboard/features/admin/utils/audit_csv_logger.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class DataIntegrityIssue {
  final String type;
  final String severity;
  final String description;
  final String location;
  final Map<String, dynamic> metadata;
  final DateTime detectedAt;

  const DataIntegrityIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.location,
    required this.metadata,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'severity': severity,
    'description': description,
    'location': location,
    'metadata': metadata,
    'detectedAt': detectedAt.toIso8601String(),
  };
}

class DuplicateData {
  final String indicatorCode;
  final String countryCode;
  final List<String> locations;
  final Map<String, dynamic> conflictingData;

  const DuplicateData({
    required this.indicatorCode,
    required this.countryCode,
    required this.locations,
    required this.conflictingData,
  });
}

class OrphanDocument {
  final String path;
  final String type;
  final String reason;
  final Map<String, dynamic> data;

  const OrphanDocument({
    required this.path,
    required this.type,
    required this.reason,
    required this.data,
  });
}

class DataAuditResult {
  final DateTime auditStartTime;
  final DateTime auditEndTime;
  final int totalDocumentsChecked;
  final List<DataIntegrityIssue> integrityIssues;
  final List<DuplicateData> duplicateData;
  final List<OrphanDocument> orphanDocuments;
  final Map<String, int> statisticsSummary;

  const DataAuditResult({
    required this.auditStartTime,
    required this.auditEndTime,
    required this.totalDocumentsChecked,
    required this.integrityIssues,
    required this.duplicateData,
    required this.orphanDocuments,
    required this.statisticsSummary,
  });

  Map<String, dynamic> toJson() => {
    'auditStartTime': auditStartTime.toIso8601String(),
    'auditEndTime': auditEndTime.toIso8601String(),
    'totalDocumentsChecked': totalDocumentsChecked,
    'integrityIssuesCount': integrityIssues.length,
    'duplicateDataCount': duplicateData.length,
    'orphanDocumentsCount': orphanDocuments.length,
    'statisticsSummary': statisticsSummary,
    'integrityIssues': integrityIssues.map((issue) => issue.toJson()).toList(),
    'duplicateData': duplicateData.map((duplicate) => {
      'indicatorCode': duplicate.indicatorCode,
      'countryCode': duplicate.countryCode,
      'locations': duplicate.locations,
      'conflictingData': duplicate.conflictingData,
    }).toList(),
    'orphanDocuments': orphanDocuments.map((orphan) => {
      'path': orphan.path,
      'type': orphan.type,
      'reason': orphan.reason,
      'data': orphan.data,
    }).toList(),
  };
}

class DataAuditService {
  static final DataAuditService _instance = DataAuditService._internal();
  factory DataAuditService() => _instance;
  DataAuditService._internal();

  static DataAuditService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminAuditService _auditService = AdminAuditService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<String> auditDataIntegrity({
    bool checkDuplicates = true,
    bool checkOrphans = true,
    bool checkConsistency = true,
    Function(String)? onProgress,
  }) async* {
    final startTime = DateTime.now();
    yield '[시작] 데이터 무결성 감사를 시작합니다...';

    String? adminAuditId;
    AuditCsvLogger? csvLogger;
    String? logFileUrl;

    try {
      // Admin audit log 시작 기록 및 ID 저장
      adminAuditId = await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '데이터 무결성 감사 시작',
        status: AdminActionStatus.started,
      );

      // CSV 로거 초기화
      csvLogger = AuditCsvLogger();
      csvLogger.initialize();
      yield '[시작] CSV 감사 로그 초기화 완료';

      List<DataIntegrityIssue> allIssues = [];
      List<DuplicateData> duplicates = [];
      List<OrphanDocument> orphans = [];
      int totalDocuments = 0;

      if (checkDuplicates) {
        yield '[진행] 중복 데이터 검사 중...';
        duplicates = await _findDuplicateData();
        yield '[결과] 중복 데이터 ${duplicates.length}건 발견';

        for (final duplicate in duplicates) {
          allIssues.add(DataIntegrityIssue(
            type: 'duplicate',
            severity: 'warning',
            description: '중복 데이터 발견: ${duplicate.indicatorCode}/${duplicate.countryCode}',
            location: duplicate.locations.join(', '),
            metadata: {'indicatorCode': duplicate.indicatorCode, 'countryCode': duplicate.countryCode},
            detectedAt: DateTime.now(),
          ));

          // CSV 로그에 중복 데이터 추가
          if (csvLogger != null) {
            csvLogger.addDuplicateData(
              auditStartTime: startTime,
              adminActionType: 'systemMaintenance',
              indicatorCode: duplicate.indicatorCode,
              countryCode: duplicate.countryCode,
              locations: duplicate.locations,
            );
          }
        }
      }

      if (checkOrphans) {
        yield '[진행] 고아 문서 검사 중...';
        orphans = await _findOrphanDocuments();
        yield '[결과] 고아 문서 ${orphans.length}건 발견';

        for (final orphan in orphans) {
          allIssues.add(DataIntegrityIssue(
            type: 'orphan',
            severity: 'error',
            description: '고아 문서 발견: ${orphan.path}',
            location: orphan.path,
            metadata: {'reason': orphan.reason, 'type': orphan.type},
            detectedAt: DateTime.now(),
          ));

          // CSV 로그에 고아 문서 추가
          if (csvLogger != null) {
            csvLogger.addOrphanDocument(
              auditStartTime: startTime,
              adminActionType: 'systemMaintenance',
              path: orphan.path,
              reason: orphan.reason,
              type: orphan.type,
            );
          }
        }
      }

      if (checkConsistency) {
        yield '[진행] 데이터 일관성 검사 중...';
        final consistencyIssues = await _checkDataConsistency();
        yield '[결과] 일관성 문제 ${consistencyIssues.length}건 발견';

        // CSV 로그에 일관성 문제 추가
        for (final issue in consistencyIssues) {
          if (csvLogger != null) {
            csvLogger.addIntegrityIssue(
              auditStartTime: startTime,
              adminActionType: 'systemMaintenance',
              type: issue.type,
              severity: issue.severity,
              description: issue.description,
              location: issue.location,
              indicatorCode: issue.metadata?['indicatorCode'] as String?,
              countryCode: issue.metadata?['countryCode'] as String?,
              metadata: issue.metadata,
            );
          }
        }

        allIssues.addAll(consistencyIssues);
      }

      yield '[진행] 전체 문서 수 계산 중...';
      totalDocuments = await _getTotalDocumentCount();
      yield '[정보] 총 검사된 문서 수: $totalDocuments개';

      // CSV 로그 파일을 Firebase Storage에 업로드
      if (csvLogger != null && !csvLogger.isEmpty && adminAuditId != null) {
        yield '[진행] 감사 로그 CSV 파일 업로드 중...';
        try {
          final storagePath = csvLogger.generateStoragePath(adminAuditId);
          final csvBytes = csvLogger.getCsvBytes();

          final ref = _storage.ref().child(storagePath);
          await ref.putData(csvBytes, SettableMetadata(
            contentType: 'text/csv',
            customMetadata: {
              'auditId': adminAuditId,
              'entryCount': csvLogger.entryCount.toString(),
              'createdAt': DateTime.now().toIso8601String(),
            },
          ));

          logFileUrl = await ref.getDownloadURL();
          yield '[완료] CSV 로그 파일 업로드 완료 (${csvLogger.entryCount}개 항목)';

        } catch (e) {
          yield '[경고] CSV 파일 업로드 실패: $e';
          AppLogger.warning('[DataAuditService] Failed to upload CSV log: $e');
        }
      }

      final auditResult = DataAuditResult(
        auditStartTime: startTime,
        auditEndTime: DateTime.now(),
        totalDocumentsChecked: totalDocuments,
        integrityIssues: allIssues,
        duplicateData: duplicates,
        orphanDocuments: orphans,
        statisticsSummary: {
          'totalIssues': allIssues.length,
          'duplicates': duplicates.length,
          'orphans': orphans.length,
          'errors': allIssues.where((i) => i.severity == 'error').length,
          'warnings': allIssues.where((i) => i.severity == 'warning').length,
        },
      );

      // 감사 결과를 admin_audit_logs의 하위 컬렉션에 저장
      if (adminAuditId != null && adminAuditId.isNotEmpty) {
        await _saveAuditResultToAdminLog(auditResult, adminAuditId);
      } else {
        // Fallback: 기존 방식으로 저장
        await _saveAuditResult(auditResult);
      }

      yield '[완료] 데이터 감사가 완료되었습니다.';
      yield '[요약] 총 ${allIssues.length}건의 문제가 발견되었습니다.';

      // Admin audit log 완료 상태로 업데이트
      if (adminAuditId != null && adminAuditId.isNotEmpty) {
        final metadata = <String, dynamic>{
          'totalIssues': allIssues.length,
          'duplicates': duplicates.length,
          'orphans': orphans.length,
          'totalDocuments': totalDocuments,
        };

        // CSV 로그 파일 URL이 있으면 추가
        if (logFileUrl != null) {
          metadata['logFile'] = logFileUrl;
        }

        await _auditService.updateAdminActionStatus(
          entryId: adminAuditId,
          status: AdminActionStatus.completed,
          duration: DateTime.now().difference(startTime),
          additionalMetadata: metadata,
        );
      } else {
        // Fallback: 새로운 완료 로그 생성
        await _auditService.logAdminAction(
          actionType: AdminActionType.systemMaintenance,
          description: '데이터 무결성 감사 완료',
          status: AdminActionStatus.completed,
          metadata: auditResult.toJson(),
        );
      }

    } catch (e) {
      yield '[오류] 데이터 감사 중 오류 발생: $e';
      AppLogger.error('[DataAuditService] Audit failed: $e');

      // Admin audit log 실패 상태로 업데이트
      if (adminAuditId != null && adminAuditId.isNotEmpty) {
        await _auditService.updateAdminActionStatus(
          entryId: adminAuditId,
          status: AdminActionStatus.failed,
          errorMessage: e.toString(),
          duration: DateTime.now().difference(startTime),
        );
      } else {
        // Fallback: 새로운 실패 로그 생성
        await _auditService.logAdminAction(
          actionType: AdminActionType.systemMaintenance,
          description: '데이터 무결성 감사 실패',
          status: AdminActionStatus.failed,
          metadata: {'error': e.toString()},
        );
      }
    }
  }

  Future<List<DuplicateData>> _findDuplicateData() async {
    List<DuplicateData> duplicates = [];
    
    try {
      // indicators collection에서 모든 indicator 가져오기
      final indicatorsSnapshot = await _firestore.collection('indicators').get();
      
      for (final indicatorDoc in indicatorsSnapshot.docs) {
        final indicatorCode = indicatorDoc.id;
        
        // 각 indicator의 series 확인
        final seriesSnapshot = await _firestore
            .collection('indicators')
            .doc(indicatorCode)
            .collection('series')
            .get();
        
        for (final seriesDoc in seriesSnapshot.docs) {
          final countryCode = seriesDoc.id;
          
          // countries collection에서 대응하는 데이터 확인
          final countryIndicatorRef = _firestore
              .collection('countries')
              .doc(countryCode)
              .collection('indicators')
              .doc(indicatorCode);
          
          final countryIndicatorDoc = await countryIndicatorRef.get();
          
          if (countryIndicatorDoc.exists) {
            // 두 데이터를 비교하여 불일치 확인
            final indicatorData = seriesDoc.data();
            final countryData = countryIndicatorDoc.data()!;
            
            if (!_areDataEqual(indicatorData, countryData)) {
              duplicates.add(DuplicateData(
                indicatorCode: indicatorCode,
                countryCode: countryCode,
                locations: [
                  'indicators/$indicatorCode/series/$countryCode',
                  'countries/$countryCode/indicators/$indicatorCode',
                ],
                conflictingData: {
                  'indicators_data': indicatorData,
                  'countries_data': countryData,
                },
              ));
            }
          }
        }
      }
      
    } catch (e) {
      AppLogger.error('[DataAuditService] Error finding duplicates: $e');
    }
    
    return duplicates;
  }

  Future<List<OrphanDocument>> _findOrphanDocuments() async {
    List<OrphanDocument> orphans = [];
    
    try {
      // indicators collection의 고아 series 문서 찾기
      final indicatorsSnapshot = await _firestore.collection('indicators').get();
      
      for (final indicatorDoc in indicatorsSnapshot.docs) {
        final indicatorCode = indicatorDoc.id;
        
        final seriesSnapshot = await _firestore
            .collection('indicators')
            .doc(indicatorCode)
            .collection('series')
            .get();
        
        for (final seriesDoc in seriesSnapshot.docs) {
          final countryCode = seriesDoc.id;
          
          // 대응하는 countries 문서가 있는지 확인
          final countryIndicatorDoc = await _firestore
              .collection('countries')
              .doc(countryCode)
              .collection('indicators')
              .doc(indicatorCode)
              .get();
          
          if (!countryIndicatorDoc.exists) {
            orphans.add(OrphanDocument(
              path: 'indicators/$indicatorCode/series/$countryCode',
              type: 'series',
              reason: 'Missing corresponding country indicator document',
              data: seriesDoc.data(),
            ));
          }
        }
      }
      
      // countries collection의 고아 indicator 문서 찾기
      final countriesSnapshot = await _firestore.collection('countries').get();
      
      for (final countryDoc in countriesSnapshot.docs) {
        final countryCode = countryDoc.id;
        
        final indicatorsSnapshot = await _firestore
            .collection('countries')
            .doc(countryCode)
            .collection('indicators')
            .get();
        
        for (final indicatorDoc in indicatorsSnapshot.docs) {
          final indicatorCode = indicatorDoc.id;
          
          // 대응하는 indicators 문서가 있는지 확인
          final seriesDoc = await _firestore
              .collection('indicators')
              .doc(indicatorCode)
              .collection('series')
              .doc(countryCode)
              .get();
          
          if (!seriesDoc.exists) {
            orphans.add(OrphanDocument(
              path: 'countries/$countryCode/indicators/$indicatorCode',
              type: 'indicator',
              reason: 'Missing corresponding indicator series document',
              data: indicatorDoc.data(),
            ));
          }
        }
      }
      
    } catch (e) {
      AppLogger.error('[DataAuditService] Error finding orphans: $e');
    }
    
    return orphans;
  }

  Future<List<DataIntegrityIssue>> _checkDataConsistency() async {
    List<DataIntegrityIssue> issues = [];
    
    try {
      final indicatorsSnapshot = await _firestore.collection('indicators').get();
      
      for (final indicatorDoc in indicatorsSnapshot.docs) {
        final indicatorCode = indicatorDoc.id;
        
        final seriesSnapshot = await _firestore
            .collection('indicators')
            .doc(indicatorCode)
            .collection('series')
            .get();
        
        for (final seriesDoc in seriesSnapshot.docs) {
          final countryCode = seriesDoc.id;
          final data = seriesDoc.data();
          
          // 필수 필드 확인
          if (!data.containsKey('timeSeries')) {
            issues.add(DataIntegrityIssue(
              type: 'missing_field',
              severity: 'error',
              description: 'timeSeries 필드 누락',
              location: 'indicators/$indicatorCode/series/$countryCode',
              metadata: {'indicatorCode': indicatorCode, 'countryCode': countryCode},
              detectedAt: DateTime.now(),
            ));
          }
          
          // timeSeries 데이터 유효성 확인
          if (data['timeSeries'] != null) {
            final timeSeries = data['timeSeries'] as List;
            for (int i = 0; i < timeSeries.length; i++) {
              final entry = timeSeries[i];
              if (entry is! Map<String, dynamic> || 
                  !entry.containsKey('year') || 
                  !entry.containsKey('value')) {
                issues.add(DataIntegrityIssue(
                  type: 'invalid_data',
                  severity: 'warning',
                  description: 'timeSeries 항목이 올바르지 않음 (index: $i)',
                  location: 'indicators/$indicatorCode/series/$countryCode',
                  metadata: {'indicatorCode': indicatorCode, 'countryCode': countryCode, 'index': i},
                  detectedAt: DateTime.now(),
                ));
              }
            }
          }
          
          // lastUpdated 필드 확인
          if (!data.containsKey('lastUpdated')) {
            issues.add(DataIntegrityIssue(
              type: 'missing_field',
              severity: 'warning',
              description: 'lastUpdated 필드 누락',
              location: 'indicators/$indicatorCode/series/$countryCode',
              metadata: {'indicatorCode': indicatorCode, 'countryCode': countryCode},
              detectedAt: DateTime.now(),
            ));
          }
        }
      }
      
    } catch (e) {
      AppLogger.error('[DataAuditService] Error checking consistency: $e');
    }
    
    return issues;
  }

  Future<int> _getTotalDocumentCount() async {
    int total = 0;
    
    try {
      // indicators collection 카운트
      final indicatorsSnapshot = await _firestore.collection('indicators').get();
      total += indicatorsSnapshot.docs.length;
      
      for (final indicatorDoc in indicatorsSnapshot.docs) {
        final seriesSnapshot = await _firestore
            .collection('indicators')
            .doc(indicatorDoc.id)
            .collection('series')
            .get();
        total += seriesSnapshot.docs.length;
      }
      
      // countries collection 카운트
      final countriesSnapshot = await _firestore.collection('countries').get();
      total += countriesSnapshot.docs.length;
      
      for (final countryDoc in countriesSnapshot.docs) {
        final indicatorsSnapshot = await _firestore
            .collection('countries')
            .doc(countryDoc.id)
            .collection('indicators')
            .get();
        total += indicatorsSnapshot.docs.length;
      }
      
      // 기타 collection 카운트
      final usersSnapshot = await _firestore.collection('users').get();
      total += usersSnapshot.docs.length;
      
      final oecdCountriesSnapshot = await _firestore.collection('oecd_countries').get();
      total += oecdCountriesSnapshot.docs.length;
      
    } catch (e) {
      AppLogger.error('[DataAuditService] Error counting documents: $e');
    }
    
    return total;
  }

  bool _areDataEqual(Map<String, dynamic> data1, Map<String, dynamic> data2) {
    // 핵심 필드들만 비교 (lastUpdated 등은 제외)
    final keys = ['timeSeries', 'metadata', 'indicatorName', 'countryName'];
    
    for (final key in keys) {
      if (data1[key] != data2[key]) {
        return false;
      }
    }
    
    return true;
  }

  // admin_audit_logs의 하위 컬렉션에 감사 결과 저장
  Future<void> _saveAuditResultToAdminLog(DataAuditResult result, String adminAuditId) async {
    try {
      AppLogger.info('[DataAuditService] Saving audit result to admin log: $adminAuditId');

      // 간단한 요약 데이터만 저장 (복잡한 배열 제외)
      final simplifiedData = {
        'auditStartTime': result.auditStartTime.toIso8601String(),
        'auditEndTime': result.auditEndTime.toIso8601String(),
        'totalDocumentsChecked': result.totalDocumentsChecked,
        'integrityIssuesCount': result.integrityIssues.length,
        'duplicateDataCount': result.duplicateData.length,
        'orphanDocumentsCount': result.orphanDocuments.length,
        'statisticsSummary': result.statisticsSummary,
        'createdAt': FieldValue.serverTimestamp(),
        'parentAuditId': adminAuditId,
      };

      AppLogger.info('[DataAuditService] Simplified data prepared, keys: ${simplifiedData.keys.toList()}');

      final docRef = await _firestore
          .collection('admin_audit_logs')
          .doc(adminAuditId)
          .collection('data_audit_results')
          .add(simplifiedData);

      AppLogger.info('[DataAuditService] Audit result saved successfully: ${docRef.id}');

      // 텍스트 파일로도 내보내기
      try {
        await _exportAuditResultToFile(result, docRef.id);
        AppLogger.info('[DataAuditService] Text file export completed');
      } catch (fileError) {
        AppLogger.warning('[DataAuditService] Text file export failed: $fileError');
      }

    } catch (e, stackTrace) {
      AppLogger.error('[DataAuditService] Error saving audit result to admin log: $e');
      AppLogger.error('[DataAuditService] Stack trace: $stackTrace');

      // 실패 시 기존 방식으로 fallback
      try {
        AppLogger.warning('[DataAuditService] Falling back to standalone collection');
        await _saveAuditResult(result);
        AppLogger.info('[DataAuditService] Fallback save successful');
      } catch (fallbackError) {
        AppLogger.error('[DataAuditService] Fallback also failed: $fallbackError');
      }
    }
  }

  Future<void> _saveAuditResult(DataAuditResult result) async {
    try {
      final docRef = await _firestore.collection('data_audit_results').add({
        ...result.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 텍스트 파일로도 내보내기
      await _exportAuditResultToFile(result, docRef.id);

    } catch (e) {
      AppLogger.error('[DataAuditService] Error saving audit result: $e');
    }
  }

  // 퀵 감사 (최근 7일간 데이터만)
  Stream<String> quickAudit() async* {
    yield '[시작] 빠른 감사를 시작합니다...';
    
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      yield '[진행] 최근 7일간 수정된 데이터 확인 중...';
      
      final recentIndicators = await _firestore
          .collection('indicators')
          .where('lastUpdated', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();
      
      yield '[정보] 최근 수정된 indicators: ${recentIndicators.docs.length}개';
      
      int issuesFound = 0;
      
      for (final doc in recentIndicators.docs) {
        final seriesSnapshot = await _firestore
            .collection('indicators')
            .doc(doc.id)
            .collection('series')
            .get();
        
        for (final seriesDoc in seriesSnapshot.docs) {
          final data = seriesDoc.data();
          
          // 기본적인 데이터 유효성만 확인
          if (!data.containsKey('timeSeries') || data['timeSeries'] == null) {
            issuesFound++;
          }
        }
      }
      
      yield '[완료] 빠른 감사 완료';
      yield issuesFound == 0 
          ? '[결과] 문제가 발견되지 않았습니다.' 
          : '[결과] $issuesFound건의 문제가 발견되었습니다.';
      
    } catch (e) {
      yield '[오류] 빠른 감사 중 오류 발생: $e';
    }
  }

  // 최신 감사 결과 ID 가져오기
  Future<String?> getLatestAuditResultId() async {
    try {
      final snapshot = await _firestore
          .collection('data_audit_results')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.id;
    } catch (e) {
      AppLogger.error('[DataAuditService] Error getting latest audit ID: $e');
      return null;
    }
  }

  // 최신 감사 결과 요약 정보 가져오기
  Future<Map<String, dynamic>?> getLatestAuditSummary() async {
    try {
      // 1. admin_audit_logs에서 완료된 감사 작업 찾기 (인덱스 없이 실행)
      final adminLogsSnapshot = await _firestore
          .collection('admin_audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(20) // 최근 20개만 확인하여 성능 최적화
          .get();

      if (adminLogsSnapshot.docs.isEmpty) {
        AppLogger.info('[DataAuditService] No admin logs found, trying fallback');
        return await _getLatestAuditSummaryFallback();
      }

      // 클라이언트 측에서 필터링: systemMaintenance + completed 상태만
      final completedAuditDocs = adminLogsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['actionType'] == 'systemMaintenance' && data['status'] == 'completed';
      }).toList();

      if (completedAuditDocs.isEmpty) {
        AppLogger.info('[DataAuditService] No completed audit logs found, trying fallback');
        return await _getLatestAuditSummaryFallback();
      }

      final adminLogDoc = completedAuditDocs.first;
      final adminLogData = adminLogDoc.data();

      // 2. 해당 admin_audit_logs 문서의 하위 컬렉션에서 감사 결과 가져오기
      final auditResultsSnapshot = await _firestore
          .collection('admin_audit_logs')
          .doc(adminLogDoc.id)
          .collection('data_audit_results')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (auditResultsSnapshot.docs.isEmpty) {
        AppLogger.warning('[DataAuditService] No audit results found in subcollection for ${adminLogDoc.id}');
        // admin_audit_logs의 메타데이터에서 요약 정보 추출
        final metadata = adminLogData['metadata'] as Map<String, dynamic>? ?? {};
        return {
          'duplicateDataCount': metadata['duplicates'] ?? 0,
          'orphanDocumentsCount': metadata['orphans'] ?? 0,
          'integrityIssuesCount': metadata['totalIssues'] ?? 0,
          'totalDocumentsChecked': metadata['totalDocuments'] ?? 0,
          'statisticsSummary': metadata,
          'auditStartTime': adminLogData['timestamp']?.toDate()?.toIso8601String(),
          'auditEndTime': adminLogData['updatedAt']?.toDate()?.toIso8601String(),
        };
      }

      final auditResultData = auditResultsSnapshot.docs.first.data();

      // 필요한 요약 정보만 추출
      return {
        'duplicateDataCount': auditResultData['duplicateDataCount'] ?? 0,
        'orphanDocumentsCount': auditResultData['orphanDocumentsCount'] ?? 0,
        'integrityIssuesCount': auditResultData['integrityIssuesCount'] ?? 0,
        'totalDocumentsChecked': auditResultData['totalDocumentsChecked'] ?? 0,
        'statisticsSummary': auditResultData['statisticsSummary'] ?? {},
        'auditStartTime': auditResultData['auditStartTime'],
        'auditEndTime': auditResultData['auditEndTime'],
      };
    } catch (e) {
      AppLogger.error('[DataAuditService] Error getting latest audit summary: $e');
      return await _getLatestAuditSummaryFallback();
    }
  }

  // 기존 data_audit_results 컬렉션에서 가져오는 fallback 메서드
  Future<Map<String, dynamic>?> _getLatestAuditSummaryFallback() async {
    try {
      final snapshot = await _firestore
          .collection('data_audit_results')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data();

      return {
        'duplicateDataCount': data['duplicateDataCount'] ?? 0,
        'orphanDocumentsCount': data['orphanDocumentsCount'] ?? 0,
        'integrityIssuesCount': data['integrityIssuesCount'] ?? 0,
        'totalDocumentsChecked': data['totalDocumentsChecked'] ?? 0,
        'statisticsSummary': data['statisticsSummary'] ?? {},
        'auditStartTime': data['auditStartTime'],
        'auditEndTime': data['auditEndTime'],
      };
    } catch (e) {
      AppLogger.error('[DataAuditService] Fallback also failed: $e');
      return null;
    }
  }

  // 최근 감사 결과 가져오기
  Future<List<DataAuditResult>> getRecentAuditResults({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('data_audit_results')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return DataAuditResult(
          auditStartTime: DateTime.parse(data['auditStartTime']),
          auditEndTime: DateTime.parse(data['auditEndTime']),
          totalDocumentsChecked: data['totalDocumentsChecked'],
          integrityIssues: [], // 요약 정보만 표시
          duplicateData: [],
          orphanDocuments: [],
          statisticsSummary: Map<String, int>.from(data['statisticsSummary']),
        );
      }).toList();

    } catch (e) {
      AppLogger.error('[DataAuditService] Error getting recent results: $e');
      return [];
    }
  }

  // 감사 결과를 텍스트 파일로 내보내기
  Future<String?> _exportAuditResultToFile(DataAuditResult result, String auditId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'audit_report_${auditId}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');

      final buffer = StringBuffer();

      // 헤더 정보
      buffer.writeln('=== 데이터 감사 보고서 ===');
      buffer.writeln('감사 ID: $auditId');
      buffer.writeln('감사 시작: ${result.auditStartTime}');
      buffer.writeln('감사 완료: ${result.auditEndTime}');
      buffer.writeln('총 검사 문서: ${result.totalDocumentsChecked}개');
      buffer.writeln('감사 소요시간: ${result.auditEndTime.difference(result.auditStartTime).inMinutes}분');
      buffer.writeln('');

      // 요약 정보
      buffer.writeln('=== 요약 ===');
      buffer.writeln('전체 문제: ${result.statisticsSummary['totalIssues']}건');
      buffer.writeln('중복 데이터: ${result.duplicateData.length}건');
      buffer.writeln('고아 문서: ${result.orphanDocuments.length}건');
      buffer.writeln('오류: ${result.statisticsSummary['errors']}건');
      buffer.writeln('경고: ${result.statisticsSummary['warnings']}건');
      buffer.writeln('');

      // 중복 데이터 상세 정보
      if (result.duplicateData.isNotEmpty) {
        buffer.writeln('=== 중복 데이터 상세 ===');
        for (int i = 0; i < result.duplicateData.length; i++) {
          final duplicate = result.duplicateData[i];
          buffer.writeln('${i + 1}. ${duplicate.indicatorCode}/${duplicate.countryCode}');
          buffer.writeln('   위치:');
          for (final location in duplicate.locations) {
            buffer.writeln('   - $location');
          }
          buffer.writeln('   충돌 데이터:');

          // indicators 데이터
          final indicatorsData = duplicate.conflictingData['indicators_data'] as Map<String, dynamic>?;
          if (indicatorsData != null) {
            buffer.writeln('   [indicators 위치]');
            buffer.writeln('   - indicatorName: ${indicatorsData['indicatorName']}');
            buffer.writeln('   - countryName: ${indicatorsData['countryName']}');
            if (indicatorsData['timeSeries'] is List) {
              final timeSeries = indicatorsData['timeSeries'] as List;
              buffer.writeln('   - timeSeries: ${timeSeries.length}개 항목');
              if (timeSeries.isNotEmpty) {
                buffer.writeln('     최신: ${timeSeries.first}');
              }
            }
            if (indicatorsData['metadata'] != null) {
              buffer.writeln('   - metadata: ${indicatorsData['metadata']}');
            }
          }

          // countries 데이터
          final countriesData = duplicate.conflictingData['countries_data'] as Map<String, dynamic>?;
          if (countriesData != null) {
            buffer.writeln('   [countries 위치]');
            buffer.writeln('   - indicatorName: ${countriesData['indicatorName']}');
            buffer.writeln('   - countryName: ${countriesData['countryName']}');
            if (countriesData['timeSeries'] is List) {
              final timeSeries = countriesData['timeSeries'] as List;
              buffer.writeln('   - timeSeries: ${timeSeries.length}개 항목');
              if (timeSeries.isNotEmpty) {
                buffer.writeln('     최신: ${timeSeries.first}');
              }
            }
            if (countriesData['metadata'] != null) {
              buffer.writeln('   - metadata: ${countriesData['metadata']}');
            }
          }
          buffer.writeln('');
        }
      }

      // 고아 문서 상세 정보
      if (result.orphanDocuments.isNotEmpty) {
        buffer.writeln('=== 고아 문서 상세 ===');
        for (int i = 0; i < result.orphanDocuments.length; i++) {
          final orphan = result.orphanDocuments[i];
          buffer.writeln('${i + 1}. ${orphan.path}');
          buffer.writeln('   유형: ${orphan.type}');
          buffer.writeln('   이유: ${orphan.reason}');
          buffer.writeln('   데이터 크기: ${orphan.data.keys.length}개 필드');
          buffer.writeln('');
        }
      }

      // 무결성 문제 상세 정보
      if (result.integrityIssues.isNotEmpty) {
        buffer.writeln('=== 무결성 문제 상세 ===');
        for (int i = 0; i < result.integrityIssues.length; i++) {
          final issue = result.integrityIssues[i];
          buffer.writeln('${i + 1}. [${issue.severity.toUpperCase()}] ${issue.type}');
          buffer.writeln('   설명: ${issue.description}');
          buffer.writeln('   위치: ${issue.location}');
          buffer.writeln('   발견시각: ${issue.detectedAt}');
          if (issue.metadata.isNotEmpty) {
            buffer.writeln('   메타데이터: ${issue.metadata}');
          }
          buffer.writeln('');
        }
      }

      buffer.writeln('=== 권장 조치사항 ===');
      if (result.duplicateData.isNotEmpty) {
        buffer.writeln('1. 중복 데이터 ${result.duplicateData.length}건을 확인하고 정합성을 맞춰주세요.');
        buffer.writeln('   - World Bank API에서 최신 데이터를 다시 수집하거나');
        buffer.writeln('   - 수동으로 올바른 데이터로 통합해주세요.');
      }
      if (result.orphanDocuments.isNotEmpty) {
        buffer.writeln('2. 고아 문서 ${result.orphanDocuments.length}건을 정리해주세요.');
        buffer.writeln('   - 불필요한 문서는 삭제하거나');
        buffer.writeln('   - 누락된 대응 문서를 생성해주세요.');
      }
      if (result.integrityIssues.isNotEmpty) {
        buffer.writeln('3. 무결성 문제 ${result.integrityIssues.length}건을 수정해주세요.');
        buffer.writeln('   - 누락된 필드를 추가하거나');
        buffer.writeln('   - 잘못된 데이터 형식을 수정해주세요.');
      }

      await file.writeAsString(buffer.toString());

      AppLogger.info('[DataAuditService] Audit report exported to: ${file.path}');
      return file.path;

    } catch (e) {
      AppLogger.error('[DataAuditService] Error exporting audit result: $e');
      return null;
    }
  }

  // 사용자가 저장 위치를 선택하여 감사 결과를 텍스트 파일로 내보내기
  Future<String?> exportAuditResultWithFilePicker(String auditId) async {
    try {
      AppLogger.info('[DataAuditService] Starting export for audit ID: $auditId');

      // 새로운 구조에서 감사 결과 찾기 시도
      final newStructureResult = await _tryFindAuditResultInNewStructure(auditId);
      if (newStructureResult != null) {
        return await _exportDataAuditResult(newStructureResult, auditId);
      }

      // Fallback: 기존 구조에서 감사 결과 가져오기
      AppLogger.info('[DataAuditService] Trying fallback - standalone collection');
      final auditDoc = await _firestore.collection('data_audit_results').doc(auditId).get();

      if (!auditDoc.exists) {
        AppLogger.error('[DataAuditService] Audit result not found: $auditId');
        return null;
      }

      AppLogger.info('[DataAuditService] Audit document found, loading data...');

      final data = auditDoc.data()!;

      // DataAuditResult 객체 재구성
      final result = DataAuditResult(
        auditStartTime: DateTime.parse(data['auditStartTime']),
        auditEndTime: DateTime.parse(data['auditEndTime']),
        totalDocumentsChecked: data['totalDocumentsChecked'],
        integrityIssues: (data['integrityIssues'] as List<dynamic>?)?.map((item) {
          final issueData = item as Map<String, dynamic>;
          return DataIntegrityIssue(
            type: issueData['type'],
            severity: issueData['severity'],
            description: issueData['description'],
            location: issueData['location'],
            metadata: Map<String, dynamic>.from(issueData['metadata']),
            detectedAt: DateTime.parse(issueData['detectedAt']),
          );
        }).toList() ?? [],
        duplicateData: (data['duplicateData'] as List<dynamic>?)?.map((item) {
          final dupData = item as Map<String, dynamic>;
          return DuplicateData(
            indicatorCode: dupData['indicatorCode'],
            countryCode: dupData['countryCode'],
            locations: List<String>.from(dupData['locations']),
            conflictingData: Map<String, dynamic>.from(dupData['conflictingData']),
          );
        }).toList() ?? [],
        orphanDocuments: (data['orphanDocuments'] as List<dynamic>?)?.map((item) {
          final orphanData = item as Map<String, dynamic>;
          return OrphanDocument(
            path: orphanData['path'],
            type: orphanData['type'],
            reason: orphanData['reason'],
            data: Map<String, dynamic>.from(orphanData['data']),
          );
        }).toList() ?? [],
        statisticsSummary: Map<String, int>.from(data['statisticsSummary']),
      );

      // 파일 저장 위치 선택
      final fileName = 'audit_report_${auditId}_${DateTime.now().millisecondsSinceEpoch}.txt';

      AppLogger.info('[DataAuditService] Opening file picker with filename: $fileName');

      String? outputPath;
      bool useFilePicker = true;

      // macOS에서는 FilePicker 대신 바로 Downloads 폴더 사용 (더 안정적)
      if (Platform.isMacOS) {
        AppLogger.info('[DataAuditService] macOS detected, using Downloads directory directly');
        useFilePicker = false;
      }

      if (useFilePicker) {
        try {
          AppLogger.info('[DataAuditService] Attempting to open file picker...');
          outputPath = await FilePicker.platform.saveFile(
            dialogTitle: '감사 보고서 저장 위치 선택',
            fileName: fileName,
          );
          AppLogger.info('[DataAuditService] File picker completed. Result: $outputPath');

          if (outputPath != null) {
            AppLogger.info('[DataAuditService] File picker successful: $outputPath');
          } else {
            AppLogger.info('[DataAuditService] File picker returned null (user cancelled or error)');
          }
        } catch (e, stackTrace) {
          AppLogger.error('[DataAuditService] File picker failed with error: $e');
          AppLogger.error('[DataAuditService] File picker stack trace: $stackTrace');
          outputPath = null;
        }
      }

      // File picker가 실패했거나 null을 반환한 경우 fallback 사용
      if (outputPath == null) {
        AppLogger.info('[DataAuditService] Using fallback directory options...');

        // Fallback 1: Downloads 폴더
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            outputPath = '${downloadsDir.path}/$fileName';
            AppLogger.info('[DataAuditService] Using Downloads directory: $outputPath');
          } else {
            AppLogger.warning('[DataAuditService] Downloads directory not available');
          }
        } catch (e) {
          AppLogger.error('[DataAuditService] Downloads directory access failed: $e');
        }

        // Fallback 2: Documents 폴더
        if (outputPath == null) {
          try {
            final documentsDir = await getApplicationDocumentsDirectory();
            outputPath = '${documentsDir.path}/$fileName';
            AppLogger.info('[DataAuditService] Using Documents directory: $outputPath');
          } catch (e) {
            AppLogger.error('[DataAuditService] Documents directory access failed: $e');
            return null;
          }
        }

        // Fallback 3: Temporary 폴더 (최후의 수단)
        if (outputPath == null) {
          try {
            final tempDir = await getTemporaryDirectory();
            outputPath = '${tempDir.path}/$fileName';
            AppLogger.info('[DataAuditService] Using temporary directory: $outputPath');
          } catch (e) {
            AppLogger.error('[DataAuditService] Temporary directory access failed: $e');
            return null;
          }
        }
      }

      if (outputPath == null) {
        AppLogger.error('[DataAuditService] All fallback options failed');
        return null;
      }

      // 확장자 확인 및 추가
      if (!outputPath.endsWith('.txt')) {
        outputPath = '$outputPath.txt';
      }

      // 보고서 내용 생성
      AppLogger.info('[DataAuditService] Generating report content...');
      final reportContent = _generateAuditReportContent(result, auditId);
      AppLogger.info('[DataAuditService] Report content generated. Length: ${reportContent.length} characters');

      // 파일 저장
      AppLogger.info('[DataAuditService] Writing file to: $outputPath');
      final file = File(outputPath);

      // 디렉토리가 존재하는지 확인하고 필요시 생성
      final directory = file.parent;
      if (!await directory.exists()) {
        AppLogger.info('[DataAuditService] Creating directory: ${directory.path}');
        await directory.create(recursive: true);
      }

      await file.writeAsString(reportContent);

      if (await file.exists()) {
        final fileSize = await file.length();
        AppLogger.info('[DataAuditService] File written successfully. Size: $fileSize bytes');
        AppLogger.info('[DataAuditService] Audit report exported to: $outputPath');
        return outputPath;
      } else {
        AppLogger.error('[DataAuditService] File was not created successfully');
        return null;
      }

    } catch (e, stackTrace) {
      AppLogger.error('[DataAuditService] Error exporting audit result: $e');
      AppLogger.error('[DataAuditService] Stack trace: $stackTrace');
      return null;
    }
  }

  // 테스트용 간단한 내보내기 (디버깅용)
  Future<String?> exportTestReport() async {
    try {
      AppLogger.info('[DataAuditService] Starting test export...');

      // 간단한 테스트 내용
      final testContent = '''
=== 테스트 감사 보고서 ===
생성일시: ${DateTime.now()}
테스트 목적: 파일 저장 기능 확인

이 파일이 정상적으로 저장되면 내보내기 기능이 작동하고 있습니다.
''';

      final fileName = 'test_audit_report_${DateTime.now().millisecondsSinceEpoch}.txt';
      AppLogger.info('[DataAuditService] Test filename: $fileName');

      // macOS에서는 Downloads 폴더에 직접 저장
      String? outputPath;
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          outputPath = '${downloadsDir.path}/$fileName';
          AppLogger.info('[DataAuditService] Test output path: $outputPath');
        } else {
          final documentsDir = await getApplicationDocumentsDirectory();
          outputPath = '${documentsDir.path}/$fileName';
          AppLogger.info('[DataAuditService] Fallback to documents: $outputPath');
        }

        final file = File(outputPath);
        await file.writeAsString(testContent);

        if (await file.exists()) {
          final fileSize = await file.length();
          AppLogger.info('[DataAuditService] Test file created successfully. Size: $fileSize bytes');
          return outputPath;
        } else {
          AppLogger.error('[DataAuditService] Test file was not created');
          return null;
        }

      } catch (e, stackTrace) {
        AppLogger.error('[DataAuditService] Test export failed: $e');
        AppLogger.error('[DataAuditService] Test stack trace: $stackTrace');
        return null;
      }

    } catch (e, stackTrace) {
      AppLogger.error('[DataAuditService] Test export outer error: $e');
      AppLogger.error('[DataAuditService] Test outer stack trace: $stackTrace');
      return null;
    }
  }

  // 감사 보고서 내용 생성 (기존 코드를 별도 메서드로 분리)
  String _generateAuditReportContent(DataAuditResult result, String auditId) {
    final buffer = StringBuffer();

    // 헤더 정보
    buffer.writeln('=== 데이터 감사 보고서 ===');
    buffer.writeln('감사 ID: $auditId');
    buffer.writeln('감사 시작: ${result.auditStartTime}');
    buffer.writeln('감사 완료: ${result.auditEndTime}');
    buffer.writeln('총 검사 문서: ${result.totalDocumentsChecked}개');
    buffer.writeln('감사 소요시간: ${result.auditEndTime.difference(result.auditStartTime).inMinutes}분');
    buffer.writeln('');

    // 요약 정보
    buffer.writeln('=== 요약 ===');
    buffer.writeln('전체 문제: ${result.statisticsSummary['totalIssues']}건');
    buffer.writeln('중복 데이터: ${result.duplicateData.length}건');
    buffer.writeln('고아 문서: ${result.orphanDocuments.length}건');
    buffer.writeln('오류: ${result.statisticsSummary['errors']}건');
    buffer.writeln('경고: ${result.statisticsSummary['warnings']}건');
    buffer.writeln('');

    // 중복 데이터 상세 정보
    if (result.duplicateData.isNotEmpty) {
      buffer.writeln('=== 중복 데이터 상세 ===');
      for (int i = 0; i < result.duplicateData.length; i++) {
        final duplicate = result.duplicateData[i];
        buffer.writeln('${i + 1}. ${duplicate.indicatorCode}/${duplicate.countryCode}');
        buffer.writeln('   위치:');
        for (final location in duplicate.locations) {
          buffer.writeln('   - $location');
        }
        buffer.writeln('   충돌 데이터:');

        // indicators 데이터
        final indicatorsData = duplicate.conflictingData['indicators_data'] as Map<String, dynamic>?;
        if (indicatorsData != null) {
          buffer.writeln('   [indicators 위치]');
          buffer.writeln('   - indicatorName: ${indicatorsData['indicatorName']}');
          buffer.writeln('   - countryName: ${indicatorsData['countryName']}');
          if (indicatorsData['timeSeries'] is List) {
            final timeSeries = indicatorsData['timeSeries'] as List;
            buffer.writeln('   - timeSeries: ${timeSeries.length}개 항목');
            if (timeSeries.isNotEmpty) {
              buffer.writeln('     최신: ${timeSeries.first}');
            }
          }
          if (indicatorsData['metadata'] != null) {
            buffer.writeln('   - metadata: ${indicatorsData['metadata']}');
          }
        }

        // countries 데이터
        final countriesData = duplicate.conflictingData['countries_data'] as Map<String, dynamic>?;
        if (countriesData != null) {
          buffer.writeln('   [countries 위치]');
          buffer.writeln('   - indicatorName: ${countriesData['indicatorName']}');
          buffer.writeln('   - countryName: ${countriesData['countryName']}');
          if (countriesData['timeSeries'] is List) {
            final timeSeries = countriesData['timeSeries'] as List;
            buffer.writeln('   - timeSeries: ${timeSeries.length}개 항목');
            if (timeSeries.isNotEmpty) {
              buffer.writeln('     최신: ${timeSeries.first}');
            }
          }
          if (countriesData['metadata'] != null) {
            buffer.writeln('   - metadata: ${countriesData['metadata']}');
          }
        }
        buffer.writeln('');
      }
    }

    // 고아 문서 상세 정보
    if (result.orphanDocuments.isNotEmpty) {
      buffer.writeln('=== 고아 문서 상세 ===');
      for (int i = 0; i < result.orphanDocuments.length; i++) {
        final orphan = result.orphanDocuments[i];
        buffer.writeln('${i + 1}. ${orphan.path}');
        buffer.writeln('   유형: ${orphan.type}');
        buffer.writeln('   이유: ${orphan.reason}');
        buffer.writeln('   데이터 크기: ${orphan.data.keys.length}개 필드');
        buffer.writeln('');
      }
    }

    // 무결성 문제 상세 정보
    if (result.integrityIssues.isNotEmpty) {
      buffer.writeln('=== 무결성 문제 상세 ===');
      for (int i = 0; i < result.integrityIssues.length; i++) {
        final issue = result.integrityIssues[i];
        buffer.writeln('${i + 1}. [${issue.severity.toUpperCase()}] ${issue.type}');
        buffer.writeln('   설명: ${issue.description}');
        buffer.writeln('   위치: ${issue.location}');
        buffer.writeln('   발견시각: ${issue.detectedAt}');
        if (issue.metadata.isNotEmpty) {
          buffer.writeln('   메타데이터: ${issue.metadata}');
        }
        buffer.writeln('');
      }
    }

    buffer.writeln('=== 권장 조치사항 ===');
    if (result.duplicateData.isNotEmpty) {
      buffer.writeln('1. 중복 데이터 ${result.duplicateData.length}건을 확인하고 정합성을 맞춰주세요.');
      buffer.writeln('   - World Bank API에서 최신 데이터를 다시 수집하거나');
      buffer.writeln('   - 수동으로 올바른 데이터로 통합해주세요.');
    }
    if (result.orphanDocuments.isNotEmpty) {
      buffer.writeln('2. 고아 문서 ${result.orphanDocuments.length}건을 정리해주세요.');
      buffer.writeln('   - 불필요한 문서는 삭제하거나');
      buffer.writeln('   - 누락된 대응 문서를 생성해주세요.');
    }
    if (result.integrityIssues.isNotEmpty) {
      buffer.writeln('3. 무결성 문제 ${result.integrityIssues.length}건을 수정해주세요.');
      buffer.writeln('   - 누락된 필드를 추가하거나');
      buffer.writeln('   - 잘못된 데이터 형식을 수정해주세요.');
    }

    return buffer.toString();
  }

  // 중복 데이터 제거
  Stream<String> removeDuplicateData() async* {
    yield '[시작] 중복 데이터 제거를 시작합니다...';

    try {
      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '중복 데이터 제거 시작',
        status: AdminActionStatus.started,
      );

      // 먼저 중복 데이터 찾기
      yield '[진행] 중복 데이터 검색 중...';
      final duplicates = await _findDuplicateData();

      if (duplicates.isEmpty) {
        yield '[완료] 제거할 중복 데이터가 없습니다.';
        return;
      }

      yield '[정보] ${duplicates.length}건의 중복 데이터를 발견했습니다.';

      int processedCount = 0;
      int removedCount = 0;

      for (final duplicate in duplicates) {
        try {
          yield '[진행] ${duplicate.indicatorCode}/${duplicate.countryCode} 처리 중... (${processedCount + 1}/${duplicates.length})';

          // 두 위치의 데이터를 비교하여 더 최신 데이터 유지
          final success = await _resolveDuplicateData(duplicate);

          if (success) {
            removedCount++;
            yield '[성공] ${duplicate.indicatorCode}/${duplicate.countryCode} 중복 해결 완료';
          } else {
            yield '[경고] ${duplicate.indicatorCode}/${duplicate.countryCode} 중복 해결 실패';
          }

          processedCount++;

          // 처리 간격 (과부하 방지)
          await Future.delayed(const Duration(milliseconds: 100));

        } catch (e) {
          yield '[오류] ${duplicate.indicatorCode}/${duplicate.countryCode} 처리 중 오류: $e';
          processedCount++;
        }
      }

      yield '[완료] 중복 데이터 제거 완료';
      yield '[결과] 총 ${duplicates.length}건 중 ${removedCount}건 해결, ${duplicates.length - removedCount}건 실패';

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '중복 데이터 제거 완료',
        status: AdminActionStatus.completed,
        metadata: {
          'totalDuplicates': duplicates.length,
          'removedCount': removedCount,
          'failedCount': duplicates.length - removedCount,
        },
      );

    } catch (e) {
      yield '[오류] 중복 데이터 제거 중 오류 발생: $e';
      AppLogger.error('[DataAuditService] Remove duplicates failed: $e');

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '중복 데이터 제거 실패',
        status: AdminActionStatus.failed,
        metadata: {'error': e.toString()},
      );
    }
  }

  // 개별 중복 데이터 해결
  Future<bool> _resolveDuplicateData(DuplicateData duplicate) async {
    try {
      final indicatorsData = duplicate.conflictingData['indicators_data'] as Map<String, dynamic>;
      final countriesData = duplicate.conflictingData['countries_data'] as Map<String, dynamic>;

      // 어느 것이 더 최신인지 판단 (lastUpdated 기준)
      DateTime? indicatorsLastUpdated;
      DateTime? countriesLastUpdated;

      if (indicatorsData['lastUpdated'] != null) {
        if (indicatorsData['lastUpdated'] is Timestamp) {
          indicatorsLastUpdated = (indicatorsData['lastUpdated'] as Timestamp).toDate();
        } else if (indicatorsData['lastUpdated'] is String) {
          indicatorsLastUpdated = DateTime.parse(indicatorsData['lastUpdated']);
        }
      }

      if (countriesData['lastUpdated'] != null) {
        if (countriesData['lastUpdated'] is Timestamp) {
          countriesLastUpdated = (countriesData['lastUpdated'] as Timestamp).toDate();
        } else if (countriesData['lastUpdated'] is String) {
          countriesLastUpdated = DateTime.parse(countriesData['lastUpdated']);
        }
      }

      // 더 최신 데이터 결정
      Map<String, dynamic> sourceData;
      String targetPath;

      if (indicatorsLastUpdated != null && countriesLastUpdated != null) {
        if (indicatorsLastUpdated.isAfter(countriesLastUpdated)) {
          // indicators 데이터가 더 최신
          sourceData = indicatorsData;
          targetPath = 'countries/${duplicate.countryCode}/indicators/${duplicate.indicatorCode}';
        } else {
          // countries 데이터가 더 최신
          sourceData = countriesData;
          targetPath = 'indicators/${duplicate.indicatorCode}/series/${duplicate.countryCode}';
        }
      } else if (indicatorsLastUpdated != null) {
        // indicators만 lastUpdated가 있음
        sourceData = indicatorsData;
        targetPath = 'countries/${duplicate.countryCode}/indicators/${duplicate.indicatorCode}';
      } else if (countriesLastUpdated != null) {
        // countries만 lastUpdated가 있음
        sourceData = countriesData;
        targetPath = 'indicators/${duplicate.indicatorCode}/series/${duplicate.countryCode}';
      } else {
        // 둘 다 lastUpdated가 없으면 timeSeries 길이로 판단
        final indicatorsTimeSeries = indicatorsData['timeSeries'] as List? ?? [];
        final countriesTimeSeries = countriesData['timeSeries'] as List? ?? [];

        if (indicatorsTimeSeries.length >= countriesTimeSeries.length) {
          sourceData = indicatorsData;
          targetPath = 'countries/${duplicate.countryCode}/indicators/${duplicate.indicatorCode}';
        } else {
          sourceData = countriesData;
          targetPath = 'indicators/${duplicate.indicatorCode}/series/${duplicate.countryCode}';
        }
      }

      // 타겟 위치에 소스 데이터로 업데이트
      sourceData['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore.doc(targetPath).set(sourceData, SetOptions(merge: true));

      AppLogger.info('[DataAuditService] Resolved duplicate for ${duplicate.indicatorCode}/${duplicate.countryCode}');
      return true;

    } catch (e) {
      AppLogger.error('[DataAuditService] Failed to resolve duplicate ${duplicate.indicatorCode}/${duplicate.countryCode}: $e');
      return false;
    }
  }

  // 오래된 데이터 제거
  Stream<String> removeOutdatedData({int daysOld = 365}) async* {
    yield '[시작] 오래된 데이터 제거를 시작합니다...';

    try {
      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '오래된 데이터 제거 시작',
        status: AdminActionStatus.started,
      );

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      yield '[정보] ${daysOld}일 이전 데이터를 검색합니다 (기준일: ${cutoffDate.toString().substring(0, 10)})';

      int removedCount = 0;
      int checkedCount = 0;

      // indicators collection 확인
      yield '[진행] indicators 컬렉션 검사 중...';
      final indicatorsSnapshot = await _firestore.collection('indicators').get();

      for (final indicatorDoc in indicatorsSnapshot.docs) {
        final indicatorCode = indicatorDoc.id;

        final seriesSnapshot = await _firestore
            .collection('indicators')
            .doc(indicatorCode)
            .collection('series')
            .get();

        for (final seriesDoc in seriesSnapshot.docs) {
          checkedCount++;
          final data = seriesDoc.data();

          // lastUpdated 확인
          DateTime? lastUpdated;
          if (data['lastUpdated'] != null) {
            if (data['lastUpdated'] is Timestamp) {
              lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
            } else if (data['lastUpdated'] is String) {
              lastUpdated = DateTime.parse(data['lastUpdated']);
            }
          }

          // timeSeries가 오래된 데이터만 포함하는지 확인
          bool hasOldDataOnly = true;
          if (data['timeSeries'] is List) {
            final timeSeries = data['timeSeries'] as List;
            for (final entry in timeSeries) {
              if (entry is Map<String, dynamic> && entry['year'] != null) {
                final year = entry['year'] as int;
                if (year >= cutoffDate.year - 1) { // 최근 2년 내 데이터가 있으면 유지
                  hasOldDataOnly = false;
                  break;
                }
              }
            }
          }

          // 제거 조건: lastUpdated가 오래되었거나 timeSeries가 모두 오래된 데이터
          bool shouldRemove = false;
          if (lastUpdated != null && lastUpdated.isBefore(cutoffDate)) {
            shouldRemove = true;
          } else if (hasOldDataOnly && (data['timeSeries'] as List?)?.isNotEmpty == true) {
            shouldRemove = true;
          }

          if (shouldRemove) {
            try {
              await seriesDoc.reference.delete();
              removedCount++;

              if (removedCount % 10 == 0) {
                yield '[진행] ${removedCount}개 문서 제거 완료 (검사: ${checkedCount}개)';
              }
            } catch (e) {
              yield '[경고] ${indicatorCode}/${seriesDoc.id} 제거 실패: $e';
            }
          }
        }
      }

      // countries collection도 동일하게 처리
      yield '[진행] countries 컬렉션 검사 중...';
      final countriesSnapshot = await _firestore.collection('countries').get();

      for (final countryDoc in countriesSnapshot.docs) {
        final countryCode = countryDoc.id;

        final indicatorsSnapshot = await _firestore
            .collection('countries')
            .doc(countryCode)
            .collection('indicators')
            .get();

        for (final indicatorDoc in indicatorsSnapshot.docs) {
          checkedCount++;
          final data = indicatorDoc.data();

          DateTime? lastUpdated;
          if (data['lastUpdated'] != null) {
            if (data['lastUpdated'] is Timestamp) {
              lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
            } else if (data['lastUpdated'] is String) {
              lastUpdated = DateTime.parse(data['lastUpdated']);
            }
          }

          bool hasOldDataOnly = true;
          if (data['timeSeries'] is List) {
            final timeSeries = data['timeSeries'] as List;
            for (final entry in timeSeries) {
              if (entry is Map<String, dynamic> && entry['year'] != null) {
                final year = entry['year'] as int;
                if (year >= cutoffDate.year - 1) {
                  hasOldDataOnly = false;
                  break;
                }
              }
            }
          }

          bool shouldRemove = false;
          if (lastUpdated != null && lastUpdated.isBefore(cutoffDate)) {
            shouldRemove = true;
          } else if (hasOldDataOnly && (data['timeSeries'] as List?)?.isNotEmpty == true) {
            shouldRemove = true;
          }

          if (shouldRemove) {
            try {
              await indicatorDoc.reference.delete();
              removedCount++;

              if (removedCount % 10 == 0) {
                yield '[진행] ${removedCount}개 문서 제거 완료 (검사: ${checkedCount}개)';
              }
            } catch (e) {
              yield '[경고] ${countryCode}/${indicatorDoc.id} 제거 실패: $e';
            }
          }
        }
      }

      yield '[완료] 오래된 데이터 제거 완료';
      yield '[결과] 총 ${checkedCount}개 문서 검사, ${removedCount}개 문서 제거';

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '오래된 데이터 제거 완료',
        status: AdminActionStatus.completed,
        metadata: {
          'daysOld': daysOld,
          'checkedCount': checkedCount,
          'removedCount': removedCount,
        },
      );

    } catch (e) {
      yield '[오류] 오래된 데이터 제거 중 오류 발생: $e';
      AppLogger.error('[DataAuditService] Remove outdated data failed: $e');

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: '오래된 데이터 제거 실패',
        status: AdminActionStatus.failed,
        metadata: {'error': e.toString()},
      );
    }
  }

  // 새로운 구조(admin_audit_logs 하위 컬렉션)에서 감사 결과 찾기
  Future<DataAuditResult?> _tryFindAuditResultInNewStructure(String auditId) async {
    try {
      AppLogger.info('[DataAuditService] Looking for audit result in new structure');

      // admin_audit_logs에서 최신 감사 작업 찾기 (인덱스 없이 실행)
      final adminLogsSnapshot = await _firestore
          .collection('admin_audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(20) // 최신 20개 확인
          .get();

      if (adminLogsSnapshot.docs.isEmpty) {
        AppLogger.info('[DataAuditService] No admin logs found');
        return null;
      }

      // 클라이언트 측에서 필터링: systemMaintenance + completed 상태만
      final completedAuditDocs = adminLogsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['actionType'] == 'systemMaintenance' && data['status'] == 'completed';
      }).toList();

      if (completedAuditDocs.isEmpty) {
        AppLogger.info('[DataAuditService] No completed audit logs found');
        return null;
      }

      // 각 admin_audit_logs 문서의 하위 컬렉션에서 해당 auditId 찾기
      for (final adminLogDoc in completedAuditDocs) {
        final auditResultsSnapshot = await _firestore
            .collection('admin_audit_logs')
            .doc(adminLogDoc.id)
            .collection('data_audit_results')
            .doc(auditId)
            .get();

        if (auditResultsSnapshot.exists) {
          AppLogger.info('[DataAuditService] Found audit result in admin log: ${adminLogDoc.id}');
          final data = auditResultsSnapshot.data()!;

          return DataAuditResult(
            auditStartTime: DateTime.parse(data['auditStartTime']),
            auditEndTime: DateTime.parse(data['auditEndTime']),
            totalDocumentsChecked: data['totalDocumentsChecked'],
            integrityIssues: (data['integrityIssues'] as List<dynamic>?)?.map((item) {
              final issueData = item as Map<String, dynamic>;
              return DataIntegrityIssue(
                type: issueData['type'],
                severity: issueData['severity'],
                description: issueData['description'],
                location: issueData['location'],
                metadata: Map<String, dynamic>.from(issueData['metadata']),
                detectedAt: DateTime.parse(issueData['detectedAt']),
              );
            }).toList() ?? [],
            duplicateData: (data['duplicateData'] as List<dynamic>?)?.map((item) {
              final dupData = item as Map<String, dynamic>;
              return DuplicateData(
                indicatorCode: dupData['indicatorCode'],
                countryCode: dupData['countryCode'],
                locations: List<String>.from(dupData['locations']),
                conflictingData: Map<String, dynamic>.from(dupData['conflictingData']),
              );
            }).toList() ?? [],
            orphanDocuments: (data['orphanDocuments'] as List<dynamic>?)?.map((item) {
              final orphanData = item as Map<String, dynamic>;
              return OrphanDocument(
                path: orphanData['path'],
                type: orphanData['type'],
                reason: orphanData['reason'],
                data: Map<String, dynamic>.from(orphanData['data']),
              );
            }).toList() ?? [],
            statisticsSummary: Map<String, int>.from(data['statisticsSummary']),
          );
        }
      }

      AppLogger.info('[DataAuditService] Audit result not found in new structure');
      return null;

    } catch (e) {
      AppLogger.error('[DataAuditService] Error finding audit result in new structure: $e');
      return null;
    }
  }

  // DataAuditResult를 파일로 내보내는 공통 메서드
  Future<String?> _exportDataAuditResult(DataAuditResult result, String auditId) async {
    try {
      AppLogger.info('[DataAuditService] Exporting audit result: $auditId');

      // 파일 저장 위치 선택
      final fileName = 'audit_report_${auditId}_${DateTime.now().millisecondsSinceEpoch}.txt';

      AppLogger.info('[DataAuditService] Opening file picker with filename: $fileName');

      String? outputPath;
      bool useFilePicker = true;

      // macOS에서는 FilePicker 대신 바로 Downloads 폴더 사용 (더 안정적)
      if (Platform.isMacOS) {
        AppLogger.info('[DataAuditService] macOS detected, using Downloads directory directly');
        useFilePicker = false;
      }

      if (useFilePicker) {
        try {
          AppLogger.info('[DataAuditService] Attempting to open file picker...');
          outputPath = await FilePicker.platform.saveFile(
            dialogTitle: '감사 보고서 저장 위치 선택',
            fileName: fileName,
          );
          AppLogger.info('[DataAuditService] File picker completed. Result: $outputPath');

          if (outputPath != null) {
            AppLogger.info('[DataAuditService] File picker successful: $outputPath');
          } else {
            AppLogger.info('[DataAuditService] File picker returned null (user cancelled or error)');
          }
        } catch (e, stackTrace) {
          AppLogger.error('[DataAuditService] File picker failed with error: $e');
          AppLogger.error('[DataAuditService] File picker stack trace: $stackTrace');
          outputPath = null;
        }
      }

      // File picker가 실패했거나 null을 반환한 경우 fallback 사용
      if (outputPath == null) {
        AppLogger.info('[DataAuditService] Using fallback directory options...');

        // Fallback 1: Downloads 폴더
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            outputPath = '${downloadsDir.path}/$fileName';
            AppLogger.info('[DataAuditService] Using Downloads directory: $outputPath');
          } else {
            AppLogger.warning('[DataAuditService] Downloads directory not available');
          }
        } catch (e) {
          AppLogger.error('[DataAuditService] Downloads directory access failed: $e');
        }

        // Fallback 2: Documents 폴더
        if (outputPath == null) {
          try {
            final documentsDir = await getApplicationDocumentsDirectory();
            outputPath = '${documentsDir.path}/$fileName';
            AppLogger.info('[DataAuditService] Using Documents directory: $outputPath');
          } catch (e) {
            AppLogger.error('[DataAuditService] Documents directory access failed: $e');
            return null;
          }
        }

        // Fallback 3: Temporary 폴더 (최후의 수단)
        if (outputPath == null) {
          try {
            final tempDir = await getTemporaryDirectory();
            outputPath = '${tempDir.path}/$fileName';
            AppLogger.info('[DataAuditService] Using temporary directory: $outputPath');
          } catch (e) {
            AppLogger.error('[DataAuditService] Temporary directory access failed: $e');
            return null;
          }
        }
      }

      if (outputPath == null) {
        AppLogger.error('[DataAuditService] All fallback options failed');
        return null;
      }

      // 확장자 확인 및 추가
      if (!outputPath.endsWith('.txt')) {
        outputPath = '$outputPath.txt';
      }

      // 보고서 내용 생성
      AppLogger.info('[DataAuditService] Generating report content...');
      final reportContent = _generateAuditReportContent(result, auditId);
      AppLogger.info('[DataAuditService] Report content generated. Length: ${reportContent.length} characters');

      // 파일 저장
      AppLogger.info('[DataAuditService] Writing file to: $outputPath');
      final file = File(outputPath);

      // 디렉토리가 존재하는지 확인하고 필요시 생성
      final directory = file.parent;
      if (!await directory.exists()) {
        AppLogger.info('[DataAuditService] Creating directory: ${directory.path}');
        await directory.create(recursive: true);
      }

      await file.writeAsString(reportContent);

      if (await file.exists()) {
        final fileSize = await file.length();
        AppLogger.info('[DataAuditService] File written successfully. Size: $fileSize bytes');
        AppLogger.info('[DataAuditService] Audit report exported to: $outputPath');
        return outputPath;
      } else {
        AppLogger.error('[DataAuditService] File was not created successfully');
        return null;
      }

    } catch (e, stackTrace) {
      AppLogger.error('[DataAuditService] Error exporting audit result: $e');
      AppLogger.error('[DataAuditService] Stack trace: $stackTrace');
      return null;
    }
  }
}