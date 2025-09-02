import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';

/// 정보 툴팁 위젯
class InfoTooltip extends StatelessWidget {
  final String message;
  final String? title;
  final Widget? child;
  final IconData iconData;
  final Color iconColor;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final bool showIcon;
  final TooltipTriggerMode triggerMode;
  final Duration waitDuration;
  final Duration showDuration;
  final Widget? richMessage;

  const InfoTooltip({
    super.key,
    this.message = '',
    this.title,
    this.child,
    this.iconData = FontAwesomeIcons.circleInfo,
    this.iconColor = AppColors.textSecondary,
    this.iconSize = 16,
    this.padding,
    this.showIcon = true,
    this.triggerMode = TooltipTriggerMode.tap,
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(seconds: 3),
    this.richMessage,
  });

  @override
  Widget build(BuildContext context) {
    final tooltipContent = richMessage ?? 
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      );

    return Tooltip(
      message: '',  // Empty because we use richMessage
      richMessage: WidgetSpan(child: tooltipContent),
      triggerMode: triggerMode,
      waitDuration: waitDuration,
      showDuration: showDuration,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: AppTypography.bodySmall.copyWith(color: Colors.white70),
      child: child ?? (showIcon ? FaIcon(
        iconData,
        size: iconSize,
        color: iconColor,
      ) : const SizedBox.shrink()),
    );
  }
}

/// 지표 정의 툴팁
class IndicatorDefinitionTooltip extends StatelessWidget {
  final String indicatorName;
  final String definition;
  final String? unit;
  final String? source;
  final String? methodology;
  final Widget? child;

  const IndicatorDefinitionTooltip({
    super.key,
    required this.indicatorName,
    required this.definition,
    this.unit,
    this.source,
    this.methodology,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InfoTooltip(
      title: indicatorName,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 5),
      richMessage: _buildRichContent(),
      child: child ?? const FaIcon(
        FontAwesomeIcons.circleInfo,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildRichContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            indicatorName,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            definition,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '단위: ',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  unit!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
          if (source != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '출처: ',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(
                    source!,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (methodology != null) ...[
            const SizedBox(height: 8),
            Text(
              '계산 방법:',
              style: AppTypography.caption.copyWith(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              methodology!,
              style: AppTypography.caption.copyWith(
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 도움말 툴팁
class HelpTooltip extends StatelessWidget {
  final String helpText;
  final Widget? child;
  final IconData iconData;

  const HelpTooltip({
    super.key,
    required this.helpText,
    this.child,
    this.iconData = FontAwesomeIcons.circleQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return InfoTooltip(
      message: helpText,
      iconData: iconData,
      iconColor: AppColors.textSecondary,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: child,
    );
  }
}