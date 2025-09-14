import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geo_economy_dashboard/common/logger.dart';

enum AdminActionType {
  dataCollection,
  userManagement, 
  systemMaintenance,
  configurationChange,
  dataExport,
  dataImport,
  systemMonitoring,
}

enum AdminActionStatus {
  started,
  inProgress,
  completed,
  failed,
  cancelled,
}

class AdminAuditEntry {
  final String id;
  final String userId;
  final String userEmail;
  final AdminActionType actionType;
  final AdminActionStatus status;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? errorMessage;
  final Duration? duration;

  const AdminAuditEntry({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.actionType,
    required this.status,
    required this.description,
    required this.timestamp,
    this.metadata,
    this.errorMessage,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'actionType': actionType.name,
      'status': status.name,
      'description': description,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'errorMessage': errorMessage,
      'durationMs': duration?.inMilliseconds,
    };
  }

  factory AdminAuditEntry.fromMap(Map<String, dynamic> map, String docId) {
    return AdminAuditEntry(
      id: docId,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      actionType: AdminActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => AdminActionType.systemMaintenance,
      ),
      status: AdminActionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AdminActionStatus.completed,
      ),
      description: map['description'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      errorMessage: map['errorMessage'],
      duration: map['durationMs'] != null 
          ? Duration(milliseconds: map['durationMs'] as int)
          : null,
    );
  }
}

class AdminAuditService {
  static final AdminAuditService _instance = AdminAuditService._internal();
  factory AdminAuditService() => _instance;
  AdminAuditService._internal();

  static AdminAuditService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collectionName = 'admin_audit_logs';

  // Document ID 생성: YYYYMMDDHHMMSS_{AdminActionType}_{randomSuffix}
  String _generateDocumentId(DateTime timestamp, AdminActionType actionType) {
    final formattedTime = timestamp.toUtc().toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('T', '')
        .substring(0, 14); // YYYYMMDDHHMMSS

    // 밀리초를 이용해 같은 초 내 중복 방지
    final millis = timestamp.millisecondsSinceEpoch.toString().substring(10); // 마지막 3자리

    return '${formattedTime}_${actionType.name}_$millis';
  }

  Future<String> logAdminAction({
    required AdminActionType actionType,
    required String description,
    AdminActionStatus status = AdminActionStatus.started,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('[AdminAuditService] No authenticated user for audit log');
        return '';
      }

      final now = DateTime.now();
      final docId = _generateDocumentId(now, actionType);

      final entry = AdminAuditEntry(
        id: docId,
        userId: user.uid,
        userEmail: user.email ?? 'unknown',
        actionType: actionType,
        status: status,
        description: description,
        timestamp: now,
        metadata: metadata,
        errorMessage: errorMessage,
      );

      await _firestore
          .collection(_collectionName)
          .doc(entry.id)
          .set(entry.toMap());

      AppLogger.info('[AdminAuditService] Logged admin action: ${entry.id} - $description');
      return entry.id;

    } catch (e) {
      AppLogger.error('[AdminAuditService] Failed to log admin action: $e');
      return '';
    }
  }

  Future<void> updateAdminActionStatus({
    required String entryId,
    required AdminActionStatus status,
    String? errorMessage,
    Duration? duration,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      if (duration != null) {
        updateData['durationMs'] = duration.inMilliseconds;
      }

      // 기존 arrayUnion 사용을 제거하고, Map 형태로 일관 저장
      if (additionalMetadata != null) {
        updateData['metadata'] = additionalMetadata;
      }

      await _firestore
          .collection(_collectionName)
          .doc(entryId)
          .update(updateData);

      AppLogger.info('[AdminAuditService] Updated admin action status: $entryId -> ${status.name}');

    } catch (e) {
      AppLogger.error('[AdminAuditService] Failed to update admin action: $e');
    }
  }

  Future<List<AdminAuditEntry>> getRecentAuditLogs({
    int limit = 100,
    DateTime? since,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (since != null) {
        query = query.where('timestamp', isGreaterThan: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => AdminAuditEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

    } catch (e) {
      AppLogger.error('[AdminAuditService] Failed to fetch audit logs: $e');
      return [];
    }
  }

  Future<List<AdminAuditEntry>> getAuditLogsByAction(AdminActionType actionType, {
    int limit = 50,
    DateTime? since,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('actionType', isEqualTo: actionType.name)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (since != null) {
        query = query.where('timestamp', isGreaterThan: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => AdminAuditEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

    } catch (e) {
      AppLogger.error('[AdminAuditService] Failed to fetch audit logs by action: $e');
      return [];
    }
  }

  Future<Map<String, int>> getActionStatistics({
    DateTime? since,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName);
      
      if (since != null) {
        query = query.where('timestamp', isGreaterThan: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();
      final stats = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final actionType = data['actionType'] as String;
        final status = data['status'] as String;
        
        final key = '${actionType}_$status';
        stats[key] = (stats[key] ?? 0) + 1;
      }

      return stats;

    } catch (e) {
      AppLogger.error('[AdminAuditService] Failed to get action statistics: $e');
      return {};
    }
  }

  Future<void> cleanupOldLogs({int keepDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isEmpty) {
        AppLogger.info('[AdminAuditService] No old logs to cleanup');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      AppLogger.info('[AdminAuditService] Cleaned up ${snapshot.docs.length} old audit logs');

    } catch (e) {
      AppLogger.error('[AdminAuditService] Failed to cleanup old logs: $e');
    }
  }
}
