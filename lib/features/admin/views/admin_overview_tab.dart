import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../services/admin_overview_service.dart';
import '../view_models/admin_overview_view_model.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sizes.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatus(ref),
          const SizedBox(height: Sizes.size24),
          _buildDataStatistics(ref),
          const SizedBox(height: Sizes.size24),
          _buildUserStatistics(ref),
          const SizedBox(height: Sizes.size24),
          _buildRecentActivity(ref),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(WidgetRef ref) {
    final systemStatusAsync = ref.watch(systemStatusProvider);

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
                  '시스템 상태',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                systemStatusAsync.when(
                  data: (status) => Text(
                    '마지막 확인: ${_formatTime(status.lastChecked)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            systemStatusAsync.when(
              data: (status) => Row(
                children: [
                  Expanded(
                    child: _buildStatusItem(
                      '서버 상태',
                      status.serverHealthy ? '정상' : '오류',
                      status.serverHealthy ? AppColors.accent : AppColors.error,
                      status.serverHealthy ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
                    ),
                  ),
                  Expanded(
                    child: _buildStatusItem(
                      'Firebase',
                      status.firebaseConnected ? '연결됨' : '연결 실패',
                      status.firebaseConnected ? AppColors.accent : AppColors.error,
                      FontAwesomeIcons.database,
                    ),
                  ),
                  Expanded(
                    child: _buildStatusItem(
                      'World Bank API',
                      status.worldBankApiHealthy ? '정상' : '점검 필요',
                      status.worldBankApiHealthy ? AppColors.accent : Colors.orange,
                      FontAwesomeIcons.globe,
                    ),
                  ),
                ],
              ),
              loading: () => const Row(
                children: [
                  Expanded(child: _LoadingStatusItem()),
                  Expanded(child: _LoadingStatusItem()),
                  Expanded(child: _LoadingStatusItem()),
                ],
              ),
              error: (error, _) => Center(
                child: Text(
                  '상태 확인 실패: $error',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatistics(WidgetRef ref) {
    final dataStatsStream = ref.watch(dataStatisticsStreamProvider);

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
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '데이터 통계',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            dataStatsStream.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDataStatItem(
                          '총 지표 수',
                          '${stats.totalIndicators}개',
                          FontAwesomeIcons.chartLine,
                          AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: _buildDataStatItem(
                          '총 국가 수',
                          '${stats.totalCountries}개',
                          FontAwesomeIcons.globe,
                          AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.size16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDataStatItem(
                          '총 데이터 포인트',
                          '${_formatNumber(stats.totalDataPoints)}개',
                          FontAwesomeIcons.database,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildDataStatItem(
                          '마지막 업데이트',
                          _formatDate(stats.lastUpdated),
                          FontAwesomeIcons.clock,
                          AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.size16),
                  // 커버리지 표시
                  _buildCoverageSection(stats),
                ],
              ),
              loading: () => const Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _LoadingDataStatItem()),
                      Expanded(child: _LoadingDataStatItem()),
                    ],
                  ),
                  SizedBox(height: Sizes.size16),
                  Row(
                    children: [
                      Expanded(child: _LoadingDataStatItem()),
                      Expanded(child: _LoadingDataStatItem()),
                    ],
                  ),
                ],
              ),
              error: (error, _) => Center(
                child: Text(
                  '데이터 통계 로딩 실패: $error',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatistics(WidgetRef ref) {
    final userStatsStream = ref.watch(userStatisticsStreamProvider);

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
                  FontAwesomeIcons.users,
                  color: Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '사용자 통계',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            userStatsStream.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildUserStatItem(
                          '총 사용자',
                          '${stats.totalUsers}명',
                          FontAwesomeIcons.userGroup,
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildUserStatItem(
                          '활성 사용자',
                          '${stats.activeUsers}명',
                          FontAwesomeIcons.userCheck,
                          AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.size16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUserStatItem(
                          '관리자',
                          '${stats.adminUsers}명',
                          FontAwesomeIcons.userShield,
                          AppColors.error,
                        ),
                      ),
                      Expanded(
                        child: _buildUserStatItem(
                          '프리미엄',
                          '${stats.premiumUsers}명',
                          FontAwesomeIcons.crown,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _LoadingUserStatItem()),
                      Expanded(child: _LoadingUserStatItem()),
                    ],
                  ),
                  SizedBox(height: Sizes.size16),
                  Row(
                    children: [
                      Expanded(child: _LoadingUserStatItem()),
                      Expanded(child: _LoadingUserStatItem()),
                    ],
                  ),
                ],
              ),
              error: (error, _) => Center(
                child: Text(
                  '사용자 통계 로딩 실패: $error',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(WidgetRef ref) {
    final recentActivityStream = ref.watch(recentActivityStreamProvider);

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
                  FontAwesomeIcons.clockRotateLeft,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '최근 활동',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            recentActivityStream.when(
              data: (activities) => activities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Sizes.size24),
                        child: Text(
                          '최근 활동이 없습니다.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: activities
                          .take(5)
                          .map((activity) => _buildActivityItem(activity))
                          .toList(),
                    ),
              loading: () => Column(
                children: List.generate(3, (index) => const _LoadingActivityItem()),
              ),
              error: (error, _) => Center(
                child: Text(
                  '최근 활동 로딩 실패: $error',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDataStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatItem(String title, String value, IconData icon, Color color) {
    return _buildDataStatItem(title, value, icon, color);
  }

  Widget _buildCoverageSection(DataStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '데이터 커버리지',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildCoverageBar('지표 커버리지', stats.indicatorCoverage),
          const SizedBox(height: 8),
          _buildCoverageBar('국가 커버리지', stats.countryCoverage),
        ],
      ),
    );
  }

  Widget _buildCoverageBar(String label, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 80 ? AppColors.accent : 
            percentage > 50 ? Colors.orange : AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    IconData icon;
    Color color;
    
    switch (activity.actionType) {
      case 'dataCollection':
        icon = FontAwesomeIcons.download;
        color = AppColors.primary;
        break;
      case 'userManagement':
        icon = FontAwesomeIcons.userGear;
        color = Colors.purple;
        break;
      case 'systemMaintenance':
        icon = FontAwesomeIcons.wrench;
        color = Colors.orange;
        break;
      default:
        icon = FontAwesomeIcons.gear;
        color = AppColors.textSecondary;
    }

    Color statusColor;
    switch (activity.status) {
      case 'completed':
        statusColor = AppColors.accent;
        break;
      case 'failed':
        statusColor = AppColors.error;
        break;
      case 'inProgress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FaIcon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      activity.userEmail,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      ' • ${_formatTime(activity.timestamp)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(activity.status),
              style: AppTypography.bodySmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '완료';
      case 'failed':
        return '실패';
      case 'inProgress':
        return '진행중';
      case 'started':
        return '시작됨';
      default:
        return status;
    }
  }
}

// 로딩 위젯들
class _LoadingStatusItem extends StatelessWidget {
  const _LoadingStatusItem();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}

class _LoadingDataStatItem extends StatelessWidget {
  const _LoadingDataStatItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _LoadingUserStatItem extends StatelessWidget {
  const _LoadingUserStatItem();

  @override
  Widget build(BuildContext context) {
    return const _LoadingDataStatItem();
  }
}

class _LoadingActivityItem extends StatelessWidget {
  const _LoadingActivityItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}