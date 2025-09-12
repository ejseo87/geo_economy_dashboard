import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/gaps.dart';
import '../services/data_migration_service.dart';

/// PRD v1.1 데이터 마이그레이션 관리 탭
class AdminMigrationTab extends ConsumerStatefulWidget {
  const AdminMigrationTab({super.key});

  @override
  ConsumerState<AdminMigrationTab> createState() => _AdminMigrationTabState();
}

class _AdminMigrationTabState extends ConsumerState<AdminMigrationTab> {
  final DataMigrationService _migrationService = DataMigrationService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _lastResult;
  final List<String> _migrationLogs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRD v1.1 데이터 마이그레이션'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            Gaps.v24,
            _buildMigrationActions(),
            Gaps.v24,
            _buildStatusSection(),
            if (_lastResult != null) ...[
              Gaps.v24,
              _buildResultsSection(),
            ],
            if (_migrationLogs.isNotEmpty) ...[
              Gaps.v24,
              _buildLogsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                Gaps.h8,
                Text(
                  '마이그레이션 개요',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Gaps.v16,
            _buildInfoRow('현재 구조', 'Old Version (단일 컬렉션)', Colors.orange),
            Gaps.v8,
            _buildInfoRow('목표 구조', 'PRD v1.1 (이중 정규화)', Colors.green),
            Gaps.v8,
            _buildInfoRow('마이그레이션 방식', '점진적 이전 (데이터 보존)', Colors.blue),
            Gaps.v16,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber[700]),
                  Gaps.h8,
                  Expanded(
                    child: Text(
                      '마이그레이션 전 반드시 데이터 백업을 생성하고 Dry Run을 실행하세요.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.amber[700],
                      ),
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

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Gaps.h8,
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildMigrationActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '마이그레이션 작업',
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Gaps.v16,
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  '검증 실행',
                  '현재 데이터 구조 검증',
                  Icons.fact_check,
                  Colors.blue,
                  _isLoading ? null : _runValidation,
                ),
                _buildActionButton(
                  'Dry Run',
                  '실제 변경 없이 마이그레이션 테스트',
                  Icons.preview,
                  Colors.orange,
                  _isLoading ? null : _runDryRun,
                ),
                _buildActionButton(
                  '실제 마이그레이션',
                  'PRD v1.1 구조로 데이터 이전',
                  Icons.play_arrow,
                  Colors.green,
                  _isLoading ? null : _runActualMigration,
                ),
                _buildActionButton(
                  '백업 & 정리',
                  '기존 데이터 백업 및 정리',
                  Icons.cleaning_services,
                  Colors.red,
                  _isLoading ? null : _runCleanup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            Gaps.v8,
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Gaps.v4,
            Text(
              description,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
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
              '상태',
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
                    '처리 중...',
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
              '최근 실행 결과',
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
              _buildResultGrid(result),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultGrid(Map<String, dynamic> result) {
    final items = <Widget>[];
    
    if (result.containsKey('migrated')) {
      final migrated = result['migrated'] as Map<String, dynamic>;
      items.addAll([
        _buildResultItem('Countries', '${migrated['countries']}', Icons.flag),
        _buildResultItem('Indicators', '${migrated['indicators']}', Icons.analytics),
        _buildResultItem('Series', '${migrated['series']}', Icons.timeline),
      ]);
    }
    
    if (result.containsKey('skipped')) {
      items.add(_buildResultItem('Skipped', '${result['skipped']}', Icons.skip_next));
    }
    
    if (result.containsKey('errors')) {
      final errors = result['errors'] as List;
      items.add(_buildResultItem('Errors', '${errors.length}', Icons.error));
    }
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items,
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          Gaps.v4,
          Text(value, style: AppTypography.heading3.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTypography.bodySmall),
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
                  '마이그레이션 로그',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _migrationLogs.clear()),
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
                  _migrationLogs.join('\n'),
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

  Future<void> _runValidation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '데이터 구조 검증 중...';
    });

    try {
      final result = await _migrationService.validateMigration();
      setState(() {
        _lastResult = result;
        _statusMessage = result['isValid'] == true 
            ? '✅ 검증 완료: 데이터 구조 정상'
            : '⚠️ 검증 실패: 데이터 불일치 발견';
      });
      
      _addLog('Validation completed: ${result['isValid'] ? 'PASSED' : 'FAILED'}');
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 검증 실패: $e';
      });
      _addLog('Validation error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runDryRun() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Dry Run 실행 중...';
    });

    try {
      final result = await _migrationService.migrateToV11(
        dryRun: true,
        onProgress: (message) {
          setState(() => _statusMessage = message);
          _addLog(message);
        },
      );
      
      setState(() {
        _lastResult = result;
        _statusMessage = '✅ Dry Run 완료: ${result['migrated']['indicators']}개 지표 처리 준비';
      });
      
    } catch (e) {
      setState(() => _statusMessage = '❌ Dry Run 실패: $e');
      _addLog('Dry Run error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runActualMigration() async {
    // 확인 대화상자
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('실제 마이그레이션 실행'),
        content: const Text(
          '실제 데이터 마이그레이션을 실행하시겠습니까?\n\n'
          '이 작업은 Firestore에 새로운 데이터 구조를 생성합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('실행', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '실제 마이그레이션 실행 중...';
    });

    try {
      final result = await _migrationService.migrateToV11(
        dryRun: false,
        onProgress: (message) {
          setState(() => _statusMessage = message);
          _addLog(message);
        },
      );
      
      setState(() {
        _lastResult = result;
        _statusMessage = '🎉 마이그레이션 완료: ${result['migrated']['indicators']}개 지표 이전됨';
      });
      
    } catch (e) {
      setState(() => _statusMessage = '❌ 마이그레이션 실패: $e');
      _addLog('Migration error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runCleanup() async {
    // 확인 대화상자
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 정리'),
        content: const Text(
          '기존 데이터를 백업하고 정리하시겠습니까?\n\n'
          '⚠️ 이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('실행', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '데이터 백업 및 정리 중...';
    });

    try {
      final result = await _migrationService.cleanupOldData(
        createBackup: true,
        deleteOld: true,
      );
      
      setState(() {
        _lastResult = result;
        _statusMessage = '✅ 정리 완료: ${result['backedUpDocuments']}개 백업, ${result['deletedDocuments']}개 삭제';
      });
      
    } catch (e) {
      setState(() => _statusMessage = '❌ 정리 실패: $e');
      _addLog('Cleanup error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _migrationLogs.add('[$timestamp] $message');
      if (_migrationLogs.length > 50) {
        _migrationLogs.removeAt(0);
      }
    });
  }
}