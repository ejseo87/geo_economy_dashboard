import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/settings/view_models/settings_view_model.dart';
import '../../features/search/views/search_screen.dart';
import '../widgets/app_bar_widget.dart';
import 'widgets/nav_tab.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  static const String routeName = "mainNavigation";
  static const String routeURL = "/";

  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsProvider).darkmode;
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          SearchScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
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
            children: [
              NavTab(
                icon: FontAwesomeIcons.house,
                selectedIcon: FontAwesomeIcons.house,
                text: '홈',
                isSelected: _selectedIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              NavTab(
                icon: FontAwesomeIcons.magnifyingGlass,
                selectedIcon: FontAwesomeIcons.magnifyingGlass,
                text: '검색',
                isSelected: _selectedIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              NavTab(
                icon: FontAwesomeIcons.bookmark,
                selectedIcon: FontAwesomeIcons.solidBookmark,
                text: '즐겨찾기',
                isSelected: _selectedIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              NavTab(
                icon: FontAwesomeIcons.gear,
                selectedIcon: FontAwesomeIcons.gear,
                text: '설정',
                isSelected: _selectedIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// 임시 즐겨찾기 화면
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBarWidget(
        title: '즐겨찾기',
        showGlobe: false,
      ),
      body: Center(
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.solidBookmark,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: Sizes.size16),
            Text(
              '즐겨찾기 기능 구현 예정',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}