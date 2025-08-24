import 'package:flutter/foundation.dart';
import '../logger.dart';

/// 웹용 공유 서비스 스텁 (실제로는 사용되지 않음)
class ShareServiceMobile {
  /// 이미지 파일로 저장 후 공유 (웹에서는 사용되지 않음)
  static Future<bool> shareImageFile(
    Uint8List imageBytes, 
    String filename, 
    String? text, 
    String title,
  ) async {
    // 웹에서는 이 메서드가 호출되지 않아야 함
    AppLogger.error('[ShareServiceMobile] Web stub method called');
    return false;
  }

  /// 이미지를 저장 (웹에서는 사용되지 않음)
  static Future<bool> saveImageFile(Uint8List imageBytes, String filename) async {
    // 웹에서는 이 메서드가 호출되지 않아야 함
    AppLogger.error('[ShareServiceMobile] Web stub method called');
    return false;
  }

  /// CSV 파일로 저장 후 공유 (웹에서는 사용되지 않음)
  static Future<bool> shareCsvFile(
    String csvContent, 
    String csvFileName, 
    String? title,
  ) async {
    // 웹에서는 이 메서드가 호출되지 않아야 함
    AppLogger.error('[ShareServiceMobile] Web stub method called');
    return false;
  }
}