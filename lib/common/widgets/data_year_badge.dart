import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';

/// 데이터 년도를 표시하는 뱃지 위젯
class DataYearBadge extends StatelessWidget {
  final int year;
  final bool isLatest;
  final String? prefix;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;

  const DataYearBadge({
    super.key,
    required this.year,
    this.isLatest = true,
    this.prefix,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final isCurrentYear = year >= (currentYear - 1); // 작년 이상이면 최신으로 간주
    var effectiveBackgroundColor =
        backgroundColor ?? (isCurrentYear ? AppColors.accent : AppColors.error);
    effectiveBackgroundColor = effectiveBackgroundColor.withValues(alpha: 0.6);
    final effectiveTextColor = textColor ?? Colors.white;
    final displayText = prefix != null ? '$prefix $year년' : '$year년';

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: effectiveBackgroundColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            FaIcon(icon, size: 12, color: effectiveTextColor),
            const SizedBox(width: 4),
          ],
          Text(
            displayText,
            style: AppTypography.caption.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          if (isCurrentYear) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: effectiveTextColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 데이터 업데이트 상태를 표시하는 뱃지
class DataStatusBadge extends StatelessWidget {
  final int year;
  final DateTime? lastUpdated;
  final bool showUpdateTime;

  const DataStatusBadge({
    super.key,
    required this.year,
    this.lastUpdated,
    this.showUpdateTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final isCurrentYear = year >= (currentYear - 1); // 작년 이상이면 최신으로 간주

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (year == currentYear) {
      statusText = '최신';
      statusColor = AppColors.accent;
      statusIcon = FontAwesomeIcons.clockRotateLeft;
    } else if (year == currentYear - 1) {
      statusText = '작년';
      statusColor = AppColors.primary;
      statusIcon = FontAwesomeIcons.calendar;
    } else {
      statusText = '${currentYear - year}년 전';
      statusColor = AppColors.error;
      statusIcon = FontAwesomeIcons.triangleExclamation;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataYearBadge(
          year: year,
          isLatest: isCurrentYear,
          prefix: statusText,
          icon: statusIcon,
          backgroundColor: statusColor,
        ),
        if (showUpdateTime && lastUpdated != null) ...[
          const SizedBox(height: 4),
          Text(
            '업데이트: ${_formatUpdateTime(lastUpdated!)}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  String _formatUpdateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

/// 다중 년도 데이터 범위를 표시하는 뱃지
class DataRangeBadge extends StatelessWidget {
  final int startYear;
  final int endYear;
  final int? totalCount;

  const DataRangeBadge({
    super.key,
    required this.startYear,
    required this.endYear,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final rangeText = '$startYear-$endYear년';
    final countText = totalCount != null ? ' ($totalCount개)' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.chartLine,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$rangeText$countText',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
