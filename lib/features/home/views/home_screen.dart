import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import 'package:geo_economy_dashboard/features/settings/views/settings_screen.dart';
import '../../countries/widgets/country_selection_bottom_sheet.dart';
import '../../countries/view_models/selected_country_provider.dart';
import '../models/tab_state.dart';
import '../view_models/tab_view_model.dart';
import 'tabs/country_summary_tab.dart';
import 'tabs/ai_comparison_tab.dart';
import 'tabs/all_indicators_tab.dart';

class HomeScreen extends ConsumerWidget {
  static const String routeName = "home";
  static const String routeURL = "/home";
  
  const HomeScreen({super.key});

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
    final tabState = ref.watch(tabViewModelProvider);
    
    final backgroundColor = isDark
        ? const Color(0xFF1A1A2E)
        : AppColors.background;
    final surfaceColor = isDark ? const Color(0xFF16213E) : AppColors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.globe,
            color: isDark ? Colors.white : AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => _onGlobeTap(context, ref),
        ),
        title: Text(
          'Geo Economy Dashboard',
          style: AppTypography.heading3.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.gear,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () => _onGearTap(context),
          ),
        ],
      ),
      body: _buildTabContent(tabState.currentTab),
      bottomNavigationBar: _buildBottomNavigationBar(context, ref, isDark),
    );
  }

  Widget _buildTabContent(HomeTab currentTab) {
    switch (currentTab) {
      case HomeTab.summary:
        return const CountrySummaryTab();
      case HomeTab.comparison:
        return const AIComparisonTab();
      case HomeTab.indicators:
        return const AllIndicatorsTab();
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context, WidgetRef ref, bool isDark) {
    final tabState = ref.watch(tabViewModelProvider);
    final backgroundColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : AppColors.outline,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: HomeTab.values.map((tab) {
              final isSelected = tabState.currentTab == tab;
              return _buildNavItem(
                tab: tab,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => ref.read(tabViewModelProvider.notifier).changeTab(tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required HomeTab tab,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.white38 : AppColors.textSecondary;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? activeColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tab.icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}