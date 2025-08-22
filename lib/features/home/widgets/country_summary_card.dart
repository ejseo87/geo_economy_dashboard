import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/ranking_colors.dart';
import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/home/models/simple_indicator_data.dart';
import 'package:geo_economy_dashboard/common/widgets/app_card.dart';
import 'package:geo_economy_dashboard/router/router_constants.dart';
import '../view_models/sparkline_view_model.dart';
import '../widgets/sparkline_chart.dart';
import '../models/sparkline_data.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../countries/view_models/selected_country_provider.dart';

class CountrySummaryCard extends ConsumerWidget {
  final CountrySummary summary;

  const CountrySummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Gaps.v16,
          _buildOverallRanking(),
          Gaps.v16,
          _buildSparklineSection(ref),
          Gaps.v20,
          _buildTopIndicators(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 국기 아이콘 (임시로 텍스트 사용)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              '🇰🇷',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        Gaps.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.countryName,
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'OECD 38개국 중',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildFreshnessBadge(),
      ],
    );
  }

  Widget _buildSparklineSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final sparklineState = ref.watch(countrySparklineViewModelProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '5년 트렌드',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sparklineState.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            Gaps.v12,
            sparklineState.when(
              data: (sparklines) => sparklines.isEmpty 
                  ? _buildNoDataMessage()
                  : _buildSparklineGrid(sparklines),
              loading: () => _buildSparklineShimmer(),
              error: (error, stack) => _buildErrorMessage(error.toString()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSparklineGrid(List<SparklineData> sparklines) {
    // Top 3 지표만 표시
    final displaySparklines = sparklines.take(3).toList();
    
    return Column(
      children: displaySparklines.map((sparkline) =>
        Padding(
          padding: const EdgeInsets.only(bottom: Sizes.size8),
          child: _buildSparklineTile(sparkline),
        ),
      ).toList(),
    );
  }

  Widget _buildSparklineTile(SparklineData sparkline) {
    return Consumer(
      builder: (context, ref, child) {
        return InkWell(
          onTap: () => _navigateToIndicatorDetail(context, ref, sparkline),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(Sizes.size12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sparkline.indicatorName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gaps.v2,
                Row(
                  children: [
                    Text(
                      sparkline.latestPoint?.value.toStringAsFixed(1) ?? '--',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      sparkline.unit,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (sparkline.changePercentage != null) ...[
                  Gaps.v2,
                  Row(
                    children: [
                      Icon(
                        _getSparklineTrendIcon(sparkline.trend),
                        size: 12,
                        color: _getSparklineTrendColor(sparkline.trend),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${sparkline.changePercentage! > 0 ? '+' : ''}${sparkline.changePercentage!.toStringAsFixed(1)}%',
                        style: AppTypography.caption.copyWith(
                          color: _getSparklineTrendColor(sparkline.trend),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: CompactSparkline(
              data: sparkline,
              width: 80,
              height: 32,
            ),
          ),
        ],
      ),
          ),
        );
      },
    );
  }

  Widget _buildSparklineShimmer() {
    return Column(
      children: List.generate(3, (index) =>
        Padding(
          padding: const EdgeInsets.only(bottom: Sizes.size8),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Container(
      padding: const EdgeInsets.all(Sizes.size16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.timeline_outlined,
              color: AppColors.textSecondary,
              size: 32,
            ),
            Gaps.v8,
            Text(
              '트렌드 데이터를 불러오는 중...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(Sizes.size12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          Gaps.h8,
          Expanded(
            child: Text(
              '트렌드 데이터 로드 실패',
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSparklineTrendIcon(SparklineTrend trend) {
    switch (trend) {
      case SparklineTrend.rising:
        return Icons.trending_up;
      case SparklineTrend.falling:
        return Icons.trending_down;
      case SparklineTrend.volatile:
        return Icons.timeline;
      case SparklineTrend.stable:
        return Icons.trending_flat;
    }
  }

  Color _getSparklineTrendColor(SparklineTrend trend) {
    switch (trend) {
      case SparklineTrend.rising:
        return AppColors.accent;
      case SparklineTrend.falling:
        return AppColors.error;
      case SparklineTrend.volatile:
        return Colors.orange;
      case SparklineTrend.stable:
        return AppColors.primary;
    }
  }

  Widget _buildFreshnessBadge() {
    final daysDiff = DateTime.now().difference(summary.lastUpdated).inDays;
    final Color badgeColor;
    final String badgeText;

    if (daysDiff <= 30) {
      badgeColor = AppColors.accent;
      badgeText = '최신';
    } else if (daysDiff <= 90) {
      badgeColor = Colors.orange;
      badgeText = '지연';
    } else {
      badgeColor = Colors.red;
      badgeText = '오래됨';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.size8,
        vertical: Sizes.size4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: AppTypography.caption.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOverallRanking() {
    // 전체 순위 요약 계산
    final topTierCount = summary.topIndicators
        .where((indicator) => indicator.ranking.tier == RankingTier.top)
        .length;
    final bottomTierCount = summary.topIndicators
        .where((indicator) => indicator.ranking.tier == RankingTier.bottom)
        .length;

    final String overallSummary;
    final Color summaryColor;

    if (topTierCount >= 3) {
      overallSummary = '전반적으로 상위권';
      summaryColor = RankingColors.getTierColor(RankingTier.top);
    } else if (bottomTierCount >= 3) {
      overallSummary = '일부 지표 개선 필요';
      summaryColor = RankingColors.getTierColor(RankingTier.bottom);
    } else {
      overallSummary = '전반적으로 중위권';
      summaryColor = RankingColors.getTierColor(RankingTier.upper);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sizes.size16),
      decoration: BoxDecoration(
        color: summaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: summaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            topTierCount >= 3 ? Icons.trending_up : 
            bottomTierCount >= 3 ? Icons.trending_down : Icons.trending_flat,
            color: summaryColor,
            size: 28,
          ),
          Gaps.v8,
          Text(
            overallSummary,
            style: AppTypography.heading3.copyWith(
              color: summaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gaps.v4,
          Text(
            '상위권 $topTierCount개 지표 • 하위권 $bottomTierCount개 지표',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주요 지표',
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Gaps.v12,
        ...summary.topIndicators.map((indicator) => 
          Padding(
            padding: const EdgeInsets.only(bottom: Sizes.size12),
            child: _buildIndicatorTile(indicator),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorTile(IndicatorData indicator) {
    final tierColor = RankingColors.getTierColor(indicator.ranking.tier);
    final isPositive = RankingColors.isPositiveIndicator(indicator.code);
    final trendColor = RankingColors.getTrendColor(indicator.trend, isPositive);

    return Container(
      padding: const EdgeInsets.all(Sizes.size16),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // 순위 배지
          Container(
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              color: tierColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${indicator.ranking.rank}위',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Gaps.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        indicator.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sizes.size6,
                        vertical: Sizes.size2,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        indicator.ranking.tier.badgeText,
                        style: AppTypography.caption.copyWith(
                          color: tierColor,
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
                      _formatValue(indicator.value, indicator.unit),
                      style: AppTypography.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gaps.h8,
                    if (indicator.previousValue != null) ...[
                      Icon(
                        indicator.trend == TrendDirection.up ? Icons.arrow_upward :
                        indicator.trend == TrendDirection.down ? Icons.arrow_downward :
                        Icons.arrow_forward,
                        color: trendColor,
                        size: 16,
                      ),
                      Gaps.h4,
                      Text(
                        _formatChange(indicator.value, indicator.previousValue!),
                        style: AppTypography.caption.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value, String unit) {
    if (unit == '%') {
      return '${value.toStringAsFixed(1)}%';
    } else if (unit == 'USD') {
      if (value >= 1000000) {
        return '\$${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '\$${(value / 1000).toStringAsFixed(0)}K';
      }
      return '\$${value.toStringAsFixed(0)}';
    } else {
      return '${value.toStringAsFixed(1)} $unit';
    }
  }

  String _formatChange(double current, double previous) {
    final change = ((current - previous) / previous * 100).abs();
    return '${change.toStringAsFixed(1)}%';
  }

  /// 지표 상세 화면으로 네비게이션
  void _navigateToIndicatorDetail(BuildContext context, WidgetRef ref, SparklineData sparkline) {
    final selectedCountry = ref.read(selectedCountryProvider);
    
    // IndicatorCode 찾기
    IndicatorCode? indicatorCode;
    try {
      indicatorCode = IndicatorCode.values.firstWhere(
        (code) => code.code == sparkline.indicatorCode,
      );
    } catch (e) {
      // 매칭되는 IndicatorCode가 없으면 기본값
      indicatorCode = IndicatorCode.gdpRealGrowth;
    }
    
    context.pushNamed(
      RouteName.indicatorDetail,
      pathParameters: {
        'indicatorCode': indicatorCode.code,
        'countryCode': selectedCountry.code,
      },
    );
  }
}