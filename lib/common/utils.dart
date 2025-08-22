import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool isDarkMode(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark;
}

/// Firebase 오류를 사용자 친화적인 메시지로 변환
void showFirebaseErrorSnack({
  required BuildContext context,
  required Object error,
}) {
  String message = _getUserFriendlyErrorMessage(error);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red.shade600,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: '확인',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

/// 오류 메시지를 사용자 친화적으로 변환
String _getUserFriendlyErrorMessage(Object error) {
  final errorString = error.toString().toLowerCase();

  // 키체인 관련 오류 (개선된 메시지)
  if (errorString.contains('keychain') ||
      errorString.contains('nslocalizedfailurereasonerrorkey')) {
    return '로컬 저장소 접근에 문제가 있지만, 계정 생성은 완료되었습니다. 로그인을 다시 시도해주세요.';
  }

  // 네트워크 관련 오류
  if (errorString.contains('network') ||
      errorString.contains('timeout') ||
      errorString.contains('connection')) {
    return '네트워크 연결을 확인해주세요.';
  }

  // Firebase 인증 오류
  if (errorString.contains('user-not-found')) {
    return '등록되지 않은 이메일입니다.';
  }
  if (errorString.contains('wrong-password')) {
    return '잘못된 비밀번호입니다.';
  }
  if (errorString.contains('email-already-in-use')) {
    return '이미 사용 중인 이메일입니다.';
  }
  if (errorString.contains('weak-password')) {
    return '비밀번호가 너무 약합니다.';
  }
  if (errorString.contains('invalid-email')) {
    return '유효하지 않은 이메일 형식입니다.';
  }
  if (errorString.contains('too-many-requests')) {
    return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
  }
  if (errorString.contains('user-disabled')) {
    return '비활성화된 계정입니다.';
  }

  // 기타 오류는 원본 메시지 사용 (Exception: 제거)
  return errorString.replaceAll('exception: ', '');
}

/// 키체인 오류 복구 시도 (개선된 버전)
Future<bool> tryRecoverFromKeychainError() async {
  try {
    // SharedPreferences를 통한 단계별 복구 시도
    final prefs = await SharedPreferences.getInstance();
    
    // 1단계: 인증 관련 키만 제거
    final authKeys = ['auth_state', 'user_token', 'refresh_token'];
    for (String key in authKeys) {
      try {
        await prefs.remove(key);
      } catch (e) {
        AppLogger.warning('Could not remove key $key', e);
      }
    }
    
    // 2단계: 전체 정리 (1단계가 실패한 경우)
    try {
      await prefs.clear();
      AppLogger.info('Successfully cleared all SharedPreferences');
    } catch (e) {
      AppLogger.warning('Could not clear all preferences', e);
    }
    
    return true;
  } catch (e) {
    AppLogger.warning('Could not recover from keychain error', e);
    return false;
  }
}

/// 향상된 키체인 오류 복구 (사용자 알림 포함)
Future<bool> recoverFromKeychainErrorWithUserNotification(
  BuildContext context,
) async {
  final recovered = await tryRecoverFromKeychainError();
  
  if (recovered && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('로컬 저장소 문제를 해결했습니다. 다시 로그인해주세요.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  return recovered;
}

/// 안전한 로컬 저장소 접근
Future<T?> safeLocalStorageAccess<T>(
  Future<T> Function() operation, {
  T? defaultValue,
}) async {
  try {
    return await operation();
  } catch (e) {
    AppLogger.warning('Local storage access failed', e);
    return defaultValue;
  }
}

void showInfoSnackBar({required String title, required BuildContext context}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.size10),
      ),
      duration: Duration(milliseconds: 2000),
      content: Text(title),
      action: SnackBarAction(label: "Ok", onPressed: () {}),
    ),
  );
}

String makeDateTimeDifference(int createdAt) {
  final createdDateTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
  final currentDateTime = DateTime.now();
  final diffMins = currentDateTime.difference(createdDateTime).inMinutes;
  final diffHours = currentDateTime.difference(createdDateTime).inHours;
  final diffDays = currentDateTime.difference(createdDateTime).inDays;

  if (diffMins < 60) {
    if (diffMins == 1 || diffMins == 0) {
      return "$diffMins minute ago";
    } else {
      return "$diffMins minutes ago";
    }
  } else if (diffMins > 59 && diffMins < 1440) {
    if (diffHours == 1) {
      return "$diffHours hour ago";
    } else {
      return "$diffHours hours ago";
    }
  } else {
    if (diffDays == 1) {
      return "$diffDays day ago";
    } else {
      return "$diffDays days ago";
    }
  }
}
