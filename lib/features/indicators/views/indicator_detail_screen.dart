import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/sizes.dart';
import '../../../constants/typography.dart';
import '../models/indicator_metadata.dart';
import '../view_models/indicator_detail_view_model.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../countries/models/country.dart';
import '../../home/widgets/sparkline_chart.dart';
import '../../home/models/sparkline_data.dart';

/// 지표 상세 화면
class IndicatorDetailScreen extends ConsumerWidget {
  final IndicatorCode indicatorCode;
  final Country country;

  const IndicatorDetailScreen({
    super.key,
    required this.indicatorCode,
    required this.country,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(indicatorDetailProvider(indicatorCode, country));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          indicatorCode.name,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => _showShareOptions(context),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.bookmark, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => _toggleBookmark(ref),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (detail) => _buildDetailContent(context, detail),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          Gaps.v16,
          Text(
            '지표 상세 정보를 불러오고 있습니다...',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 48,
              color: AppColors.error,
            ),
            Gaps.v16,
            Text(
              '데이터를 불러올 수 없습니다',
              style: AppTypography.heading3.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gaps.v8,
            Text(
              error,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, IndicatorDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(detail),
          Gaps.v16,
          _buildHistoricalChart(detail),
          Gaps.v16,
          _buildTrendAnalysis(detail.trendAnalysis),
          Gaps.v16,
          _buildOECDComparison(detail.oecdStats),
          Gaps.v16,
          _buildMetadataSection(detail.metadata),
          Gaps.v16,
          _buildDataSourceInfo(detail.metadata.source),
          Gaps.v32,
        ],
      ),
    );
  }

  Widget _buildOverviewCard(IndicatorDetail detail) {
    return Container(
      width: double.infinity,
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
              if (detail.metadata.emoji != null) ...[
                Text(
                  detail.metadata.emoji!,
                  style: const TextStyle(fontSize: 32),
                ),
                Gaps.h12,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${detail.countryName}의 ${detail.metadata.name}',
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Gaps.v4,
                    Text(
                      detail.metadata.category,
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
          Gaps.v20,
          _buildCurrentValueSection(detail),
          Gaps.v16,
          _buildRankingSection(detail),
        ],
      ),
    );
  }

  Widget _buildCurrentValueSection(IndicatorDetail detail) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현재값',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Gaps.v4,
              Text(
                detail.currentValue != null 
                    ? '${detail.currentValue!.toStringAsFixed(1)}${detail.metadata.unit}'
                    : '데이터 없음',
                style: AppTypography.heading1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '마지막 업데이트',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Gaps.v4,
              Text(
                detail.lastCalculated != null 
                    ? '${detail.lastCalculated!.year}년'
                    : '알 수 없음',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingSection(IndicatorDetail detail) {
    if (detail.currentRank == null) return const SizedBox.shrink();

    final Color rankColor;
    final String rankLabel;
    
    if (detail.currentRank! <= detail.totalCountries * 0.25) {
      rankColor = AppColors.accent;
      rankLabel = '상위권';
    } else if (detail.currentRank! <= detail.totalCountries * 0.5) {
      rankColor = AppColors.primary;
      rankLabel = '중상위권';
    } else if (detail.currentRank! <= detail.totalCountries * 0.75) {
      rankColor = AppColors.warning;
      rankLabel = '중하위권';
    } else {
      rankColor = AppColors.error;
      rankLabel = '하위권';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${detail.currentRank}',
                style: AppTypography.bodyLarge.copyWith(
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
                Text(
                  'OECD ${detail.totalCountries}개국 중 $rankLabel',
                  style: AppTypography.bodyMedium.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${detail.currentRank}위 / ${detail.totalCountries}개국',
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

  Widget _buildHistoricalChart(IndicatorDetail detail) {
    if (detail.historicalData.isEmpty) return const SizedBox.shrink();

    // 스파크라인 데이터로 변환
    final sparklinePoints = detail.historicalData
        .map((point) => SparklinePoint(
              year: point.year,
              value: point.value,
              isEstimated: point.isEstimated,
            ))
        .toList();

    final sparklineData = SparklineData(
      indicatorCode: detail.metadata.code,
      indicatorName: detail.metadata.name,
      unit: detail.metadata.unit,
      countryCode: detail.countryCode,
      points: sparklinePoints,
      trend: _mapTrendToSparkline(detail.trendAnalysis.longTerm),
      changePercentage: _calculateChangePercentage(sparklinePoints),
      lastUpdated: DateTime.now(),
    );

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
              const FaIcon(
                FontAwesomeIcons.chartLine,
                color: AppColors.primary,
                size: 20,
              ),
              Gaps.h8,
              Text(
                '${detail.historicalData.length}년간 추이',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.v16,
          SparklineChart(
            data: sparklineData,
            width: double.infinity,
            height: 120,
            showMetadata: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis(TrendAnalysis analysis) {
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
              const FaIcon(
                FontAwesomeIcons.chartArea,
                color: AppColors.primary,
                size: 20,
              ),
              Gaps.h8,
              Text(
                '트렌드 분석',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.v16,
          _buildTrendRow('단기 (1년)', analysis.shortTerm),
          Gaps.v8,
          _buildTrendRow('중기 (3년)', analysis.mediumTerm),
          Gaps.v8,
          _buildTrendRow('장기 (5년)', analysis.longTerm),
          Gaps.v16,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 분석 요약',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Gaps.v4,
                Text(
                  analysis.summary,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (analysis.insights.isNotEmpty) ...[
                  Gaps.v8,
                  ...analysis.insights.map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                insight,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow(String period, TrendDirection trend) {
    return Row(
      children: [
        Text(
          period,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTrendColor(trend).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trend.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                trend.label,
                style: AppTypography.bodySmall.copyWith(
                  color: _getTrendColor(trend),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOECDComparison(OECDStats stats) {
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
              const FaIcon(
                FontAwesomeIcons.globe,
                color: AppColors.primary,
                size: 20,
              ),
              Gaps.h8,
              Text(
                'OECD 비교',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.v16,
          Row(
            children: [
              _buildStatBox('중앙값', '${stats.median.toStringAsFixed(1)}'),
              _buildStatBox('평균', '${stats.mean.toStringAsFixed(1)}'),
              _buildStatBox('표준편차', '${stats.standardDeviation.toStringAsFixed(1)}'),
            ],
          ),
          Gaps.v12,
          Row(
            children: [
              _buildStatBox('최솟값', '${stats.min.toStringAsFixed(1)}'),
              _buildStatBox('Q1', '${stats.q1.toStringAsFixed(1)}'),
              _buildStatBox('Q3', '${stats.q3.toStringAsFixed(1)}'),
              _buildStatBox('최댓값', '${stats.max.toStringAsFixed(1)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Gaps.v2,
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(IndicatorDetailMetadata metadata) {
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
              const FaIcon(
                FontAwesomeIcons.circleInfo,
                color: AppColors.primary,
                size: 20,
              ),
              Gaps.h8,
              Text(
                '지표 정보',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.v16,
          _buildMetadataRow('설명', metadata.description),
          Gaps.v12,
          _buildMetadataRow('측정 방법', metadata.methodology),
          Gaps.v12,
          _buildMetadataRow('제한사항', metadata.limitations),
          Gaps.v12,
          _buildMetadataRow('업데이트 주기', '${metadata.updateFrequency.labelKr} (${metadata.updateFrequency.description})'),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Gaps.v4,
        Text(
          content,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSourceInfo(DataSource source) {
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
              const FaIcon(
                FontAwesomeIcons.database,
                color: AppColors.primary,
                size: 20,
              ),
              Gaps.h8,
              Text(
                '데이터 출처',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.v16,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Gaps.v4,
                    Text(
                      source.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    Gaps.v8,
                    Row(
                      children: [
                        Text(
                          '라이선스: ',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          source.license,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _launchURL(source.url),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 14),
                    SizedBox(width: 4),
                    Text('방문'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SparklineTrend _mapTrendToSparkline(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return SparklineTrend.rising;
      case TrendDirection.down:
        return SparklineTrend.falling;
      case TrendDirection.stable:
        return SparklineTrend.stable;
      case TrendDirection.volatile:
        return SparklineTrend.volatile;
    }
  }

  double? _calculateChangePercentage(List<SparklinePoint> points) {
    if (points.length < 2) return null;
    final first = points.first.value;
    final last = points.last.value;
    if (first == 0) return null;
    return ((last - first) / first.abs()) * 100;
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return AppColors.accent;
      case TrendDirection.down:
        return AppColors.error;
      case TrendDirection.stable:
        return AppColors.primary;
      case TrendDirection.volatile:
        return AppColors.warning;
    }
  }

  void _showShareOptions(BuildContext context) {
    // 공유 기능 구현 (추후)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 기능은 곧 추가될 예정입니다.')),
    );
  }

  void _toggleBookmark(WidgetRef ref) {
    // 북마크 기능 구현 (추후)
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('북마크 기능은 곧 추가될 예정입니다.')),
    );
  }

  void _launchURL(String url) {
    // URL 실행 기능 구현 (추후)
  }
}