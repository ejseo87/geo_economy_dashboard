import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/countries/view_models/selected_country_provider.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import '../../../common/widgets/app_bar_widget.dart';
import '../models/tab_state.dart';
import '../view_models/tab_view_model.dart';
import '../widgets/persistant_tab_bar.dart';
import 'tabs/country_summary_tab.dart';
import 'tabs/ai_comparison_tab.dart';
import 'tabs/all_indicators_tab.dart';

class HomeScreen extends ConsumerWidget {
  static const String routeName = "home";
  static const String routeURL = "/home";

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(settingsProvider).darkmode;
    final tabState = ref.watch(tabViewModelProvider);

    final backgroundColor = isDark
        ? const Color(0xFF1A1A2E)
        : AppColors.background;

    return DefaultTabController(
      length: HomeTab.values.length,
      initialIndex: HomeTab.values.indexOf(tabState.currentTab),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: const AppBarWidget(),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final selectedCountry = ref.watch(selectedCountryProvider);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Text(
                          selectedCountry.flagEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCountry.nameKo,
                                style: AppTypography.heading2,
                              ),
                              Text(
                                'OECD 38개국 중 현재 순위',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverPersistentHeader(
              delegate: PersistentTabBar(
                tabs: HomeTab.values
                    .map((tab) => Tab(icon: Icon(tab.icon), text: tab.label))
                    .toList(),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            children: HomeTab.values
                .map((tab) => _buildTabContent(tab))
                .toList(),
          ),
        ),
      ),
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
}
