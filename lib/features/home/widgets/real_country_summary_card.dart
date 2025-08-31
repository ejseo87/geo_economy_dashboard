import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../../../constants/performance_colors.dart';
import '../models/country_summary.dart';
import '../view_models/country_summary_view_model.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';
import '../../favorites/models/favorite_item.dart';
import '../../favorites/widgets/favorites_floating_button.dart';

class RealCountrySummaryCard extends ConsumerStatefulWidget {
  const RealCountrySummaryCard({super.key});

  @override
  ConsumerState<RealCountrySummaryCard> createState() =>
      _RealCountrySummaryCardState();
}

class _RealCountrySummaryCardState
    extends ConsumerState<RealCountrySummaryCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(countrySummaryViewModelProvider.notifier).loadCountrySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(countrySummaryViewModelProvider);
    final selectedCountry = ref.watch(selectedCountryProvider);

    return summaryAsync.when(
      loading: () => _buildLoadingCard(),
      error: (error, _) => _buildErrorCard(error),
      data: (summary) => _buildShareableCard(summary, selectedCountry),
    );
  }

  Widget _buildLoadingCard() {
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
      child: _buildLoadingState(),
    );
  }

  Widget _buildErrorCard(Object error) {
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
      child: _buildErrorState(error),
    );
  }

  Widget _buildShareableCard(CountrySummary summary, selectedCountry) {
    final favoriteItem = FavoriteItemFactory.createCountrySummary(
      country: selectedCountry,
      indicators: [
        IndicatorCode.gdpRealGrowth,
        IndicatorCode.unemployment,
        IndicatorCode.cpiInflation,
        IndicatorCode.currentAccount,
        IndicatorCode.gdpPppPerCapita,
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Stack(
        children: [
          _buildSummaryContent(summary),
          // 즐겨찾기 버튼
          Positioned(
            top: 18,
            right: 18,
            child: FavoriteButton(
              favoriteItem: favoriteItem,
              onFavoriteChanged: () {
                // 즐겨찾기 상태 변경 시 스낵바 표시는 FavoriteButton에서 처리
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        Gaps.v12,
        Text(
          'OECD 국가 순위 분석 중...',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Gaps.v8,
        Text(
          '핵심 5개 지표 데이터 수집 및 백분위 계산',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.triangleExclamation,
            color: AppColors.error,
            size: 24,
          ),
          Gaps.v12,
          Text(
            '국가 요약 데이터 로딩 실패',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gaps.v8,
          Text(
            '네트워크 연결을 확인하고 다시 시도해주세요.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          Gaps.v16,
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(countrySummaryViewModelProvider.notifier)
                  .refreshSummary();
            },
            icon: const FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(CountrySummary summary) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallRanking(summary),
          Gaps.v16,
          _buildIndicatorsGrid(summary.topIndicators),
          Gaps.v12,
          _buildLastUpdated(summary.lastUpdated),
        ],
      ),
    );
  }

  Widget _buildOverallRanking(CountrySummary summary) {
    final rankingColor = _getOverallRankingColor(summary.overallRanking);
    final rankingIcon = _getOverallRankingIcon(summary.overallRanking);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rankingColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankingColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rankingColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FaIcon(rankingIcon, color: rankingColor, size: 20),
          ),
          Gaps.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전반적으로 ${summary.overallRanking}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: rankingColor,
                  ),
                ),
                Text(
                  '상위권 2개 지표 · 하위권 1개 지표',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsGrid(List<KeyIndicator> indicators) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주요 지표',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Gaps.v12,
        ...indicators.map(
          (indicator) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIndicatorTile(indicator),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorTile(KeyIndicator indicator) {
    final performanceColor = PerformanceColors.getPerformanceColor(
      indicator.performance,
    );
    final rankBadgeColor = PerformanceColors.getRankBadgeColor(
      indicator.percentile,
    );

    return GestureDetector(
      onTap: () => _navigateToIndicatorDetail(indicator),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: performanceColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // 이모지 및 성과 표시
            Text(
              indicator.sparklineEmoji ?? '📊',
              style: const TextStyle(fontSize: 24),
            ),
            Gaps.h12,
            // 지표 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          indicator.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: rankBadgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          indicator.rankBadge,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gaps.v4,
                  Row(
                    children: [
                      Text(
                        '${_formatValue(indicator.value)}${indicator.unit}',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: performanceColor,
                        ),
                      ),
                      Gaps.h8,
                      Text(
                        '${indicator.rank}위/${indicator.totalCountries}개국',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated(DateTime lastUpdated) {
    return Center(
      child: Text(
        '마지막 업데이트: ${_formatDateTime(lastUpdated)}',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Color _getOverallRankingColor(String ranking) {
    switch (ranking) {
      case '상위권':
        return PerformanceColors.excellent;
      case '중상위권':
        return PerformanceColors.good;
      case '중위권':
        return PerformanceColors.average;
      case '하위권':
        return PerformanceColors.poor;
      default:
        return PerformanceColors.average;
    }
  }

  IconData _getOverallRankingIcon(String ranking) {
    switch (ranking) {
      case '상위권':
        return FontAwesomeIcons.trophy;
      case '중상위권':
        return FontAwesomeIcons.thumbsUp;
      case '중위권':
        return FontAwesomeIcons.minus;
      case '하위권':
        return FontAwesomeIcons.arrowDown;
      default:
        return FontAwesomeIcons.minus;
    }
  }

  String _formatValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(1);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToIndicatorDetail(KeyIndicator indicator) {
    // 지표 코드로부터 IndicatorCode enum을 찾기
    final indicatorCode = _getIndicatorCodeFromString(indicator.code);
    if (indicatorCode == null) return;

    // 현재 선택된 국가 정보 가져오기
    final selectedCountry = ref.read(selectedCountryProvider);

    // GoRouter를 사용한 네비게이션
    context.go('/indicator/${indicatorCode.code}/${selectedCountry.code}');
  }

  IndicatorCode? _getIndicatorCodeFromString(String code) {
    try {
      return IndicatorCode.values.firstWhere((ic) => ic.code == code);
    } catch (e) {
      return null;
    }
  }
}
