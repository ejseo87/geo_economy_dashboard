import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import '../logger.dart';

/// 모바일용 공유 서비스 헬퍼
class ShareServiceMobile {
  /// 이미지 파일로 저장 후 공유
  static Future<bool> shareImageFile(
    Uint8List imageBytes, 
    String filename, 
    String? text, 
    String title,
  ) async {
    try {
      await _requestPermissions();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(imageBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: text ?? title, 
        subject: title,
      );
      return true;
    } catch (e) {
      AppLogger.error('[ShareServiceMobile] Error sharing image: $e');
      return false;
    }
  }

  /// 이미지를 갤러리에 저장 (iOS/Android 최적화)
  static Future<bool> saveImageFile(Uint8List imageBytes, String filename) async {
    try {
      // 권한 확인 및 요청
      final hasPermission = await _checkAndRequestGalleryPermission();
      if (!hasPermission) {
        AppLogger.error('[ShareServiceMobile] Gallery permission denied');
        return false;
      }

      if (Platform.isIOS) {
        // iOS: gal 패키지를 사용하여 Photos 앱에 저장
        try {
          await Gal.putImageBytes(imageBytes, album: 'Geo Economy Dashboard');
          AppLogger.info('[ShareServiceMobile] Successfully saved image to iOS Photos');
        } catch (galError) {
          AppLogger.error('[ShareServiceMobile] Gal package failed: $galError');
          
          // Fallback: Documents 폴더에 저장
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$filename');
          await file.writeAsBytes(imageBytes);
          AppLogger.info('[ShareServiceMobile] Fallback: Saved to Documents folder: ${file.path}');
          
          // 시뮬레이터에서는 이것이 정상적인 동작임을 알림
          final isSimulator = await _isIOSSimulator();
          if (isSimulator) {
            AppLogger.warning('[ShareServiceMobile] iOS Simulator detected - Photos app save not supported, saved to Documents instead');
          }
        }
      } else if (Platform.isAndroid) {
        // Android: gal 패키지 사용
        await Gal.putImageBytes(imageBytes, album: 'Geo Economy Dashboard');
        AppLogger.info('[ShareServiceMobile] Successfully saved image to Android Gallery');
      } else {
        // 기타 플랫폼: Documents 폴더에 저장
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(imageBytes);
        AppLogger.info('[ShareServiceMobile] Successfully saved image to: ${file.path}');
      }
      return true;
    } catch (e) {
      AppLogger.error('[ShareServiceMobile] Error saving image: $e');
      return false;
    }
  }

  /// CSV 파일로 저장 후 공유
  static Future<bool> shareCsvFile(
    String csvContent, 
    String csvFileName, 
    String? title,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$csvFileName');
      await file.writeAsString(csvContent, encoding: utf8);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: title ?? 'CSV 데이터 내보내기',
        subject: title ?? csvFileName,
      );
      return true;
    } catch (e) {
      AppLogger.error('[ShareServiceMobile] Error sharing CSV: $e');
      return false;
    }
  }

  /// 공유용 권한 요청 (가벼운 버전)
  static Future<void> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        // iOS에서는 공유만 하는 경우 특별한 권한 불필요
        AppLogger.info('[ShareServiceMobile] iOS share permissions OK');
      } else if (Platform.isAndroid) {
        // Android에서는 임시 파일 접근만 필요
        await Permission.storage.request();
      }
    } catch (e) {
      AppLogger.error('[ShareServiceMobile] Error requesting permissions: $e');
    }
  }

  /// 갤러리 저장을 위한 권한 확인 및 요청
  static Future<bool> _checkAndRequestGalleryPermission() async {
    try {
      if (Platform.isIOS) {
        // iOS Simulator 감지
        final isSimulator = await _isIOSSimulator();
        if (isSimulator) {
          AppLogger.warning('[ShareServiceMobile] Running on iOS Simulator - gallery save may not work properly');
          // 시뮬레이터에서도 시도해보지만 실패할 수 있음을 로그에 남김
        }

        // iOS에서는 gal 패키지가 자동으로 권한 처리
        final status = await Permission.photos.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          AppLogger.info('[ShareServiceMobile] Requesting iOS Photos permission');
          final result = await Permission.photos.request();
          if (result.isDenied || result.isPermanentlyDenied) {
            AppLogger.error('[ShareServiceMobile] iOS Photos permission denied: $result');
            return false;
          }
        }
        AppLogger.info('[ShareServiceMobile] iOS Photos permission: ${await Permission.photos.status}');
        return true;
      } else if (Platform.isAndroid) {
        // Android API 레벨별 권한 처리
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 33) {
          // Android 13+ (API 33+)
          final result = await Permission.photos.request();
          return result.isGranted;
        } else {
          // Android 12 이하
          final result = await Permission.storage.request();
          return result.isGranted;
        }
      }
      return true;
    } catch (e) {
      AppLogger.error('[ShareServiceMobile] Error checking gallery permissions: $e');
      return false;
    }
  }

  /// Android 버전 확인
  static Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      // 실제 구현에서는 device_info_plus를 사용해야 함
      // 여기서는 안전한 기본값으로 30 반환
      return 30;
    }
    return 0;
  }

  /// iOS Simulator 여부 확인
  static Future<bool> _isIOSSimulator() async {
    if (Platform.isIOS) {
      try {
        // iOS에서 시뮬레이터인지 확인하는 간단한 방법
        // 실제로는 device_info_plus를 사용하는 것이 더 정확함
        return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
               Platform.environment.containsKey('SIMULATOR_ROOT');
      } catch (e) {
        AppLogger.error('[ShareServiceMobile] Error checking simulator: $e');
        return false;
      }
    }
    return false;
  }
}