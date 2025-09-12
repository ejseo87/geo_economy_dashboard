import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/gaps.dart';
import '../services/firestore_reset_service.dart';

/// Firestore 완전 재구축 관리 탭
class AdminResetTab extends ConsumerStatefulWidget {
  const AdminResetTab({super.key});

  @override
  ConsumerState<AdminResetTab> createState() => _AdminResetTabState();
}

class _AdminResetTabState extends ConsumerState<AdminResetTab> {
  final FirestoreResetService _resetService = FirestoreResetService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _dataOverview;
  Map<String, dynamic>? _lastResult;
  final List<String> _resetLogs = [];

  @override
  void initState() {
    super.initState();
    _loadDataOverview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore 완전 재구축'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningSection(),
            Gaps.v24,
            _buildDataOverviewSection(),
            Gaps.v24,
            _buildResetActions(),
            Gaps.v24,
            _buildStatusSection(),
            if (_lastResult != null) ...[
              Gaps.v24,
              _buildResultsSection(),
            ],
            if (_resetLogs.isNotEmpty) ...[
              Gaps.v24,
              _buildLogsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarningSection() {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 32),
                Gaps.h12,
                Text(
                  '⚠️ 위험: 완전 재구축 모드',
                  style: AppTypography.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            Gaps.v16,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이 작업은 되돌릴 수 없습니다!',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Gaps.v8,
                  Text(
                    '• 모든 기존 지표 데이터가 삭제됩니다\n'
                    '• World Bank API에서 데이터를 다시 수집해야 합니다\n'
                    '• 사용자 데이터는 선택적으로 보존 가능합니다\n'
                    '• 백업 생성을 강력히 권장합니다',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.red[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataOverviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppColors.primary),
                Gaps.h8,
                Text(
                  '현재 데이터 현황',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isLoading ? null : _loadDataOverview,
                  icon: const Icon(Icons.refresh),
                  label: const Text('새로고침'),
                ),
              ],
            ),
            Gaps.v16,
            if (_dataOverview != null) ...[
              _buildDataOverviewGrid(_dataOverview!),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataOverviewGrid(Map<String, dynamic> overview) {
    final collections = overview['collections'] as Map<String, dynamic>? ?? {};
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ...collections.entries.map((entry) => 
          _buildDataCard(entry.key, entry.value.toString(), _getCollectionIcon(entry.key), _getCollectionStatus(entry.key))
        ),
        _buildDataCard('Total', '${overview['totalDocuments']}', Icons.storage, 'info'),
      ],
    );
  }

  Widget _buildDataCard(String label, String count, IconData icon, String status) {
    Color statusColor;
    switch (status) {
      case 'delete':
        statusColor = Colors.red;
        break;
      case 'preserve':
        statusColor = Colors.green;
        break;
      case 'info':
        statusColor = AppColors.primary;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: statusColor, size: 32),
          Gaps.v8,
          Text(
            count,
            style: AppTypography.heading2.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: statusColor,
            ),
          ),
          if (status == 'delete') ...[
            Gaps.v4,
            Text(
              '🗑️ 삭제',
              style: AppTypography.caption.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else if (status == 'preserve') ...[
            Gaps.v4,
            Text(
              '💾 보존',
              style: AppTypography.caption.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCollectionIcon(String collection) {
    switch (collection) {
      case 'indicator_data':
        return Icons.analytics;
      case 'oecd_stats':
        return Icons.bar_chart;
      case 'oecd_countries':
        return Icons.flag;
      case 'users':
        return Icons.people;
      default:
        return Icons.storage;
    }
  }

  String _getCollectionStatus(String collection) {
    switch (collection) {
      case 'indicator_data':
      case 'oecd_stats':
      case 'oecd_countries':
        return 'delete';
      case 'users':
        return 'preserve';
      default:
        return 'info';
    }
  }

  Widget _buildResetActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '재구축 작업',
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Gaps.v16,
            Column(
              children: [
                _buildResetActionTile(
                  '1단계: 백업 생성 + 데이터 삭제',
                  '기존 데이터를 백업하고 Old 구조 삭제',
                  Icons.delete_forever,
                  Colors.red,
                  _isLoading ? null : _executeReset,
                  isDestructive: true,
                ),
                Gaps.v12,
                _buildResetActionTile(
                  '2단계: PRD v1.1 구조 초기화',
                  '새로운 컬렉션 구조 및 메타데이터 생성',
                  Icons.architecture,
                  Colors.blue,
                  _isLoading ? null : _initializePRDStructure,
                ),
                Gaps.v12,
                _buildResetActionTile(
                  '3단계: 데이터 재수집',
                  'World Bank API에서 Core 20 지표 수집',
                  Icons.download,
                  Colors.green,
                  _isLoading ? null : _collectNewData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetActionTile(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? Colors.red : color,
            foregroundColor: Colors.white,
          ),
          child: Text(isDestructive ? '위험' : '실행'),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    if (!_isLoading && _statusMessage.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '실행 상태',
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Gaps.v16,
            if (_isLoading) ...[
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  Gaps.h12,
                  Text(
                    '작업 실행 중...',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
              Gaps.v12,
            ],
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final result = _lastResult!;
    final hasError = result.containsKey('error');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '실행 결과',
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Gaps.v16,
            if (hasError) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: ${result['error']}',
                  style: AppTypography.bodySmall.copyWith(color: Colors.red),
                ),
              ),
            ] else ...[
              _buildResultDetails(result),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultDetails(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.containsKey('totalDeleted')) ...[
          _buildResultRow('총 삭제된 문서', '${result['totalDeleted']}개'),
        ],
        if (result.containsKey('deletedCollections')) ...[
          const Text('삭제된 컬렉션:', style: TextStyle(fontWeight: FontWeight.bold)),
          Gaps.v8,
          ...(result['deletedCollections'] as Map<String, dynamic>).entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text('• ${entry.key}: ${entry.value}개'),
            ),
          ),
        ],
        if (result.containsKey('preservedCollections')) ...[
          Gaps.v8,
          const Text('보존된 컬렉션:', style: TextStyle(fontWeight: FontWeight.bold)),
          Gaps.v8,
          ...(result['preservedCollections'] as Map<String, dynamic>).entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text('• ${entry.key}: ${entry.value}개 (보존됨)', 
                style: const TextStyle(color: Colors.green)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실행 로그',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _resetLogs.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            Gaps.v16,
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _resetLogs.join('\n'),
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDataOverview() async {
    try {
      final overview = await _resetService.getDataOverview();
      setState(() {
        _dataOverview = overview;
      });
    } catch (e) {
      _addLog('데이터 현황 로드 실패: $e');
    }
  }

  Future<void> _executeReset() async {
    // 경고 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 위험한 작업'),
        content: const Text(
          '정말로 모든 기존 데이터를 삭제하시겠습니까?\n\n'
          '이 작업은 되돌릴 수 없습니다!\n'
          '백업이 생성되지만 데이터 복구는 복잡할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제 실행', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Firestore 데이터 삭제 시작...';
    });

    try {
      final result = await _resetService.resetFirestoreData(
        preserveUsers: true,
        createBackup: true,
        onProgress: (message) {
          setState(() => _statusMessage = message);
          _addLog(message);
        },
      );
      
      setState(() {
        _lastResult = result;
        _statusMessage = result.containsKey('error') 
            ? '❌ 삭제 실패: ${result['error']}'
            : '✅ 삭제 완료: ${result['totalDeleted']}개 문서 삭제됨';
      });
      
      // 데이터 현황 새로고침
      await _loadDataOverview();
      
    } catch (e) {
      setState(() => _statusMessage = '❌ 삭제 실패: $e');
      _addLog('Reset error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializePRDStructure() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'PRD v1.1 구조 초기화 중...';
    });

    try {
      final result = await _resetService.initializePRDv11Structure(
        onProgress: (message) {
          setState(() => _statusMessage = message);
          _addLog(message);
        },
      );
      
      setState(() {
        _lastResult = result;
        _statusMessage = result.containsKey('error')
            ? '❌ 초기화 실패: ${result['error']}'
            : '✅ PRD v1.1 구조 초기화 완료';
      });
      
    } catch (e) {
      setState(() => _statusMessage = '❌ 초기화 실패: $e');
      _addLog('Structure init error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _collectNewData() async {
    setState(() {
      _statusMessage = '📡 World Bank API 데이터 수집은 별도 탭에서 실행하세요';
    });
    _addLog('데이터 수집은 Admin Data Management 탭에서 실행 가능');
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _resetLogs.add('[$timestamp] $message');
      if (_resetLogs.length > 50) {
        _resetLogs.removeAt(0);
      }
    });
  }
}