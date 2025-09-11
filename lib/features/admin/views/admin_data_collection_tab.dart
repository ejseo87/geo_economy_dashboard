import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';

class AdminDataCollectionTab extends ConsumerStatefulWidget {
  const AdminDataCollectionTab({super.key});

  @override
  ConsumerState<AdminDataCollectionTab> createState() => _AdminDataCollectionTabState();
}

class _AdminDataCollectionTabState extends ConsumerState<AdminDataCollectionTab> {
  bool _isCollecting = false;
  double _progress = 0.0;
  String _currentTask = '';
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sizes.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCollectionControls(),
          const SizedBox(height: Sizes.size24),
          _buildProgressSection(),
          const SizedBox(height: Sizes.size24),
          _buildDataStatus(),
          const SizedBox(height: Sizes.size24),
          _buildCollectionLogs(),
        ],
      ),
    );
  }

  Widget _buildCollectionControls() {
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
            ),
            const SizedBox(height: Sizes.size16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCollecting ? null : _startFullCollection,
                    icon: _isCollecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.play, size: 16),
                    label: Text(_isCollecting ? '수집 중...' : '전체 데이터 수집'),
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
                    onPressed: _isCollecting ? null : _startIncrementalCollection,
                    icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
                    label: const Text('증분 업데이트'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_isCollecting) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _stopCollection,
                icon: const FaIcon(FontAwesomeIcons.stop, size: 16),
                label: const Text('수집 중단'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
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
                  FontAwesomeIcons.chartLine,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '수집 진행률',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.outline.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentTask.isEmpty ? '대기 중...' : _currentTask,
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatus() {
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
                  FontAwesomeIcons.database,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '데이터 현황',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final indicators = [
                  'GDP 실질성장률',
                  '실업률',
                  'CPI 인플레이션',
                  '경상수지',
                  '1인당 GDP(PPP)',
                ];
                return _buildIndicatorStatus(indicators[index], '38/38개국', '완료');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionLogs() {
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
                  FontAwesomeIcons.fileLines,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '수집 로그',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearLogs,
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 14),
                  label: const Text('지우기'),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        '로그가 없습니다',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.green,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorStatus(String indicator, String countries, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              indicator,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              countries,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: AppTypography.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startFullCollection() {
    setState(() {
      _isCollecting = true;
      _progress = 0.0;
      _currentTask = '전체 데이터 수집을 시작합니다...';
      _logs.clear();
    });

    _addLog('[INFO] 전체 데이터 수집을 시작합니다.');
    _simulateDataCollection();
  }

  void _startIncrementalCollection() {
    setState(() {
      _isCollecting = true;
      _progress = 0.0;
      _currentTask = '증분 업데이트를 시작합니다...';
      _logs.clear();
    });

    _addLog('[INFO] 증분 업데이트를 시작합니다.');
    _simulateDataCollection(incremental: true);
  }

  void _stopCollection() {
    setState(() {
      _isCollecting = false;
      _currentTask = '수집이 중단되었습니다.';
    });
    _addLog('[WARN] 사용자에 의해 수집이 중단되었습니다.');
  }

  void _simulateDataCollection({bool incremental = false}) async {
    final tasks = incremental
        ? ['최신 데이터 확인', '변경된 데이터 수집', '캐시 업데이트']
        : [
            'World Bank API 연결 확인',
            'OECD 국가 목록 가져오기',
            'GDP 데이터 수집',
            '실업률 데이터 수집',
            '인플레이션 데이터 수집',
            'Firebase 저장',
            '캐시 갱신'
          ];

    for (int i = 0; i < tasks.length; i++) {
      if (!_isCollecting) break;

      setState(() {
        _currentTask = tasks[i];
        _progress = (i + 1) / tasks.length;
      });

      _addLog('[INFO] ${tasks[i]}...');
      
      await Future.delayed(const Duration(seconds: 2));
      
      _addLog('[SUCCESS] ${tasks[i]} 완료');
    }

    if (_isCollecting) {
      setState(() {
        _isCollecting = false;
        _currentTask = '수집이 완료되었습니다.';
      });
      _addLog('[INFO] 모든 데이터 수집이 완료되었습니다.');
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now();
    final formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    
    setState(() {
      _logs.add('[$formattedTime] $message');
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }
}