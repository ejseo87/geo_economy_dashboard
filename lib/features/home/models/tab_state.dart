import 'package:flutter/material.dart';

/// 홈 탭 정의
enum HomeTab {
  summary('요약', Icons.summarize),
  comparison('비교', Icons.compare_arrows), 
  indicators('전체지표', Icons.dashboard);

  const HomeTab(this.label, this.icon);
  
  final String label;
  final IconData icon;
}

/// 홈 탭 상태 관리
class TabState {
  final HomeTab currentTab;
  final int previousTabIndex;
  
  const TabState({
    required this.currentTab,
    this.previousTabIndex = 0,
  });
  
  TabState copyWith({
    HomeTab? currentTab,
    int? previousTabIndex,
  }) {
    return TabState(
      currentTab: currentTab ?? this.currentTab,
      previousTabIndex: previousTabIndex ?? this.previousTabIndex,
    );
  }
}