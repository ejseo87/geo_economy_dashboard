import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../view_models/data_audit_view_model.dart';
import '../services/data_audit_service.dart';
import '../services/data_standardization_service.dart';
import '../providers/data_monitoring_provider.dart';
import '../widgets/real_time_data_status_card.dart';
import '../widgets/automated_cleanup_card.dart';

class AdminDataManagementTab extends ConsumerStatefulWidget {
  const AdminDataManagementTab({super.key});

  @override
  ConsumerState<AdminDataManagementTab> createState() => _AdminDataManagementTabState();
}

class _AdminDataManagementTabState extends ConsumerState<AdminDataManagementTab> {
  bool _isExporting = false;
  bool _isStandardizing = false;

  @override
  void initState() {
    super.initState();
    // 화면 로드 시 최신 감사 결과 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dataAuditProvider.notifier).loadLatestAuditResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sizes.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuditControls(),
          const SizedBox(height: Sizes.size24),
          const RealTimeDataStatusCard(),
          const SizedBox(height: Sizes.size24),
          _buildDataStandardization(),
          const SizedBox(height: Sizes.size24),
          _buildCleanupControls(),
          const SizedBox(height: Sizes.size24),
          const AutomatedCleanupCard(),
          const SizedBox(height: Sizes.size24),
          _buildAuditResults(),
        ],
      ),
    );
  }

  Widget _buildAuditControls() {
    final auditState = ref.watch(dataAuditProvider);
    
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
                    onPressed: auditState.isAuditing ? null : () => ref.read(dataAuditProvider.notifier).startFullAudit(),
                    icon: auditState.isAuditing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.searchengin, size: 16),
                    label: Text(auditState.isAuditing ? '감사 중...' : '전체 감사'),
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
                    onPressed: auditState.isAuditing ? null : () => ref.read(dataAuditProvider.notifier).startQuickAudit(),
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


  Widget _buildDataStandardization() {
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
                  FontAwesomeIcons.language,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '데이터 표준화',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size16),
            Text(
              'indicators와 countries 컬렉션의 국가명과 지표명을 한글로 통일합니다.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: Sizes.size16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isStandardizing ? null : () => _standardizeAllData(),
                    icon: _isStandardizing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.globe, size: 16),
                    label: Text(_isStandardizing ? '표준화 중...' : '전체 표준화'),
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
                    onPressed: _isStandardizing ? null : () => _initializeMetadata(),
                    icon: const FaIcon(FontAwesomeIcons.database, size: 16),
                    label: const Text('메타데이터 초기화'),
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

  Widget _buildCleanupControls() {
    final auditState = ref.watch(dataAuditProvider);
    final cleanupState = ref.watch(dataCleanupProvider);
    
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
                    onPressed: (cleanupState.isCleaning || auditState.duplicateCount == 0) ? null : () => ref.read(dataCleanupProvider.notifier).removeDuplicates(),
                    icon: cleanupState.isCleaning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.trash, size: 16),
                    label: Text(cleanupState.isCleaning ? '정리 중...' : '중복 제거'),
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
                    onPressed: (cleanupState.isCleaning || auditState.outdatedCount == 0) ? null : () => ref.read(dataCleanupProvider.notifier).removeOutdated(),
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
    final auditState = ref.watch(dataAuditProvider);
    
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
                  onPressed: () => _exportLatestAuditResult(),
                  icon: const FaIcon(FontAwesomeIcons.download, size: 14),
                  label: const Text('내보내기'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _testExport(),
                  icon: const FaIcon(FontAwesomeIcons.vial, size: 14),
                  label: const Text('테스트'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: auditState.auditResults.isEmpty ? null : () => ref.read(dataAuditProvider.notifier).clearResults(),
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
              child: auditState.auditResults.isEmpty
                  ? Center(
                      child: Text(
                        '감사 결과가 없습니다',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: auditState.auditResults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            auditState.auditResults[index],
                            style: AppTypography.bodySmall.copyWith(
                              color: _getLogColor(auditState.auditResults[index]),
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
    if (log.contains('[오류]') || log.contains('[ERROR]')) return Colors.red;
    if (log.contains('[경고]') || log.contains('[WARN]')) return Colors.orange;
    if (log.contains('[완료]') || log.contains('[SUCCESS]')) return Colors.green;
    if (log.contains('[결과]')) return Colors.cyan;
    return Colors.lightBlue;
  }

  Future<void> _exportLatestAuditResult() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // 최신 감사 결과 가져오기
      final recentResults = await DataAuditService.instance.getRecentAuditResults(limit: 1);

      if (recentResults.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('내보낼 감사 결과가 없습니다. 먼저 데이터 감사를 실행해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 최신 감사 결과 ID 가져오기
      final auditId = await DataAuditService.instance.getLatestAuditResultId();

      if (auditId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('감사 결과를 찾을 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 파일 내보내기
      print('[DEBUG] Calling exportAuditResultWithFilePicker with ID: $auditId');
      final savedPath = await DataAuditService.instance.exportAuditResultWithFilePicker(auditId);
      print('[DEBUG] Export result: $savedPath');

      if (mounted) {
        if (savedPath != null && savedPath.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('감사 보고서가 저장되었습니다:\n$savedPath'),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('파일 저장이 실패했습니다.\n개발자 도구나 로그를 확인해 상세한 오류를 확인하세요.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('내보내기 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // 테스트 내보내기 (디버깅용)
  Future<void> _testExport() async {
    try {
      final savedPath = await DataAuditService.instance.exportTestReport();

      if (mounted) {
        if (savedPath != null && savedPath.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('테스트 파일이 저장되었습니다:\n$savedPath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('테스트 파일 저장이 실패했습니다.\n로그를 확인해 주세요.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 내보내기 중 오류: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 전체 데이터 표준화 실행
  Future<void> _standardizeAllData() async {
    if (_isStandardizing) return;

    setState(() {
      _isStandardizing = true;
    });

    try {
      await for (final message in DataStandardizationService.instance.standardizeAllData()) {
        // 진행상황을 감사 결과에 표시
        final auditNotifier = ref.read(dataAuditProvider.notifier);
        final currentResults = ref.read(dataAuditProvider).auditResults;
        auditNotifier.state = auditNotifier.state.copyWith(
          auditResults: [...currentResults, message],
        );
      }

      // 완료 후 최신 감사 결과 로드
      await ref.read(dataAuditProvider.notifier).loadLatestAuditResults();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('데이터 표준화가 완료되었습니다!'),
            backgroundColor: AppColors.accent,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 표준화 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStandardizing = false;
        });
      }
    }
  }

  // 메타데이터만 초기화
  Future<void> _initializeMetadata() async {
    if (_isStandardizing) return;

    setState(() {
      _isStandardizing = true;
    });

    try {
      // indicators_metadata 초기화
      await DataStandardizationService.instance.initializeIndicatorsMetadata();

      // OECD 국가 한글명 초기화
      await DataStandardizationService.instance.initializeOecdCountriesKoreanNames();

      // 감사 결과에 로그 표시
      final auditNotifier = ref.read(dataAuditProvider.notifier);
      final currentResults = ref.read(dataAuditProvider).auditResults;
      auditNotifier.state = auditNotifier.state.copyWith(
        auditResults: [
          ...currentResults,
          '[완료] indicators_metadata 컬렉션 초기화 완료',
          '[완료] oecd_countries 한글명 초기화 완료',
        ],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메타데이터 초기화가 완료되었습니다!'),
            backgroundColor: AppColors.accent,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메타데이터 초기화 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStandardizing = false;
        });
      }
    }
  }
}