import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../providers/automated_cleanup_provider.dart';
import '../services/automated_cleanup_service.dart';

class AutomatedCleanupCard extends ConsumerStatefulWidget {
  const AutomatedCleanupCard({super.key});

  @override
  ConsumerState<AutomatedCleanupCard> createState() => _AutomatedCleanupCardState();
}

class _AutomatedCleanupCardState extends ConsumerState<AutomatedCleanupCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: Sizes.size16),
            _buildAutoCleanupToggle(),
            const SizedBox(height: Sizes.size16),
            _buildCleanupSettings(),
            const SizedBox(height: Sizes.size16),
            _buildManualCleanupControls(),
            const SizedBox(height: Sizes.size16),
            _buildProgressTracker(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const FaIcon(
          FontAwesomeIcons.broom,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '자동화된 데이터 정리',
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Consumer(
          builder: (context, ref, child) {
            final isEnabled = ref.watch(autoCleanupEnabledProvider);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isEnabled ? AppColors.accent.withOpacity(0.1) : AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isEnabled ? AppColors.accent : AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isEnabled ? '활성화' : '비활성화',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isEnabled ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAutoCleanupToggle() {
    return Consumer(
      builder: (context, ref, child) {
        final isEnabled = ref.watch(autoCleanupEnabledProvider);
        final schedule = ref.watch(cleanupScheduleSettingsProvider);

        return Container(
          padding: const EdgeInsets.all(16),
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
                  Text(
                    '자동 정리',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      ref.read(autoCleanupEnabledProvider.notifier).toggle();
                    },
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
              if (isEnabled) ...[
                const SizedBox(height: 12),
                Text(
                  '스케줄',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CleanupSchedule>(
                  value: schedule,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: CleanupSchedule.values.map((schedule) {
                    return DropdownMenuItem(
                      value: schedule,
                      child: Text(_getScheduleDisplayName(schedule)),
                    );
                  }).toList(),
                  onChanged: (schedule) {
                    if (schedule != null) {
                      ref.read(cleanupScheduleSettingsProvider.notifier).updateSchedule(schedule);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCleanupSettings() {
    return Consumer(
      builder: (context, ref, child) {
        final policy = ref.watch(cleanupPolicySettingsProvider);

        return ExpansionTile(
          leading: const FaIcon(
            FontAwesomeIcons.gear,
            size: 16,
            color: AppColors.textSecondary,
          ),
          title: Text(
            '정리 설정',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildPolicyPresets(),
                  const SizedBox(height: 16),
                  _buildPolicyToggle('중복 데이터 정리', policy.cleanupDuplicates, (value) {
                    ref.read(cleanupPolicySettingsProvider.notifier).updateCleanupDuplicates(value);
                  }),
                  _buildPolicyToggle('고아 문서 정리', policy.cleanupOrphans, (value) {
                    ref.read(cleanupPolicySettingsProvider.notifier).updateCleanupOrphans(value);
                  }),
                  _buildPolicyToggle('오래된 데이터 정리', policy.cleanupOldData, (value) {
                    ref.read(cleanupPolicySettingsProvider.notifier).updateCleanupOldData(value);
                  }),
                  _buildPolicyToggle('스토리지 최적화', policy.optimizeStorage, (value) {
                    ref.read(cleanupPolicySettingsProvider.notifier).updateOptimizeStorage(value);
                  }),
                  const SizedBox(height: 16),
                  _buildBatchSizeSlider(policy.batchSize),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolicyPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정책 프리셋',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(cleanupPolicySettingsProvider.notifier).setConservativePolicy();
                },
                child: const Text('보수적'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(cleanupPolicySettingsProvider.notifier).setDefaultPolicy();
                },
                child: const Text('기본'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(cleanupPolicySettingsProvider.notifier).setAggressivePolicy();
                },
                child: const Text('적극적'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPolicyToggle(String title, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodySmall,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildBatchSizeSlider(int batchSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '배치 크기',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$batchSize개',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: batchSize.toDouble(),
          min: 10,
          max: 200,
          divisions: 19,
          onChanged: (value) {
            ref.read(cleanupPolicySettingsProvider.notifier).updateBatchSize(value.round());
          },
          activeColor: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildManualCleanupControls() {
    return Consumer(
      builder: (context, ref, child) {
        final executionState = ref.watch(manualCleanupExecutionProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '수동 정리',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (executionState.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: executionState.isLoading ? null : () {
                      ref.read(manualCleanupExecutionProvider.notifier).executeCleanup();
                    },
                    icon: const FaIcon(FontAwesomeIcons.play, size: 16),
                    label: Text(executionState.isLoading ? '정리 중...' : '전체 정리'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: executionState.isLoading ? null : () {
                      _showSpecificCleanupDialog();
                    },
                    icon: const FaIcon(FontAwesomeIcons.listCheck, size: 16),
                    label: const Text('선택 정리'),
                  ),
                ),
              ],
            ),
            if (executionState.hasValue && executionState.value != null) ...[
              const SizedBox(height: 12),
              _buildCleanupResult(executionState.value!),
            ],
            if (executionState.hasError) ...[
              const SizedBox(height: 12),
              _buildErrorDisplay(executionState.error.toString()),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProgressTracker() {
    return Consumer(
      builder: (context, ref, child) {
        final progressAsyncValue = ref.watch(cleanupProgressStreamProvider);

        return progressAsyncValue.when(
          data: (progress) => _buildProgressDisplay(progress),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildProgressDisplay(CleanupProgress progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: progress.hasError ? AppColors.error.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                progress.hasError ? FontAwesomeIcons.triangleExclamation : FontAwesomeIcons.gear,
                size: 16,
                color: progress.hasError ? AppColors.error : AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.message,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!progress.hasError) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress.progress * 100).toStringAsFixed(0)}% 완료',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCleanupResult(CleanupResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success ? AppColors.accent.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.success ? AppColors.accent : AppColors.error,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                result.success ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.triangleExclamation,
                size: 16,
                color: result.success ? AppColors.accent : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                result.success ? '정리 완료' : '정리 실패',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: result.success ? AppColors.accent : AppColors.error,
                ),
              ),
              const Spacer(),
              Text(
                '${result.duration.inSeconds}초',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (result.success) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultStat('중복', result.duplicatesCleaned, AppColors.warning),
                _buildResultStat('고아', result.orphansCleaned, AppColors.error),
                _buildResultStat('오래된', result.oldDataCleaned, AppColors.textSecondary),
                _buildResultStat('총합', result.totalCleaned, AppColors.accent),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultStat(String label, int count, Color color) {
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

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSpecificCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택적 정리'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CleanupType.values.map((type) {
            return CheckboxListTile(
              title: Text(_getCleanupTypeDisplayName(type)),
              value: true, // 기본값으로 모두 선택
              onChanged: (value) {
                // TODO: 선택 상태 관리
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 선택된 항목들로 정리 실행
              ref.read(manualCleanupExecutionProvider.notifier).executeCleanup();
            },
            child: const Text('정리'),
          ),
        ],
      ),
    );
  }

  String _getScheduleDisplayName(CleanupSchedule schedule) {
    switch (schedule) {
      case CleanupSchedule.hourly:
        return '매시간';
      case CleanupSchedule.daily:
        return '매일';
      case CleanupSchedule.weekly:
        return '매주';
      case CleanupSchedule.monthly:
        return '매월';
    }
  }

  String _getCleanupTypeDisplayName(CleanupType type) {
    switch (type) {
      case CleanupType.audit:
        return '감사 실행';
      case CleanupType.duplicates:
        return '중복 데이터';
      case CleanupType.orphans:
        return '고아 문서';
      case CleanupType.oldData:
        return '오래된 데이터';
      case CleanupType.optimization:
        return '최적화';
    }
  }
}