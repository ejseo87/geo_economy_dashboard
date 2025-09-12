import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/logger.dart';

/// Firestore 완전 재구축 서비스
class FirestoreResetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 완전 재구축을 위한 데이터 삭제
  Future<Map<String, dynamic>> resetFirestoreData({
    bool preserveUsers = true,
    bool createBackup = true,
    Function(String)? onProgress,
  }) async {
    final result = <String, dynamic>{
      'startTime': DateTime.now().toIso8601String(),
      'preserveUsers': preserveUsers,
      'backupCreated': createBackup,
      'deletedCollections': <String, int>{},
      'preservedCollections': <String, int>{},
      'errors': <String>[],
      'totalDeleted': 0,
    };

    try {
      onProgress?.call('🔍 기존 데이터 분석 중...');
      
      // 삭제 대상 컬렉션 목록
      final collectionsToDelete = <String>[
        'indicator_data',      // Old 지표 데이터
        'oecd_stats',         // Old OECD 통계
        'oecd_countries',     // Old 국가 데이터 (새 구조로 재생성)
      ];
      
      // 사용자 보존 여부에 따라 users 컬렉션 처리
      if (!preserveUsers) {
        collectionsToDelete.add('users');
      }

      // 백업 생성 (옵션)
      if (createBackup) {
        onProgress?.call('💾 데이터 백업 생성 중...');
        await _createBackup(collectionsToDelete, result);
      }

      // 컬렉션별 삭제
      for (final collectionName in collectionsToDelete) {
        onProgress?.call('🗑️ 삭제 중: $collectionName');
        
        try {
          final deletedCount = await _deleteCollection(collectionName);
          final deletedCollections = result['deletedCollections'] as Map<String, int>;
          deletedCollections[collectionName] = deletedCount;
          result['totalDeleted'] = (result['totalDeleted'] as int) + deletedCount;
          
          AppLogger.info('[FirestoreReset] Deleted $deletedCount documents from $collectionName');
          
        } catch (e) {
          final errors = result['errors'] as List<String>;
          errors.add('Failed to delete $collectionName: $e');
          AppLogger.error('[FirestoreReset] Error deleting $collectionName: $e');
        }
      }

      // 보존된 컬렉션 확인
      if (preserveUsers) {
        final usersCount = await _getCollectionCount('users');
        final preservedCollections = result['preservedCollections'] as Map<String, int>;
        preservedCollections['users'] = usersCount;
      }

      result['endTime'] = DateTime.now().toIso8601String();
      AppLogger.info('[FirestoreReset] Reset completed: ${result['totalDeleted']} documents deleted');

    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error('[FirestoreReset] Reset failed: $e');
    }

    return result;
  }

  /// 백업 생성
  Future<void> _createBackup(List<String> collections, Map<String, dynamic> result) async {
    final backupTimestamp = DateTime.now().millisecondsSinceEpoch;
    int totalBackedUp = 0;

    for (final collectionName in collections) {
      try {
        final snapshot = await _firestore.collection(collectionName).get();
        
        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          int batchCount = 0;
          
          for (final doc in snapshot.docs) {
            final backupRef = _firestore
                .collection('backup_$backupTimestamp')
                .doc('${collectionName}_${doc.id}');
                
            batch.set(backupRef, {
              'originalCollection': collectionName,
              'originalId': doc.id,
              'data': doc.data(),
              'backedUpAt': FieldValue.serverTimestamp(),
            });
            
            batchCount++;
            totalBackedUp++;
            
            // 배치 크기 제한 (500개)
            if (batchCount >= 500) {
              await batch.commit();
              batchCount = 0;
            }
          }
          
          if (batchCount > 0) {
            await batch.commit();
          }
        }
        
      } catch (e) {
        final errors = result['errors'] as List<String>;
        errors.add('Backup failed for $collectionName: $e');
      }
    }
    
    result['backedUpDocuments'] = totalBackedUp;
    AppLogger.info('[FirestoreReset] Backup created: $totalBackedUp documents');
  }

  /// 컬렉션 삭제
  Future<int> _deleteCollection(String collectionName) async {
    int deletedCount = 0;
    
    try {
      // 컬렉션의 모든 문서 가져오기
      var snapshot = await _firestore.collection(collectionName).get();
      
      while (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        int batchCount = 0;
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          batchCount++;
          deletedCount++;
          
          // 배치 크기 제한 (500개)
          if (batchCount >= 500) {
            break;
          }
        }
        
        await batch.commit();
        
        // 다음 배치 가져오기
        if (snapshot.docs.length < 500) {
          break;
        }
        
        snapshot = await _firestore.collection(collectionName).get();
      }
      
    } catch (e) {
      AppLogger.error('[FirestoreReset] Error deleting collection $collectionName: $e');
      rethrow;
    }
    
    return deletedCount;
  }

  /// 컬렉션 문서 수 조회
  Future<int> _getCollectionCount(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('[FirestoreReset] Error counting $collectionName: $e');
      return 0;
    }
  }

  /// PRD v1.1 구조 초기화
  Future<Map<String, dynamic>> initializePRDv11Structure({
    Function(String)? onProgress,
  }) async {
    final result = {
      'startTime': DateTime.now().toIso8601String(),
      'initializedCollections': <String>[],
      'errors': <String>[],
    };

    try {
      onProgress?.call('🏗️ PRD v1.1 구조 초기화 중...');

      // 1. Core 20 indicators 메타데이터 추가
      await _initializeCoreIndicators();
      final initializedCollections = result['initializedCollections'] as List<String>;
      initializedCollections.add('core_indicators_meta');

      // 2. OECD 국가 데이터 초기화 (새 구조)
      await _initializeOECDCountries();
      initializedCollections.add('countries');

      // 3. 빈 컬렉션 구조 생성 (향후 데이터 수집용)
      await _createEmptyCollectionStructures();
      initializedCollections.addAll([
        'indicators',
        'oecd_statistics',
      ]);

      result['endTime'] = DateTime.now().toIso8601String();
      AppLogger.info('[FirestoreReset] PRD v1.1 structure initialized');

    } catch (e) {
      result['error'] = e.toString();
      AppLogger.error('[FirestoreReset] Structure initialization failed: $e');
    }

    return result;
  }

  /// Core Indicators 메타데이터 초기화
  Future<void> _initializeCoreIndicators() async {
    // Core 20 indicators 메타데이터
    final coreIndicators = [
      {
        'code': 'NY.GDP.MKTP.KD.ZG',
        'name': 'GDP 실질 성장률',
        'nameEn': 'GDP growth (annual %)',
        'category': 'growth',
        'unit': '%',
        'description': '전년 동기 대비 실질 국내총생산(GDP)의 증감률',
        'isPositive': true,
      },
      {
        'code': 'SL.UEM.TOTL.ZS',
        'name': '실업률',
        'nameEn': 'Unemployment, total (% of total labor force)',
        'category': 'employment',
        'unit': '%',
        'description': '경제활동인구 중에서 실업자가 차지하는 비율',
        'isPositive': false,
      },
      {
        'code': 'FP.CPI.TOTL.ZG',
        'name': 'CPI 인플레이션',
        'nameEn': 'Inflation, consumer prices (annual %)',
        'category': 'inflation',
        'unit': '%',
        'description': '소비자물가지수(CPI)의 전년 동월 대비 상승률',
        'isPositive': null,
      },
      // ... 나머지 Core 17개 지표
    ];

    final batch = _firestore.batch();
    for (final indicator in coreIndicators) {
      final ref = _firestore.collection('core_indicators_meta').doc(indicator['code'] as String);
      batch.set(ref, {
        ...indicator,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    AppLogger.info('[FirestoreReset] Core indicators metadata initialized');
  }

  /// OECD 국가 데이터 초기화
  Future<void> _initializeOECDCountries() async {
    // OECD 38개국 데이터 (새 구조)
    final oecdCountries = [
      {'code': 'AUS', 'name': 'Australia', 'nameKo': '호주', 'flagEmoji': '🇦🇺', 'region': 'Asia-Pacific'},
      {'code': 'AUT', 'name': 'Austria', 'nameKo': '오스트리아', 'flagEmoji': '🇦🇹', 'region': 'Europe'},
      {'code': 'BEL', 'name': 'Belgium', 'nameKo': '벨기에', 'flagEmoji': '🇧🇪', 'region': 'Europe'},
      {'code': 'CAN', 'name': 'Canada', 'nameKo': '캐나다', 'flagEmoji': '🇨🇦', 'region': 'North America'},
      {'code': 'KOR', 'name': 'South Korea', 'nameKo': '한국', 'flagEmoji': '🇰🇷', 'region': 'Asia-Pacific'},
      {'code': 'USA', 'name': 'United States', 'nameKo': '미국', 'flagEmoji': '🇺🇸', 'region': 'North America'},
      {'code': 'JPN', 'name': 'Japan', 'nameKo': '일본', 'flagEmoji': '🇯🇵', 'region': 'Asia-Pacific'},
      {'code': 'DEU', 'name': 'Germany', 'nameKo': '독일', 'flagEmoji': '🇩🇪', 'region': 'Europe'},
      {'code': 'FRA', 'name': 'France', 'nameKo': '프랑스', 'flagEmoji': '🇫🇷', 'region': 'Europe'},
      {'code': 'GBR', 'name': 'United Kingdom', 'nameKo': '영국', 'flagEmoji': '🇬🇧', 'region': 'Europe'},
      // ... 나머지 28개국
    ];

    final batch = _firestore.batch();
    for (final country in oecdCountries) {
      // 새 구조: /countries/{countryCode}
      final ref = _firestore.collection('countries').doc(country['code'] as String);
      batch.set(ref, {
        ...country,
        'isOECD': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    AppLogger.info('[FirestoreReset] OECD countries initialized: ${oecdCountries.length} countries');
  }

  /// 빈 컬렉션 구조 생성
  Future<void> _createEmptyCollectionStructures() async {
    // 향후 데이터 수집을 위한 빈 구조 생성
    
    // 1. indicators 컬렉션에 메타 문서 생성
    await _firestore.collection('indicators').doc('_metadata').set({
      'description': 'PRD v1.1 indicator series data',
      'structure': 'indicators/{indicatorCode}/series/{countryCode}',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. oecd_statistics 컬렉션에 메타 문서 생성
    await _firestore.collection('oecd_statistics').doc('_metadata').set({
      'description': 'OECD statistical data for rankings',
      'structure': 'oecd_statistics/{year}_{indicatorCode}',
      'createdAt': FieldValue.serverTimestamp(),
    });

    AppLogger.info('[FirestoreReset] Empty collection structures created');
  }

  /// 삭제 전 데이터 현황 조회
  Future<Map<String, dynamic>> getDataOverview() async {
    final overview = <String, dynamic>{
      'collections': <String, int>{},
      'totalDocuments': 0,
      'estimatedSize': 0,
    };

    try {
      final collections = ['indicator_data', 'oecd_countries', 'oecd_stats', 'users'];

      for (final collectionName in collections) {
        final count = await _getCollectionCount(collectionName);
        final collectionsMap = overview['collections'] as Map<String, int>;
        collectionsMap[collectionName] = count;
        overview['totalDocuments'] = (overview['totalDocuments'] as int) + count;
      }

    } catch (e) {
      overview['error'] = e.toString();
    }

    return overview;
  }
}