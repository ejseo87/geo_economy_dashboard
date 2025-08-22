import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/settings/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class AppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  final bool showGear;
  const AppBarWidget({super.key, required this.showGear});

  void _onGearTap(BuildContext context) {
    context.pushNamed(SettingsScreen.routeName);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.white,
      title: Text(
        "Geo Economy Dashboard".toUpperCase(),
        style: AppTypography.heading3.copyWith(color: AppColors.primary),
      ),
      actions: showGear
          ? [
              GestureDetector(
                onTap: () => _onGearTap(context),
                child: Container(
                  height: (kToolbarHeight),
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(right: Sizes.size20),
                  child: FaIcon(
                    FontAwesomeIcons.gear,
                    size: Sizes.size18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
