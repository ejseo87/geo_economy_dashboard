import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geo_economy_dashboard/common/logger.dart';

class SystemStatus {
  final bool serverHealthy;
  final bool firebaseConnected;
  final bool worldBankApiHealthy;
  final DateTime lastChecked;

  const SystemStatus({
    required this.serverHealthy,
    required this.firebaseConnected,
    required this.worldBankApiHealthy,
    required this.lastChecked,
  });

  factory SystemStatus.loading() => SystemStatus(
    serverHealthy: false,
    firebaseConnected: false,
    worldBankApiHealthy: false,
    lastChecked: DateTime.now(),
  );
}

class DataStatistics {
  final int totalIndicators;
  final int totalCountries;
  final int totalDataPoints;
  final DateTime lastUpdated;
  final int indicatorsWithData;
  final int countriesWithData;

  const DataStatistics({
    required this.totalIndicators,
    required this.totalCountries,
    required this.totalDataPoints,
    required this.lastUpdated,
    required this.indicatorsWithData,
    required this.countriesWithData,
  });

  factory DataStatistics.empty() => DataStatistics(
    totalIndicators: 0,
    totalCountries: 0,
    totalDataPoints: 0,
    lastUpdated: DateTime.now(),
    indicatorsWithData: 0,
    countriesWithData: 0,
  );

  double get indicatorCoverage => totalIndicators > 0 
      ? (indicatorsWithData / totalIndicators) * 100 
      : 0.0;
  
  double get countryCoverage => totalCountries > 0 
      ? (countriesWithData / totalCountries) * 100 
      : 0.0;
}

class UserStatistics {
  final int totalUsers;
  final int activeUsers;
  final int adminUsers;
  final int guestUsers;
  final int premiumUsers;

  const UserStatistics({
    required this.totalUsers,
    required this.activeUsers,
    required this.adminUsers,
    required this.guestUsers,
    required this.premiumUsers,
  });

  factory UserStatistics.empty() => const UserStatistics(
    totalUsers: 0,
    activeUsers: 0,
    adminUsers: 0,
    guestUsers: 0,
    premiumUsers: 0,
  );
}

class RecentActivity {
  final String id;
  final String actionType;
  final String description;
  final String userEmail;
  final DateTime timestamp;
  final String status;

  const RecentActivity({
    required this.id,
    required this.actionType,
    required this.description,
    required this.userEmail,
    required this.timestamp,
    required this.status,
  });

  factory RecentActivity.fromMap(Map<String, dynamic> map, String docId) {
    return RecentActivity(
      id: docId,
      actionType: map['actionType'] ?? '',
      description: map['description'] ?? '',
      userEmail: map['userEmail'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'] ?? '',
    );
  }
}

class AdminOverviewService {
  static final AdminOverviewService _instance = AdminOverviewService._internal();
  factory AdminOverviewService() => _instance;
  AdminOverviewService._internal();

  static AdminOverviewService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<SystemStatus> getSystemStatus() async {
    try {
      // Firebase 연결 상태 확인
      bool firebaseConnected = false;
      try {
        await _firestore.collection('system_health').limit(1).get();
        firebaseConnected = true;
      } catch (e) {
        AppLogger.warning('[AdminOverviewService] Firebase connection check failed: $e');
      }

      // World Bank API 상태 확인 (최근 데이터 수집 성공 여부로 판단)
      bool worldBankApiHealthy = false;
      try {
        final recentCollection = await _firestore
            .collection('admin_audit_logs')
            .where('actionType', isEqualTo: 'dataCollection')
            .where('status', isEqualTo: 'completed')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        
        if (recentCollection.docs.isNotEmpty) {
          final lastSuccess = (recentCollection.docs.first.data()['timestamp'] as Timestamp).toDate();
          final hoursSinceLastSuccess = DateTime.now().difference(lastSuccess).inHours;
          worldBankApiHealthy = hoursSinceLastSuccess < 24; // 24시간 이내 성공한 수집이 있으면 정상
        }
      } catch (e) {
        AppLogger.warning('[AdminOverviewService] World Bank API status check failed: $e');
      }

      return SystemStatus(
        serverHealthy: firebaseConnected, // Firebase 연결이 되면 서버도 정상으로 간주
        firebaseConnected: firebaseConnected,
        worldBankApiHealthy: worldBankApiHealthy,
        lastChecked: DateTime.now(),
      );

    } catch (e) {
      AppLogger.error('[AdminOverviewService] System status check failed: $e');
      return SystemStatus.loading();
    }
  }

  Future<DataStatistics> getDataStatistics() async {
    try {
      // Indicators 컬렉션 통계
      int totalIndicators = 0;
      int indicatorsWithData = 0;
      int totalDataPoints = 0;
      DateTime? lastUpdated;
      Set<String> uniqueCountries = {}; // 실제 데이터가 있는 국가들

      final indicatorsSnapshot = await _firestore.collection('indicators').get();
      totalIndicators = indicatorsSnapshot.docs.length;

      for (final indicatorDoc in indicatorsSnapshot.docs) {
        final seriesSnapshot = await _firestore
            .collection('indicators')
            .doc(indicatorDoc.id)
            .collection('series')
            .get();

        if (seriesSnapshot.docs.isNotEmpty) {
          indicatorsWithData++;
          
          for (final seriesDoc in seriesSnapshot.docs) {
            // 국가 코드 추가 (series document ID가 국가 코드)
            uniqueCountries.add(seriesDoc.id);
            
            final data = seriesDoc.data();
            if (data['timeSeries'] != null) {
              final timeSeries = data['timeSeries'] as List;
              totalDataPoints += timeSeries.length;
              
              // 마지막 업데이트 시간 확인
              if (data['lastUpdated'] != null) {
                final docLastUpdated = (data['lastUpdated'] as Timestamp).toDate();
                if (lastUpdated == null || docLastUpdated.isAfter(lastUpdated)) {
                  lastUpdated = docLastUpdated;
                }
              }
            }
          }
        }
      }

      // Countries 컬렉션에서 총 국가 수 가져오기
      final countriesSnapshot = await _firestore.collection('countries').get();
      int totalCountries = countriesSnapshot.docs.length;
      int countriesWithData = 0;

      if (countriesSnapshot.docs.isNotEmpty) {
        // countries 컬렉션이 있다면 해당 데이터에서 데이터 보유 국가 계산
        for (final countryDoc in countriesSnapshot.docs) {
          final indicatorsSnapshot = await _firestore
              .collection('countries')
              .doc(countryDoc.id)
              .collection('indicators')
              .get();

          if (indicatorsSnapshot.docs.isNotEmpty) {
            countriesWithData++;
          }
        }
      } else {
        // Countries 컬렉션이 비어있다면 indicators에서 추출한 값 사용
        totalCountries = uniqueCountries.length;
        countriesWithData = uniqueCountries.length;
        AppLogger.warning('[AdminOverviewService] Countries collection is empty, using indicators data');
      }

      AppLogger.info('[AdminOverviewService] Data statistics: $totalIndicators indicators, $totalCountries countries, $totalDataPoints data points');

      return DataStatistics(
        totalIndicators: totalIndicators,
        totalCountries: totalCountries,
        totalDataPoints: totalDataPoints,
        lastUpdated: lastUpdated ?? DateTime.now(),
        indicatorsWithData: indicatorsWithData,
        countriesWithData: countriesWithData,
      );

    } catch (e) {
      AppLogger.error('[AdminOverviewService] Data statistics failed: $e');
      return DataStatistics.empty();
    }
  }

  Future<UserStatistics> getUserStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = 0;
      int adminUsers = 0;
      int guestUsers = 0;
      int premiumUsers = 0;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        
        // 활성 사용자 (30일 이내 로그인)
        if (userData['lastLogin'] != null) {
          final lastLogin = (userData['lastLogin'] as Timestamp).toDate();
          if (lastLogin.isAfter(thirtyDaysAgo)) {
            activeUsers++;
          }
        }

        // 사용자 유형별 분류
        final role = userData['role'] as String? ?? 'guest';
        switch (role) {
          case 'admin':
            adminUsers++;
            break;
          case 'free_user':
            guestUsers++;
            break;
          case 'premium_user':
          case 'pro_user':
            premiumUsers++;
            break;
          default:
            guestUsers++;
        }
      }

      return UserStatistics(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        adminUsers: adminUsers,
        guestUsers: guestUsers,
        premiumUsers: premiumUsers,
      );

    } catch (e) {
      AppLogger.error('[AdminOverviewService] User statistics failed: $e');
      return UserStatistics.empty();
    }
  }

  Future<List<RecentActivity>> getRecentActivity({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('admin_audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RecentActivity.fromMap(doc.data(), doc.id))
          .toList();

    } catch (e) {
      AppLogger.error('[AdminOverviewService] Recent activity failed: $e');
      return [];
    }
  }

  // 실시간 스트림으로 데이터 구독
  Stream<DataStatistics> get dataStatisticsStream {
    return _firestore.collection('indicators').snapshots().asyncMap((_) async {
      return await getDataStatistics();
    });
  }

  Stream<UserStatistics> get userStatisticsStream {
    return _firestore.collection('users').snapshots().asyncMap((_) async {
      return await getUserStatistics();
    });
  }

  Stream<List<RecentActivity>> get recentActivityStream {
    return _firestore
        .collection('admin_audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecentActivity.fromMap(doc.data(), doc.id))
            .toList());
  }
}