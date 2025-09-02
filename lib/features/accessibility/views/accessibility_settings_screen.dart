import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/gaps.dart';
import '../../../common/widgets/app_bar_widget.dart';
import '../models/accessibility_settings.dart';
import '../view_models/accessibility_view_model.dart';
import '../services/accessibility_service.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  static const String routeName = "accessibility";
  static const String routeURL = "/accessibility";

  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilityViewModelProvider);
    final notifier = ref.read(accessibilityViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AccessibilityService.instance.adjustColorForHighContrast(
        AppColors.background,
        isBackground: true,
      ),
      appBar: const AppBarWidget(
        title: '접근성',
        showGlobe: false,
        showNotification: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: '텍스트 크기',
            children: [
              _buildFontSizeSection(context, settings, notifier),
            ],
          ),
          Gaps.v24,
          _buildSection(
            title: '시각적 접근성',
            children: [
              _buildToggleOption(
                icon: FontAwesomeIcons.circleHalfStroke,
                title: '고대비 모드',
                subtitle: '텍스트와 배경의 대비를 높입니다',
                value: settings.highContrast,
                onToggle: (_) => notifier.toggleHighContrast(),
              ),
              Gaps.v12,
              _buildColorblindSection(context, settings, notifier),
            ],
          ),
          Gaps.v24,
          _buildSection(
            title: '상호작용',
            children: [
              _buildToggleOption(
                icon: FontAwesomeIcons.hand,
                title: '애니메이션 감소',
                subtitle: '화면 전환과 애니메이션을 줄입니다',
                value: settings.reduceMotion,
                onToggle: (_) => notifier.toggleReduceMotion(),
              ),
              Gaps.v12,
              _buildToggleOption(
                icon: FontAwesomeIcons.universalAccess,
                title: '스크린 리더 지원',
                subtitle: 'VoiceOver 및 TalkBack 최적화',
                value: settings.screenReaderSupport,
                onToggle: (_) => notifier.toggleScreenReaderSupport(),
              ),
            ],
          ),
          Gaps.v24,
          _buildPreviewSection(settings),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AccessibilityService.instance.applyFontScale(
            AppTypography.heading3.copyWith(
              color: AccessibilityService.instance.adjustColorForHighContrast(
                AppColors.textPrimary,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Gaps.v12,
        Container(
          decoration: BoxDecoration(
            color: AccessibilityService.instance.adjustColorForHighContrast(
              AppColors.white,
              isBackground: true,
            ),
            borderRadius: BorderRadius.circular(12),
            border: AccessibilityService.instance.settings.highContrast
                ? Border.all(color: AppColors.textPrimary, width: 2)
                : null,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildFontSizeSection(
    BuildContext context,
    AccessibilitySettings settings,
    AccessibilityViewModel notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '텍스트 크기 조정',
            style: AccessibilityService.instance.applyFontScale(
              AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Gaps.v12,
          Slider(
            value: settings.fontScale,
            min: 0.8,
            max: 2.0,
            divisions: 12,
            activeColor: AccessibilityService.instance.adjustColorForColorblind(
              AppColors.primary,
            ),
            onChanged: (value) => notifier.setFontScale(value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: FontSizePreset.values.map((preset) {
              final isSelected = (settings.fontScale - preset.scale).abs() < 0.1;
              return GestureDetector(
                onTap: () => notifier.setFontScale(preset.scale),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AccessibilityService.instance.adjustColorForColorblind(
                            AppColors.primary.withValues(alpha: 0.1),
                          )
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? Border.all(
                            color: AccessibilityService.instance.adjustColorForColorblind(
                              AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  child: Text(
                    preset.displayName,
                    style: TextStyle(
                      fontSize: 12 * preset.scale,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Gaps.v8,
          Text(
            '현재 크기: ${(settings.fontScale * 100).round()}%',
            style: AccessibilityService.instance.applyFontScale(
              AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorblindSection(
    BuildContext context,
    AccessibilitySettings settings,
    AccessibilityViewModel notifier,
  ) {
    return ExpansionTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.eyeDropper,
            color: AppColors.primary,
            size: 16,
          ),
        ),
      ),
      title: Text(
        '색맹 지원',
        style: AccessibilityService.instance.applyFontScale(
          AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      subtitle: Text(
        settings.colorblindMode
            ? '활성화: ${settings.colorblindType.displayName}'
            : '색상을 구분하기 어려운 사용자를 위한 설정',
        style: AccessibilityService.instance.applyFontScale(
          AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: ColorblindType.values.map((type) {
              final isSelected = settings.colorblindMode && settings.colorblindType == type;
              return RadioListTile<ColorblindType>(
                title: Text(
                  type.displayName,
                  style: AccessibilityService.instance.applyFontScale(
                    AppTypography.bodyMedium,
                  ),
                ),
                value: type,
                groupValue: settings.colorblindMode ? settings.colorblindType : null,
                onChanged: (value) {
                  if (value != null) {
                    notifier.setColorblindMode(value != ColorblindType.none, value);
                  }
                },
                activeColor: AccessibilityService.instance.adjustColorForColorblind(
                  AppColors.primary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onToggle,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (value ? AppColors.primary : AppColors.textSecondary)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: value ? AppColors.primary : AppColors.textSecondary,
            size: 16,
          ),
        ),
      ),
      title: Text(
        title,
        style: AccessibilityService.instance.applyFontScale(
          AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AccessibilityService.instance.applyFontScale(
          AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onToggle,
        activeColor: AccessibilityService.instance.adjustColorForColorblind(
          AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPreviewSection(AccessibilitySettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '미리보기',
          style: AccessibilityService.instance.applyFontScale(
            AppTypography.heading3.copyWith(
              color: AccessibilityService.instance.adjustColorForHighContrast(
                AppColors.textPrimary,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Gaps.v12,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AccessibilityService.instance.adjustColorForHighContrast(
              AppColors.white,
              isBackground: true,
            ),
            borderRadius: BorderRadius.circular(12),
            border: settings.highContrast
                ? Border.all(color: AppColors.textPrimary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AccessibilityService.instance.adjustColorForColorblind(
                        AppColors.primary,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Gaps.h8,
                  Expanded(
                    child: Text(
                      '대한민국의 GDP 성장률',
                      style: AccessibilityService.instance.applyFontScale(
                        AppTypography.heading4.copyWith(
                          color: AccessibilityService.instance.adjustColorForHighContrast(
                            AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Gaps.v8,
              Text(
                '1.4%',
                style: AccessibilityService.instance.applyFontScale(
                  AppTypography.heading1.copyWith(
                    color: AccessibilityService.instance.adjustColorForColorblind(
                      AppColors.accent,
                    ),
                  ),
                ),
              ),
              Gaps.v4,
              Text(
                '전년 대비 상승',
                style: AccessibilityService.instance.applyFontScale(
                  AppTypography.bodySmall.copyWith(
                    color: AccessibilityService.instance.adjustColorForHighContrast(
                      AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}