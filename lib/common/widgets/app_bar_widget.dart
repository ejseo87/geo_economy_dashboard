import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/settings/views/settings_screen.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import 'package:geo_economy_dashboard/common/countries/widgets/country_selection_bottom_sheet.dart';
import 'package:geo_economy_dashboard/common/countries/view_models/selected_country_provider.dart';
import 'package:geo_economy_dashboard/features/notifications/widgets/notification_button.dart';
import 'package:geo_economy_dashboard/common/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class AppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  final bool showGear;
  final bool showGlobe;
  final bool showNotification;
  final String? title;

  const AppBarWidget({
    super.key,
    this.showGear = true,
    this.showGlobe = true,
    this.showNotification = true,
    this.title,
  });

  void _onGearTap(BuildContext context) {
    context.pushNamed(SettingsScreen.routeName);
  }

  void _onGlobeTap(BuildContext context, WidgetRef ref) {
    final selectedCountry = ref.read(selectedCountryProvider);

    CountrySelectionBottomSheet.show(
      context,
      selectedCountry: selectedCountry,
      onCountrySelected: (country) {
        ref.read(selectedCountryProvider.notifier).selectCountry(country);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(settingsProvider).darkmode;
    final selectedCountry = ref.watch(selectedCountryProvider);
    final surfaceColor = isDark ? const Color(0xFF16213E) : AppColors.white;

    return AppBar(
      backgroundColor: surfaceColor,
      elevation: 0,
      leading: showGlobe
          ? GestureDetector(
              onTap: () => _onGlobeTap(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedCountry.flagEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 4),
                    FaIcon(
                      FontAwesomeIcons.chevronDown,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      size: 12,
                    ),
                  ],
                ),
              ),
            )
          : null,
      title: Column(
        children: [
          Text(
            title ?? 'Geo Economy Dashboard',
            style: AppTypography.heading4.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showGlobe)
            Text(
              selectedCountry.nameKo,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Center(child: ConnectionStatusWidget()),
        ),
        if (showNotification) const NotificationButton(),
        if (showGear)
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.gear,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () => _onGearTap(context),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
