import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logger.dart';

enum UserRole { guest, freeUser, premiumUser, admin }

enum PlanType { free, basic, pro }

/// 사용자 권한 확인 결과
class PermissionResult {
  final bool allowed;
  final String? reason;
  final int? used;
  final int? limit;

  PermissionResult._(this.allowed, this.reason, this.used, this.limit);

  factory PermissionResult.allowed() => PermissionResult._(true, null, null, null);
  factory PermissionResult.denied([String? reason]) => PermissionResult._(false, reason, null, null);
  factory PermissionResult.limitExceeded({required int used, required int limit}) =>
      PermissionResult._(false, 'Limit exceeded', used, limit);

  bool get isLimitExceeded => reason == 'Limit exceeded';
}

/// 구독 상태 정보
class SubscriptionStatus {
  final PlanType planType;
  final bool isActive;
  final DateTime? endDate;
  final bool autoRenew;

  const SubscriptionStatus({
    required this.planType,
    required this.isActive,
    this.endDate,
    this.autoRenew = false,
  });

  factory SubscriptionStatus.none() => const SubscriptionStatus(
        planType: PlanType.free,
        isActive: false,
      );

  factory SubscriptionStatus.free() => const SubscriptionStatus(
        planType: PlanType.free,
        isActive: true,
      );

  factory SubscriptionStatus.fromMap(Map<String, dynamic> data) {
    return SubscriptionStatus(
      planType: _parsePlanType(data['type']),
      isActive: data['isActive'] ?? false,
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      autoRenew: data['autoRenew'] ?? false,
    );
  }

  static PlanType _parsePlanType(dynamic type) {
    switch (type?.toString()) {
      case 'basic': return PlanType.basic;
      case 'pro': return PlanType.pro;
      default: return PlanType.free;
    }
  }

  bool get isPremium => isActive && planType != PlanType.free;
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);

  Map<String, dynamic> toMap() {
    return {
      'type': planType.name,
      'isActive': isActive,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'autoRenew': autoRenew,
    };
  }
}

/// 사용자 권한 관리 서비스
class UserPermissionService {
  static final UserPermissionService _instance = UserPermissionService._internal();
  factory UserPermissionService() => _instance;
  UserPermissionService._internal();

  static UserPermissionService get instance => _instance;


  // 플랜별 기본 권한
  static const Map<PlanType, Map<String, dynamic>> _planPermissions = {
    PlanType.free: {
      'bookmarks': false,
      'imageDownload': false,
      'csvExport': false,
      'customIndicators': false,
      'notifications': false,
    },
    PlanType.basic: {
      'bookmarks': true,
      'imageDownload': true,
      'csvExport': false,
      'customIndicators': false,
      'notifications': true,
    },
    PlanType.pro: {
      'bookmarks': true,
      'imageDownload': true,
      'csvExport': true,
      'customIndicators': true,
      'notifications': true,
    },
  };

  // 플랜별 사용량 제한
  static const Map<PlanType, Map<String, int>> _planLimits = {
    PlanType.free: {
      'bookmarkCount': 0,
      'downloadCount': 0,
    },
    PlanType.basic: {
      'bookmarkCount': 20,
      'downloadCount': 50,
    },
    PlanType.pro: {
      'bookmarkCount': -1, // 무제한
      'downloadCount': -1, // 무제한
    },
  };

  /// 빠른 권한 체크 (Custom Claims 사용)
  Future<bool> hasPermission(String permission) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final idTokenResult = await user.getIdTokenResult();
      final claims = idTokenResult.claims ?? {};
      
      // 관리자는 모든 권한 보유
      if (claims['admin'] == true) return true;
      
      // 프리미엄 사용자 권한 체크
      if (claims['premium'] == true) {
        return _checkPremiumPermission(permission, claims);
      }
      
      // 무료 사용자 기본 권한
      return _checkFreePermission(permission);
      
    } catch (e) {
      AppLogger.warning('[UserPermissionService] Custom Claims check failed: $e');
      // Custom Claims 실패 시 Firestore 폴백
      return await _checkFirestorePermission(permission);
    }
  }

  /// 상세한 권한 및 사용량 체크 (Firestore 사용)
  Future<PermissionResult> checkPermissionWithLimits(String permission) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return PermissionResult.denied('Not logged in');

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // 사용자 문서가 없으면 기본 문서 생성
        await _createDefaultUserDocument(user);
        return PermissionResult.denied('Free user');
      }
      
      final userData = userDoc.data()!;
      final permissions = userData['permissions'] as Map<String, dynamic>? ?? {};
      final limits = userData['limits'] as Map<String, dynamic>? ?? {};
      final usage = userData['usage'] as Map<String, dynamic>? ?? {};

      // 관리자는 모든 권한 허용
      if (userData['role'] == 'admin') {
        return PermissionResult.allowed();
      }

      // 권한 확인
      if (permissions[permission] != true) {
        return PermissionResult.denied('Permission not granted');
      }

      // 사용량 제한 확인
      if (permission == 'imageDownload') {
        final limit = limits['downloadCount'] ?? 0;
        final used = usage['monthlyDownloads'] ?? 0;
        
        if (limit > 0 && used >= limit) {
          return PermissionResult.limitExceeded(used: used, limit: limit);
        }
      } else if (permission == 'bookmarks') {
        final limit = limits['bookmarkCount'] ?? 0;
        final used = usage['currentBookmarks'] ?? 0;
        
        if (limit > 0 && used >= limit) {
          return PermissionResult.limitExceeded(used: used, limit: limit);
        }
      }

      return PermissionResult.allowed();

    } catch (e) {
      AppLogger.error('[UserPermissionService] Permission check failed: $e');
      return PermissionResult.denied('Check failed');
    }
  }

  /// 관리자 권한 체크
  Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // 1단계: Custom Claims 확인 (우선순위)
      final idTokenResult = await user.getIdTokenResult();
      final customClaims = idTokenResult.claims ?? {};
      
      if (customClaims['admin'] == true) {
        AppLogger.info('[UserPermissionService] Admin access granted via Custom Claims');
        return true;
      }

      // 2단계: Firestore 문서 확인
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (userData['role'] == 'admin') {
          AppLogger.info('[UserPermissionService] Admin access granted via Firestore');
          return true;
        }
      }

      return false;
    } catch (e) {
      AppLogger.error('[UserPermissionService] Error checking admin status: $e');
      return false;
    }
  }

  /// 구독 상태 확인
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SubscriptionStatus.none();

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return SubscriptionStatus.free();

      final planData = userDoc.data()?['plan'] as Map<String, dynamic>?;
      if (planData == null) return SubscriptionStatus.free();

      return SubscriptionStatus.fromMap(planData);

    } catch (e) {
      AppLogger.error('[UserPermissionService] Subscription check failed: $e');
      return SubscriptionStatus.free();
    }
  }

  /// 사용량 업데이트
  Future<void> updateUsage(String usageType, int increment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'usage.$usageType': FieldValue.increment(increment),
        'usage.lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('[UserPermissionService] Updated usage: $usageType += $increment');

    } catch (e) {
      AppLogger.error('[UserPermissionService] Usage update failed: $e');
    }
  }

  /// 기본 사용자 문서 생성
  Future<void> _createDefaultUserDocument(User user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'email': user.email,
      'role': 'free_user', // 기본값은 무료 사용자
      'plan': SubscriptionStatus.free().toMap(),
      'permissions': _planPermissions[PlanType.free],
      'limits': _planLimits[PlanType.free],
      'usage': {
        'currentBookmarks': 0,
        'monthlyDownloads': 0,
        'lastResetDate': FieldValue.serverTimestamp(),
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });

    AppLogger.info('[UserPermissionService] Created default user document for ${user.email}');
  }

  // Helper methods
  bool _checkPremiumPermission(String permission, Map<String, Object?> claims) {
    final plan = claims['plan']?.toString() ?? 'basic';
    final planType = plan == 'pro' ? PlanType.pro : PlanType.basic;
    return _planPermissions[planType]?[permission] == true;
  }

  bool _checkFreePermission(String permission) {
    return _planPermissions[PlanType.free]?[permission] == true;
  }

  Future<bool> _checkFirestorePermission(String permission) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final permissions = userData['permissions'] as Map<String, dynamic>? ?? {};

      return permissions[permission] == true;

    } catch (e) {
      AppLogger.error('[UserPermissionService] Firestore permission check failed: $e');
      return false;
    }
  }

}