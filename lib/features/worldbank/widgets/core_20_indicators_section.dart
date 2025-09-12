import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../../../constants/performance_colors.dart';
import '../../home/models/indicator_comparison.dart' show PerformanceLevel;
import '../models/core_indicators.dart';
import '../models/country_indicator.dart';
import '../services/integrated_data_service.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';
import '../../../common/widgets/data_year_badge.dart';
import '../../../common/logger.dart';

/// PRD v1.1 핵심 20개 지표 섹션
/// 카테고리별로 그룹화하여 표시하고 QoQ/YoY 변화율 포함
class Core20IndicatorsSection extends ConsumerStatefulWidget {
  const Core20IndicatorsSection({super.key});

  @override
  ConsumerState<Core20IndicatorsSection> createState() => _Core20IndicatorsSectionState();
}

class _Core20IndicatorsSectionState extends ConsumerState<Core20IndicatorsSection> {
  final Map<String, List<CountryIndicator>> _categoryData = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllIndicators();
    });
  }

  Future<void> _loadAllIndicators() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final selectedCountry = ref.read(selectedCountryProvider);
      final dataService = IntegratedDataService();
      
      AppLogger.debug('[Core20IndicatorsSection] Loading all 20 indicators for ${selectedCountry.code}');

      // 통합 데이터 서비스를 사용하여 카테고리별 데이터 로드
      final core20Data = await dataService.getCore20Indicators(
        countryCode: selectedCountry.code,
        forceRefresh: false,
      );
      
      // 결과를 _categoryData에 매핑
      _categoryData.clear();
      for (final entry in core20Data.entries) {
        _categoryData[entry.key.nameKo] = entry.value;
      }

      setState(() {
        _isLoading = false;
      });
      
      AppLogger.debug('[Core20IndicatorsSection] Successfully loaded all indicators');
    } catch (error, stackTrace) {
      AppLogger.error('[Core20IndicatorsSection] Error loading indicators: $error', stackTrace);
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 선택된 국가가 변경되면 다시 로드
    ref.listen(selectedCountryProvider, (previous, next) {
      if (previous != null && previous.code != next.code) {
        _categoryData.clear();
        _loadAllIndicators();
      }
    });

    if (_isLoading && _categoryData.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _categoryData.isEmpty) {
      return _buildErrorState();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Gaps.v16,
          ...CoreIndicatorCategory.values.map((category) => 
            _buildCategorySection(category),
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
            FontAwesomeIcons.chartColumn,
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
                '핵심 20개 지표',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '7개 카테고리 · OECD 순위 및 변화율',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadAllIndicators,
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
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          Gaps.v16,
          Text(
            'World Bank API에서 핵심 20개 지표 로딩 중...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Gaps.v8,
          Text(
            '7개 카테고리 데이터 수집 및 OECD 통계 분석',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
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
            '핵심 지표 데이터 로딩 실패',
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
            onPressed: _loadAllIndicators,
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

  Widget _buildCategorySection(CoreIndicatorCategory category) {
    final categoryData = _categoryData[category.nameKo] ?? [];
    
    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: category.getColor().withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: category.getColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: category.getColor(),
                    size: 16,
                  ),
                ),
                Gaps.h8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.nameKo,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: category.getColor(),
                        ),
                      ),
                      Text(
                        category.nameEn,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${categoryData.length}개',
                  style: AppTypography.caption.copyWith(
                    color: category.getColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // 지표 리스트
          ...categoryData.map((indicator) => _buildIndicatorTile(indicator, category)),
        ],
      ),
    );
  }

  Widget _buildIndicatorTile(CountryIndicator indicator, CoreIndicatorCategory category) {
    final coreIndicator = CoreIndicators.findByCode(indicator.indicatorCode);
    final performanceLevel = _getPerformanceFromPercentile(indicator.oecdPercentile ?? 50.0);
    final performanceColor = PerformanceColors.getPerformanceColor(performanceLevel);
    final rankBadgeColor = PerformanceColors.getRankBadgeColor(indicator.oecdPercentile ?? 50.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 성과 이모지
          Text(
            _getPerformanceEmoji(performanceLevel),
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
                        indicator.indicatorName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (indicator.latestYear != null)
                      DataYearBadge(year: indicator.latestYear!),
                  ],
                ),
                Gaps.v4,
                Row(
                  children: [
                    Text(
                      '${_formatValue(indicator.latestValue ?? 0.0)}${indicator.unit}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: performanceColor,
                      ),
                    ),
                    Gaps.h8,
                    Text(
                      '${indicator.oecdRanking ?? 0}위/38개국',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
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
                        indicator.getRankingBadge(),
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // YoY 변화율 표시 (데이터가 있는 경우)
                if (indicator.yearOverYearChange != null) ...[
                  Gaps.v4,
                  Row(
                    children: [
                      FaIcon(
                        indicator.yearOverYearChange! > 0 
                            ? FontAwesomeIcons.arrowUp 
                            : FontAwesomeIcons.arrowDown,
                        size: 12,
                        color: _getTrendColor(indicator.yearOverYearChange!, coreIndicator),
                      ),
                      Gaps.h4,
                      Text(
                        '전년 대비 ${indicator.yearOverYearChange!.abs().toStringAsFixed(1)}%',
                        style: AppTypography.caption.copyWith(
                          color: _getTrendColor(indicator.yearOverYearChange!, coreIndicator),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(CoreIndicatorCategory category) {
    switch (category) {
      case CoreIndicatorCategory.growth:
        return FontAwesomeIcons.chartLine;
      case CoreIndicatorCategory.inflation:
        return FontAwesomeIcons.coins;
      case CoreIndicatorCategory.employment:
        return FontAwesomeIcons.users;
      case CoreIndicatorCategory.fiscal:
        return FontAwesomeIcons.landmark;
      case CoreIndicatorCategory.external:
        return FontAwesomeIcons.globe;
      case CoreIndicatorCategory.social:
        return FontAwesomeIcons.handshake;
      case CoreIndicatorCategory.environment:
        return FontAwesomeIcons.leaf;
    }
  }

  String _getPerformanceEmoji(PerformanceLevel performance) {
    switch (performance) {
      case PerformanceLevel.excellent:
        return '🔥';
      case PerformanceLevel.good:
        return '📈';
      case PerformanceLevel.average:
        return '📊';
      case PerformanceLevel.poor:
        return '📉';
    }
  }

  PerformanceLevel _getPerformanceFromPercentile(double percentile) {
    if (percentile >= 75) return PerformanceLevel.excellent;
    if (percentile >= 50) return PerformanceLevel.good;
    if (percentile >= 25) return PerformanceLevel.average;
    return PerformanceLevel.poor;
  }

  Color _getTrendColor(double changeValue, CoreIndicator? coreIndicator) {
    if (changeValue == 0) return AppColors.textSecondary;

    final bool isIncrease = changeValue > 0;
    
    if (coreIndicator?.isPositive == true) {
      // 증가=좋은 지표: 증가시 녹색, 감소시 빨강
      return isIncrease ? AppColors.accent : AppColors.error;
    } else if (coreIndicator?.isPositive == false) {
      // 감소=좋은 지표: 감소시 녹색, 증가시 빨강  
      return isIncrease ? AppColors.error : AppColors.accent;
    } else {
      // 중립 지표: 항상 파랑
      return AppColors.primary;
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
}

