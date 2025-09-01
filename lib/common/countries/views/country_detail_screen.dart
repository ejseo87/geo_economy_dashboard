import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../models/country.dart';
import '../widgets/country_indicators_section.dart';
import '../widgets/country_overview_card.dart';
import '../../../features/favorites/widgets/favorites_floating_button.dart';
import '../../../features/favorites/models/favorite_item.dart';
import '../../../features/worldbank/models/indicator_codes.dart';

class CountryDetailScreen extends ConsumerWidget {
  static const String routeName = 'countryDetail';
  static const String routeURL = '/country/:countryCode';

  final Country country;

  const CountryDetailScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size16),
              child: Column(
                children: [
                  _build10YearLineChart(),
                  const SizedBox(height: Sizes.size16),
                  _buildOECDComparisonChart(),
                  const SizedBox(height: Sizes.size16),
                  _buildIndicatorButtonsGrid(context),
                  const SizedBox(height: Sizes.size16),
                  CountryOverviewCard(country: country),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FavoritesFloatingButton(
        favoriteItem: FavoriteItemFactory.createCountrySummary(
          country: country,
          indicators: [
            IndicatorCode.gdpRealGrowth,
            IndicatorCode.cpiInflation,
            IndicatorCode.unemployment,
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              country.flagEmoji.isNotEmpty ? country.flagEmoji : '🏳️',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              country.nameKo,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, Color(0xFF003D7A)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  country.flagEmoji.isNotEmpty ? country.flagEmoji : '🏳️',
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: Sizes.size8),
                Text(
                  country.nameKo,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Sizes.size4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sizes.size12,
                    vertical: Sizes.size4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${country.region} • ${country.code}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 10년 라인 차트
  Widget _build10YearLineChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
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
                const SizedBox(width: Sizes.size8),
                Text(
                  '10년 GDP 성장률 추이',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final year = 2014 + value.toInt();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              year.toString(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 35,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${value.toInt()}%',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  minX: 0,
                  maxX: 9,
                  minY: -4,
                  maxY: 8,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getMockGdpData(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // OECD 대비 바 차트
  Widget _buildOECDComparisonChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.chartBar,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: Sizes.size8),
                Text(
                  'OECD 평균 대비 비교',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 15,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          AppColors.textPrimary.withValues(alpha: 0.8),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final String indicator = _getIndicatorName(groupIndex);
                        final String value = '${rod.toY.toStringAsFixed(1)}%';
                        return BarTooltipItem(
                          '$indicator\n$value',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _getIndicatorShortName(value.toInt()),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${value.toInt()}%',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  barGroups: _getMockOECDComparisonData(),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 기타 지표 버튼 그리드
  Widget _buildIndicatorButtonsGrid(BuildContext context) {
    final indicators = [
      {
        'code': IndicatorCode.gdpRealGrowth,
        'icon': FontAwesomeIcons.chartLine,
        'color': AppColors.primary,
      },
      {
        'code': IndicatorCode.unemployment,
        'icon': FontAwesomeIcons.users,
        'color': AppColors.accent,
      },
      {
        'code': IndicatorCode.cpiInflation,
        'icon': FontAwesomeIcons.dollarSign,
        'color': AppColors.warning,
      },
      {
        'code': IndicatorCode.currentAccount,
        'icon': FontAwesomeIcons.globe,
        'color': AppColors.primaryVariant,
      },
      {
        'code': IndicatorCode.gdpPppPerCapita,
        'icon': FontAwesomeIcons.chartColumn,
        'color': AppColors.accentVariant,
      },
      {
        'code': IndicatorCode.employmentRate,
        'icon': FontAwesomeIcons.briefcase,
        'color': AppColors.textSecondary,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.tableColumns,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: Sizes.size8),
                Text(
                  '기타 경제지표',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: indicators.length,
              itemBuilder: (context, index) {
                final indicator = indicators[index];
                final indicatorCode = indicator['code'] as IndicatorCode;
                final icon = indicator['icon'] as IconData;
                final color = indicator['color'] as Color;

                return InkWell(
                  onTap: () {
                    context.push(
                      '/indicator/${indicatorCode.code}/${country.code}',
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline, width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: color.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FaIcon(icon, size: 14, color: color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                indicatorCode.name,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                indicatorCode.unit,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const FaIcon(
                          FontAwesomeIcons.chevronRight,
                          size: 10,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Mock 데이터 생성 메서드들
  List<FlSpot> _getMockGdpData() {
    // 한국의 GDP 성장률 샘플 데이터 (2014-2023)
    return [
      const FlSpot(0, 3.2), // 2014
      const FlSpot(1, 2.8), // 2015
      const FlSpot(2, 2.9), // 2016
      const FlSpot(3, 3.2), // 2017
      const FlSpot(4, 2.7), // 2018
      const FlSpot(5, 2.0), // 2019
      const FlSpot(6, -0.7), // 2020
      const FlSpot(7, 4.3), // 2021
      const FlSpot(8, 3.1), // 2022
      const FlSpot(9, 3.1), // 2023
    ];
  }

  List<BarChartGroupData> _getMockOECDComparisonData() {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: 3.1,
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: 2.8,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: 3.8,
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: 5.2,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: 3.6,
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: 4.1,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
    ];
  }

  String _getIndicatorName(int index) {
    switch (index) {
      case 0:
        return 'GDP 성장률';
      case 1:
        return '실업률';
      case 2:
        return 'CPI 인플레이션';
      default:
        return '지표';
    }
  }

  String _getIndicatorShortName(int index) {
    switch (index) {
      case 0:
        return 'GDP\n성장률';
      case 1:
        return '실업률';
      case 2:
        return 'CPI\n인플레이션';
      default:
        return '지표';
    }
  }
}
