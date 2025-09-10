import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

/// 알림 버튼 (헤더에 표시)
class NotificationButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const NotificationButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = NotificationService.instance.unreadCount;
    
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed ?? () => _showNotificationModal(context),
          icon: Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationModal(),
    );
  }
}

/// 알림 모달
class NotificationModal extends ConsumerStatefulWidget {
  const NotificationModal({super.key});

  @override
  ConsumerState<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends ConsumerState<NotificationModal> {
  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService.instance.notifications;
    final unreadNotifications = NotificationService.instance.unreadNotifications;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  '알림',
                  style: AppTypography.heading3,
                ),
                const Spacer(),
                if (unreadNotifications.isNotEmpty) ...[
                  TextButton(
                    onPressed: () async {
                      await NotificationService.instance.markAllAsRead();
                      setState(() {});
                    },
                    child: Text(
                      '모두 읽음',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // 알림 리스트
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationListItem(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                        onRemove: () => _removeNotification(notification.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '알림이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 데이터 업데이트나 알림이\n있을 때 여기에 표시됩니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) async {
    await NotificationService.instance.markAsRead(notification.id);
    setState(() {});
    
    // TODO: 알림에 따른 화면 이동 처리
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _removeNotification(String notificationId) async {
    await NotificationService.instance.deleteNotification(notificationId);
    setState(() {});
  }
}

/// 알림 리스트 아이템
class NotificationListItem extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.white : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? AppColors.outline : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          notification.title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityBadge(),
                const Spacer(),
                Text(
                  _formatTime(notification.scheduledAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') {
              onRemove?.call();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getPriorityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          notification.iconEmoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        notification.priority.displayName,
        style: AppTypography.caption.copyWith(
          color: _getPriorityColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (notification.priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.medium:
        return AppColors.primary;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.critical:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

/// 알림 설정 버튼
class NotificationSettingsButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const NotificationSettingsButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed ?? () => _showNotificationSettings(context),
      icon: Icon(
        Icons.settings,
        size: 18,
        color: AppColors.primary,
      ),
      label: Text(
        '알림 설정',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationSettingsModal(),
    );
  }
}

/// 알림 설정 모달
class NotificationSettingsModal extends ConsumerWidget {
  const NotificationSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  '알림 설정',
                  style: AppTypography.heading3,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // 설정 목록
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildSettingTile(
                  '데이터 업데이트 알림',
                  '새로운 경제 데이터가 업데이트될 때 알림을 받습니다',
                  true,
                  (value) {},
                ),
                _buildSettingTile(
                  '임계값 알림',
                  '설정한 임계값에 도달했을 때 알림을 받습니다',
                  false,
                  (value) {},
                ),
                _buildSettingTile(
                  '순위 변동 알림',
                  '국가 순위가 변경되었을 때 알림을 받습니다',
                  true,
                  (value) {},
                ),
                _buildSettingTile(
                  '주간 리포트',
                  '매주 경제지표 요약 리포트를 받습니다',
                  false,
                  (value) {},
                ),
                const SizedBox(height: 20),
                Text(
                  '알림 시간',
                  style: AppTypography.bodyMediumBold,
                ),
                const SizedBox(height: 12),
                _buildTimePicker(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('알림 설정이 저장되었습니다'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: AppTypography.bodyMedium,
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            '오전 9:00',
            style: AppTypography.bodyMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // TODO: 시간 선택 다이얼로그
            },
            child: Text(
              '변경',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}