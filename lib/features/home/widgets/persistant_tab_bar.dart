import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';

class PersistentTabBar extends SliverPersistentHeaderDelegate {
  final List<Tab> tabs;

  PersistentTabBar({required this.tabs});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? Colors.white10 : AppColors.outline,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        labelColor: isDark ? Colors.white : AppColors.primary,
        unselectedLabelColor: isDark ? Colors.white54 : AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        tabs: tabs
            .map(
              (tab) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sizes.size12,
                  vertical: Sizes.size10,
                ),
                child: tab,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}
