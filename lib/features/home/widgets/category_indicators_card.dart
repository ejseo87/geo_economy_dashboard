import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/performance_colors.dart';
import '../models/indicator_comparison.dart';
import '../view_models/all_indicators_view_model.dart';
import '../view_models/sparkline_view_model.dart';
import '../widgets/sparkline_chart.dart';
import '../../worldbank/models/indicator_codes.dart';

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
              child: FaIcon(
                _getCategoryIcon(),
                size: 16,
                color: _getCategoryColor(),
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
                    _getCategoryDescription(),
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
    AsyncValue<Map<String, List<IndicatorComparison>>> allIndicatorsAsync,
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
        final indicators = categoryData[category] ?? [];
        
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

  Widget _buildIndicatorTile(IndicatorComparison indicator) {
    final performanceColor = PerformanceColors.getPerformanceColor(
      indicator.insight.performance,
    );
    
    return ListTile(
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
            '1',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: performanceColor,
            ),
          ),
        ),
      ),
      title: Text(
        indicator.indicatorName,
        style: AppTypography.bodyMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${indicator.korea.value.toStringAsFixed(2)} ${indicator.unit}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          _buildCompactSparkline(indicator),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: performanceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getPerformanceText(indicator.insight.performance),
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${indicator.oecdStats.totalCountries}개국 중',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSparkline(IndicatorComparison indicator) {
    // 지표 코드로부터 IndicatorCode 찾기
    IndicatorCode? indicatorCode;
    try {
      indicatorCode = IndicatorCode.values.firstWhere(
        (code) => code.name.toLowerCase().contains(indicator.indicatorName.toLowerCase()) ||
                  indicator.indicatorName.toLowerCase().contains(code.name.toLowerCase()) ||
                  _isMatchingIndicator(code, indicator.indicatorName),
      );
    } catch (e) {
      // 매칭되는 IndicatorCode가 없으면 null
    }

    if (indicatorCode == null) {
      return const SizedBox(height: 20); // 빈 공간
    }

    return Consumer(
      builder: (context, ref, child) {
        return FutureBuilder(
          future: ref.read(sparklineViewModelProvider.notifier).loadSingleSparkline(indicatorCode!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 20,
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox(height: 20);
            }

            final sparklineData = snapshot.data!;
            return CompactSparkline(
              data: sparklineData,
              width: 60,
              height: 20,
            );
          },
        );
      },
    );
  }

  bool _isMatchingIndicator(IndicatorCode code, String indicatorName) {
    // 특정 지표명 매칭 로직
    final codeNameLower = code.name.toLowerCase();
    final indicatorNameLower = indicatorName.toLowerCase();
    
    // 키워드 매칭
    final keywordMatches = {
      'gdp': ['gdp', '국내총생산', '경제성장'],
      'unemployment': ['실업', '실업률'],
      'inflation': ['인플레이션', '물가', 'cpi'],
      'export': ['수출', 'export'],
      'import': ['수입', 'import'],
    };
    
    for (final entry in keywordMatches.entries) {
      if (codeNameLower.contains(entry.key)) {
        for (final keyword in entry.value) {
          if (indicatorNameLower.contains(keyword)) {
            return true;
          }
        }
      }
    }
    
    return false;
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

  IconData _getCategoryIcon() {
    switch (category) {
      case '성장/활동':
        return FontAwesomeIcons.chartLine;
      case '고용/노동':
        return FontAwesomeIcons.users;
      case '물가/통화':
        return FontAwesomeIcons.coins;
      case '재정/정부':
        return FontAwesomeIcons.landmark;
      case '대외/거시건전성':
        return FontAwesomeIcons.globe;
      case '분배/사회':
        return FontAwesomeIcons.scaleBalanced;
      case '환경/에너지':
        return FontAwesomeIcons.leaf;
      default:
        return FontAwesomeIcons.chartBar;
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
}