import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/logger.dart';
import '../models/accessibility_settings.dart';

/// 접근성 서비스
class AccessibilityService {
  static const String _settingsKey = 'accessibility_settings';
  
  static AccessibilityService? _instance;
  static AccessibilityService get instance => _instance ??= AccessibilityService._();
  
  AccessibilityService._();

  SharedPreferences? _prefs;
  AccessibilitySettings _settings = const AccessibilitySettings();

  /// 초기화
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      AppLogger.info('[AccessibilityService] Initialized successfully');
    } catch (e) {
      AppLogger.error('[AccessibilityService] Error initializing: $e');
    }
  }

  /// 현재 설정 가져오기
  AccessibilitySettings get settings => _settings;

  /// 설정 저장
  Future<void> _saveSettings() async {
    try {
      final json = jsonEncode(_settings.toJson());
      await _prefs?.setString(_settingsKey, json);
      AppLogger.debug('[AccessibilityService] Settings saved');
    } catch (e) {
      AppLogger.error('[AccessibilityService] Error saving settings: $e');
    }
  }

  /// 설정 로드
  Future<void> _loadSettings() async {
    try {
      final json = _prefs?.getString(_settingsKey);
      if (json != null && json.isNotEmpty) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _settings = AccessibilitySettings.fromJson(data);
      }
    } catch (e) {
      AppLogger.error('[AccessibilityService] Error loading settings: $e');
      _settings = const AccessibilitySettings();
    }
  }

  /// 폰트 크기 설정
  Future<void> setFontScale(double scale) async {
    _settings = _settings.copyWith(fontScale: scale);
    await _saveSettings();
  }

  /// 고대비 모드 설정
  Future<void> setHighContrast(bool enabled) async {
    _settings = _settings.copyWith(highContrast: enabled);
    await _saveSettings();
  }

  /// 색맹 모드 설정
  Future<void> setColorblindMode(bool enabled, [ColorblindType? type]) async {
    _settings = _settings.copyWith(
      colorblindMode: enabled,
      colorblindType: type ?? _settings.colorblindType,
    );
    await _saveSettings();
  }

  /// 애니메이션 감소 설정
  Future<void> setReduceMotion(bool enabled) async {
    _settings = _settings.copyWith(reduceMotion: enabled);
    await _saveSettings();
  }

  /// 스크린 리더 지원 설정
  Future<void> setScreenReaderSupport(bool enabled) async {
    _settings = _settings.copyWith(screenReaderSupport: enabled);
    await _saveSettings();
  }

  /// 색맹 대응 색상 조정
  Color adjustColorForColorblind(Color original) {
    if (!_settings.colorblindMode) return original;
    
    final hsl = HSLColor.fromColor(original);
    
    switch (_settings.colorblindType) {
      case ColorblindType.protanopia:
      case ColorblindType.protanomaly:
        // 적색 인식 어려움 - 청록색 계열로 변환
        return HSLColor.fromAHSL(
          hsl.alpha, 
          (hsl.hue + 180) % 360, 
          hsl.saturation, 
          hsl.lightness
        ).toColor();
        
      case ColorblindType.deuteranopia:
      case ColorblindType.deuteranomaly:
        // 녹색 인식 어려움 - 보라색 계열로 변환
        return HSLColor.fromAHSL(
          hsl.alpha, 
          270, 
          hsl.saturation, 
          hsl.lightness
        ).toColor();
        
      case ColorblindType.tritanopia:
      case ColorblindType.tritanomaly:
        // 청색 인식 어려움 - 노란색 계열로 변환
        return HSLColor.fromAHSL(
          hsl.alpha, 
          60, 
          hsl.saturation, 
          hsl.lightness
        ).toColor();
        
      case ColorblindType.none:
        return original;
    }
  }

  /// 고대비 색상 조정
  Color adjustColorForHighContrast(Color color, {bool isBackground = false}) {
    if (!_settings.highContrast) return color;
    
    final luminance = color.computeLuminance();
    
    if (isBackground) {
      // 배경색은 더 극단적으로
      return luminance > 0.5 ? Colors.white : Colors.black;
    } else {
      // 텍스트/아이콘은 대비 강화
      return luminance > 0.5 ? Colors.black : Colors.white;
    }
  }

  /// WCAG AA 대비 준수 확인
  bool checkWCAGContrast(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    final contrast = (lighter + 0.05) / (darker + 0.05);
    return contrast >= 4.5; // WCAG AA 기준
  }

  /// 텍스트 크기 조정 적용
  TextStyle applyFontScale(TextStyle style) {
    return style.copyWith(
      fontSize: (style.fontSize ?? 14.0) * _settings.fontScale,
    );
  }
}