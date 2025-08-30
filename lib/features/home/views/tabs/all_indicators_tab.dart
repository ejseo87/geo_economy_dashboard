import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/typography.dart';
import '../../../countries/view_models/selected_country_provider.dart';
import '../../widgets/all_indicators_section.dart';

/// 세번째 탭: 핵심 20지표 전체 + QoQ/YoY 변화
class AllIndicatorsTab extends ConsumerWidget {
  const AllIndicatorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // 헤더
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.database,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '전체 지표: 종합 분석',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 전체 지표 섹션
        const SliverToBoxAdapter(child: AllIndicatorsSection()),

        // 데이터 출처 및 업데이트 정보
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.circleInfo,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '데이터 정보',
                      style: AppTypography.bodyMediumBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '모든 데이터는 World Bank API를 통해 실시간으로 제공됩니다.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '• 데이터 출처: World Bank Open Data (api.worldbank.org)\n'
                  '• 비교 기준: OECD 38개국\n'
                  '• 업데이트: 지표별 상이 (월간/분기/연간)\n'
                  '• 통계 방법: 미디안, 사분위수(IQR), 백분위 기반\n'
                  '• 캐시: Firebase Firestore를 통한 최적화',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.lightbulb,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '각 지표 카드를 길게 눌러 상세 정보를 확인하세요!',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 여백
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
