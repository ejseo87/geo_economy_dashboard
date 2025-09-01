import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/logger.dart';

class SearchHistoryService {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryLength = 10;

  /// 검색 기록 저장
  static Future<void> addSearchHistory(String query) async {
    try {
      if (query.trim().isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      final history = await getSearchHistory();
      
      // 중복 제거 및 최상단으로 이동
      history.remove(query);
      history.insert(0, query);
      
      // 최대 길이 제한
      if (history.length > _maxHistoryLength) {
        history.removeLast();
      }
      
      await prefs.setStringList(_historyKey, history);
      AppLogger.debug('[SearchHistory] Added: $query');
    } catch (e) {
      AppLogger.error('[SearchHistory] Error adding history: $e');
    }
  }

  /// 검색 기록 조회
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_historyKey) ?? [];
    } catch (e) {
      AppLogger.error('[SearchHistory] Error getting history: $e');
      return [];
    }
  }

  /// 검색 기록 삭제
  static Future<void> removeSearchHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getSearchHistory();
      history.remove(query);
      await prefs.setStringList(_historyKey, history);
      AppLogger.debug('[SearchHistory] Removed: $query');
    } catch (e) {
      AppLogger.error('[SearchHistory] Error removing history: $e');
    }
  }

  /// 모든 검색 기록 삭제
  static Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      AppLogger.debug('[SearchHistory] Cleared all history');
    } catch (e) {
      AppLogger.error('[SearchHistory] Error clearing history: $e');
    }
  }
}