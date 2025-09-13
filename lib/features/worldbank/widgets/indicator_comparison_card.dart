import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../../../constants/performance_colors.dart';
import '../models/country_indicator.dart';
import '../models/core_indicators.dart';
import '../../../common/countries/models/country.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';
import '../../home/models/indicator_comparison.dart';

/// 특정 지표의 모든 OECD 국가 비교 카드
class IndicatorComparisonCard extends ConsumerStatefulWidget {
  final CoreIndicator indicator;

  const IndicatorComparisonCard({
    super.key,
    required this.indicator,
  });

  @override
  ConsumerState<IndicatorComparisonCard> createState() => _IndicatorComparisonCardState();
}

class _IndicatorComparisonCardState extends ConsumerState<IndicatorComparisonCard> {
  @override
  void initState() {
    super.initState();
    // 임시로 빈 구현
  }

  void _loadComparison() {
    // 임시로 빈 구현
  }

  @override
  Widget build(BuildContext context) {
    return _buildLoadingCard();
  }

  Widget _buildLoadingCard() {
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
          _buildLoadingState(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final selectedCountry = ref.watch(selectedCountryProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.indicator.category.getColor().withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.indicator.category.getColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  FontAwesomeIcons.chartBar,
                  color: widget.indicator.category.getColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.indicator.category.nameKo,
                      style: AppTypography.caption.copyWith(
                        color: widget.indicator.category.getColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.indicator.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
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
          Gaps.v12,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedCountry.flagEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  '${selectedCountry.nameKo}의 OECD 순위',
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
            'OECD 38개국 데이터 분석 중...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gaps.v8,
          Text(
            '${widget.indicator.name} 지표의 모든 국가 데이터를 수집하고 있습니다',
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
            '지표별 비교 데이터 로딩 실패',
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
        '이 지표에 대한 데이터가 없습니다.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildComparisonContent(IndicatorComparisonResult result) {
    final selectedCountry = ref.watch(selectedCountryProvider);
    final selectedCountryData = result.countries
        .where((c) => c.countryCode == selectedCountry.code)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택 국가의 성과 하이라이트
          if (selectedCountryData != null) ...[
            _buildHighlightSection(selectedCountryData, selectedCountry),
            Gaps.v20,
          ],
          
          // OECD 순위 Top 5 & Bottom 5
          Text(
            'OECD 순위 (상위 5개국 vs 하위 5개국)',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Gaps.v16,
          
          // Top 5 국가들
          _buildRankingSection(
            '🏆 상위 5개국',
            result.countries.take(5).toList(),
            AppColors.primary,
          ),
          
          Gaps.v16,
          
          // Bottom 5 국가들  
          _buildRankingSection(
            '📉 하위 5개국',
            result.countries.reversed.take(5).toList().reversed.toList(),
            AppColors.error,
          ),
          
          Gaps.v16,
          _buildLastUpdated(result.lastUpdated),
        ],
      ),
    );
  }

  Widget _buildHighlightSection(CountryIndicator data, Country country) {
    final performanceColor = PerformanceColors.getPerformanceColor(
      _getPerformanceFromPercentile(data.oecdPercentile ?? 50.0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: performanceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: performanceColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            country.flagEmoji,
            style: const TextStyle(fontSize: 32),
          ),
          Gaps.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${country.nameKo}의 성과',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Gaps.v4,
                Text(
                  '${_formatValue(data.latestValue ?? 0.0)}${data.unit}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: performanceColor,
                  ),
                ),
                Gaps.v4,
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: PerformanceColors.getRankBadgeColor(data.oecdPercentile ?? 50.0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${data.oecdRanking}위',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'OECD 38개국 중',
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
    );
  }

  Widget _buildRankingSection(String title, List<CountryIndicator> countries, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Gaps.v12,
          ...countries.map((data) => _buildCountryRankItem(data)),
        ],
      ),
    );
  }

  Widget _buildCountryRankItem(CountryIndicator data) {
    final performanceColor = PerformanceColors.getPerformanceColor(
      _getPerformanceFromPercentile(data.oecdPercentile ?? 50.0),
    );

    // 국가 코드로부터 Country 객체를 찾아야 합니다 (임시로 코드만 사용)
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: performanceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${data.oecdRanking}',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Gaps.h12,
          Text(
            data.countryCode, // 실제로는 국가명으로 변환 필요
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '${_formatValue(data.latestValue ?? 0.0)}${data.unit}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: performanceColor,
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


// 지표별 비교 결과 모델 (실제 구현 필요)
class IndicatorComparisonResult {
  final List<CountryIndicator> countries;
  final DateTime lastUpdated;

  IndicatorComparisonResult({
    required this.countries,
    required this.lastUpdated,
  });
}