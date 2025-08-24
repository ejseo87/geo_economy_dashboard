import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../services/share_service.dart';

/// 공유 가능한 카드 위젯
class ShareCardWidget extends ConsumerWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final String? fileName;
  final Map<String, dynamic>? shareData;
  final bool showShareButton;
  final String? csvContent;  // CSV 데이터 (있으면 CSV 버튼 표시)
  final String Function()? onGenerateCsv;  // CSV 생성 콜백
  final VoidCallback? onShareSuccess;
  final VoidCallback? onShareFailure;

  const ShareCardWidget({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.fileName,
    this.shareData,
    this.showShareButton = true,
    this.csvContent,
    this.onGenerateCsv,
    this.onShareSuccess,
    this.onShareFailure,
  });

  static final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 헤더 (공유할 때만 표시)
                _buildShareHeader(),
                // 실제 콘텐츠
                child,
                // 푸터 (공유할 때만 표시)
                _buildShareFooter(),
              ],
            ),
          ),
        ),
        if (showShareButton) ...[
          const SizedBox(height: 16),
          _buildShareButtons(context),
        ],
      ],
    );
  }

  /// 공유용 헤더
  Widget _buildShareHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 공유용 푸터
  Widget _buildShareFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Geo Economy Dashboard',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            DateTime.now().toString().split(' ')[0],
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 공유 버튼들
  Widget _buildShareButtons(BuildContext context) {
    final buttons = <Widget>[
      Expanded(
        child: _ShareButton(
          icon: Icons.share,
          label: '공유',
          onPressed: () => _handleShare(context, ShareOption.imageWithText),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _ShareButton(
          icon: Icons.download,
          label: '저장',
          onPressed: () => _handleShare(context, ShareOption.saveToGallery),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _ShareButton(
          icon: Icons.link,
          label: '링크',
          onPressed: () => _handleShare(context, ShareOption.link),
        ),
      ),
    ];

    // CSV 버튼 추가 (CSV 콘텐츠나 생성 함수가 있는 경우)
    if (csvContent != null || onGenerateCsv != null) {
      buttons.addAll([
        const SizedBox(width: 12),
        Expanded(
          child: _ShareButton(
            icon: Icons.table_chart,
            label: 'CSV',
            onPressed: () => _handleShare(context, ShareOption.exportCsv),
          ),
        ),
      ]);
    }

    return Row(children: buttons);
  }

  /// 공유 처리
  Future<void> _handleShare(BuildContext context, ShareOption option) async {
    try {
      final shareService = ShareService.instance;
      bool success = false;
      
      switch (option) {
        case ShareOption.image:
          success = await shareService.shareWidgetAsImage(
            repaintBoundaryKey: _repaintBoundaryKey,
            title: title,
            fileName: fileName,
          );
          break;
          
        case ShareOption.imageWithText:
          final shareText = _generateShareText();
          success = await shareService.shareTextWithImage(
            repaintBoundaryKey: _repaintBoundaryKey,
            title: title,
            text: shareText,
            fileName: fileName,
          );
          break;
          
        case ShareOption.link:
          final shareText = _generateShareText();
          success = await shareService.shareLink(
            url: 'https://geo-dashboard.com', // TODO: 실제 앱 URL로 변경
            title: title,
            description: shareText,
          );
          break;
          
        case ShareOption.saveToGallery:
          success = await shareService.saveImageToGallery(
            repaintBoundaryKey: _repaintBoundaryKey,
            fileName: fileName,
          );
          break;
          
        case ShareOption.copyLink:
          success = await shareService.copyToClipboard(_generateShareText());
          break;
          
        case ShareOption.exportCsv:
          final csvData = csvContent ?? onGenerateCsv?.call();
          if (csvData != null) {
            success = await shareService.exportToCsv(
              csvContent: csvData,
              fileName: fileName?.replaceAll('.png', '') ?? 'geo_dashboard_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
            );
          }
          break;
      }
      
      if (success) {
        if (context.mounted) {
          _showSuccessSnackBar(context, option);
        }
        onShareSuccess?.call();
      } else {
        if (context.mounted) {
          _showErrorSnackBar(context, option);
        }
        onShareFailure?.call();
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, option);
      }
      onShareFailure?.call();
    }
  }

  /// 공유 텍스트 생성
  String _generateShareText() {
    final buffer = StringBuffer();
    buffer.write(title);
    
    if (subtitle != null) {
      buffer.write('\n$subtitle');
    }
    
    buffer.write('\n\nGeo Economy Dashboard로 생성됨');
    buffer.write('\n${DateTime.now().toString().split(' ')[0]}');
    
    return buffer.toString();
  }

  /// 성공 스낵바
  void _showSuccessSnackBar(BuildContext context, ShareOption option) {
    String message;
    switch (option) {
      case ShareOption.saveToGallery:
        message = kIsWeb ? '이미지가 다운로드되었습니다' : '갤러리에 저장되었습니다';
        break;
      case ShareOption.exportCsv:
        message = 'CSV 파일이 내보내졌습니다';
        break;
      case ShareOption.image:
      case ShareOption.imageWithText:
        message = '이미지가 공유되었습니다';
        break;
      case ShareOption.link:
        message = '링크가 공유되었습니다';
        break;
      case ShareOption.copyLink:
        message = '클립보드에 복사되었습니다';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 오류 스낵바
  void _showErrorSnackBar(BuildContext context, ShareOption option) {
    String message;
    switch (option) {
      case ShareOption.saveToGallery:
        message = kIsWeb ? '이미지 다운로드 실패' : '갤러리 저장 실패 - 권한을 확인하세요';
        break;
      case ShareOption.exportCsv:
        message = 'CSV 내보내기 실패';
        break;
      case ShareOption.image:
      case ShareOption.imageWithText:
        message = '이미지 공유 실패';
        break;
      case ShareOption.link:
        message = '링크 공유 실패';
        break;
      case ShareOption.copyLink:
        message = '클립보드 복사 실패';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: option == ShareOption.saveToGallery && !kIsWeb
            ? SnackBarAction(
                label: '설정',
                textColor: Colors.white,
                onPressed: () {
                  // 권한 설정으로 이동할 수 있는 기능 (추후 구현)
                },
              )
            : null,
      ),
    );
  }
}

/// 공유 버튼 위젯
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: AppColors.primary,
      ),
      label: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        side: BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// 공유 모달 위젯
class ShareModalWidget extends StatelessWidget {
  final String title;
  final GlobalKey repaintBoundaryKey;
  final String? fileName;
  final String? csvContent;
  final String Function()? onGenerateCsv;
  final VoidCallback? onClose;

  const ShareModalWidget({
    super.key,
    required this.title,
    required this.repaintBoundaryKey,
    this.fileName,
    this.csvContent,
    this.onGenerateCsv,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // 제목
          Text(
            '공유하기',
            style: AppTypography.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // 공유 옵션들
          _buildShareOption(
            context,
            icon: Icons.share,
            title: '이미지와 텍스트 공유',
            subtitle: '카드를 이미지로 만들어서 텍스트와 함께 공유',
            onTap: () => _share(context, ShareOption.imageWithText),
          ),
          const SizedBox(height: 16),
          _buildShareOption(
            context,
            icon: Icons.image,
            title: '이미지만 공유',
            subtitle: '카드를 이미지로만 공유',
            onTap: () => _share(context, ShareOption.image),
          ),
          const SizedBox(height: 16),
          _buildShareOption(
            context,
            icon: Icons.download,
            title: '갤러리에 저장',
            subtitle: '카드를 이미지로 저장',
            onTap: () => _share(context, ShareOption.saveToGallery),
          ),
          const SizedBox(height: 16),
          _buildShareOption(
            context,
            icon: Icons.link,
            title: '링크 공유',
            subtitle: '앱 링크와 함께 텍스트 공유',
            onTap: () => _share(context, ShareOption.link),
          ),
          
          // CSV 옵션 (CSV 데이터가 있는 경우만)
          if (csvContent != null || onGenerateCsv != null) ...[
            const SizedBox(height: 16),
            _buildShareOption(
              context,
              icon: Icons.table_chart,
              title: 'CSV로 내보내기',
              subtitle: '데이터를 CSV 파일로 내보내기',
              onTap: () => _share(context, ShareOption.exportCsv),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, ShareOption option) async {
    Navigator.of(context).pop();
    
    final shareService = ShareService.instance;
    bool success = false;
    
    try {
      switch (option) {
        case ShareOption.image:
          success = await shareService.shareWidgetAsImage(
            repaintBoundaryKey: repaintBoundaryKey,
            title: title,
            fileName: fileName,
          );
          break;
          
        case ShareOption.imageWithText:
          success = await shareService.shareTextWithImage(
            repaintBoundaryKey: repaintBoundaryKey,
            title: title,
            text: '$title\n\nGeo Economy Dashboard로 생성됨',
            fileName: fileName,
          );
          break;
          
        case ShareOption.saveToGallery:
          success = await shareService.saveImageToGallery(
            repaintBoundaryKey: repaintBoundaryKey,
            fileName: fileName,
          );
          break;
          
        case ShareOption.link:
          success = await shareService.shareLink(
            url: 'https://geo-dashboard.com',
            title: title,
            description: '$title\n\nGeo Economy Dashboard로 생성됨',
          );
          break;
          
        case ShareOption.copyLink:
          success = await shareService.copyToClipboard(
            '$title\n\nGeo Economy Dashboard로 생성됨',
          );
          break;
          
        case ShareOption.exportCsv:
          final csvData = csvContent ?? onGenerateCsv?.call();
          if (csvData != null) {
            success = await shareService.exportToCsv(
              csvContent: csvData,
              fileName: fileName?.replaceAll('.png', '') ?? 'geo_dashboard_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
            );
          }
          break;
      }
    } catch (e) {
      success = false;
    }
    
    if (context.mounted) {
      final message = success 
          ? '${option.displayName} 성공' 
          : '${option.displayName} 실패';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
    
    onClose?.call();
  }
}

/// 공유 모달 표시 헬퍼
void showShareModal(
  BuildContext context, {
  required String title,
  required GlobalKey repaintBoundaryKey,
  String? fileName,
  String? csvContent,
  String Function()? onGenerateCsv,
  VoidCallback? onClose,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ShareModalWidget(
      title: title,
      repaintBoundaryKey: repaintBoundaryKey,
      fileName: fileName,
      csvContent: csvContent,
      onGenerateCsv: onGenerateCsv,
      onClose: onClose,
    ),
  );
}