import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/tab_state.dart';

part 'tab_view_model.g.dart';

@riverpod
class TabViewModel extends _$TabViewModel {
  @override
  TabState build() {
    return const TabState(currentTab: HomeTab.summary);
  }

  /// 탭 변경
  void changeTab(HomeTab newTab) {
    if (state.currentTab != newTab) {
      state = state.copyWith(
        currentTab: newTab,
        previousTabIndex: state.currentTab.index,
      );
    }
  }

  /// 탭 인덱스로 변경
  void changeTabByIndex(int index) {
    if (index >= 0 && index < HomeTab.values.length) {
      final tab = HomeTab.values[index];
      changeTab(tab);
    }
  }

  /// 이전 탭으로 돌아가기
  void goToPreviousTab() {
    if (state.previousTabIndex >= 0 && 
        state.previousTabIndex < HomeTab.values.length) {
      final previousTab = HomeTab.values[state.previousTabIndex];
      changeTab(previousTab);
    }
  }
}