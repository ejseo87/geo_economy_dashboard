import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';

class EconomicHighlightCard extends StatelessWidget {
  const EconomicHighlightCard({
    super.key,
    required this.title,
    required this.value,
    required this.year,
    required this.isDark,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String year;
  final bool isDark;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark ? Colors.white60 : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Gaps.v4,
                Text(
                  value,
                  style: AppTypography.heading2.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v2,
                Text(
                  year,
                  style: AppTypography.bodySmall.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }
}
