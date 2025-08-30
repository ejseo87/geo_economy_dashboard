import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../models/country.dart';
import '../../worldbank/models/indicator_codes.dart';

class CountryIndicatorsSection extends ConsumerWidget {
  final Country country;
  
  const CountryIndicatorsSection({
    super.key,
    required this.country,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.chartBar,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: Sizes.size8),
            Text(
              '주요 경제지표',
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: Sizes.size16),
        _buildIndicatorCategory(
          context: context,
          title: '경제 성장',
          icon: FontAwesomeIcons.chartLine,
          indicators: [
            IndicatorCode.gdpRealGrowth,
            IndicatorCode.gdpPppPerCapita,
            IndicatorCode.gdpPppPerCapita,
          ],
        ),
        const SizedBox(height: Sizes.size16),
        _buildIndicatorCategory(
          context: context,
          title: '고용 및 노동',
          icon: FontAwesomeIcons.users,
          indicators: [
            IndicatorCode.unemployment,
            IndicatorCode.employmentRate,
            IndicatorCode.laborParticipation,
          ],
        ),
        const SizedBox(height: Sizes.size16),
        _buildIndicatorCategory(
          context: context,
          title: '물가 및 통화',
          icon: FontAwesomeIcons.dollarSign,
          indicators: [
            IndicatorCode.cpiInflation,
            IndicatorCode.m2Money,
          ],
        ),
        const SizedBox(height: Sizes.size16),
        _buildIndicatorCategory(
          context: context,
          title: '대외거래',
          icon: FontAwesomeIcons.globe,
          indicators: [
            IndicatorCode.currentAccount,
            IndicatorCode.exportsShare,
            IndicatorCode.importsShare,
          ],
        ),
      ],
    );
  }
  
  Widget _buildIndicatorCategory({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<IndicatorCode> indicators,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  icon,
                  color: AppColors.accent,
                  size: 16,
                ),
                const SizedBox(width: Sizes.size8),
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size12),
            Column(
              children: indicators.map((indicator) => 
                _buildIndicatorItem(context, indicator)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIndicatorItem(BuildContext context, IndicatorCode indicator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sizes.size8),
      child: InkWell(
        onTap: () {
          context.push('/indicator/${indicator.code}/${country.code}');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(Sizes.size12),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.chartLine,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: Sizes.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indicator.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      indicator.unit,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}