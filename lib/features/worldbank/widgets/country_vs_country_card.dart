import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../../../constants/performance_colors.dart';
import '../models/country_indicator.dart';
import '../models/core_indicators.dart';
import '../view_models/country_comparison_view_model.dart';
import '../../../common/countries/models/country.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';
import '../../../common/widgets/data_year_badge.dart';
import '../../home/models/indicator_comparison.dart' show PerformanceLevel;

class CountryVsCountryCard extends ConsumerStatefulWidget {
  final Country comparisonCountry;

  const CountryVsCountryCard({
    super.key,
    required this.comparisonCountry,
  });

  @override
  ConsumerState<CountryVsCountryCard> createState() => _CountryVsCountryCardState();
}

class _CountryVsCountryCardState extends ConsumerState<CountryVsCountryCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComparison();
    });
  }

  void _loadComparison() {
    final selectedCountry = ref.read(selectedCountryProvider);
    ref.read(countryComparisonViewModelProvider.notifier).compareCountries(
      country1: selectedCountry,
      country2: widget.comparisonCountry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final comparisonAsync = ref.watch(countryComparisonViewModelProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          comparisonAsync.when(
            loading: () => _buildLoadingState(),
            error: (error, _) => _buildErrorState(error),
            data: (result) => result != null 
                ? _buildComparisonContent(result)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final selectedCountry = ref.watch(selectedCountryProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // 첫 번째 국가
          Expanded(
            child: Column(
              children: [
                Text(
                  selectedCountry.flagEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                Gaps.v8,
                Text(
                  selectedCountry.nameKo,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // VS 아이콘
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // 두 번째 국가
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.comparisonCountry.flagEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                Gaps.v8,
                Text(
                  widget.comparisonCountry.nameKo,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 새로고침 버튼
          IconButton(
            onPressed: _loadComparison,
            icon: const FaIcon(
              FontAwesomeIcons.arrowRotateRight,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          Gaps.v12,
          Text(
            'Top 5 지표 데이터 비교 중...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gaps.v8,
          Text(
            'OECD 순위 및 통계 데이터 분석',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
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
            '비교 데이터 로딩 실패',
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
            onPressed: _loadComparison,
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        '비교할 데이터가 없습니다.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildComparisonContent(CountryComparisonResult result) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top 5 지표 비교
          Text(
            'Top 5 지표 비교',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Gaps.v16,
          ...CoreIndicators.top5Indicators.map((coreIndicator) {
            final country1Data = result.country1Indicators
                .where((i) => i.indicatorCode == coreIndicator.code)
                .firstOrNull;
            final country2Data = result.country2Indicators
                .where((i) => i.indicatorCode == coreIndicator.code)
                .firstOrNull;
            
            return _buildIndicatorComparison(
              coreIndicator,
              country1Data,
              country2Data,
              result.country1,
              result.country2!,
            );
          }),
          Gaps.v16,
          _buildLastUpdated(result.lastUpdated),
        ],
      ),
    );
  }

  Widget _buildIndicatorComparison(
    CoreIndicator coreIndicator,
    CountryIndicator? country1Data,
    CountryIndicator? country2Data,
    Country country1,
    Country country2,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 지표 헤더
          Row(
            children: [
              Text(
                coreIndicator.category.nameKo,
                style: AppTypography.caption.copyWith(
                  color: coreIndicator.category.getColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (country1Data?.latestYear != null)
                DataYearBadge(year: country1Data!.latestYear!),
            ],
          ),
          Gaps.v8,
          Text(
            coreIndicator.name,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Gaps.v12,
          // 국가별 데이터 비교
          Row(
            children: [
              Expanded(
                child: _buildCountryDataColumn(
                  country1,
                  country1Data,
                  coreIndicator,
                  true,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.outline,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildCountryDataColumn(
                  country2,
                  country2Data,
                  coreIndicator,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDataColumn(
    Country country,
    CountryIndicator? data,
    CoreIndicator coreIndicator,
    bool isLeftSide,
  ) {
    if (data == null) {
      return Column(
        children: [
          Text(
            country.flagEmoji,
            style: const TextStyle(fontSize: 20),
          ),
          Gaps.v8,
          Text(
            '데이터 없음',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    final performanceColor = PerformanceColors.getPerformanceColor(
      _getPerformanceFromPercentile(data.oecdPercentile ?? 50.0),
    );

    return Column(
      children: [
        Text(
          country.flagEmoji,
          style: const TextStyle(fontSize: 20),
        ),
        Gaps.v8,
        Text(
          '${_formatValue(data.latestValue ?? 0.0)}${data.unit}',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: performanceColor,
          ),
        ),
        Gaps.v4,
        Text(
          '${data.oecdRanking}위/38개국',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Gaps.v4,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: PerformanceColors.getRankBadgeColor(data.oecdPercentile ?? 50.0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            data.getRankingBadge(),
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdated(DateTime lastUpdated) {
    return Center(
      child: Text(
        '마지막 업데이트: ${_formatDateTime(lastUpdated)}',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  PerformanceLevel _getPerformanceFromPercentile(double percentile) {
    if (percentile >= 75) return PerformanceLevel.excellent;
    if (percentile >= 50) return PerformanceLevel.good;
    if (percentile >= 25) return PerformanceLevel.average;
    return PerformanceLevel.poor;
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

