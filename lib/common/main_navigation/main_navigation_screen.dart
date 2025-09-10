import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../features/settings/view_models/settings_view_model.dart';
import 'widgets/nav_tab.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  static const String routeName = "mainNavigation";
  static const String routeURL = "/";
  
  final StatefulNavigationShell navigationShell;

  const MainNavigationScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsProvider).darkmode;
    
    return Scaffold(
      body: widget.navigationShell,
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
                isSelected: widget.navigationShell.currentIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              NavTab(
                icon: FontAwesomeIcons.magnifyingGlass,
                selectedIcon: FontAwesomeIcons.magnifyingGlass,
                text: '검색',
                isSelected: widget.navigationShell.currentIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              NavTab(
                icon: FontAwesomeIcons.bookmark,
                selectedIcon: FontAwesomeIcons.solidBookmark,
                text: '즐겨찾기',
                isSelected: widget.navigationShell.currentIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              NavTab(
                icon: FontAwesomeIcons.gear,
                selectedIcon: FontAwesomeIcons.gear,
                text: '설정',
                isSelected: widget.navigationShell.currentIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


