import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/typography.dart';
import '../../widgets/recommended_comparison_card.dart';

/// 두번째 탭: 1분 규칙 - AI 추천 비교 (1-2개 지표)
class AIComparisonTab extends ConsumerWidget {
  const AIComparisonTab({super.key});

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
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '1분 규칙: 심화 분석',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accent,
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
        // AI 추천 비교 카드
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: RecommendedComparisonCard(),
          ),
        ),

        // AI 추천 알고리즘 설명
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
                      FontAwesomeIcons.brain,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI 추천 알고리즘',
                      style: AppTypography.bodyMediumBold.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'AI가 7개 카테고리에서 다양성을 고려해 2-3개 지표를 자동 선별합니다.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '• 성장/활동: GDP 성장률, 1인당 GDP, 제조업 비중, 투자율\n'
                  '• 고용/노동: 실업률, 고용률, 노동참가율\n'
                  '• 물가/통화: 인플레이션, 통화량\n'
                  '• 재정/정부: 정부지출, 조세수입, 정부부채\n'
                  '• 대외/거시건전성: 경상수지, 수출입, 외환보유액\n'
                  '• 분배/사회: 지니계수, 빈곤율\n'
                  '• 환경/에너지: CO₂ 배출, 재생에너지',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
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
