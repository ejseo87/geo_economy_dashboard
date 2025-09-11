import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../../../common/logger.dart';

/// 사용자 프로필 관리 서비스
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  static UserProfileService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 현재 사용자 프로필 가져오기
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        // 사용자 문서가 없으면 생성
        await createUserProfile(user);
        final newDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserProfile.fromMap(newDoc.data()!, user.uid);
      }

      return UserProfile.fromMap(doc.data()!, user.uid);

    } catch (e) {
      AppLogger.error('[UserProfileService] Failed to get user profile: $e');
      return null;
    }
  }

  /// 사용자 프로필 생성 (회원가입 시)
  Future<void> createUserProfile(User user) async {
    try {
      final isAdmin = user.email == 'ged2025@gmail.com';
      
      final profileData = {
        'email': user.email,
        'nickname': 'anon',
        'avatarUrl': null,
        'role': isAdmin ? 'admin' : 'free_user',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'plan': {
          'type': 'free',
          'isActive': true,
          'startDate': FieldValue.serverTimestamp(),
          'endDate': null,
          'autoRenew': false,
        },
        'permissions': isAdmin ? _getAdminPermissions() : _getFreePermissions(),
        'limits': isAdmin ? _getAdminLimits() : _getFreeLimits(),
        'usage': {
          'currentBookmarks': 0,
          'monthlyDownloads': 0,
          'lastResetDate': FieldValue.serverTimestamp(),
        },
      };

      await _firestore.collection('users').doc(user.uid).set(profileData);
      AppLogger.info('[UserProfileService] Created user profile for ${user.email}');

    } catch (e) {
      AppLogger.error('[UserProfileService] Failed to create user profile: $e');
      rethrow;
    }
  }

  /// 닉네임 업데이트
  Future<void> updateNickname(String nickname) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'nickname': nickname,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('[UserProfileService] Updated nickname: $nickname');

    } catch (e) {
      AppLogger.error('[UserProfileService] Failed to update nickname: $e');
      rethrow;
    }
  }

  /// 아바타 이미지 업로드
  Future<String> uploadAvatar(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 이전 아바타 삭제 (옵션)
      await _deleteOldAvatar(user.uid);

      // 새 아바타 업로드
      final fileName = 'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('avatars').child(fileName);
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Firestore 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'avatarUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('[UserProfileService] Uploaded avatar: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      AppLogger.error('[UserProfileService] Failed to upload avatar: $e');
      rethrow;
    }
  }

  /// 아바타 제거
  Future<void> removeAvatar() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // Storage에서 삭제
      await _deleteOldAvatar(user.uid);

      // Firestore 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'avatarUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('[UserProfileService] Removed avatar');

    } catch (e) {
      AppLogger.error('[UserProfileService] Failed to remove avatar: $e');
      rethrow;
    }
  }

  /// 비밀번호 변경
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 현재 비밀번호로 재인증
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);

      // 새 비밀번호로 변경
      await user.updatePassword(newPassword);

      AppLogger.info('[UserProfileService] Password changed successfully');

    } catch (e) {
      AppLogger.error('[UserProfileService] Failed to change password: $e');
      rethrow;
    }
  }

  /// 마지막 로그인 시간 업데이트
  Future<void> updateLastLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      AppLogger.warning('[UserProfileService] Failed to update last login: $e');
      // 로그인 시간 업데이트 실패는 치명적이지 않으므로 에러를 던지지 않음
    }
  }

  /// 사용자 프로필 스트림 (실시간 업데이트)
  Stream<UserProfile?> watchUserProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromMap(snapshot.data()!, user.uid);
    });
  }

  /// 사용자 계정 삭제 (프로필 데이터 포함)
  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 1. 아바타 이미지 삭제
      await _deleteOldAvatar(user.uid);

      // 2. Firestore 사용자 데이터 삭제
      await _firestore.collection('users').doc(user.uid).delete();

      // 3. Auth 계정 삭제
      await user.delete();

      AppLogger.info('[UserProfileService] User account deleted');

    } catch (e) {
      AppLogger.error('[UserProfileService] Failed to delete user account: $e');
      rethrow;
    }
  }

  // Helper Methods
  
  /// 이전 아바타 삭제
  Future<void> _deleteOldAvatar(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      final oldAvatarUrl = data?['avatarUrl'] as String?;

      if (oldAvatarUrl != null) {
        final oldRef = _storage.refFromURL(oldAvatarUrl);
        await oldRef.delete();
      }
    } catch (e) {
      AppLogger.warning('[UserProfileService] Failed to delete old avatar: $e');
      // 이전 아바타 삭제 실패는 치명적이지 않음
    }
  }

  /// 관리자 권한 반환
  Map<String, bool> _getAdminPermissions() {
    return {
      'bookmarks': true,
      'imageDownload': true,
      'csvExport': true,
      'customIndicators': true,
      'notifications': true,
    };
  }

  /// 무료 사용자 권한 반환
  Map<String, bool> _getFreePermissions() {
    return {
      'bookmarks': false,
      'imageDownload': false,
      'csvExport': false,
      'customIndicators': false,
      'notifications': false,
    };
  }

  /// 관리자 제한 반환 (무제한)
  Map<String, int> _getAdminLimits() {
    return {
      'bookmarkCount': -1,
      'downloadCount': -1,
    };
  }

  /// 무료 사용자 제한 반환
  Map<String, int> _getFreeLimits() {
    return {
      'bookmarkCount': 0,
      'downloadCount': 0,
    };
  }
}