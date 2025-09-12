import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/indicators_catalog.dart';
import '../view_models/all_indicators_view_model.dart';
import '../../worldbank/models/core_indicators.dart';
import '../../worldbank/models/country_indicator.dart';
import 'category_indicators_card.dart';
import '../../../common/widgets/data_year_badge.dart';

/// 전체 20개 지표를 카테고리별로 표시하는 섹션
class AllIndicatorsSection extends ConsumerStatefulWidget {
  const AllIndicatorsSection({super.key});

  @override
  ConsumerState<AllIndicatorsSection> createState() =>
      _AllIndicatorsSectionState();
}

class _AllIndicatorsSectionState extends ConsumerState<AllIndicatorsSection> {
  CoreIndicatorCategory? expandedCategory;

  @override
  void initState() {
    super.initState();
    // 초기화 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allIndicatorsViewModelProvider.notifier).loadAllIndicators();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allIndicatorsAsync = ref.watch(allIndicatorsViewModelProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), _buildContent(allIndicatorsAsync)],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text('📊', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '핵심 ${IndicatorCatalogUtils.totalIndicatorCount}개 지표 전체 현황',
                      style: AppTypography.bodyMediumBold,
                    ),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final indicatorsAsync = ref.watch(
                          allIndicatorsViewModelProvider,
                        );
                        return indicatorsAsync.when(
                          data: (categoryData) {
                            final firstCategory = categoryData.values.isNotEmpty
                                ? categoryData.values.first
                                : <CountryIndicator>[];
                            return firstCategory.isNotEmpty
                                ? DataYearBadge(
                                    year: firstCategory.first.latestYear ?? 2024,
                                  )
                                : const DataYearBadge(year: 2024);
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  '${IndicatorCatalogUtils.indicatorCountByCategory.length}개 카테고리별로 분류된 경제지표 상세보기',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref
                  .read(allIndicatorsViewModelProvider.notifier)
                  .refreshIndicators();
            },
            icon: const Icon(Icons.refresh),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<Map<CoreIndicatorCategory, List<CountryIndicator>>> allIndicatorsAsync,
  ) {
    return allIndicatorsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              '데이터를 불러올 수 없습니다',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(allIndicatorsViewModelProvider.notifier)
                    .loadAllIndicators();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (categoryData) {
        if (categoryData.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.data_usage,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사용 가능한 데이터가 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            const Divider(height: 1),
            ...categoryData.keys.map(
              (category) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CategoryIndicatorsCard(
                  category: category.nameKo,
                  isExpanded: expandedCategory == category,
                  onToggle: () {
                    setState(() {
                      expandedCategory = expandedCategory == category
                          ? null
                          : category;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummary(categoryData),
          ],
        );
      },
    );
  }

  Widget _buildSummary(Map<CoreIndicatorCategory, List<CountryIndicator>> categoryData) {
    var totalIndicators = 0;
    var excellentCount = 0;
    var goodCount = 0;
    var averageCount = 0;
    var poorCount = 0;

    for (final indicators in categoryData.values) {
      for (final indicator in indicators) {
        totalIndicators++;
        
        // OECD 백분위수로 성과 계산
        final percentile = indicator.oecdPercentile ?? 50.0;
        if (percentile >= 75) {
          excellentCount++;
        } else if (percentile >= 50) {
          goodCount++;
        } else if (percentile >= 25) {
          averageCount++;
        } else {
          poorCount++;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Text('📈', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('전체 성과 요약', style: AppTypography.bodyMediumBold),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPerformanceBadge('우수', excellentCount, Colors.blue),
              const SizedBox(width: 8),
              _buildPerformanceBadge('양호', goodCount, Colors.teal),
              const SizedBox(width: 8),
              _buildPerformanceBadge('보통', averageCount, Colors.purple),
              const SizedBox(width: 8),
              _buildPerformanceBadge('미흡', poorCount, Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '총 $totalIndicators개 지표 분석 완료',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: AppTypography.headlineSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: AppTypography.bodySmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
