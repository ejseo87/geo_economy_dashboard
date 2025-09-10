import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/logger.dart';
import '../models/favorite_item.dart';

/// 즐겨찾기 관리 서비스
class FavoritesService {
  static const String _keyPrefix = 'favorites_';
  static const String _keyFavoritesList = '${_keyPrefix}list';
  static const int _maxFavorites = 50; // 무료 사용자 기본 제한
  
  static FavoritesService? _instance;
  static FavoritesService get instance => _instance ??= FavoritesService._();
  
  FavoritesService._();

  SharedPreferences? _prefs;
  List<FavoriteItem> _favorites = [];
  
  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFavorites();
    AppLogger.info('[FavoritesService] Initialized with ${_favorites.length} favorites');
  }

  /// 모든 즐겨찾기 조회
  List<FavoriteItem> get favorites => List.unmodifiable(_favorites);

  /// 타입별 즐겨찾기 조회
  List<FavoriteItem> getFavoritesByType(FavoriteType type) {
    return _favorites.where((item) => item.type == type).toList();
  }

  /// 즐겨찾기 추가
  Future<bool> addFavorite(FavoriteItem item) async {
    try {
      // 중복 확인
      if (_favorites.any((fav) => fav.id == item.id)) {
        AppLogger.warning('[FavoritesService] Favorite already exists: ${item.id}');
        return false;
      }

      // 최대 개수 확인
      if (_favorites.length >= _maxFavorites) {
        AppLogger.warning('[FavoritesService] Maximum favorites limit reached: $_maxFavorites');
        return false;
      }

      _favorites.insert(0, item); // 최신 항목을 맨 앞에
      await _saveFavorites();
      
      AppLogger.info('[FavoritesService] Added favorite: ${item.title}');
      return true;
    } catch (e) {
      AppLogger.error('[FavoritesService] Error adding favorite: $e');
      return false;
    }
  }

  /// 즐겨찾기 제거
  Future<bool> removeFavorite(String id) async {
    try {
      final initialLength = _favorites.length;
      _favorites.removeWhere((item) => item.id == id);
      
      if (_favorites.length < initialLength) {
        await _saveFavorites();
        AppLogger.info('[FavoritesService] Removed favorite: $id');
        return true;
      } else {
        AppLogger.warning('[FavoritesService] Favorite not found: $id');
        return false;
      }
    } catch (e) {
      AppLogger.error('[FavoritesService] Error removing favorite: $e');
      return false;
    }
  }

  /// 즐겨찾기 업데이트
  Future<bool> updateFavorite(FavoriteItem item) async {
    try {
      final index = _favorites.indexWhere((fav) => fav.id == item.id);
      if (index != -1) {
        _favorites[index] = item;
        await _saveFavorites();
        AppLogger.info('[FavoritesService] Updated favorite: ${item.title}');
        return true;
      } else {
        AppLogger.warning('[FavoritesService] Favorite not found for update: ${item.id}');
        return false;
      }
    } catch (e) {
      AppLogger.error('[FavoritesService] Error updating favorite: $e');
      return false;
    }
  }

  /// 즐겨찾기 존재 여부 확인
  bool isFavorite(String id) {
    return _favorites.any((item) => item.id == id);
  }

  /// 특정 즐겨찾기 조회
  FavoriteItem? getFavorite(String id) {
    try {
      return _favorites.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 즐겨찾기 검색
  List<FavoriteItem> searchFavorites(String query) {
    if (query.trim().isEmpty) return favorites;
    
    final lowerQuery = query.toLowerCase();
    return _favorites.where((item) => 
      item.searchableText.contains(lowerQuery)
    ).toList();
  }

  /// 최근 본 항목으로 정렬된 즐겨찾기
  List<FavoriteItem> get recentlyViewedFavorites {
    final sortedFavorites = List<FavoriteItem>.from(_favorites);
    sortedFavorites.sort((a, b) => b.lastViewedTime.compareTo(a.lastViewedTime));
    return sortedFavorites;
  }

  /// 인기 있는 즐겨찾기 (자주 본 순)
  List<FavoriteItem> getPopularFavorites({int limit = 10}) {
    // 현재는 생성 시간 기준으로 정렬
    // 실제로는 조회 횟수나 최근 조회 빈도를 기준으로 해야 함
    final sortedFavorites = List<FavoriteItem>.from(_favorites);
    sortedFavorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedFavorites.take(limit).toList();
  }

  /// 태그별 즐겨찾기 그룹핑
  Map<String, List<FavoriteItem>> getFavoritesByTags() {
    final Map<String, List<FavoriteItem>> groupedFavorites = {};
    
    for (final favorite in _favorites) {
      for (final tag in favorite.tags) {
        groupedFavorites.putIfAbsent(tag, () => []).add(favorite);
      }
    }
    
    return groupedFavorites;
  }

  /// 즐겨찾기 순서 변경
  Future<bool> reorderFavorites(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < 0 || oldIndex >= _favorites.length || 
          newIndex < 0 || newIndex >= _favorites.length) {
        return false;
      }

      final item = _favorites.removeAt(oldIndex);
      _favorites.insert(newIndex, item);
      
      await _saveFavorites();
      AppLogger.info('[FavoritesService] Reordered favorites: $oldIndex -> $newIndex');
      return true;
    } catch (e) {
      AppLogger.error('[FavoritesService] Error reordering favorites: $e');
      return false;
    }
  }

  /// 즐겨찾기 일괄 삭제
  Future<bool> clearFavorites() async {
    try {
      _favorites.clear();
      await _saveFavorites();
      AppLogger.info('[FavoritesService] Cleared all favorites');
      return true;
    } catch (e) {
      AppLogger.error('[FavoritesService] Error clearing favorites: $e');
      return false;
    }
  }

  /// 타입별 즐겨찾기 개수
  Map<FavoriteType, int> getFavoritesCounts() {
    final counts = <FavoriteType, int>{};
    for (final type in FavoriteType.values) {
      counts[type] = _favorites.where((item) => item.type == type).length;
    }
    return counts;
  }

  /// 즐겨찾기 내보내기 (JSON)
  Future<String> exportFavorites() async {
    try {
      final exportData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'favorites': _favorites.map((item) => item.toJson()).toList(),
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      AppLogger.error('[FavoritesService] Error exporting favorites: $e');
      return '{}';
    }
  }

  /// 즐겨찾기 가져오기 (JSON)
  Future<bool> importFavorites(String jsonString, {bool merge = true}) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final favoritesData = data['favorites'] as List<dynamic>;
      
      final importedFavorites = favoritesData
          .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!merge) {
        _favorites.clear();
      }

      // 중복 제거하면서 추가
      for (final item in importedFavorites) {
        if (!_favorites.any((existing) => existing.id == item.id)) {
          _favorites.add(item);
        }
      }

      // 최대 개수 제한 적용
      if (_favorites.length > _maxFavorites) {
        _favorites = _favorites.take(_maxFavorites).toList();
      }

      await _saveFavorites();
      AppLogger.info('[FavoritesService] Imported ${importedFavorites.length} favorites');
      return true;
    } catch (e) {
      AppLogger.error('[FavoritesService] Error importing favorites: $e');
      return false;
    }
  }

  /// 즐겨찾기 로드
  Future<void> _loadFavorites() async {
    try {
      final favoritesJson = _prefs?.getString(_keyFavoritesList);
      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        final List<dynamic> favoritesList = jsonDecode(favoritesJson);
        _favorites = favoritesList
            .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.error('[FavoritesService] Error loading favorites: $e');
      _favorites = [];
    }
  }

  /// 즐겨찾기 저장
  Future<void> _saveFavorites() async {
    try {
      final favoritesJson = jsonEncode(_favorites.map((item) => item.toJson()).toList());
      await _prefs?.setString(_keyFavoritesList, favoritesJson);
    } catch (e) {
      AppLogger.error('[FavoritesService] Error saving favorites: $e');
    }
  }

  /// 즐겨찾기 통계
  FavoriteStats getStats() {
    final now = DateTime.now();
    final thisWeek = now.subtract(const Duration(days: 7));
    final thisMonth = now.subtract(const Duration(days: 30));

    return FavoriteStats(
      totalFavorites: _favorites.length,
      thisWeekFavorites: _favorites.where((item) => item.createdAt.isAfter(thisWeek)).length,
      thisMonthFavorites: _favorites.where((item) => item.createdAt.isAfter(thisMonth)).length,
      favoritesByType: getFavoritesCounts(),
      mostUsedTags: _getMostUsedTags(),
    );
  }

  /// 가장 많이 사용된 태그 조회
  List<String> _getMostUsedTags({int limit = 5}) {
    final tagCounts = <String, int>{};
    
    for (final favorite in _favorites) {
      for (final tag in favorite.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTags.take(limit).map((e) => e.key).toList();
  }
}

/// 즐겨찾기 통계 클래스
class FavoriteStats {
  final int totalFavorites;
  final int thisWeekFavorites;
  final int thisMonthFavorites;
  final Map<FavoriteType, int> favoritesByType;
  final List<String> mostUsedTags;

  const FavoriteStats({
    required this.totalFavorites,
    required this.thisWeekFavorites,
    required this.thisMonthFavorites,
    required this.favoritesByType,
    required this.mostUsedTags,
  });

  @override
  String toString() => 
      'FavoriteStats(total: $totalFavorites, week: $thisWeekFavorites, month: $thisMonthFavorites)';
}