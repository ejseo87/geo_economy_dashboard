import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../models/favorite_item.dart';
import '../services/favorites_service.dart';

/// 즐겨찾기 플로팅 버튼
class FavoritesFloatingButton extends ConsumerStatefulWidget {
  final FavoriteItem? favoriteItem;
  final String? customId;
  final VoidCallback? onFavoriteAdded;
  final VoidCallback? onFavoriteRemoved;

  const FavoritesFloatingButton({
    super.key,
    this.favoriteItem,
    this.customId,
    this.onFavoriteAdded,
    this.onFavoriteRemoved,
  });

  @override
  ConsumerState<FavoritesFloatingButton> createState() =>
      _FavoritesFloatingButtonState();
}

class _FavoritesFloatingButtonState
    extends ConsumerState<FavoritesFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isFavorite {
    if (widget.favoriteItem != null) {
      return FavoritesService.instance.isFavorite(widget.favoriteItem!.id);
    }
    if (widget.customId != null) {
      return FavoritesService.instance.isFavorite(widget.customId!);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: _isLoading ? null : _toggleFavorite,
            backgroundColor: _isFavorite ? AppColors.primary : AppColors.white,
            foregroundColor: _isFavorite ? Colors.white : AppColors.primary,
            elevation: 8,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 28,
                  ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading || widget.favoriteItem == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      final favoritesService = FavoritesService.instance;
      bool success = false;

      if (_isFavorite) {
        // 즐겨찾기 제거
        success = await favoritesService.removeFavorite(
          widget.favoriteItem!.id,
        );
        if (success) {
          widget.onFavoriteRemoved?.call();
          _showSnackBar('즐겨찾기에서 제거되었습니다', Colors.orange);
        }
      } else {
        // 즐겨찾기 추가
        success = await favoritesService.addFavorite(widget.favoriteItem!);
        if (success) {
          widget.onFavoriteAdded?.call();
          _showSnackBar('즐겨찾기에 추가되었습니다', Colors.green);
        } else {
          _showSnackBar('즐겨찾기 추가에 실패했습니다', Colors.red);
        }
      }
    } catch (e) {
      _showSnackBar('오류가 발생했습니다', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// 즐겨찾기 상태 위젯 (하트 아이콘만)
class FavoriteHeartIcon extends ConsumerWidget {
  final String favoriteId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onTap;

  const FavoriteHeartIcon({
    super.key,
    required this.favoriteId,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = FavoritesService.instance.isFavorite(favoriteId);

    return GestureDetector(
      onTap: onTap,
      child: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: isFavorite
            ? (activeColor ?? AppColors.primary)
            : (inactiveColor ?? AppColors.textSecondary),
      ),
    );
  }
}

/// 즐겨찾기 버튼 (작은 버튼 형태)
class FavoriteButton extends ConsumerStatefulWidget {
  final FavoriteItem favoriteItem;
  final VoidCallback? onFavoriteChanged;

  const FavoriteButton({
    super.key,
    required this.favoriteItem,
    this.onFavoriteChanged,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _isLoading = false;

  bool get _isFavorite =>
      FavoritesService.instance.isFavorite(widget.favoriteItem.id);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _toggleFavorite,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: _isFavorite
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isFavorite ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ] else ...[
              Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: _isFavorite
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ],
            const SizedBox(width: 4),
            Text(
              _isFavorite ? '즐겨찾기됨' : '즐겨찾기',
              style: AppTypography.bodySmall.copyWith(
                color: _isFavorite
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: _isFavorite ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final favoritesService = FavoritesService.instance;
      bool success = false;

      if (_isFavorite) {
        success = await favoritesService.removeFavorite(widget.favoriteItem.id);
      } else {
        success = await favoritesService.addFavorite(widget.favoriteItem);
      }

      if (success) {
        widget.onFavoriteChanged?.call();
      }
    } catch (e) {
      // 에러 처리
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// 즐겨찾기 상태 배지
class FavoriteBadge extends ConsumerWidget {
  final String favoriteId;
  final Widget child;

  const FavoriteBadge({
    super.key,
    required this.favoriteId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = FavoritesService.instance.isFavorite(favoriteId);

    if (!isFavorite) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// 즐겨찾기 리스트 아이템
class FavoriteListItem extends ConsumerWidget {
  final FavoriteItem favorite;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const FavoriteListItem({
    super.key,
    required this.favorite,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getTypeIcon(favorite.type), color: AppColors.primary),
        ),
        title: Text(
          favorite.title,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favorite.description != null) ...[
              const SizedBox(height: 4),
              Text(
                favorite.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    favorite.type.displayName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(favorite.createdAt),
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

  IconData _getTypeIcon(FavoriteType type) {
    switch (type) {
      case FavoriteType.countrySummary:
        return Icons.flag;
      case FavoriteType.indicatorComparison:
        return Icons.compare_arrows;
      case FavoriteType.customComparison:
        return Icons.dashboard_customize;
      case FavoriteType.indicatorDetail:
        return Icons.analytics;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else {
      return '방금 전';
    }
  }
}
