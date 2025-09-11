import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../../../common/services/user_permission_service.dart';
import '../../../common/logger.dart';

part 'user_profile_view_model.g.dart';

/// 사용자 프로필 상태
@riverpod
class UserProfileViewModel extends _$UserProfileViewModel {
  @override
  Future<UserProfile?> build() async {
    return await UserProfileService.instance.getCurrentUserProfile();
  }

  /// 프로필 업데이트 (닉네임과 아바타)
  Future<void> updateProfile({
    required String displayName,
    File? avatarFile,
  }) async {
    if (displayName.trim().isEmpty) {
      throw Exception('닉네임을 입력해주세요');
    }

    if (displayName.trim().length > 20) {
      throw Exception('닉네임은 20자 이하로 입력해주세요');
    }

    try {
      state = const AsyncValue.loading();
      
      // 닉네임 업데이트
      await UserProfileService.instance.updateNickname(displayName.trim());
      
      // 아바타 업로드 (있는 경우)
      if (avatarFile != null) {
        await UserProfileService.instance.uploadAvatar(avatarFile);
      }
      
      // 상태 새로고침
      final updatedProfile = await UserProfileService.instance.getCurrentUserProfile();
      state = AsyncValue.data(updatedProfile);

      AppLogger.info('[UserProfileViewModel] Profile updated successfully');

    } catch (e) {
      AppLogger.error('[UserProfileViewModel] Failed to update profile: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// 닉네임 업데이트
  Future<void> updateNickname(String nickname) async {
    if (nickname.trim().isEmpty) {
      throw Exception('닉네임을 입력해주세요');
    }

    if (nickname.trim().length > 20) {
      throw Exception('닉네임은 20자 이하로 입력해주세요');
    }

    try {
      state = const AsyncValue.loading();
      
      await UserProfileService.instance.updateNickname(nickname.trim());
      
      // 상태 새로고침
      final updatedProfile = await UserProfileService.instance.getCurrentUserProfile();
      state = AsyncValue.data(updatedProfile);

      AppLogger.info('[UserProfileViewModel] Nickname updated successfully');

    } catch (e) {
      AppLogger.error('[UserProfileViewModel] Failed to update nickname: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// 아바타 업로드
  Future<void> uploadAvatar(File imageFile) async {
    try {
      state = const AsyncValue.loading();
      
      await UserProfileService.instance.uploadAvatar(imageFile);
      
      // 상태 새로고침
      final updatedProfile = await UserProfileService.instance.getCurrentUserProfile();
      state = AsyncValue.data(updatedProfile);

      AppLogger.info('[UserProfileViewModel] Avatar uploaded successfully');

    } catch (e) {
      AppLogger.error('[UserProfileViewModel] Failed to upload avatar: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// 아바타 제거
  Future<void> removeAvatar() async {
    try {
      state = const AsyncValue.loading();
      
      await UserProfileService.instance.removeAvatar();
      
      // 상태 새로고침
      final updatedProfile = await UserProfileService.instance.getCurrentUserProfile();
      state = AsyncValue.data(updatedProfile);

      AppLogger.info('[UserProfileViewModel] Avatar removed successfully');

    } catch (e) {
      AppLogger.error('[UserProfileViewModel] Failed to remove avatar: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// 비밀번호 변경
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('비밀번호를 입력해주세요');
    }

    if (newPassword.length < 6) {
      throw Exception('새 비밀번호는 6자 이상이어야 합니다');
    }

    if (currentPassword == newPassword) {
      throw Exception('현재 비밀번호와 새 비밀번호가 같습니다');
    }

    try {
      await UserProfileService.instance.changePassword(currentPassword, newPassword);
      AppLogger.info('[UserProfileViewModel] Password changed successfully');

    } catch (e) {
      AppLogger.error('[UserProfileViewModel] Failed to change password: $e');
      rethrow;
    }
  }

  /// 프로필 새로고침
  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final profile = await UserProfileService.instance.getCurrentUserProfile();
      state = AsyncValue.data(profile);

    } catch (e) {
      AppLogger.error('[UserProfileViewModel] Failed to refresh profile: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 사용자 계정 삭제
  Future<void> deleteAccount() async {
    try {
      await UserProfileService.instance.deleteUserAccount();
      state = const AsyncValue.data(null);

      AppLogger.info('[UserProfileViewModel] Account deleted successfully');

    } catch (e) {
      AppLogger.error('[UserProfileViewModel] Failed to delete account: $e');
      rethrow;
    }
  }
}

/// 관리자 권한 체크 Provider
@riverpod
Future<bool> isAdminUser(Ref ref) async {
  return await UserPermissionService.instance.isAdmin();
}

/// 구독 상태 Provider
@riverpod
Future<SubscriptionStatus> subscriptionStatus(Ref ref) async {
  return await UserPermissionService.instance.getSubscriptionStatus();
}

/// 특정 권한 체크 Provider
@riverpod
Future<bool> hasUserPermission(Ref ref, String permission) async {
  return await UserPermissionService.instance.hasPermission(permission);
}

/// 권한과 제한 체크 Provider
@riverpod
Future<PermissionResult> checkPermissionWithLimits(Ref ref, String permission) async {
  return await UserPermissionService.instance.checkPermissionWithLimits(permission);
}