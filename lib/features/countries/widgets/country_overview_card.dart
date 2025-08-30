import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../models/country.dart';

class CountryOverviewCard extends ConsumerWidget {
  final Country country;

  const CountryOverviewCard({super.key, required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 선택된 국가를 현재 국가로 설정하고 summary를 가져옴
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.chartLine,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: Sizes.size8),
                Text(
                  '경제 개요',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            _buildStaticOverviewContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticOverviewContent() {
    return Column(
      children: [
        _buildOverviewItem(
          icon: FontAwesomeIcons.chartLine,
          title: 'GDP 성장률',
          value: null, // 실제 데이터를 가져와야 함
          unit: '%',
          color: AppColors.textSecondary,
        ),
        const Divider(height: Sizes.size24),
        _buildOverviewItem(
          icon: FontAwesomeIcons.users,
          title: '실업률',
          value: null,
          unit: '%',
          color: AppColors.textSecondary,
        ),
        const Divider(height: Sizes.size24),
        _buildOverviewItem(
          icon: FontAwesomeIcons.dollarSign,
          title: '1인당 GDP (PPP)',
          value: null,
          unit: 'USD',
          isLarge: true,
          color: AppColors.accent,
        ),
        const Divider(height: Sizes.size24),
        _buildOverviewItem(
          icon: FontAwesomeIcons.chartColumn,
          title: 'CPI 인플레이션',
          value: null,
          unit: '%',
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String title,
    required dynamic value,
    required String unit,
    bool isLarge = false,
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, size: 16, color: color ?? AppColors.primary),
        ),
        const SizedBox(width: Sizes.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value != null
                    ? isLarge && unit == 'USD'
                          ? '\$${_formatLargeNumber(value)}'
                          : '${_formatNumber(value)}$unit'
                    : '데이터 없음',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: value != null
                      ? color ?? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number.abs() >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number.abs() >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(1);
    }
  }

  String _formatLargeNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}
