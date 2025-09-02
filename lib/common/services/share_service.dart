import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../logger.dart';
import 'share_service_mobile.dart' if (dart.library.html) 'share_service_web.dart';

/// 카드 공유 및 이미지 내보내기 서비스
class ShareService {
  static ShareService? _instance;
  static ShareService get instance => _instance ??= ShareService._();
  
  ShareService._();

  /// 위젯을 이미지로 캡처하고 공유하기
  Future<bool> shareWidgetAsImage({
    required GlobalKey repaintBoundaryKey,
    required String title,
    String? text,
    String? fileName,
  }) async {
    try {
      // 위젯을 이미지로 캡처
      final imageBytes = await _captureWidget(repaintBoundaryKey);
      if (imageBytes == null) {
        AppLogger.error('[ShareService] Failed to capture widget');
        return false;
      }

      final filename = fileName ?? 'geo_dashboard_${DateTime.now().millisecondsSinceEpoch}.png';
      
      if (kIsWeb) {
        // 웹에서는 메모리에서 직접 공유
        await Share.shareXFiles([
          XFile.fromData(imageBytes, name: filename, mimeType: 'image/png')
        ]);
      } else {
        // 모바일에서는 헬퍼 클래스 사용
        return await ShareServiceMobile.shareImageFile(imageBytes, filename, text, title);
      }

      AppLogger.info('[ShareService] Successfully shared widget as image');
      return true;
    } catch (e) {
      AppLogger.error('[ShareService] Error sharing widget as image: $e');
      return false;
    }
  }

  /// 텍스트와 함께 이미지 공유
  Future<bool> shareTextWithImage({
    required GlobalKey repaintBoundaryKey,
    required String title,
    required String text,
    String? fileName,
  }) async {
    return await shareWidgetAsImage(
      repaintBoundaryKey: repaintBoundaryKey,
      title: title,
      text: text,
      fileName: fileName,
    );
  }

  /// 링크 공유
  Future<bool> shareLink({
    required String url,
    required String title,
    String? description,
  }) async {
    try {
      final shareText = description != null 
          ? '$title\n$description\n\n$url'
          : '$title\n\n$url';

      await Share.share(shareText, subject: title);
      AppLogger.info('[ShareService] Successfully shared link');
      return true;
    } catch (e) {
      AppLogger.error('[ShareService] Error sharing link: $e');
      return false;
    }
  }

  /// 이미지를 갤러리/다운로드 폴더에 저장
  Future<bool> saveImageToGallery({
    required GlobalKey repaintBoundaryKey,
    String? fileName,
  }) async {
    try {
      AppLogger.info('[ShareService] Starting image save to gallery');
      
      final imageBytes = await _captureWidget(repaintBoundaryKey);
      if (imageBytes == null) {
        AppLogger.error('[ShareService] Failed to capture widget for gallery save');
        return false;
      }

      final filename = fileName ?? 'geo_dashboard_${DateTime.now().millisecondsSinceEpoch}.png';
      AppLogger.info('[ShareService] Captured image (${imageBytes.length} bytes), filename: $filename');

      if (kIsWeb) {
        // 웹에서는 공유 기능으로 대체 (브라우저가 다운로드 처리)
        await Share.shareXFiles([
          XFile.fromData(imageBytes, name: filename, mimeType: 'image/png')
        ]);
        AppLogger.info('[ShareService] Shared image for web download');
      } else {
        // 모바일에서는 헬퍼 클래스 사용
        AppLogger.info('[ShareService] Attempting to save to mobile gallery');
        final result = await ShareServiceMobile.saveImageFile(imageBytes, filename);
        if (!result) {
          AppLogger.error('[ShareService] Mobile gallery save failed');
          return false;
        }
        AppLogger.info('[ShareService] Mobile gallery save successful');
      }
      
      return true;
    } catch (e) {
      AppLogger.error('[ShareService] Error saving image to gallery: $e');
      return false;
    }
  }

  /// CSV 파일 내보내기
  Future<bool> exportToCsv({
    required String csvContent,
    required String fileName,
    String? title,
  }) async {
    try {
      final csvFileName = fileName.endsWith('.csv') ? fileName : '$fileName.csv';
      
      if (kIsWeb) {
        // 웹에서는 메모리에서 직접 공유
        await Share.shareXFiles([
          XFile.fromData(
            utf8.encode(csvContent), 
            name: csvFileName,
            mimeType: 'text/csv',
          )
        ]);
      } else {
        // 모바일에서는 헬퍼 클래스 사용
        return await ShareServiceMobile.shareCsvFile(csvContent, csvFileName, title);
      }
      
      AppLogger.info('[ShareService] CSV exported successfully');
      return true;
    } catch (e) {
      AppLogger.error('[ShareService] Error exporting CSV: $e');
      return false;
    }
  }

  /// 위젯 캡처 (RepaintBoundary 사용)
  Future<Uint8List?> _captureWidget(GlobalKey repaintBoundaryKey) async {
    try {
      final RenderRepaintBoundary boundary = 
          repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      
      // 고해상도로 캡처 (2배)
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      AppLogger.error('[ShareService] Error capturing widget: $e');
      return null;
    }
  }


  /// 공유 가능 여부 확인
  Future<bool> canShare() async {
    return true; // 모든 플랫폼에서 지원
  }

  /// 클립보드에 텍스트 복사
  Future<bool> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      AppLogger.info('[ShareService] Text copied to clipboard successfully');
      return true;
    } catch (e) {
      AppLogger.error('[ShareService] Error copying to clipboard: $e');
      // 클립보드 복사에 실패한 경우 공유로 대체
      try {
        await Share.share(text);
        AppLogger.info('[ShareService] Fallback to share successful');
        return true;
      } catch (shareError) {
        AppLogger.error('[ShareService] Fallback share also failed: $shareError');
        return false;
      }
    }
  }
}

/// 공유 옵션 열거형
enum ShareOption {
  image('이미지로 공유'),
  imageWithText('텍스트와 함께 공유'),
  link('링크 공유'),
  saveToGallery('갤러리에 저장'),
  copyLink('링크 복사'),
  exportCsv('CSV로 내보내기');

  const ShareOption(this.displayName);
  final String displayName;

  IconData get icon {
    switch (this) {
      case ShareOption.image:
        return Icons.share;
      case ShareOption.imageWithText:
        return Icons.share_outlined;
      case ShareOption.link:
        return Icons.link;
      case ShareOption.saveToGallery:
        return Icons.download;
      case ShareOption.copyLink:
        return Icons.copy;
      case ShareOption.exportCsv:
        return Icons.table_chart;
    }
  }
}

/// 공유 옵션 결과
class ShareResult {
  final bool success;
  final String? message;
  final String? filePath;

  const ShareResult({
    required this.success,
    this.message,
    this.filePath,
  });

  factory ShareResult.success({String? message, String? filePath}) =>
      ShareResult(success: true, message: message, filePath: filePath);

  factory ShareResult.failure(String message) =>
      ShareResult(success: false, message: message);
}