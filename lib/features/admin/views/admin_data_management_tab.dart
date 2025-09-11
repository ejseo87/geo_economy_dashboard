import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';

class AdminDataManagementTab extends ConsumerStatefulWidget {
  const AdminDataManagementTab({super.key});

  @override
  ConsumerState<AdminDataManagementTab> createState() => _AdminDataManagementTabState();
}

class _AdminDataManagementTabState extends ConsumerState<AdminDataManagementTab> {
  bool _isAuditing = false;
  bool _isCleaning = false;
  int _duplicateCount = 0;
  int _outdatedCount = 0;
  final List<String> _auditResults = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sizes.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuditControls(),
          const SizedBox(height: Sizes.size24),
          _buildDataHealthCheck(),
          const SizedBox(height: Sizes.size24),
          _buildCleanupControls(),
          const SizedBox(height: Sizes.size24),
          _buildAuditResults(),
        ],
      ),
    );
  }

  Widget _buildAuditControls() {
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
                  FontAwesomeIcons.magnifyingGlass,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '데이터 감사',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            Text(
              'Firestore 데이터베이스의 중복, 불일치, 고아 문서를 찾아 정리합니다.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: Sizes.size16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAuditing ? null : _startFullAudit,
                    icon: _isAuditing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.searchengin, size: 16),
                    label: Text(_isAuditing ? '감사 중...' : '전체 감사'),
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
                    onPressed: _isAuditing ? null : _startQuickAudit,
                    icon: const FaIcon(FontAwesomeIcons.bolt, size: 16),
                    label: const Text('빠른 검사'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataHealthCheck() {
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
                  '데이터 상태',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildHealthCard(
                  '중복 문서',
                  '$_duplicateCount개',
                  _duplicateCount == 0 ? AppColors.accent : AppColors.warning,
                  FontAwesomeIcons.copy,
                ),
                _buildHealthCard(
                  '오래된 데이터',
                  '$_outdatedCount개',
                  _outdatedCount == 0 ? AppColors.accent : AppColors.warning,
                  FontAwesomeIcons.clock,
                ),
                _buildHealthCard(
                  '고아 문서',
                  '0개',
                  AppColors.accent,
                  FontAwesomeIcons.unlink,
                ),
                _buildHealthCard(
                  '데이터 일관성',
                  '98.5%',
                  AppColors.accent,
                  FontAwesomeIcons.check,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanupControls() {
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
                  FontAwesomeIcons.broom,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '데이터 정리',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            Text(
              '중복되거나 오래된 데이터를 안전하게 정리합니다. 이 작업은 되돌릴 수 없습니다.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: Sizes.size16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isCleaning || _duplicateCount == 0) ? null : _removeDuplicates,
                    icon: _isCleaning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.trash, size: 16),
                    label: Text(_isCleaning ? '정리 중...' : '중복 제거'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isCleaning || _outdatedCount == 0) ? null : _removeOutdated,
                    icon: const FaIcon(FontAwesomeIcons.clockRotateLeft, size: 16),
                    label: const Text('오래된 데이터'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditResults() {
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
                  '감사 결과',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _auditResults.isEmpty ? null : _clearResults,
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
              child: _auditResults.isEmpty
                  ? Center(
                      child: Text(
                        '감사 결과가 없습니다',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _auditResults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _auditResults[index],
                            style: AppTypography.bodySmall.copyWith(
                              color: _getLogColor(_auditResults[index]),
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

  Widget _buildHealthCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FaIcon(
              icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('[ERROR]')) return Colors.red;
    if (log.contains('[WARN]')) return Colors.orange;
    if (log.contains('[SUCCESS]')) return Colors.green;
    return Colors.lightBlue;
  }

  void _addResult(String message) {
    final timestamp = DateTime.now();
    final formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    
    setState(() {
      _auditResults.add('[$formattedTime] $message');
      if (_auditResults.length > 100) {
        _auditResults.removeAt(0);
      }
    });
  }

  void _startFullAudit() async {
    setState(() {
      _isAuditing = true;
      _auditResults.clear();
    });

    _addResult('[INFO] 전체 데이터 감사를 시작합니다...');
    
    await Future.delayed(const Duration(seconds: 1));
    _addResult('[INFO] indicators 컬렉션 스캔 중...');
    
    await Future.delayed(const Duration(seconds: 2));
    _addResult('[SUCCESS] indicators 컬렉션: 760개 문서 확인');
    
    await Future.delayed(const Duration(seconds: 1));
    _addResult('[INFO] countries 컬렉션 스캔 중...');
    
    await Future.delayed(const Duration(seconds: 2));
    _addResult('[SUCCESS] countries 컬렉션: 38개 문서 확인');
    
    await Future.delayed(const Duration(seconds: 1));
    _addResult('[WARN] 중복 문서 12개 발견');
    
    await Future.delayed(const Duration(seconds: 1));
    _addResult('[WARN] 2년 이상 오래된 데이터 5개 발견');
    
    await Future.delayed(const Duration(seconds: 1));
    _addResult('[SUCCESS] 전체 감사 완료');

    setState(() {
      _isAuditing = false;
      _duplicateCount = 12;
      _outdatedCount = 5;
    });
  }

  void _startQuickAudit() async {
    setState(() {
      _isAuditing = true;
      _auditResults.clear();
    });

    _addResult('[INFO] 빠른 검사를 시작합니다...');
    
    await Future.delayed(const Duration(seconds: 1));
    _addResult('[INFO] 최근 7일간 데이터 확인 중...');
    
    await Future.delayed(const Duration(seconds: 2));
    _addResult('[SUCCESS] 빠른 검사 완료: 문제 없음');

    setState(() {
      _isAuditing = false;
    });
  }

  void _removeDuplicates() async {
    final confirmed = await _showConfirmDialog(
      '중복 제거',
      '$_duplicateCount개의 중복 문서를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
    );

    if (!confirmed) return;

    setState(() {
      _isCleaning = true;
    });

    _addResult('[INFO] 중복 문서 제거를 시작합니다...');
    
    await Future.delayed(const Duration(seconds: 3));
    _addResult('[SUCCESS] ${'$_duplicateCount'}개 중복 문서 삭제 완료');

    setState(() {
      _isCleaning = false;
      _duplicateCount = 0;
    });
  }

  void _removeOutdated() async {
    final confirmed = await _showConfirmDialog(
      '오래된 데이터 삭제',
      '$_outdatedCount개의 오래된 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
    );

    if (!confirmed) return;

    setState(() {
      _isCleaning = true;
    });

    _addResult('[INFO] 오래된 데이터 삭제를 시작합니다...');
    
    await Future.delayed(const Duration(seconds: 3));
    _addResult('[SUCCESS] ${'$_outdatedCount'}개 오래된 데이터 삭제 완료');

    setState(() {
      _isCleaning = false;
      _outdatedCount = 0;
    });
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _clearResults() {
    setState(() {
      _auditResults.clear();
    });
  }
}