import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../services/admin_auth_service.dart';
import '../services/worldbank_data_collector.dart';
import '../services/firestore_data_manager.dart';
import '../models/admin_user.dart';
import 'package:go_router/go_router.dart';

/// 관리자 대시보드 화면
class AdminDashboardScreen extends ConsumerStatefulWidget {
  static const String routeName = 'admin_dashboard';

  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dataCollector = WorldBankDataCollector();
  final _dataManager = FirestoreDataManager();
  
  String _currentOperation = '';
  bool _isOperating = false;
  Map<String, dynamic>? _lastOperationResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkAuthStatus() {
    final isLoggedIn = AdminAuthService.instance.isLoggedIn;
    
    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/admin/login');
        }
      });
    } else {
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminAuthService.instance.logout();
      if (mounted) {
        context.go('/admin/login');
      }
    }
  }

  void _updateProgress(String operation) {
    if (mounted) {
      setState(() {
        _currentOperation = operation;
      });
    }
  }

  void _showResultDialog(String title, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(
            _formatResult(result),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _formatResult(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    
    result.forEach((key, value) {
      if (value is Map) {
        buffer.writeln('$key:');
        (value as Map).forEach((k, v) {
          buffer.writeln('  $k: $v');
        });
      } else if (value is List) {
        buffer.writeln('$key: ${value.length} items');
        if (value.isNotEmpty && value.length <= 10) {
          for (final item in value) {
            buffer.writeln('  - $item');
          }
        }
      } else {
        buffer.writeln('$key: $value');
      }
    });
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currentAdmin = AdminAuthService.instance.currentAdmin;
    
    if (currentAdmin == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(FontAwesomeIcons.rightFromBracket),
            tooltip: '로그아웃',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(FontAwesomeIcons.chartLine), text: '개요'),
            Tab(icon: Icon(FontAwesomeIcons.download), text: '데이터 수집'),
            Tab(icon: Icon(FontAwesomeIcons.database), text: '데이터 관리'),
            Tab(icon: Icon(FontAwesomeIcons.gear), text: '설정'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 진행 상태 표시
          if (_isOperating)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  const LinearProgressIndicator(),
                  Gaps.v8,
                  Text(
                    _currentOperation,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(currentAdmin),
                _buildDataCollectionTab(currentAdmin),
                _buildDataManagementTab(currentAdmin),
                _buildSettingsTab(currentAdmin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AdminUser admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(admin),
          Gaps.v16,
          _buildQuickStatsCard(),
          Gaps.v16,
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(AdminUser admin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Text(
                admin.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Gaps.h16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '환영합니다, ${admin.username}님',
                    style: AppTypography.heading2,
                  ),
                  Gaps.v4,
                  Text(
                    '권한: ${admin.role.name}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Gaps.v4,
                  Text(
                    '마지막 로그인: ${admin.lastLoginAt.toString().substring(0, 16)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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

  Widget _buildQuickStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시스템 상태',
              style: AppTypography.heading3,
            ),
            Gaps.v16,
            Row(
              children: [
                _buildStatItem('총 지표', '20개', FontAwesomeIcons.chartLine, Colors.blue),
                _buildStatItem('OECD 국가', '38개', FontAwesomeIcons.globe, Colors.green),
                _buildStatItem('데이터 년도', '10년', FontAwesomeIcons.calendar, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          Gaps.v8,
          Text(
            value,
            style: AppTypography.heading2.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 작업 결과',
              style: AppTypography.heading3,
            ),
            Gaps.v16,
            if (_lastOperationResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  _formatResult(_lastOperationResult!),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              )
            else
              Text(
                '아직 수행된 작업이 없습니다.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCollectionTab(AdminUser admin) {
    if (!admin.hasPermission(AdminPermission.dataManagement)) {
      return const Center(
        child: Text('데이터 관리 권한이 필요합니다.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'World Bank API 데이터 수집',
            style: AppTypography.heading2,
          ),
          Gaps.v16,
          
          _buildActionCard(
            title: '전체 지표 데이터 수집',
            description: '모든 OECD 국가의 20개 핵심 지표 데이터를 World Bank API에서 수집합니다.',
            icon: FontAwesomeIcons.download,
            color: Colors.blue,
            onPressed: _isOperating ? null : _collectAllData,
          ),
          
          Gaps.v16,
          
          _buildActionCard(
            title: 'OECD 통계 계산',
            description: '수집된 데이터를 바탕으로 OECD 통계(평균, 중앙값, 순위 등)를 계산합니다.',
            icon: FontAwesomeIcons.calculator,
            color: Colors.green,
            onPressed: _isOperating ? null : _calculateOECDStats,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementTab(AdminUser admin) {
    if (!admin.hasPermission(AdminPermission.dataManagement)) {
      return const Center(
        child: Text('데이터 관리 권한이 필요합니다.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Firestore 데이터 관리',
            style: AppTypography.heading2,
          ),
          Gaps.v16,
          
          _buildActionCard(
            title: '데이터 감사',
            description: '중복 데이터, 오래된 데이터, 무결성 문제를 검사합니다.',
            icon: FontAwesomeIcons.magnifyingGlass,
            color: Colors.orange,
            onPressed: _isOperating ? null : _performDataAudit,
          ),
          
          Gaps.v16,
          
          _buildActionCard(
            title: '오래된 데이터 삭제',
            description: '2년 이상 된 오래된 데이터를 삭제합니다.',
            icon: FontAwesomeIcons.trash,
            color: Colors.red,
            onPressed: _isOperating ? null : () => _deleteOldData(false),
          ),
          
          Gaps.v16,
          
          _buildActionCard(
            title: '중복 데이터 제거',
            description: '동일한 지표/국가 조합의 중복 문서를 제거합니다.',
            icon: FontAwesomeIcons.copy,
            color: Colors.purple,
            onPressed: _isOperating ? null : () => _removeDuplicates(false),
          ),
          
          Gaps.v16,
          
          _buildActionCard(
            title: '데이터베이스 통계',
            description: '전체 데이터베이스 크기 및 문서 수 통계를 확인합니다.',
            icon: FontAwesomeIcons.chartPie,
            color: Colors.teal,
            onPressed: _isOperating ? null : _getDatabaseStats,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(AdminUser admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시스템 설정',
            style: AppTypography.heading2,
          ),
          Gaps.v16,
          
          Card(
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.user),
              title: const Text('계정 정보'),
              subtitle: Text('${admin.username} (${admin.role.name})'),
              trailing: const Icon(FontAwesomeIcons.chevronRight),
              onTap: () {
                _showAccountInfoDialog(admin);
              },
            ),
          ),
          
          Gaps.v8,
          
          Card(
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.key),
              title: const Text('비밀번호 변경'),
              subtitle: const Text('관리자 비밀번호 변경'),
              trailing: const Icon(FontAwesomeIcons.chevronRight),
              onTap: () {
                _showChangePasswordDialog();
              },
            ),
          ),
          
          Gaps.v8,
          
          Card(
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.clockRotateLeft),
              title: const Text('감사 로그'),
              subtitle: const Text('시스템 작업 이력 확인'),
              trailing: const Icon(FontAwesomeIcons.chevronRight),
              onTap: () {
                _showAuditLogDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                Gaps.h12,
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.heading3,
                  ),
                ),
              ],
            ),
            Gaps.v8,
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Gaps.v16,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: Text(onPressed == null ? '실행 중...' : '실행'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 데이터 수집 작업들
  Future<void> _collectAllData() async {
    setState(() {
      _isOperating = true;
      _currentOperation = '데이터 수집 시작...';
    });

    try {
      final result = await _dataCollector.collectAllIndicatorData(
        onProgress: _updateProgress,
      );
      
      setState(() {
        _lastOperationResult = result;
      });
      
      _showResultDialog('데이터 수집 완료', result);
      
    } catch (e) {
      _showResultDialog('데이터 수집 실패', {'error': e.toString()});
    } finally {
      setState(() {
        _isOperating = false;
        _currentOperation = '';
      });
    }
  }

  Future<void> _calculateOECDStats() async {
    setState(() {
      _isOperating = true;
      _currentOperation = 'OECD 통계 계산 시작...';
    });

    try {
      await _dataCollector.calculateAndSaveOECDStats(
        onProgress: _updateProgress,
      );
      
      final result = {'status': 'success', 'message': 'OECD 통계 계산이 완료되었습니다.'};
      setState(() {
        _lastOperationResult = result;
      });
      
      _showResultDialog('OECD 통계 계산 완료', result);
      
    } catch (e) {
      _showResultDialog('OECD 통계 계산 실패', {'error': e.toString()});
    } finally {
      setState(() {
        _isOperating = false;
        _currentOperation = '';
      });
    }
  }

  // 데이터 관리 작업들
  Future<void> _performDataAudit() async {
    setState(() {
      _isOperating = true;
      _currentOperation = '데이터 감사 시작...';
    });

    try {
      final result = await _dataManager.performDataAudit(
        onProgress: _updateProgress,
      );
      
      setState(() {
        _lastOperationResult = result;
      });
      
      _showResultDialog('데이터 감사 완료', result);
      
    } catch (e) {
      _showResultDialog('데이터 감사 실패', {'error': e.toString()});
    } finally {
      setState(() {
        _isOperating = false;
        _currentOperation = '';
      });
    }
  }

  Future<void> _deleteOldData(bool dryRun) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('경고'),
        content: Text(dryRun 
          ? '오래된 데이터 삭제 시뮬레이션을 실행하시겠습니까?' 
          : '정말로 오래된 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(dryRun ? '시뮬레이션' : '삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isOperating = true;
      _currentOperation = '오래된 데이터 ${dryRun ? '시뮬레이션' : '삭제'} 중...';
    });

    try {
      final result = await _dataManager.deleteOldData(
        dryRun: dryRun,
        onProgress: _updateProgress,
      );
      
      setState(() {
        _lastOperationResult = result;
      });
      
      _showResultDialog('오래된 데이터 ${dryRun ? '시뮬레이션' : '삭제'} 완료', result);
      
    } catch (e) {
      _showResultDialog('오래된 데이터 삭제 실패', {'error': e.toString()});
    } finally {
      setState(() {
        _isOperating = false;
        _currentOperation = '';
      });
    }
  }

  Future<void> _removeDuplicates(bool dryRun) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('중복 데이터 제거'),
        content: Text(dryRun 
          ? '중복 데이터 제거 시뮬레이션을 실행하시겠습니까?' 
          : '정말로 중복 데이터를 제거하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(dryRun ? '시뮬레이션' : '제거'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isOperating = true;
      _currentOperation = '중복 데이터 ${dryRun ? '시뮬레이션' : '제거'} 중...';
    });

    try {
      final result = await _dataManager.removeDuplicateData(
        dryRun: dryRun,
        onProgress: _updateProgress,
      );
      
      setState(() {
        _lastOperationResult = result;
      });
      
      _showResultDialog('중복 데이터 ${dryRun ? '시뮬레이션' : '제거'} 완료', result);
      
    } catch (e) {
      _showResultDialog('중복 데이터 제거 실패', {'error': e.toString()});
    } finally {
      setState(() {
        _isOperating = false;
        _currentOperation = '';
      });
    }
  }

  Future<void> _getDatabaseStats() async {
    setState(() {
      _isOperating = true;
      _currentOperation = '데이터베이스 통계 수집 중...';
    });

    try {
      final result = await _dataManager.getDatabaseStatistics();
      
      setState(() {
        _lastOperationResult = result;
      });
      
      _showResultDialog('데이터베이스 통계', result);
      
    } catch (e) {
      _showResultDialog('데이터베이스 통계 실패', {'error': e.toString()});
    } finally {
      setState(() {
        _isOperating = false;
        _currentOperation = '';
      });
    }
  }

  void _showAccountInfoDialog(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('사용자명', admin.username),
            _buildInfoRow('권한', admin.role.name),
            _buildInfoRow('계정 생성일', admin.createdAt.toString().substring(0, 16)),
            _buildInfoRow('마지막 로그인', admin.lastLoginAt.toString().substring(0, 16)),
            _buildInfoRow('활성 상태', admin.isActive ? '활성' : '비활성'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('비밀번호 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '현재 비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              Gaps.v16,
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              Gaps.v16,
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호 확인',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('비밀번호는 최소 6자 이상이어야 합니다.')),
                  );
                  return;
                }

                setState(() => isLoading = true);

                try {
                  final success = await AdminAuthService.instance.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );

                  if (mounted) {
                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('현재 비밀번호가 올바르지 않습니다.')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('비밀번호 변경 실패: ${e.toString()}')),
                    );
                  }
                } finally {
                  setState(() => isLoading = false);
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuditLogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감사 로그'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                '최근 시스템 작업 이력',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Gaps.v16,
              Expanded(
                child: ListView(
                  children: [
                    _buildLogEntry('2024-09-04 15:30', 'OECD 통계 계산 완료', 'SUCCESS'),
                    _buildLogEntry('2024-09-04 14:45', '데이터 수집 시작', 'INFO'),
                    _buildLogEntry('2024-09-04 14:20', '관리자 로그인', 'INFO'),
                    _buildLogEntry('2024-09-03 16:10', '데이터베이스 통계 조회', 'INFO'),
                    _buildLogEntry('2024-09-03 15:55', '중복 데이터 제거 완료', 'SUCCESS'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('전체 로그는 별도 화면에서 확인 가능합니다.')),
              );
            },
            child: const Text('전체 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(String timestamp, String action, String status) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'SUCCESS':
        statusColor = Colors.green;
        statusIcon = FontAwesomeIcons.circleCheck;
        break;
      case 'ERROR':
        statusColor = Colors.red;
        statusIcon = FontAwesomeIcons.circleExclamation;
        break;
      case 'WARNING':
        statusColor = Colors.orange;
        statusIcon = FontAwesomeIcons.triangleExclamation;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = FontAwesomeIcons.circleInfo;
    }

    return Card(
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor, size: 20),
        title: Text(action, style: AppTypography.bodyMedium),
        subtitle: Text(timestamp, style: AppTypography.bodySmall),
        trailing: Text(
          status,
          style: AppTypography.bodySmall.copyWith(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}