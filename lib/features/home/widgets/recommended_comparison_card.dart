import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../models/indicator_comparison.dart';
import '../view_models/comparison_view_model.dart';
import '../view_models/sparkline_view_model.dart';
import '../widgets/sparkline_chart.dart';
import '../../countries/view_models/selected_country_provider.dart';
import '../../worldbank/models/indicator_codes.dart';

class RecommendedComparisonCard extends ConsumerStatefulWidget {
  const RecommendedComparisonCard({super.key});

  @override
  ConsumerState<RecommendedComparisonCard> createState() => _RecommendedComparisonCardState();
}

class _RecommendedComparisonCardState extends ConsumerState<RecommendedComparisonCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(comparisonViewModelProvider.notifier).loadRecommendedComparison();
    });
  }

  @override
  Widget build(BuildContext context) {
    final comparisonAsync = ref.watch(comparisonViewModelProvider);
    
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
          _buildHeader(),
          Gaps.v16,
          comparisonAsync.when(
            loading: () => _buildLoadingState(),
            error: (error, _) => _buildErrorState(error),
            data: (comparison) => _buildComparisonContent(comparison),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            FontAwesomeIcons.chartLine,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        Gaps.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🤖 AI 추천 비교',
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Gaps.v4,
              Consumer(
                builder: (context, ref, child) {
                  final selectedCountry = ref.watch(selectedCountryProvider);
                  return Text(
                    '${selectedCountry.nameKo} vs OECD 중앙값 vs 유사국',
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
            ref.read(comparisonViewModelProvider.notifier).refreshComparison();
          },
          icon: FaIcon(
            FontAwesomeIcons.arrowRotateRight,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        Gaps.v12,
        Text(
          'World Bank API에서 실시간 데이터 로딩 중...',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Gaps.v8,
        Text(
          'OECD 38개국 통계 분석 및 유사국 비교 데이터 생성',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        Gaps.v16,
        LinearProgressIndicator(
          backgroundColor: AppColors.background,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    final isNetworkError = error.toString().contains('connection') || 
                          error.toString().contains('timeout') ||
                          error.toString().contains('network');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          FaIcon(
            isNetworkError ? FontAwesomeIcons.wifi : FontAwesomeIcons.triangleExclamation,
            color: AppColors.error,
            size: 24,
          ),
          Gaps.v12,
          Text(
            isNetworkError ? '네트워크 연결을 확인해주세요' : '데이터 로딩 중 오류가 발생했습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Gaps.v8,
          Text(
            isNetworkError 
                ? 'World Bank API 서버에 연결할 수 없습니다.\n인터넷 연결을 확인하고 다시 시도해주세요.'
                : '잠시 후 다시 시도해주세요.\n문제가 지속되면 앱을 재시작해보세요.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          Gaps.v16,
          ElevatedButton.icon(
            onPressed: () {
              ref.read(comparisonViewModelProvider.notifier).refreshComparison();
            },
            icon: const FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (!isNetworkError) ...[
            Gaps.v8,
            TextButton(
              onPressed: () {
                // 오류 상세 정보 표시 (개발용)
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('오류 상세 정보'),
                    content: SingleChildScrollView(
                      child: Text(error.toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                '오류 상세 정보',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonContent(RecommendedComparison comparison) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comparison.selectionReason,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        Gaps.v16,
        ...comparison.comparisons.map((indicator) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildIndicatorComparison(indicator),
          ),
        ),
        _buildLastUpdated(comparison.lastUpdated),
      ],
    );
  }

  Widget _buildIndicatorComparison(IndicatorComparison indicator) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndicatorHeader(indicator),
          Gaps.v12,
          _buildSparklineSection(indicator),
          Gaps.v12,
          _buildOECDComparison(indicator),
          Gaps.v12,
          _buildSimilarCountries(indicator),
          Gaps.v8,
          _buildInsight(indicator.insight),
        ],
      ),
    );
  }

  Widget _buildIndicatorHeader(IndicatorComparison indicator) {
    return Row(
      children: [
        Text(
          indicator.insight.performance.emoji,
          style: const TextStyle(fontSize: 20),
        ),
        Gaps.h8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                indicator.indicatorName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${indicator.selectedCountry.value}${indicator.unit} (${indicator.selectedCountry.rank}위/${indicator.oecdStats.totalCountries}개국)',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPerformanceColor(indicator.insight.performance).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            indicator.insight.performance.label,
            style: AppTypography.caption.copyWith(
              color: _getPerformanceColor(indicator.insight.performance),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSparklineSection(IndicatorComparison indicator) {
    // 지표 코드로부터 IndicatorCode 찾기
    IndicatorCode? indicatorCode;
    try {
      indicatorCode = IndicatorCode.values.firstWhere(
        (code) => code.name.toLowerCase().contains(indicator.indicatorName.toLowerCase()) ||
                  indicator.indicatorName.toLowerCase().contains(code.name.toLowerCase()),
      );
    } catch (e) {
      // 매칭되는 IndicatorCode가 없으면 null
    }

    if (indicatorCode == null) {
      return const SizedBox.shrink(); // 스파크라인 없음
    }

    return Consumer(
      builder: (context, ref, child) {
        return FutureBuilder(
          future: ref.read(sparklineViewModelProvider.notifier).loadSingleSparkline(indicatorCode!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSparklineLoading();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final sparklineData = snapshot.data!;
            return _buildSparklineContent(sparklineData);
          },
        );
      },
    );
  }

  Widget _buildSparklineLoading() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildSparklineContent(sparklineData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5년 트렌드',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (sparklineData.changePercentage != null) ...[
                Row(
                  children: [
                    Icon(
                      _getSparklineTrendIcon(sparklineData.trend),
                      size: 12,
                      color: _getSparklineTrendColor(sparklineData.trend),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sparklineData.changePercentage! > 0 ? '+' : ''}${sparklineData.changePercentage!.toStringAsFixed(1)}%',
                      style: AppTypography.caption.copyWith(
                        color: _getSparklineTrendColor(sparklineData.trend),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          Gaps.v8,
          SparklineChart(
            data: sparklineData,
            width: double.infinity,
            height: 32,
            showMetadata: false,
          ),
        ],
      ),
    );
  }

  IconData _getSparklineTrendIcon(trend) {
    switch (trend.toString().split('.').last) {
      case 'rising':
        return Icons.trending_up;
      case 'falling':
        return Icons.trending_down;
      case 'volatile':
        return Icons.timeline;
      case 'stable':
      default:
        return Icons.trending_flat;
    }
  }

  Color _getSparklineTrendColor(trend) {
    switch (trend.toString().split('.').last) {
      case 'rising':
        return AppColors.accent;
      case 'falling':
        return AppColors.error;
      case 'volatile':
        return Colors.orange;
      case 'stable':
      default:
        return AppColors.primary;
    }
  }

  Widget _buildOECDComparison(IndicatorComparison indicator) {
    final stats = indicator.oecdStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OECD 통계',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Gaps.v8,
        Row(
          children: [
            _buildStatItem('중앙값', '${stats.median}${indicator.unit}'),
            _buildStatItem('IQR', '${stats.q1.toStringAsFixed(1)}-${stats.q3.toStringAsFixed(1)}'),
            _buildStatItem('범위', '${stats.min}-${stats.max}'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarCountries(IndicatorComparison indicator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '유사국 비교',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Gaps.v8,
        Row(
          children: indicator.similarCountries.map((country) => 
            Expanded(
              child: _buildCountryItem(country, indicator.unit),
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildCountryItem(CountryData country, String unit) {
    return Column(
      children: [
        Text(
          country.flagEmoji ?? '',
          style: const TextStyle(fontSize: 16),
        ),
        Gaps.v2,
        Text(
          country.countryName,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${country.value}$unit',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          '(${country.rank}위)',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInsight(ComparisonInsight insight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 분석 결과',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          Gaps.v4,
          Text(
            insight.summary,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(DateTime lastUpdated) {
    return Center(
      child: Text(
        '마지막 업데이트: ${_formatDateTime(lastUpdated)}',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Color _getPerformanceColor(PerformanceLevel performance) {
    switch (performance) {
      case PerformanceLevel.excellent:
        return AppColors.accent;
      case PerformanceLevel.good:
        return AppColors.primary;
      case PerformanceLevel.average:
        return AppColors.warning;
      case PerformanceLevel.poor:
        return AppColors.error;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}