import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/accessibility_settings.dart';
import '../services/accessibility_service.dart';

part 'accessibility_view_model.g.dart';

/// 접근성 설정 뷰모델
@riverpod
class AccessibilityViewModel extends _$AccessibilityViewModel {
  @override
  AccessibilitySettings build() {
    // 서비스 초기화가 완료되면 설정을 반환
    ref.onDispose(() {
      // 정리 작업이 필요한 경우
    });
    
    return AccessibilityService.instance.settings;
  }

  /// 폰트 크기 설정
  Future<void> setFontScale(double scale) async {
    await AccessibilityService.instance.setFontScale(scale);
    state = AccessibilityService.instance.settings;
  }

  /// 고대비 모드 토글
  Future<void> toggleHighContrast() async {
    final newValue = !state.highContrast;
    await AccessibilityService.instance.setHighContrast(newValue);
    state = AccessibilityService.instance.settings;
  }

  /// 색맹 모드 설정
  Future<void> setColorblindMode(bool enabled, ColorblindType type) async {
    await AccessibilityService.instance.setColorblindMode(enabled, type);
    state = AccessibilityService.instance.settings;
  }

  /// 애니메이션 감소 토글
  Future<void> toggleReduceMotion() async {
    final newValue = !state.reduceMotion;
    await AccessibilityService.instance.setReduceMotion(newValue);
    state = AccessibilityService.instance.settings;
  }

  /// 스크린 리더 지원 토글
  Future<void> toggleScreenReaderSupport() async {
    final newValue = !state.screenReaderSupport;
    await AccessibilityService.instance.setScreenReaderSupport(newValue);
    state = AccessibilityService.instance.settings;
  }
}