import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 제스처를 지원하는 래퍼 위젯
class GestureWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double swipeThreshold;
  final bool enableHapticFeedback;
  final Color? highlightColor;
  final BorderRadius? borderRadius;

  const GestureWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.swipeThreshold = 100,
    this.enableHapticFeedback = true,
    this.highlightColor,
    this.borderRadius,
  });

  @override
  State<GestureWrapper> createState() => _GestureWrapperState();
}

class _GestureWrapperState extends State<GestureWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _onLongPress() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final horizontalVelocity = details.velocity.pixelsPerSecond.dx;
    final verticalVelocity = details.velocity.pixelsPerSecond.dy;

    if (velocity.abs() < widget.swipeThreshold) return;

    if (horizontalVelocity.abs() > verticalVelocity.abs()) {
      // Horizontal swipe
      if (horizontalVelocity > 0) {
        // Swipe right
        if (widget.enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
        widget.onSwipeRight?.call();
      } else {
        // Swipe left
        if (widget.enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
        widget.onSwipeLeft?.call();
      }
    } else {
      // Vertical swipe
      if (verticalVelocity > 0) {
        // Swipe down
        if (widget.enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
        widget.onSwipeDown?.call();
      } else {
        // Swipe up
        if (widget.enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
        widget.onSwipeUp?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap != null ? _onTap : null,
            onLongPress: widget.onLongPress != null ? _onLongPress : null,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onPanEnd: _hasSwipeGestures() ? _onSwipe : null,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                  color: _isPressed 
                      ? (widget.highlightColor ?? Colors.grey.withValues(alpha: 0.1))
                      : Colors.transparent,
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }

  bool _hasSwipeGestures() {
    return widget.onSwipeLeft != null ||
        widget.onSwipeRight != null ||
        widget.onSwipeUp != null ||
        widget.onSwipeDown != null;
  }
}