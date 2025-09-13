import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/typography.dart';
import '../../../worldbank/widgets/country_vs_country_card.dart';
import '../../../worldbank/widgets/indicator_comparison_card.dart';
import '../../../worldbank/models/core_indicators.dart';
import '../../../worldbank/view_models/country_comparison_view_model.dart';
import '../../../../common/countries/models/country.dart';
import '../../../../common/countries/view_models/selected_country_provider.dart';

enum ComparisonMode {
  countryVsCountry,
  indicatorComparison,
}

/// 두번째 탭: 1분 규칙 - 비교 분석 (2가지 모드)
class AIComparisonTab extends ConsumerStatefulWidget {
  const AIComparisonTab({super.key});

  @override
  ConsumerState<AIComparisonTab> createState() => _AIComparisonTabState();
}

class _AIComparisonTabState extends ConsumerState<AIComparisonTab> {
  ComparisonMode _comparisonMode = ComparisonMode.countryVsCountry;

  @override
  Widget build(BuildContext context) {
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
                        '1분 규칙: 비교 분석',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 비교 모드 선택 토글
                _buildComparisonModeToggle(),
              ],
            ),
          ),
        ),
        // AI 추천 비교 카드
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAIRecommendedCard(),
          ),
        ),

        // 비교 모드에 따른 콘텐츠 표시
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _comparisonMode == ComparisonMode.countryVsCountry
                ? CountryVsCountryCard(
                    comparisonCountry: Country(
                      code: 'DEU',
                      name: '독일',
                      nameKo: '독일', 
                      region: 'Europe',
                      flagEmoji: '🇩🇪',
                    ),
                  )
                : IndicatorComparisonCard(
                    indicator: CoreIndicators.indicators.first, // 기본값
                  ),
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

  Widget _buildComparisonModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              '국가 vs 국가',
              ComparisonMode.countryVsCountry,
              Icons.public,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              '지표 비교',
              ComparisonMode.indicatorComparison,
              Icons.analytics,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, ComparisonMode mode, IconData icon) {
    final isSelected = _comparisonMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _comparisonMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendedCard() {
    return Consumer(
      builder: (context, ref, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.brain,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🤖 AI 추천 비교',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Consumer(
                          builder: (context, ref, child) {
                            final selectedCountry = ref.watch(selectedCountryProvider);
                            return Text(
                              '${selectedCountry.nameKo} vs OECD 중앙값',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(countryComparisonViewModelProvider.notifier).loadAIRecommendedComparison();
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRotateRight,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // AI 추천 로딩/에러/데이터 표시
              Consumer(
                builder: (context, ref, child) {
                  final comparisonAsync = ref.watch(countryComparisonViewModelProvider);
                  return comparisonAsync.when(
                    loading: () => Column(
                      children: [
                        const CircularProgressIndicator(color: AppColors.accent),
                        const SizedBox(height: 12),
                        Text(
                          'AI가 다양한 카테고리에서 지표를 선별 중...',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    error: (error, _) => Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.triangleExclamation,
                          color: AppColors.error,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI 추천 데이터 로딩 실패',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    data: (result) => result?.type == ComparisonType.aiRecommended
                        ? Text(
                            '✅ ${result!.country1Indicators.length}개 지표가 AI에 의해 선별되었습니다',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              ref.read(countryComparisonViewModelProvider.notifier).loadAIRecommendedComparison();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('AI 추천 받기'),
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
