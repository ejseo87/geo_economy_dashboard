import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/settings/views/settings_screen.dart';
import 'package:geo_economy_dashboard/features/authentication/views/login_screen.dart';
import 'package:geo_economy_dashboard/features/authentication/repos/authentication_repo.dart';
import 'package:geo_economy_dashboard/features/users/views/user_profile_screen.dart';
import 'package:geo_economy_dashboard/features/users/view_models/user_profile_view_model.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import 'package:geo_economy_dashboard/common/countries/widgets/country_selection_bottom_sheet.dart';
import 'package:geo_economy_dashboard/common/countries/view_models/selected_country_provider.dart';
import 'package:geo_economy_dashboard/features/notifications/widgets/notification_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class AppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  final bool showGear;
  final bool showGlobe;
  final bool showNotification;
  final bool showLogin;
  final String? title;

  const AppBarWidget({
    super.key,
    this.showGear = false,
    this.showGlobe = true,
    this.showNotification = true,
    this.showLogin = true,
    this.title,
  });

  void _onGearTap(BuildContext context) {
    context.pushNamed(SettingsScreen.routeName);
  }

  void _onLoginTap(BuildContext context) {
    context.pushNamed(LoginScreen.routeName);
  }

  void _onProfileTap(BuildContext context) {
    context.pushNamed(UserProfileScreen.routeName);
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
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final userProfileAsync = ref.watch(userProfileViewModelProvider);
    final surfaceColor = isDark ? const Color(0xFF16213E) : AppColors.white;

    return AppBar(
      backgroundColor: surfaceColor,
      elevation: 2,
     
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
                      style: const TextStyle(fontSize: 24),
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
          showGlobe
              ? Text(
                  selectedCountry.nameKo,
                  style: AppTypography.heading2.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  title ?? '국제지표 현황',
                  style: AppTypography.heading2.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          Gaps.v4,
          Text(
            'OECD 38개국과 비교',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),

      centerTitle: true,
      actions: [
        if (showNotification) const NotificationButton(),
        if (showLogin) _buildProfileButton(context, isLoggedIn, userProfileAsync, isDark),
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

  Widget _buildProfileButton(
    BuildContext context, 
    bool isLoggedIn, 
    AsyncValue userProfileAsync,
    bool isDark,
  ) {
    if (!isLoggedIn) {
      // 로그인되지 않은 경우 로그인 아이콘 표시
      return IconButton(
        icon: FaIcon(
          FontAwesomeIcons.user,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () => _onLoginTap(context),
      );
    }

    // 로그인된 경우 아바타 표시
    return userProfileAsync.when(
      loading: () => Container(
        margin: const EdgeInsets.all(8),
        width: 32,
        height: 32,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => IconButton(
        icon: FaIcon(
          FontAwesomeIcons.userXmark,
          color: isDark ? Colors.white70 : AppColors.error,
          size: 20,
        ),
        onPressed: () => _onProfileTap(context),
      ),
      data: (profile) {
        return GestureDetector(
          onTap: () => _onProfileTap(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white24 : AppColors.outline,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: profile?.avatarUrl != null
                  ? Image.network(
                      profile!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primary,
                        child: const FaIcon(
                          FontAwesomeIcons.user,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.primary,
                      child: const FaIcon(
                        FontAwesomeIcons.user,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
