import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../../../common/widgets/info_tooltip.dart';
import '../services/indicator_definitions_service.dart';
import '../services/indicator_detail_service.dart';
import '../models/indicator_metadata.dart';
import '../view_models/indicator_detail_view_model.dart';
import '../widgets/historical_line_chart.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../../common/countries/models/country.dart';
import '../../home/models/sparkline_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common/services/share_service.dart';
import '../../../common/logger.dart';
import '../../../common/widgets/data_year_badge.dart';

/// 지표 상세 화면
class IndicatorDetailScreen extends ConsumerWidget {
  final IndicatorCode indicatorCode;
  final Country country;
  static final GlobalKey _repaintBoundaryKey = GlobalKey();

  const IndicatorDetailScreen({
    super.key,
    required this.indicatorCode,
    required this.country,
  });

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    bool isBookmarked,
    int? dataYear,
  ) {
    final definition = IndicatorDefinitionsService.instance.getDefinition(indicatorCode);
    
    return AppBar(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicatorCode.name,
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (dataYear != null) ...[
                  const SizedBox(height: 2),
                  DataYearBadge(
                    year: dataYear,
                    isLatest: dataYear >= (DateTime.now().year - 1),
                  ),
                ],
              ],
            ),
          ),
          if (definition != null) ...[
            const SizedBox(width: 8),
            IndicatorDefinitionTooltip(
              indicatorName: definition.name,
              definition: definition.definition,
              unit: definition.unit,
              source: definition.source,
              methodology: definition.methodology,
            ),
          ],
        ],
      ),
      backgroundColor: AppColors.white,
      elevation: 1,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () {
          try {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          } catch (e) {
            context.go('/home');
          }
        },
      ),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 20),
          color: AppColors.textSecondary,
          onPressed: () => _showShareOptions(context),
        ),
        IconButton(
          icon: FaIcon(
            isBookmarked
                ? FontAwesomeIcons.solidBookmark
                : FontAwesomeIcons.bookmark,
            size: 20,
          ),
          color: isBookmarked ? AppColors.accent : AppColors.textSecondary,
          onPressed: () => _toggleBookmark(ref),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      indicatorDetailProvider(indicatorCode, country),
    );
    final bookmarks = ref.watch(bookmarkViewModelProvider);
    final isBookmarked = bookmarks.contains(
      '${indicatorCode.code}_${country.code}',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: detailAsync.when(
        loading: () => _buildAppBar(context, ref, isBookmarked, null),
        error: (_, __) => _buildAppBar(context, ref, isBookmarked, null),
        data: (detail) => _buildAppBar(context, ref, isBookmarked, detail.dataYear),
      ),
      body: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: detailAsync.when(
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
          data: (detail) => _buildDetailContent(context, detail),
        ),
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
          Text('지표 상세 정보를 불러오고 있습니다...', style: AppTypography.bodyMedium),
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
          _buildCountryRankingChart(detail),
          Gaps.v16,
          _buildMetadataSection(detail.metadata),
          Gaps.v16,
          _buildSimilarCountriesComparison(detail),
          Gaps.v16,
          _buildDataSourceInfo(detail.metadata.source),
          Gaps.v16,
          _buildActionButtons(context),
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

    // 히스토리컬 차트 데이터로 변환
    final countryData = <String, List<HistoricalDataPoint>>{
      country.code: detail.historicalData
          .map(
            (point) =>
                HistoricalDataPoint(year: point.year, value: point.value),
          )
          .toList(),
    };

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
                '10년간 히스토리컬 추이',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.v16,
          HistoricalLineChart(
            indicator: indicatorCode,
            countryData: countryData,
            selectedCountry: country.code,
            height: 250,
            showLegend: false,
            showTooltips: true,
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
                  ...analysis.insights.map(
                    (insight) => Padding(
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
                    ),
                  ),
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
              Text(trend.emoji, style: const TextStyle(fontSize: 14)),
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
              _buildStatBox('중앙값', stats.median.toStringAsFixed(1)),
              _buildStatBox('평균', stats.mean.toStringAsFixed(1)),
              _buildStatBox('표준편차', stats.standardDeviation.toStringAsFixed(1)),
            ],
          ),
          Gaps.v12,
          Row(
            children: [
              _buildStatBox('최솟값', stats.min.toStringAsFixed(1)),
              _buildStatBox('Q1', stats.q1.toStringAsFixed(1)),
              _buildStatBox('Q3', stats.q3.toStringAsFixed(1)),
              _buildStatBox('최댓값', stats.max.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountryRankingChart(IndicatorDetail detail) {
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
                FontAwesomeIcons.rankingStar,
                color: AppColors.primary,
                size: 20,
              ),
              Gaps.h8,
              Text(
                '국가별 순위 (상위 15개국)',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.v16,
          FutureBuilder<List<Map<String, dynamic>>>(
            future: IndicatorDetailService().getRealRankingData(
              indicatorCode: indicatorCode,
              currentCountry: country,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 400,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return SizedBox(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.triangleExclamation,
                          color: AppColors.error,
                          size: 32,
                        ),
                        Gaps.v8,
                        Text(
                          '데이터 로딩 실패',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final rankingData = snapshot.data ?? [];
              
              if (rankingData.isEmpty) {
                return SizedBox(
                  height: 400,
                  child: Center(
                    child: Text(
                      '순위 데이터가 없습니다',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 400,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: rankingData.map((e) => e['value'] as double).reduce(math.max) * 1.1,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final countryData = rankingData[groupIndex];
                          return BarTooltipItem(
                            '${countryData['name']}\n${countryData['value'].toStringAsFixed(1)}${detail.metadata.unit}',
                            AppTypography.bodySmall.copyWith(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() >= 0 && value.toInt() < rankingData.length) {
                              final countryData = rankingData[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  countryData['flag'] as String,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    barGroups: rankingData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final countryData = entry.value;
                      final isCurrentCountry = countryData['code'] == detail.countryCode;
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: countryData['value'] as double,
                            color: isCurrentCountry 
                                ? AppColors.accent 
                                : AppColors.primary.withValues(alpha: 0.7),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: math.max(1.0, rankingData.map((e) => e['value'] as double).reduce(math.max) / 5),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Gaps.v12,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Gaps.h8,
                Text(
                  '${country.nameKo}의 현재 순위: ${detail.currentRank}위',
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
          _buildMetadataRow(
            '업데이트 주기',
            '${metadata.updateFrequency.labelKr} (${metadata.updateFrequency.description})',
          ),
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

  Widget _buildSimilarCountriesComparison(IndicatorDetail detail) {
    // 유사 국가 목록 (한국 기준)
    const similarCountries = ['JPN', 'DEU', 'FRA', 'GBR'];
    final countriesData = <Map<String, dynamic>>[];

    // 현재 국가 추가
    if (detail.currentValue != null) {
      countriesData.add({
        'code': detail.countryCode,
        'name': detail.countryName,
        'value': detail.currentValue!,
        'rank': detail.currentRank ?? 0,
        'isCurrent': true,
      });
    }

    // TODO: 실제 유사국 데이터 조회 (추후 API 연동)
    // 임시 데이터
    for (int i = 0; i < similarCountries.length && i < 3; i++) {
      final countryCode = similarCountries[i];
      final countryName = _getCountryName(countryCode);
      countriesData.add({
        'code': countryCode,
        'name': countryName,
        'value':
            (detail.currentValue ?? 0) *
            (0.8 + math.Random().nextDouble() * 0.4),
        'rank': (detail.currentRank ?? 20) + math.Random().nextInt(10) - 5,
        'isCurrent': false,
      });
    }

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
                FontAwesomeIcons.userGroup,
                color: AppColors.primary,
                size: 20,
              ),
              Gaps.h8,
              Text(
                '유사 국가 비교',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.v16,
          ...countriesData.map(
            (data) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCountryComparisonTile(data, detail.metadata.unit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryComparisonTile(Map<String, dynamic> data, String unit) {
    final isCurrent = data['isCurrent'] as bool;
    final value = data['value'] as double;
    final rank = data['rank'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Text(
            _getCountryFlag(data['code'] as String),
            style: const TextStyle(fontSize: 24),
          ),
          Gaps.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(1)}$unit',
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
              color: isCurrent
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$rank위',
              style: AppTypography.caption.copyWith(
                color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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
          Text(
            '추가 액션',
            style: AppTypography.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          Gaps.v16,
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addToComparison(),
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('비교 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Gaps.h12,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewRelatedIndicators(context),
                  icon: const FaIcon(FontAwesomeIcons.chartLine, size: 16),
                  label: const Text('관련 지표'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          Gaps.v12,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _setAlert(context),
              icon: const FaIcon(FontAwesomeIcons.bell, size: 16),
              label: const Text('알림 설정'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCountryName(String countryCode) {
    const countryNames = {
      'KOR': '한국',
      'JPN': '일본',
      'DEU': '독일',
      'FRA': '프랑스',
      'GBR': '영국',
      'USA': '미국',
      'ITA': '이탈리아',
      'CAN': '캐나다',
    };
    return countryNames[countryCode] ?? countryCode;
  }

  String _getCountryFlag(String countryCode) {
    const countryFlags = {
      'KOR': '🇰🇷',
      'JPN': '🇯🇵',
      'DEU': '🇩🇪',
      'FRA': '🇫🇷',
      'GBR': '🇬🇧',
      'USA': '🇺🇸',
      'ITA': '🇮🇹',
      'CAN': '🇨🇦',
    };
    return countryFlags[countryCode] ?? '🏳️';
  }

  void _addToComparison() {
    // TODO: 비교 기능 구현
  }

  void _viewRelatedIndicators(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('관련 지표 기능을 준비 중입니다...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _setAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 설정'),
        content: const Text('이 지표의 데이터가 업데이트되면 알림을 받으시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('알림이 설정되었습니다'),
                  backgroundColor: AppColors.accent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('설정'),
          ),
        ],
      ),
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
                    Text('World Bank 방문'),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Gaps.v16,
                  Text(
                    '지표 데이터 공유',
                    style: AppTypography.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Gaps.v16,
                  _buildShareOption(
                    context,
                    FontAwesomeIcons.image,
                    '이미지로 공유',
                    '차트와 데이터를 이미지로 저장',
                    () => _shareAsImage(context),
                  ),
                  const SizedBox(height: 8),
                  _buildShareOption(
                    context,
                    FontAwesomeIcons.link,
                    '링크 공유',
                    '다른 사람과 이 지표 페이지를 공유하세요',
                    () => _shareAsLink(context),
                  ),
                  const SizedBox(height: 8),
                  _buildShareOption(
                    context,
                    FontAwesomeIcons.fileExport,
                    'CSV 내보내기',
                    '데이터를 CSV 파일로 저장',
                    () => _exportAsCSV(context),
                  ),
                  Gaps.v16,
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '취소',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  // Add bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: FaIcon(icon, color: AppColors.primary, size: 20)),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _shareAsImage(BuildContext context) async {
    try {
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지를 생성하고 있습니다...'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 1),
        ),
      );

      final fileName = '${indicatorCode.name}_${country.nameKo}_${DateTime.now().millisecondsSinceEpoch}.png';
      final shareTitle = '${country.nameKo}의 ${indicatorCode.name}';
      final shareText = '$shareTitle\n\nGeo Economy Dashboard에서 생성됨';

      final success = await ShareService.instance.shareWidgetAsImage(
        repaintBoundaryKey: _repaintBoundaryKey,
        title: shareTitle,
        text: shareText,
        fileName: fileName,
      );

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지가 성공적으로 공유되었습니다'),
              backgroundColor: AppColors.accent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지 공유에 실패했습니다'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('[IndicatorDetailScreen] Error sharing image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지 공유 중 오류가 발생했습니다'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _shareAsLink(BuildContext context) {
    // 딥링크 URL 생성
    final url = 'https://geoeconomy.app/indicators/${indicatorCode.code}/${country.code}';
    final title = '${country.nameKo}의 ${indicatorCode.name}';
    final shareText = '$title\n\n📊 ${country.nameKo}의 ${indicatorCode.name} 지표를 확인해보세요.\n\n$url\n\nGeo Economy Dashboard';
    
    // 링크 공유 옵션 다이얼로그 표시
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('링크 공유'),
          content: const Text('어떤 방식으로 링크를 공유하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _copyToClipboardDirectly(context, shareText);
              },
              child: const Text('클립보드에 복사'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _shareWithSystemSheet(context, shareText, title);
              },
              child: const Text('앱으로 공유'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyToClipboardDirectly(BuildContext context, String shareText) async {
    try {
      final success = await ShareService.instance.copyToClipboard(shareText);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크가 클립보드에 복사되었습니다'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('클립보드 복사에 실패했습니다'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('[IndicatorDetailScreen] Error copying to clipboard: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('클립보드 복사 중 오류가 발생했습니다'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareWithSystemSheet(BuildContext context, String shareText, String title) async {
    try {
      await ShareService.instance.shareLink(
        url: shareText,
        title: title,
        description: '',
      );
    } catch (e) {
      AppLogger.error('[IndicatorDetailScreen] Error with system share sheet: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공유 중 오류가 발생했습니다'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _copyLinkToClipboard(BuildContext context, String url, String title) async {
    try {
      final shareText = '$title\n\n$url\n\nGeo Economy Dashboard에서 확인하세요';
      
      final success = await ShareService.instance.copyToClipboard(shareText);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('링크가 클립보드에 복사되었습니다'),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('[IndicatorDetailScreen] Error copying to clipboard: $e');
    }
  }

  void _exportAsCSV(BuildContext context) async {
    try {
      // 현재 로딩된 데이터가 있는지 확인
      
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV 파일을 생성하고 있습니다...'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 1),
        ),
      );

      // CSV 데이터 생성 (예시 데이터)
      final csvHeader = '연도,${indicatorCode.name} (${indicatorCode.unit})\n';
      final csvRows = <String>[];
      
      // 예시 데이터 (실제로는 IndicatorDetail에서 historicalData를 사용)
      final currentYear = DateTime.now().year;
      for (int i = 9; i >= 0; i--) {
        final year = currentYear - i;
        final value = (50 + (i * 2.5) + (DateTime.now().millisecond % 10)).toStringAsFixed(1);
        csvRows.add('$year,$value');
      }
      
      final csvContent = csvHeader + csvRows.join('\n');
      final fileName = '${indicatorCode.name}_${country.nameKo}_${DateTime.now().millisecondsSinceEpoch}';
      final title = '${country.nameKo}의 ${indicatorCode.name} 데이터';

      final success = await ShareService.instance.exportToCsv(
        csvContent: csvContent,
        fileName: fileName,
        title: title,
      );

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV 파일이 성공적으로 내보내졌습니다'),
              backgroundColor: AppColors.accent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV 내보내기에 실패했습니다'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('[IndicatorDetailScreen] Error exporting CSV: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV 내보내기 중 오류가 발생했습니다'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleBookmark(WidgetRef ref) {
    final bookmarkViewModel = ref.read(bookmarkViewModelProvider.notifier);
    final isCurrentlyBookmarked = ref
        .read(bookmarkViewModelProvider)
        .contains('${indicatorCode.code}_${country.code}');

    bookmarkViewModel.toggleBookmark(indicatorCode, country.code);

    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text(isCurrentlyBookmarked ? '북마크에서 제거되었습니다' : '북마크에 추가되었습니다'),
        backgroundColor: isCurrentlyBookmarked
            ? AppColors.textSecondary
            : AppColors.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
