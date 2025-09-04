import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/logger.dart';
import '../models/admin_user.dart';

/// 관리자 인증 서비스
class AdminAuthService {
  static AdminAuthService? _instance;
  static AdminAuthService get instance => _instance ??= AdminAuthService._();
  AdminAuthService._();

  static const String _prefKeyCurrentAdmin = 'current_admin';
  static const String _prefKeyLoginTime = 'admin_login_time';
  static const Duration _sessionTimeout = Duration(hours: 2);

  AdminUser? _currentAdmin;
  DateTime? _sessionStartTime;
  AdminUser? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _currentAdmin != null && !_isSessionExpired();

  /// 초기화 (기본 관리자 계정 생성)
  Future<void> initialize() async {
    try {
      // 기본 관리자 계정 확인 및 생성
      await _ensureDefaultAdminExists();
      
      // 저장된 로그인 정보 복원
      await _restoreSession();
      
      AppLogger.info('[AdminAuthService] Initialized successfully');
    } catch (e) {
      AppLogger.error('[AdminAuthService] Initialization failed: $e');
    }
  }

  /// 관리자 로그인
  Future<bool> login(String username, String password) async {
    try {
      AppLogger.debug('[AdminAuthService] Attempting login for: $username');

      // Firestore에서 관리자 계정 조회
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(username)
          .get();

      if (!adminDoc.exists) {
        AppLogger.warning('[AdminAuthService] Admin user not found: $username');
        return false;
      }

      final adminData = adminDoc.data()!;
      final storedPasswordHash = adminData['passwordHash'] as String;
      final inputPasswordHash = _hashPassword(password);

      if (storedPasswordHash != inputPasswordHash) {
        AppLogger.warning('[AdminAuthService] Invalid password for: $username');
        return false;
      }

      // 관리자 정보 생성
      _currentAdmin = AdminUser.fromJson(adminData);

      // 세션 시작 시간 설정
      _sessionStartTime = DateTime.now();

      // 마지막 로그인 시간 업데이트
      await _updateLastLogin(username);

      // 세션 저장
      await _saveSession();

      print('[AdminAuthService] Login successful for: $username');
      print('[AdminAuthService] Current admin: ${_currentAdmin?.username}');
      print('[AdminAuthService] isLoggedIn: $isLoggedIn');
      
      AppLogger.info('[AdminAuthService] Admin logged in successfully: $username');
      return true;

    } catch (e) {
      AppLogger.error('[AdminAuthService] Login failed: $e');
      return false;
    }
  }

  /// 관리자 로그아웃
  Future<void> logout() async {
    try {
      _currentAdmin = null;
      _sessionStartTime = null;
      await _clearSession();
      AppLogger.info('[AdminAuthService] Admin logged out');
    } catch (e) {
      AppLogger.error('[AdminAuthService] Logout failed: $e');
    }
  }

  /// 권한 확인
  bool hasPermission(AdminPermission permission) {
    if (!isLoggedIn) return false;
    return _currentAdmin!.hasPermission(permission);
  }

  /// 비밀번호 변경
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      if (!isLoggedIn || _currentAdmin == null) {
        AppLogger.warning('[AdminAuthService] Not logged in for password change');
        return false;
      }

      // 현재 비밀번호 확인
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(_currentAdmin!.username)
          .get();

      if (!adminDoc.exists) {
        AppLogger.warning('[AdminAuthService] Admin user not found for password change');
        return false;
      }

      final adminData = adminDoc.data()!;
      final storedPasswordHash = adminData['passwordHash'] as String;
      final currentPasswordHash = _hashPassword(currentPassword);

      if (storedPasswordHash != currentPasswordHash) {
        AppLogger.warning('[AdminAuthService] Current password incorrect');
        return false;
      }

      // 새 비밀번호로 업데이트
      final newPasswordHash = _hashPassword(newPassword);
      await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(_currentAdmin!.username)
          .update({
        'passwordHash': newPasswordHash,
      });

      AppLogger.info('[AdminAuthService] Password changed successfully for: ${_currentAdmin!.username}');
      return true;

    } catch (e) {
      AppLogger.error('[AdminAuthService] Password change failed: $e');
      return false;
    }
  }

  /// 기본 관리자 계정 생성
  Future<void> _ensureDefaultAdminExists() async {
    try {
      const defaultUsername = 'admin';
      const defaultPassword = 'admin123!@#';

      final adminDoc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(defaultUsername)
          .get();

      if (!adminDoc.exists) {
        final now = DateTime.now();
        final defaultAdmin = {
          'id': defaultUsername,
          'username': defaultUsername,
          'email': 'admin@geo-economy.com',
          'role': AdminRole.superAdmin.name,
          'passwordHash': _hashPassword(defaultPassword),
          'createdAt': now.millisecondsSinceEpoch,
          'lastLoginAt': now.millisecondsSinceEpoch,
          'isActive': true,
        };

        await FirebaseFirestore.instance
            .collection('admin_users')
            .doc(defaultUsername)
            .set(defaultAdmin);

        AppLogger.info('[AdminAuthService] Default admin account created');
      }
    } catch (e) {
      AppLogger.error('[AdminAuthService] Failed to create default admin: $e');
    }
  }

  /// 패스워드 해시
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'geo_economy_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 마지막 로그인 시간 업데이트
  Future<void> _updateLastLogin(String username) async {
    try {
      await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(username)
          .update({
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      AppLogger.error('[AdminAuthService] Failed to update last login: $e');
    }
  }

  /// 세션 저장
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyCurrentAdmin, jsonEncode(_currentAdmin!.toJson()));
      await prefs.setInt(_prefKeyLoginTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.error('[AdminAuthService] Failed to save session: $e');
    }
  }

  /// 세션 복원
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminJson = prefs.getString(_prefKeyCurrentAdmin);
      
      if (adminJson != null) {
        final loginTime = prefs.getInt(_prefKeyLoginTime);
        if (loginTime != null) {
          _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(loginTime);
        }
        
        if (!_isSessionExpired()) {
          final adminData = jsonDecode(adminJson) as Map<String, dynamic>;
          _currentAdmin = AdminUser.fromJson(adminData);
          AppLogger.debug('[AdminAuthService] Session restored for: ${_currentAdmin!.username}');
        }
      }
    } catch (e) {
      AppLogger.error('[AdminAuthService] Failed to restore session: $e');
      await _clearSession();
    }
  }

  /// 세션 만료 확인
  bool _isSessionExpired() {
    try {
      // 현재 로그인 시간을 메모리에서 체크 (임시 해결책)
      if (_sessionStartTime == null) return true;
      return DateTime.now().difference(_sessionStartTime!) > _sessionTimeout;
    } catch (e) {
      return true;
    }
  }

  /// 세션 삭제
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyCurrentAdmin);
      await prefs.remove(_prefKeyLoginTime);
    } catch (e) {
      AppLogger.error('[AdminAuthService] Failed to clear session: $e');
    }
  }
}