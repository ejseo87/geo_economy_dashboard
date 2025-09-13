import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../view_models/data_collection_view_model.dart';

class AdminDataCollectionTab extends ConsumerWidget {
  const AdminDataCollectionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataCollectionState = ref.watch(dataCollectionNotifierProvider);
    final dataCollectionNotifier = ref.read(dataCollectionNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          _buildHeader(),
          const SizedBox(height: Sizes.size24),

          // 데이터 수집 제어
          _buildDataCollectionControls(
            dataCollectionState, 
            dataCollectionNotifier
          ),
          const SizedBox(height: Sizes.size24),

          // 진행률 표시
          if (dataCollectionState.isCollecting || dataCollectionState.progress > 0)
            _buildProgressSection(dataCollectionState),
          
          if (dataCollectionState.isCollecting || dataCollectionState.progress > 0)
            const SizedBox(height: Sizes.size24),

          // 로그 및 결과
          Expanded(
            child: _buildLogSection(dataCollectionState, dataCollectionNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const FaIcon(
          FontAwesomeIcons.download,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '데이터 수집 제어',
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDataCollectionControls(
    DataCollectionState state,
    DataCollectionNotifier notifier,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isCollecting ? null : notifier.startFullDataCollection,
            icon: state.isCollecting && state.currentType == DataCollectionType.full
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const FaIcon(FontAwesomeIcons.play, size: 16),
            label: Text(
              state.isCollecting && state.currentType == DataCollectionType.full
                  ? '수집 중...'
                  : '전체 데이터 수집'
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isCollecting ? null : notifier.startTestDataCollection,
            icon: state.isCollecting && state.currentType == DataCollectionType.test
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const FaIcon(FontAwesomeIcons.vial, size: 16),
            label: const Text('테스트 수집'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(DataCollectionState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '진행 상황',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(state.progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (state.currentTask.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              state.currentTask,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (state.startTime != null) ...[
            const SizedBox(height: 8),
            Text(
              '시작 시간: ${state.startTime!.toLocal().toString().split('.')[0]}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogSection(
    DataCollectionState state,
    DataCollectionNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.terminal,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '수집 로그',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (state.logs.isNotEmpty)
                  TextButton.icon(
                    onPressed: notifier.clearLogs,
                    icon: const FaIcon(
                      FontAwesomeIcons.trash,
                      color: Colors.white70,
                      size: 12,
                    ),
                    label: Text(
                      '지우기',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
          // 로그 내용
          Expanded(
            child: state.logs.isEmpty
                ? Center(
                    child: Text(
                      '로그가 없습니다.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.logs.length,
                    itemBuilder: (context, index) {
                      final log = state.logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.grey[500],
                                fontFamily: 'monospace',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                log,
                                style: AppTypography.bodySmall.copyWith(
                                  color: _getLogColor(log),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // 결과 요약
          if (state.result != null) _buildResultSummary(state.result!),
          if (state.error != null) _buildErrorSummary(state.error!),
        ],
      ),
    );
  }

  Widget _buildResultSummary(Map<String, dynamic> result) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ 수집 완료',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '총 처리: ${result['totalProcessed']}개 지표\n'
            '성공: ${result['successfullyProcessed']}개\n'
            '실패: ${(result['errors'] as List).length}개',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white70,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSummary(String error) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❌ 수집 실패',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white70,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('오류') || log.contains('실패') || log.contains('Error')) {
      return AppColors.error;
    } else if (log.contains('완료') || log.contains('성공') || log.contains('Success')) {
      return AppColors.accent;
    } else if (log.contains('시작') || log.contains('수집')) {
      return AppColors.primary;
    } else {
      return Colors.white70;
    }
  }
}