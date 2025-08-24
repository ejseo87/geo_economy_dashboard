import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../../common/logger.dart';
import '../models/notification_item.dart';

/// 알림 서비스
class NotificationService {
  static const String _keyPrefix = 'notifications_';
  static const String _keyNotificationsList = '${_keyPrefix}list';
  static const String _keyNotificationSettings = '${_keyPrefix}settings';
  
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  SharedPreferences? _prefs;
  List<NotificationItem> _notifications = [];
  List<NotificationSettings> _notificationSettings = [];
  bool _isInitialized = false;

  /// 초기화
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 타임존 초기화
      tz.initializeTimeZones();
      
      // SharedPreferences 초기화
      _prefs = await SharedPreferences.getInstance();
      
      // 로컬 알림 플러그인 초기화
      await _initializeLocalNotifications();
      
      // 저장된 알림 및 설정 로드
      await _loadNotifications();
      await _loadNotificationSettings();
      
      // 만료된 알림 정리
      await _cleanupExpiredNotifications();
      
      _isInitialized = true;
      AppLogger.info('[NotificationService] Initialized with ${_notifications.length} notifications');
      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Failed to initialize: $e');
      return false;
    }
  }

  /// 로컬 알림 플러그인 초기화
  Future<void> _initializeLocalNotifications() async {
    // Android 초기화 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 초기화 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // 권한 요청 (Android 13+)
    if (!kIsWeb) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payloadString = response.payload;
      if (payloadString != null && payloadString.isNotEmpty) {
        final payload = jsonDecode(payloadString) as Map<String, dynamic>;
        AppLogger.info('[NotificationService] Notification tapped: ${payload['id']}');
        
        // 알림을 읽음 상태로 변경
        markAsRead(payload['id'] as String);
        
        // TODO: 알림에 따른 화면 이동 처리
        _handleNotificationNavigation(payload);
      }
    } catch (e) {
      AppLogger.error('[NotificationService] Error handling notification tap: $e');
    }
  }

  /// 알림 네비게이션 처리
  void _handleNotificationNavigation(Map<String, dynamic> payload) {
    // TODO: GoRouter를 사용한 화면 이동 구현
    // 예: context.go('/indicator-detail/${payload['indicatorCode']}');
  }

  /// 즉시 알림 보내기
  Future<bool> showNotification(NotificationItem notification) async {
    if (!_isInitialized) {
      AppLogger.warning('[NotificationService] Service not initialized');
      return false;
    }

    try {
      // 알림 추가
      _notifications.insert(0, notification);
      await _saveNotifications();

      // 로컬 알림 표시
      await _showLocalNotification(notification);
      
      AppLogger.info('[NotificationService] Showed notification: ${notification.title}');
      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Error showing notification: $e');
      return false;
    }
  }

  /// 예약 알림 설정
  Future<bool> scheduleNotification(NotificationItem notification) async {
    if (!_isInitialized) return false;

    try {
      // 알림 추가
      _notifications.add(notification);
      await _saveNotifications();

      // 로컬 예약 알림 설정
      await _scheduleLocalNotification(notification);
      
      AppLogger.info('[NotificationService] Scheduled notification: ${notification.title} at ${notification.scheduledAt}');
      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Error scheduling notification: $e');
      return false;
    }
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification(NotificationItem notification) async {
    final androidDetails = AndroidNotificationDetails(
      'geo_dashboard_${notification.type.name}',
      'Geo Economy Dashboard - ${notification.type.displayName}',
      channelDescription: '${notification.type.displayName} 알림',
      importance: _getAndroidImportance(notification.priority),
      priority: _getAndroidPriority(notification.priority),
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      threadIdentifier: notification.type.name,
      categoryIdentifier: notification.type.name,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(notification.payload),
    );
  }

  /// 로컬 예약 알림 설정
  Future<void> _scheduleLocalNotification(NotificationItem notification) async {
    final scheduledDate = tz.TZDateTime.from(
      notification.scheduledAt,
      tz.local,
    );

    final androidDetails = AndroidNotificationDetails(
      'geo_dashboard_${notification.type.name}',
      'Geo Economy Dashboard - ${notification.type.displayName}',
      channelDescription: '${notification.type.displayName} 알림',
      importance: _getAndroidImportance(notification.priority),
      priority: _getAndroidPriority(notification.priority),
    );

    final iosDetails = DarwinNotificationDetails(
      threadIdentifier: notification.type.name,
      categoryIdentifier: notification.type.name,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      scheduledDate,
      notificationDetails,
      payload: jsonEncode(notification.payload),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Android 중요도 변환
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.critical:
        return Importance.max;
    }
  }

  /// Android 우선순위 변환
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.critical:
        return Priority.max;
    }
  }

  /// 모든 알림 조회
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  /// 읽지 않은 알림 조회
  List<NotificationItem> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  /// 읽지 않은 알림 개수
  int get unreadCount => unreadNotifications.length;

  /// 타입별 알림 조회
  List<NotificationItem> getNotificationsByType(NotificationType type) =>
      _notifications.where((n) => n.type == type).toList();

  /// 알림을 읽음 상태로 변경
  Future<bool> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          deliveredAt: DateTime.now(),
        );
        await _saveNotifications();
        AppLogger.debug('[NotificationService] Marked notification as read: $notificationId');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('[NotificationService] Error marking notification as read: $e');
      return false;
    }
  }

  /// 모든 알림을 읽음 상태로 변경
  Future<bool> markAllAsRead() async {
    try {
      bool hasChanges = false;
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            deliveredAt: DateTime.now(),
          );
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        await _saveNotifications();
        AppLogger.info('[NotificationService] Marked all notifications as read');
      }
      
      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Error marking all notifications as read: $e');
      return false;
    }
  }

  /// 알림 삭제
  Future<bool> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotifications();
      
      // 로컬 알림도 취소
      await _flutterLocalNotificationsPlugin.cancel(notificationId.hashCode);
      
      AppLogger.info('[NotificationService] Deleted notification: $notificationId');
      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Error deleting notification: $e');
      return false;
    }
  }

  /// 모든 알림 삭제
  Future<bool> clearAllNotifications() async {
    try {
      _notifications.clear();
      await _saveNotifications();
      
      // 모든 로컬 알림 취소
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      AppLogger.info('[NotificationService] Cleared all notifications');
      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Error clearing all notifications: $e');
      return false;
    }
  }

  /// 알림 설정 추가
  Future<bool> addNotificationSetting(NotificationSettings setting) async {
    try {
      _notificationSettings.add(setting);
      await _saveNotificationSettings();
      AppLogger.info('[NotificationService] Added notification setting: ${setting.name}');
      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Error adding notification setting: $e');
      return false;
    }
  }

  /// 알림 설정 업데이트
  Future<bool> updateNotificationSetting(NotificationSettings setting) async {
    try {
      final index = _notificationSettings.indexWhere((s) => s.id == setting.id);
      if (index != -1) {
        _notificationSettings[index] = setting;
        await _saveNotificationSettings();
        AppLogger.info('[NotificationService] Updated notification setting: ${setting.name}');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('[NotificationService] Error updating notification setting: $e');
      return false;
    }
  }

  /// 알림 설정 삭제
  Future<bool> deleteNotificationSetting(String settingId) async {
    try {
      _notificationSettings.removeWhere((s) => s.id == settingId);
      await _saveNotificationSettings();
      AppLogger.info('[NotificationService] Deleted notification setting: $settingId');
      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Error deleting notification setting: $e');
      return false;
    }
  }

  /// 모든 알림 설정 조회
  List<NotificationSettings> get notificationSettings => 
      List.unmodifiable(_notificationSettings);

  /// 활성화된 알림 설정 조회
  List<NotificationSettings> get activeNotificationSettings => 
      _notificationSettings.where((s) => s.isEnabled).toList();

  /// 알림 저장
  Future<void> _saveNotifications() async {
    try {
      final notificationsJson = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await _prefs?.setString(_keyNotificationsList, notificationsJson);
    } catch (e) {
      AppLogger.error('[NotificationService] Error saving notifications: $e');
    }
  }

  /// 알림 로드
  Future<void> _loadNotifications() async {
    try {
      final notificationsJson = _prefs?.getString(_keyNotificationsList);
      if (notificationsJson != null && notificationsJson.isNotEmpty) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        _notifications = notificationsList
            .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.error('[NotificationService] Error loading notifications: $e');
      _notifications = [];
    }
  }

  /// 알림 설정 저장
  Future<void> _saveNotificationSettings() async {
    try {
      final settingsJson = jsonEncode(_notificationSettings.map((s) => s.toJson()).toList());
      await _prefs?.setString(_keyNotificationSettings, settingsJson);
    } catch (e) {
      AppLogger.error('[NotificationService] Error saving notification settings: $e');
    }
  }

  /// 알림 설정 로드
  Future<void> _loadNotificationSettings() async {
    try {
      final settingsJson = _prefs?.getString(_keyNotificationSettings);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        final List<dynamic> settingsList = jsonDecode(settingsJson);
        _notificationSettings = settingsList
            .map((item) => NotificationSettings.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.error('[NotificationService] Error loading notification settings: $e');
      _notificationSettings = [];
    }
  }

  /// 만료된 알림 정리
  Future<void> _cleanupExpiredNotifications() async {
    try {
      final initialCount = _notifications.length;
      _notifications.removeWhere((n) => n.isExpired);
      
      if (_notifications.length < initialCount) {
        await _saveNotifications();
        AppLogger.info('[NotificationService] Cleaned up ${initialCount - _notifications.length} expired notifications');
      }
    } catch (e) {
      AppLogger.error('[NotificationService] Error cleaning up expired notifications: $e');
    }
  }

  /// 알림 권한 확인
  Future<bool> hasPermissions() async {
    if (kIsWeb) return true;
    
    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }
      
      return true; // iOS의 경우 초기화 시 권한을 요청하므로 true 반환
    } catch (e) {
      AppLogger.error('[NotificationService] Error checking permissions: $e');
      return false;
    }
  }

  /// 알림 통계
  NotificationStats getStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = now.subtract(const Duration(days: 7));

    return NotificationStats(
      totalNotifications: _notifications.length,
      unreadNotifications: unreadCount,
      todayNotifications: _notifications.where((n) => 
          n.scheduledAt.isAfter(today)).length,
      thisWeekNotifications: _notifications.where((n) => 
          n.scheduledAt.isAfter(thisWeek)).length,
      notificationsByType: _getNotificationCountsByType(),
      activeSettings: activeNotificationSettings.length,
    );
  }

  /// 타입별 알림 개수
  Map<NotificationType, int> _getNotificationCountsByType() {
    final counts = <NotificationType, int>{};
    for (final type in NotificationType.values) {
      counts[type] = _notifications.where((n) => n.type == type).length;
    }
    return counts;
  }
}

/// 알림 통계 클래스
class NotificationStats {
  final int totalNotifications;
  final int unreadNotifications;
  final int todayNotifications;
  final int thisWeekNotifications;
  final Map<NotificationType, int> notificationsByType;
  final int activeSettings;

  const NotificationStats({
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.todayNotifications,
    required this.thisWeekNotifications,
    required this.notificationsByType,
    required this.activeSettings,
  });

  @override
  String toString() => 
      'NotificationStats(total: $totalNotifications, unread: $unreadNotifications, today: $todayNotifications)';
}