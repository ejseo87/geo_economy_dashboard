import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../services/network_service.dart';

/// 오프라인 모드 배너 위젯
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        return _buildOfflineBanner();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOfflineBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.wifi,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            '오프라인 모드 • 저장된 데이터를 표시합니다',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 오프라인 상태 표시 위젯
class OfflineIndicator extends ConsumerWidget {
  final Widget child;
  final bool showBanner;

  const OfflineIndicator({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (isOnline) => Column(
        children: [
          if (!isOnline && showBanner) const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

/// 오프라인 상태 표시용 프로바이더
final networkStatusProvider = StreamProvider<bool>((ref) {
  return NetworkService.instance.connectionStream;
});

/// 오프라인 데이터 표시 위젯
class OfflineDataCard extends StatelessWidget {
  final Widget child;
  final String? lastUpdated;
  final VoidCallback? onRefresh;

  const OfflineDataCard({
    super.key,
    required this.child,
    this.lastUpdated,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isOnline = ref.watch(networkStatusProvider).asData?.value ?? true;
        
        if (isOnline) return child;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.clockRotateLeft,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lastUpdated != null 
                            ? '오프라인 • 마지막 업데이트: $lastUpdated'
                            : '오프라인 • 저장된 데이터 표시',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (onRefresh != null)
                      GestureDetector(
                        onTap: onRefresh,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.arrowRotateRight,
                            size: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}

/// 연결 상태 표시 위젯
class ConnectionStatusWidget extends ConsumerWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (isOnline) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            isOnline ? FontAwesomeIcons.wifi : FontAwesomeIcons.wifi,
            size: 14,
            color: isOnline ? AppColors.accent : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? '온라인' : '오프라인',
            style: AppTypography.caption.copyWith(
              color: isOnline ? AppColors.accent : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '확인 중...',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      error: (error, stack) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 14,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            '연결 오류',
            style: AppTypography.caption.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}