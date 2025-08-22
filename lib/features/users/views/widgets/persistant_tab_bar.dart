import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:geo_economy_dashboard/common/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PersistentTabBar extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).appBarTheme.backgroundColor
            : Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: const TabBar(
        //labelColor: Colors.black,
        //indicatorColor: Colors.black,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Sizes.size20,
              vertical: Sizes.size10,
            ),
            child: Icon(Icons.grid_4x4),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Sizes.size20,
              vertical: Sizes.size5,
            ),
            child: FaIcon(FontAwesomeIcons.heart),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 47;

  @override
  double get minExtent => 47;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
