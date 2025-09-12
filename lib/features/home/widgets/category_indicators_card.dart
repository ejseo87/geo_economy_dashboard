import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/performance_colors.dart';
import '../../../constants/indicators_catalog.dart';
import '../models/indicator_comparison.dart' show PerformanceLevel;
import '../view_models/all_indicators_view_model.dart';
import '../../worldbank/models/core_indicators.dart';
import '../../worldbank/models/country_indicator.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';

/// 카테고리별 지표 표시 카드
class CategoryIndicatorsCard extends ConsumerWidget {
  final String category;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const CategoryIndicatorsCard({
    super.key,
    required this.category,
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allIndicatorsAsync = ref.watch(allIndicatorsViewModelProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          _buildCategoryHeader(context),
          if (isExpanded) _buildCategoryContent(context, allIndicatorsAsync),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getCategoryColor().withValues(alpha: 0.1),
          borderRadius: isExpanded
              ? const BorderRadius.vertical(top: Radius.circular(12))
              : BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCategoryColor().withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                IndicatorCatalogUtils.getCategoryEmoji(category),
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(),
                    ),
                  ),
                  Text(
                    '${IndicatorCatalogUtils.indicatorCountByCategory[category] ?? 0}개 지표 • ${_getCategoryDescription()}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: _getCategoryColor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent(
    BuildContext context,
    AsyncValue<Map<CoreIndicatorCategory, List<CountryIndicator>>>
    allIndicatorsAsync,
  ) {
    return allIndicatorsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '데이터를 불러올 수 없습니다: ${error.toString()}',
          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
      data: (categoryData) {
        // CoreIndicatorCategory enum을 찾아서 해당 카테고리의 지표들 가져오기
        final categoryEnum = _getCategoryEnumFromString(category);
        final indicators = categoryEnum != null
            ? categoryData[categoryEnum] ?? []
            : <CountryIndicator>[];

        if (indicators.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '이 카테고리에 사용 가능한 데이터가 없습니다.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return Column(
          children: [
            const Divider(height: 1),
            ...indicators.map((indicator) => _buildIndicatorTile(indicator)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildIndicatorTile(CountryIndicator indicator) {
    // OECD 백분위수를 기반으로 성과 레벨 계산
    final percentile = indicator.oecdPercentile ?? 50.0;
    final performance = _getPerformanceFromPercentile(percentile);

    final performanceColor = PerformanceColors.getPerformanceColor(performance);

    return Builder(
      builder: (context) => Consumer(
        builder: (context, ref, child) => ListTile(
          onTap: () => _navigateToIndicatorDetail(context, ref, indicator),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: performanceColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (indicator.oecdRanking ?? 0).toString(),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: performanceColor,
                ),
              ),
            ),
          ),
          title: Text(indicator.indicatorName, style: AppTypography.bodyMedium),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(indicator.latestValue ?? 0.0).toStringAsFixed(1)} ${indicator.unit}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: performanceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPerformanceText(performance),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${indicator.oecdStats?.totalCountries ?? 38}개국 중',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 카테고리 문자열을 CoreIndicatorCategory enum으로 변환
  CoreIndicatorCategory? _getCategoryEnumFromString(String categoryString) {
    switch (categoryString) {
      case '성장/활동':
        return CoreIndicatorCategory.growth;
      case '고용/노동':
        return CoreIndicatorCategory.employment;
      case '물가/통화':
        return CoreIndicatorCategory.inflation;
      case '재정/정부':
        return CoreIndicatorCategory.fiscal;
      case '대외/거시건전성':
        return CoreIndicatorCategory.external;
      case '분배/사회':
        return CoreIndicatorCategory.social;
      case '환경/에너지':
        return CoreIndicatorCategory.environment;
      default:
        return null;
    }
  }

  /// 백분위수를 성과 레벨로 변환
  PerformanceLevel _getPerformanceFromPercentile(double percentile) {
    if (percentile >= 75) return PerformanceLevel.excellent;
    if (percentile >= 50) return PerformanceLevel.good;
    if (percentile >= 25) return PerformanceLevel.average;
    return PerformanceLevel.poor;
  }

  Color _getCategoryColor() {
    switch (category) {
      case '성장/활동':
        return const Color(0xFF1E88E5); // 파란색
      case '고용/노동':
        return const Color(0xFF26A69A); // 청록색
      case '물가/통화':
        return const Color(0xFF7E57C2); // 보라색
      case '재정/정부':
        return const Color(0xFF43A047); // 초록색
      case '대외/거시건전성':
        return const Color(0xFFFF7043); // 오렌지색
      case '분배/사회':
        return const Color(0xFFEC407A); // 분홍색
      case '환경/에너지':
        return const Color(0xFF66BB6A); // 연한 초록색
      default:
        return AppColors.primary;
    }
  }

  String _getCategoryDescription() {
    switch (category) {
      case '성장/활동':
        return 'GDP, 제조업, 투자 등';
      case '고용/노동':
        return '실업률, 고용률, 노동참가율';
      case '물가/통화':
        return '인플레이션, 통화량';
      case '재정/정부':
        return '정부지출, 세수, 부채';
      case '대외/거시건전성':
        return '수출입, 경상수지, 외환보유액';
      case '분배/사회':
        return '소득분배, 빈곤';
      case '환경/에너지':
        return 'CO₂ 배출, 재생에너지';
      default:
        return '';
    }
  }

  String _getPerformanceText(PerformanceLevel performance) {
    switch (performance) {
      case PerformanceLevel.excellent:
        return '우수';
      case PerformanceLevel.good:
        return '양호';
      case PerformanceLevel.average:
        return '보통';
      case PerformanceLevel.poor:
        return '미흡';
    }
  }

  void _navigateToIndicatorDetail(
    BuildContext context,
    WidgetRef ref,
    CountryIndicator indicator,
  ) {
    // 현재 선택된 국가 정보 가져오기
    final selectedCountry = ref.read(selectedCountryProvider);

    // GoRouter를 사용한 네비게이션
    context.go('/indicator/${indicator.indicatorCode}/${selectedCountry.code}');
  }
}
