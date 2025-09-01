import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../models/country.dart';
import '../widgets/country_indicators_section.dart';
import '../widgets/country_overview_card.dart';
import '../../../features/favorites/widgets/favorites_floating_button.dart';
import '../../../features/favorites/models/favorite_item.dart';
import '../../../features/worldbank/models/indicator_codes.dart';

class CountryDetailScreen extends ConsumerWidget {
  static const String routeName = 'countryDetail';
  static const String routeURL = '/country/:countryCode';
  
  final Country country;
  
  const CountryDetailScreen({
    super.key,
    required this.country,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size16),
              child: Column(
                children: [
                  _build10YearLineChart(),
                  const SizedBox(height: Sizes.size16),
                  _buildOECDComparisonChart(),
                  const SizedBox(height: Sizes.size16),
                  _buildIndicatorButtonsGrid(context),
                  const SizedBox(height: Sizes.size16),
                  CountryOverviewCard(country: country),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FavoritesFloatingButton(
        favoriteItem: FavoriteItemFactory.createCountrySummary(
          country: country,
          indicators: [
            IndicatorCode.gdpRealGrowth,
            IndicatorCode.cpiInflation,
            IndicatorCode.unemployment,
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              country.flagEmoji.isNotEmpty ? country.flagEmoji : '🏳️',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              country.nameKo,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                Color(0xFF003D7A),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  country.flagEmoji.isNotEmpty ? country.flagEmoji : '🏳️',
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: Sizes.size8),
                Text(
                  country.nameKo,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Sizes.size4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sizes.size12,
                    vertical: Sizes.size4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${country.region} • ${country.code}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}