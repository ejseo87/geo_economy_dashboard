import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../providers/data_monitoring_provider.dart';
import '../services/data_monitoring_service.dart';

class RealTimeDataStatusCard extends ConsumerWidget {
  const RealTimeDataStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  FontAwesomeIcons.heartPulse,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '데이터 상태 모니터링',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Consumer(
                  builder: (context, ref, child) {
                    final isRefreshing = ref.watch(dataStatusRefreshProvider);
                    return IconButton(
                      onPressed: isRefreshing
                          ? null
                          : () => ref.read(dataStatusRefreshProvider.notifier).refresh(),
                      icon: AnimatedRotation(
                        turns: isRefreshing ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: const FaIcon(
                          FontAwesomeIcons.arrowsRotate,
                          size: 16,
                        ),
                      ),
                      tooltip: '상태 새로고침',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            Consumer(
              builder: (context, ref, child) {
                final dataStatusAsyncValue = ref.watch(dataStatusMonitoringProvider);

                return dataStatusAsyncValue.when(
                  data: (snapshot) => _buildRealTimeDataStatus(snapshot),
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState(error.toString()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeDataStatus(DataStatusSnapshot snapshot) {
    final lastUpdate = DateTime.now().difference(snapshot.timestamp).inMinutes;

    return Column(
      children: [
        // 상태 헤더
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: snapshot.isHealthy ? AppColors.accent.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              FaIcon(
                snapshot.isHealthy ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.triangleExclamation,
                color: snapshot.isHealthy ? AppColors.accent : AppColors.warning,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                snapshot.isHealthy ? '데이터 상태 양호' : '데이터 상태 주의',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: snapshot.isHealthy ? AppColors.accent : AppColors.warning,
                ),
              ),
              const Spacer(),
              Text(
                lastUpdate == 0 ? '방금 업데이트' : '${lastUpdate}분 전 업데이트',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 실시간 지표들
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildHealthCard(
              '전체 문서',
              '${snapshot.totalDocuments}개',
              AppColors.primary,
              FontAwesomeIcons.database,
            ),
            _buildHealthCard(
              '오늘 업데이트',
              '${snapshot.recentActivity.updatedIndicatorsToday}개',
              snapshot.recentActivity.updatedIndicatorsToday > 0 ? AppColors.accent : AppColors.textSecondary,
              FontAwesomeIcons.clockRotateLeft,
            ),
            _buildHealthCard(
              '신선한 데이터',
              '${snapshot.dataFreshness.freshPercentage.toStringAsFixed(1)}%',
              snapshot.dataFreshness.isHealthy ? AppColors.accent : AppColors.warning,
              FontAwesomeIcons.leaf,
            ),
            _buildHealthCard(
              '최근 감사 문제',
              snapshot.lastAudit != null ? '${snapshot.lastAudit!.totalIssues}개' : 'N/A',
              (snapshot.lastAudit?.totalIssues ?? 0) == 0 ? AppColors.accent : AppColors.warning,
              FontAwesomeIcons.magnifyingGlass,
            ),
          ],
        ),

        if (snapshot.lastAudit != null) ...[
          const SizedBox(height: 16),
          _buildLastAuditSummary(snapshot.lastAudit!),
        ],

        // 데이터 수집 성능 정보
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.gauge,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '수집 시간: ${snapshot.collectionDuration.inMilliseconds}ms',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: snapshot.isHealthy ? AppColors.accent : AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '실시간',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLastAuditSummary(AuditSummaryData audit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.clockRotateLeft,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '최근 감사 결과',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (audit.hasLogFile)
                IconButton(
                  onPressed: () {
                    // TODO: CSV 로그 파일 다운로드 구현
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.download,
                    size: 12,
                  ),
                  tooltip: 'CSV 로그 다운로드',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAuditSummaryItem('중복', audit.duplicates, AppColors.warning),
              _buildAuditSummaryItem('고아', audit.orphans, AppColors.error),
              _buildAuditSummaryItem('일관성', audit.integrityIssues, AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 16, color: color),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '데이터 상태를 확인하는 중...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 32,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            '데이터 상태 확인 실패',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}