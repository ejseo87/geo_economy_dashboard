import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/common/widgets/app_card.dart';
import '../view_models/country_summary_view_model.dart';
import '../models/country_summary.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../../constants/performance_colors.dart';

class CountrySummaryCard extends ConsumerStatefulWidget {
  const CountrySummaryCard({super.key});

  @override
  ConsumerState<CountrySummaryCard> createState() => _CountrySummaryCardState();
}

class _CountrySummaryCardState extends ConsumerState<CountrySummaryCard> {
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
      data: (summary) => _buildSummaryCard(summary, selectedCountry),
    );
  }

  Widget _buildLoadingCard() {
    return AppCard(
      child: Column(
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
        ],
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          Gaps.v12,
          Text(
            '데이터 로딩 실패',
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
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CountrySummary summary, selectedCountry) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(summary, selectedCountry),
          Gaps.v16,
          _buildOverallRanking(summary),
          Gaps.v16,
          _buildTopIndicators(summary),
        ],
      ),
    );
  }

  Widget _buildHeader(CountrySummary summary, selectedCountry) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              selectedCountry.flagEmoji,
              style: const TextStyle(fontSize: 20),
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
      ],
    );
  }

  Widget _buildOverallRanking(CountrySummary summary) {
    final rankingColor = _getOverallRankingColor(summary.overallRanking);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rankingColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankingColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            _getOverallRankingIcon(summary.overallRanking),
            color: rankingColor,
            size: 28,
          ),
          Gaps.v8,
          Text(
            '전반적으로 ${summary.overallRanking}',
            style: AppTypography.heading3.copyWith(
              color: rankingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gaps.v4,
          Text(
            '핵심 5개 지표 기준',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIndicators(CountrySummary summary) {
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
            Text(
              indicator.sparklineEmoji ?? '📊',
              style: const TextStyle(fontSize: 24),
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
        return Icons.trending_up;
      case '중상위권':
        return Icons.trending_up;
      case '중위권':
        return Icons.trending_flat;
      case '하위권':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
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

  void _navigateToIndicatorDetail(KeyIndicator indicator) {
    final indicatorCode = _getIndicatorCodeFromString(indicator.code);
    if (indicatorCode == null) return;

    final selectedCountry = ref.read(selectedCountryProvider);
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