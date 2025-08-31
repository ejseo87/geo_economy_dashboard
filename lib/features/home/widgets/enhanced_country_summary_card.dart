import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../../../constants/performance_colors.dart';
import '../models/country_summary.dart';
import '../models/indicator_comparison.dart';
import '../view_models/country_summary_view_model.dart';
import '../../../common/countries/view_models/selected_country_provider.dart';
import '../../worldbank/models/indicator_codes.dart';

/// PRD 기준 10초-1분-5분 규칙을 적용한 개선된 국가 요약카드
class EnhancedCountrySummaryCard extends ConsumerStatefulWidget {
  const EnhancedCountrySummaryCard({super.key});

  @override
  ConsumerState<EnhancedCountrySummaryCard> createState() => _EnhancedCountrySummaryCardState();
}

class _EnhancedCountrySummaryCardState extends ConsumerState<EnhancedCountrySummaryCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(countrySummaryViewModelProvider.notifier).loadCountrySummary();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(countrySummaryViewModelProvider);
    final selectedCountry = ref.watch(selectedCountryProvider);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: summaryAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error),
                data: (summary) => _buildSummaryContent(summary, selectedCountry),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          Gaps.v16,
          Text(
            '국가 경제 현황 분석 중...',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gaps.v8,
          Text(
            'OECD 38개국 데이터 수집 및 순위 계산',
            style: AppTypography.bodySmall.copyWith(
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
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            color: AppColors.error,
            size: 48,
          ),
          Gaps.v16,
          Text(
            '데이터 로딩 실패',
            style: AppTypography.heading3.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
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
          Gaps.v20,
          ElevatedButton.icon(
            onPressed: () {
              ref.read(countrySummaryViewModelProvider.notifier).refreshSummary();
            },
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

  Widget _buildSummaryContent(CountrySummary summary, dynamic selectedCountry) {
    return Column(
      children: [
        // 10초: 즉시 파악 가능한 헤더
        _buildQuickOverviewHeader(summary, selectedCountry),
        
        // 1분: 핵심 지표 그리드
        _buildKeyIndicatorsSection(summary),
        
        // 5분: 상세 액션 버튼들
        _buildActionSection(summary),
      ],
    );
  }

  /// 10초 규칙: 한눈에 파악 가능한 헤더
  Widget _buildQuickOverviewHeader(CountrySummary summary, dynamic selectedCountry) {
    final overallColor = _getOverallPerformanceColor(summary.overallRanking);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            overallColor.withValues(alpha: 0.1),
            overallColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 국기와 국가명
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: overallColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    summary.flagEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              Gaps.h16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.countryName,
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'OECD 38개국 기준',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 전체 순위 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: overallColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.overallRanking,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Gaps.v20,
          // 핵심 성과 요약 (10초에 파악 가능)
          _buildQuickInsight(summary),
        ],
      ),
    );
  }

  Widget _buildQuickInsight(CountrySummary summary) {
    final topPerformer = summary.topIndicators.where((i) => 
        i.performance == PerformanceLevel.excellent || 
        i.performance == PerformanceLevel.good
    ).length;
    
    final needsImprovement = summary.topIndicators.where((i) => 
        i.performance == PerformanceLevel.poor
    ).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat('강점 지표', '$topPerformer개', AppColors.accent),
          Container(width: 1, height: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          _buildQuickStat('개선 필요', '$needsImprovement개', AppColors.error),
          Container(width: 1, height: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          _buildQuickStat('업데이트', _formatLastUpdated(summary.lastUpdated), AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.heading3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 1분 규칙: 핵심 지표 상세 분석
  Widget _buildKeyIndicatorsSection(CountrySummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                '핵심 경제지표 (Top 5)',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Gaps.v16,
          ...summary.topIndicators.map((indicator) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildEnhancedIndicatorTile(indicator),
          )),
        ],
      ),
    );
  }

  Widget _buildEnhancedIndicatorTile(KeyIndicator indicator) {
    final performanceColor = PerformanceColors.getPerformanceColor(indicator.performance);
    final rankBadgeColor = PerformanceColors.getRankBadgeColor(indicator.percentile);
    
    return GestureDetector(
      onTap: () => _navigateToIndicatorDetail(indicator),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: performanceColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 지표 아이콘과 성과
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: performanceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    indicator.sparklineEmoji ?? '📊',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              Gaps.h16,
              // 지표 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indicator.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_formatValue(indicator.value)}${indicator.unit}',
                      style: AppTypography.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: performanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              // 순위 배지
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: rankBadgeColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      indicator.rankBadge,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Gaps.v4,
                  Text(
                    '${indicator.rank}위',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Gaps.v12,
          // 성과 표시 바
          _buildPerformanceBar(indicator.percentile, performanceColor),
        ],
      ),
      ),
    );
  }

  Widget _buildPerformanceBar(double percentile, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OECD 38개국 중',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '상위 ${(100 - percentile).toStringAsFixed(1)}%',
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Gaps.v8,
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (100 - percentile) / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 5분 규칙: 액션 유도 섹션
  Widget _buildActionSection(CountrySummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '더 자세히 알아보기',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Gaps.v16,
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToDetailedComparison(),
                  icon: const FaIcon(FontAwesomeIcons.chartColumn, size: 16),
                  label: const Text('상세 비교'),
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
                  onPressed: () => _shareCountrySummary(summary),
                  icon: const FaIcon(FontAwesomeIcons.share, size: 16),
                  label: const Text('공유'),
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
            child: TextButton.icon(
              onPressed: () => _setCountryAlert(),
              icon: const FaIcon(FontAwesomeIcons.bell, size: 16),
              label: const Text('이 국가 업데이트 알림 설정'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getOverallPerformanceColor(String ranking) {
    switch (ranking) {
      case '상위권':
        return PerformanceColors.excellent;
      case '중상위권':
        return PerformanceColors.good;
      case '중위권':
        return PerformanceColors.average;
      case '하위권':
        return PerformanceColors.poor;
      default:
        return PerformanceColors.average;
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

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  void _navigateToDetailedComparison() {
    // TODO: 상세 비교 화면으로 네비게이션
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('상세 비교 화면으로 이동합니다...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _shareCountrySummary(CountrySummary summary) {
    // TODO: 국가 요약 공유 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('국가 요약을 공유합니다...'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _setCountryAlert() {
    // TODO: 국가 알림 설정
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('알림이 설정되었습니다'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _navigateToIndicatorDetail(KeyIndicator indicator) {
    // 지표 코드로부터 IndicatorCode enum을 찾기
    final indicatorCode = _getIndicatorCodeFromString(indicator.code);
    if (indicatorCode == null) return;

    // 현재 선택된 국가 정보 가져오기
    final selectedCountry = ref.read(selectedCountryProvider);

    // GoRouter를 사용한 네비게이션
    context.go('/indicator/${indicatorCode.code}/${selectedCountry.code}');
  }

  IndicatorCode? _getIndicatorCodeFromString(String code) {
    try {
      return IndicatorCode.values.firstWhere((ic) => ic.code == code);
    } catch (e) {
      return null;
    }
  }
}