import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/authentication/repos/authentication_repo.dart';
import 'package:geo_economy_dashboard/features/authentication/views/sign_up_screen.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import 'package:geo_economy_dashboard/features/favorites/services/favorites_service.dart';
import 'package:geo_economy_dashboard/common/widgets/app_bar_widget.dart';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  static const String routeName = "settings";
  static const String routeURL = "/settings";

  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dataUpdateAlerts = true;
  bool _weeklyReports = false;
  final String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    // Load notification settings from service
    // This is a placeholder - implement actual loading from NotificationService
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ref.watch(settingsProvider).darkmode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : AppColors.background,
      appBar: const AppBarWidget(
        title: "설정",
        showGlobe: false,
        showNotification: false,
        showGear: true,
        showLogin: false,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: '모양',
            children: [
              _buildSwitchTile(
                icon: isDark ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
                title: '다크 모드',
                subtitle: isDark ? '어두운 테마 사용 중' : '밝은 테마 사용 중',
                value: isDark,
                onChanged: (value) => ref.read(settingsProvider.notifier).setDarkmode(value),
                isDark: isDark,
              ),
              _buildActionTile(
                icon: FontAwesomeIcons.universalAccess,
                title: '접근성',
                subtitle: '폰트 크기, 색맹 대응, 대비 설정',
                onTap: () => context.push('/settings/accessibility'),
                isDark: isDark,
              ),
            ],
          ),
          _buildSection(
            title: '알림',
            children: [
              _buildSwitchTile(
                icon: FontAwesomeIcons.bell,
                title: '푸시 알림',
                subtitle: '새로운 데이터 업데이트 알림 받기',
                value: _notificationsEnabled,
                onChanged: (value) => setState(() => _notificationsEnabled = value),
                isDark: isDark,
              ),
              _buildSwitchTile(
                icon: FontAwesomeIcons.database,
                title: '데이터 업데이트 알림',
                subtitle: '관심 있는 지표의 새로운 데이터 알림',
                value: _dataUpdateAlerts,
                onChanged: (value) => setState(() => _dataUpdateAlerts = value),
                isDark: isDark,
              ),
              _buildSwitchTile(
                icon: FontAwesomeIcons.calendarWeek,
                title: '주간 리포트',
                subtitle: '매주 경제 동향 요약 받기',
                value: _weeklyReports,
                onChanged: (value) => setState(() => _weeklyReports = value),
                isDark: isDark,
              ),
            ],
          ),
          _buildSection(
            title: '데이터 관리',
            children: [
              _buildActionTile(
                icon: FontAwesomeIcons.download,
                title: '즐겨찾기 내보내기',
                subtitle: 'JSON 형식으로 즐겨찾기 백업',
                onTap: _exportFavorites,
                isDark: isDark,
              ),
              _buildActionTile(
                icon: FontAwesomeIcons.upload,
                title: '즐겨찾기 가져오기',
                subtitle: '백업된 즐겨찾기 복원',
                onTap: _importFavorites,
                isDark: isDark,
              ),
              _buildActionTile(
                icon: FontAwesomeIcons.broom,
                title: '캐시 지우기',
                subtitle: '저장된 데이터 캐시 삭제',
                onTap: _clearCache,
                isDark: isDark,
              ),
            ],
          ),
          _buildSection(
            title: '관리자',
            children: [
              _buildActionTile(
                icon: FontAwesomeIcons.userShield,
                title: '관리자 모드',
                subtitle: '시스템 관리 및 데이터 관리',
                onTap: () => context.push('/admin/login'),
                isDark: isDark,
              ),
            ],
          ),
          _buildSection(
            title: '정보',
            children: [
              _buildActionTile(
                icon: FontAwesomeIcons.circleInfo,
                title: '앱 정보',
                subtitle: '버전 $_appVersion',
                onTap: _showAppInfo,
                isDark: isDark,
                showArrow: false,
              ),
              _buildActionTile(
                icon: FontAwesomeIcons.headset,
                title: '고객 지원',
                subtitle: '문의사항 및 피드백',
                onTap: _contactSupport,
                isDark: isDark,
              ),
              _buildActionTile(
                icon: FontAwesomeIcons.shield,
                title: '개인정보 처리방침',
                subtitle: '데이터 보호 및 개인정보 정책',
                onTap: _showPrivacyPolicy,
                isDark: isDark,
              ),
              _buildActionTile(
                icon: FontAwesomeIcons.fileContract,
                title: '서비스 이용약관',
                subtitle: '앱 사용에 관한 약관',
                onTap: _showTermsOfService,
                isDark: isDark,
              ),
            ],
          ),
          _buildSection(
            title: '계정',
            children: [
              _buildActionTile(
                icon: FontAwesomeIcons.rightFromBracket,
                title: '로그아웃',
                subtitle: '현재 계정에서 로그아웃',
                onTap: _showLogoutDialog,
                isDark: isDark,
                isDestructive: true,
              ),
            ],
          ),
          Gaps.v32,
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = ref.watch(settingsProvider).darkmode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16213E) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (value ? AppColors.primary : AppColors.textSecondary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: value ? AppColors.primary : AppColors.textSecondary,
            size: 16,
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool showArrow = true,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.primary;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: color,
            size: 16,
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: isDestructive 
              ? AppColors.error 
              : (isDark ? Colors.white : AppColors.textPrimary),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
      ),
      trailing: showArrow 
          ? FaIcon(
              FontAwesomeIcons.chevronRight,
              color: isDark ? Colors.white30 : AppColors.textSecondary,
              size: 12,
            )
          : null,
      onTap: onTap,
    );
  }

  void _exportFavorites() async {
    try {
      final favoritesJson = await FavoritesService.instance.exportFavorites();
      final fileName = 'geo_dashboard_favorites_${DateTime.now().millisecondsSinceEpoch}.json';
      
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(favoritesJson.codeUnits),
          name: fileName,
          mimeType: 'application/json',
        )
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('즐겨찾기가 성공적으로 내보내졌습니다'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('즐겨찾기 내보내기에 실패했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _importFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('즐겨찾기 가져오기 기능을 준비 중입니다...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _clearCache() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('캐시 지우기'),
        content: const Text('저장된 데이터 캐시를 모두 삭제하시겠습니까?\n앱이 다시 시작될 수 있습니다.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('캐시가 삭제되었습니다'),
                  backgroundColor: AppColors.accent,
                ),
              );
            },
            isDestructiveAction: true,
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Geo Economy Dashboard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const FaIcon(
              FontAwesomeIcons.chartLine,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '버전 $_appVersion\n\nOECD 국가들의 경제 지표를\n쉽게 비교하고 분석할 수 있는\n대시보드 앱입니다.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() async {
    const email = 'support@geodashboard.com';
    const subject = 'Geo Dashboard 문의사항';
    const body = '안녕하세요,\n\n문의사항: \n\n---\n앱 버전: 1.0.0';
    
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이메일 앱을 열 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() async {
    const url = 'https://geodashboard.com/privacy';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크를 열 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showTermsOfService() async {
    const url = 'https://geodashboard.com/terms';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크를 열 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              ref.read(authRepo).signOut(context);
              context.go(SignUpScreen.routeURL);
            },
            isDestructiveAction: true,
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
