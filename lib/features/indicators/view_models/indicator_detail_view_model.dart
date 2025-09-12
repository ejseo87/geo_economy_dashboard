import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/logger.dart';
import '../models/indicator_metadata.dart';
import '../services/indicator_detail_service.dart';
import '../../worldbank/models/core_indicators.dart';
import '../../../common/countries/models/country.dart';

part 'indicator_detail_view_model.g.dart';

/// 지표 상세 정보 프로바이더
@riverpod
Future<IndicatorDetail> indicatorDetail(
  Ref ref,
  String indicatorCode,
  Country country,
) async {
  final service = IndicatorDetailService();

  try {
    final coreIndicator = CoreIndicators.findByCode(indicatorCode);
    final indicatorName = coreIndicator?.name ?? indicatorCode;

    AppLogger.debug(
      '[IndicatorDetailProvider] Loading detail for $indicatorName in ${country.nameKo}',
    );

    final detail = await service.getIndicatorDetail(
      indicatorCode: indicatorCode,
      country: country,
    );

    AppLogger.info(
      '[IndicatorDetailProvider] Successfully loaded detail for $indicatorName',
    );
    return detail;
  } catch (error) {
    AppLogger.error('[IndicatorDetailProvider] Error loading detail: $error');
    rethrow;
  } finally {
    service.dispose();
  }
}

/// 지표 메타데이터 프로바이더
@riverpod
IndicatorDetailMetadata indicatorMetadata(Ref ref, String indicatorCode) {
  final coreIndicator = CoreIndicators.findByCode(indicatorCode);
  if (coreIndicator != null) {
    return IndicatorDetailMetadata(
      code: coreIndicator.code,
      name: coreIndicator.name,
      nameEn: coreIndicator.nameEn,
      description: coreIndicator.description,
      unit: coreIndicator.unit,
      category: coreIndicator.category.nameKo,
      source: DataSourceFactory.worldBank(),
      updateFrequency: UpdateFrequency.yearly,
      methodology: 'World Bank 표준 방법론을 따라 계산됩니다.',
      limitations: '데이터 수집 방법론과 국가별 차이로 인한 제약이 있을 수 있습니다.',
      relatedIndicators: [],
      isHigherBetter: coreIndicator.isPositive == true,
    );
  }

  // 폴백 메타데이터
  switch (indicatorCode) {
    case 'NY.GDP.MKTP.KD.ZG':
      return IndicatorDetailMetadataFactory.createGDPRealGrowth();
    case 'SL.UEM.TOTL.ZS':
      return IndicatorDetailMetadataFactory.createUnemploymentRate();
    case 'FP.CPI.TOTL.ZG':
      return IndicatorDetailMetadataFactory.createInflationCPI();
    default:
      return IndicatorDetailMetadata(
        code: indicatorCode,
        name: indicatorCode,
        nameEn: indicatorCode,
        description: '$indicatorCode에 대한 경제 지표입니다.',
        unit: '%',
        category: '기타',
        source: DataSourceFactory.worldBank(),
        updateFrequency: UpdateFrequency.yearly,
        methodology: 'World Bank 표준 방법론을 따릅니다.',
        limitations: '데이터 수집 방법론의 차이가 있을 수 있습니다.',
        relatedIndicators: [],
        isHigherBetter: true,
      );
  }
}

/// 북마크 관리 뷰모델
@riverpod
class BookmarkViewModel extends _$BookmarkViewModel {
  static const String _bookmarksKey = 'user_bookmarks';

  @override
  Set<String> build() {
    _loadBookmarksSync();
    return <String>{};
  }

  /// 동기적으로 북마크를 로드 (SharedPreferences 캐시 사용)
  void _loadBookmarksSync() {
    SharedPreferences.getInstance()
        .then((prefs) {
          final bookmarksList = prefs.getStringList(_bookmarksKey) ?? [];
          state = Set<String>.from(bookmarksList);
          AppLogger.debug(
            '[BookmarkViewModel] Loaded ${bookmarksList.length} bookmarks',
          );
        })
        .catchError((e) {
          AppLogger.error('[BookmarkViewModel] Error loading bookmarks: $e');
        });
  }

  /// SharedPreferences에 북마크 저장
  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_bookmarksKey, state.toList());
      AppLogger.debug('[BookmarkViewModel] Saved ${state.length} bookmarks');
    } catch (e) {
      AppLogger.error('[BookmarkViewModel] Error saving bookmarks: $e');
    }
  }

  /// 북마크 토글
  void toggleBookmark(String indicatorCode, String countryCode) {
    final key = '${indicatorCode}_$countryCode';
    final newBookmarks = Set<String>.from(state);

    if (newBookmarks.contains(key)) {
      newBookmarks.remove(key);
      AppLogger.debug('[BookmarkViewModel] Removed bookmark: $key');
    } else {
      newBookmarks.add(key);
      AppLogger.debug('[BookmarkViewModel] Added bookmark: $key');
    }

    state = newBookmarks;
    _saveBookmarks();
  }

  /// 북마크 상태 확인
  bool isBookmarked(String indicatorCode, String countryCode) {
    final key = '${indicatorCode}_$countryCode';
    return state.contains(key);
  }

  /// 모든 북마크 제거
  void clearAllBookmarks() {
    state = <String>{};
    _saveBookmarks();
    AppLogger.debug('[BookmarkViewModel] Cleared all bookmarks');
  }

  /// 북마크 목록 가져오기 (파싱된 형태)
  List<BookmarkItem> getBookmarkItems() {
    return state.map((bookmark) {
      final parts = bookmark.split('_');
      if (parts.length >= 2) {
        final indicatorCode = parts[0];
        final countryCode = parts.sublist(1).join('_');
        return BookmarkItem(
          indicatorCode: indicatorCode,
          countryCode: countryCode,
          bookmarkKey: bookmark,
        );
      }
      return BookmarkItem(
        indicatorCode: bookmark,
        countryCode: '',
        bookmarkKey: bookmark,
      );
    }).toList();
  }
}

/// 북마크 아이템 클래스
class BookmarkItem {
  final String indicatorCode;
  final String countryCode;
  final String bookmarkKey;

  const BookmarkItem({
    required this.indicatorCode,
    required this.countryCode,
    required this.bookmarkKey,
  });
}

/// 지표 비교 뷰모델
@riverpod
class IndicatorComparisonViewModel extends _$IndicatorComparisonViewModel {
  @override
  List<String> build() {
    return [];
  }

  /// 비교 목록에 지표 추가
  void addToComparison(String indicatorCode) {
    if (state.length >= 5) {
      AppLogger.warning(
        '[IndicatorComparisonViewModel] Maximum 5 indicators can be compared',
      );
      return;
    }

    if (!state.contains(indicatorCode)) {
      state = [...state, indicatorCode];
      final coreIndicator = CoreIndicators.findByCode(indicatorCode);
      final indicatorName = coreIndicator?.name ?? indicatorCode;
      AppLogger.debug(
        '[IndicatorComparisonViewModel] Added $indicatorName to comparison',
      );
    }
  }

  /// 비교 목록에서 지표 제거
  void removeFromComparison(String indicatorCode) {
    state = state.where((code) => code != indicatorCode).toList();
    final coreIndicator = CoreIndicators.findByCode(indicatorCode);
    final indicatorName = coreIndicator?.name ?? indicatorCode;
    AppLogger.debug(
      '[IndicatorComparisonViewModel] Removed $indicatorName from comparison',
    );
  }

  /// 비교 목록 초기화
  void clearComparison() {
    state = [];
    AppLogger.debug('[IndicatorComparisonViewModel] Cleared comparison list');
  }

  /// 지표가 비교 목록에 있는지 확인
  bool isInComparison(String indicatorCode) {
    return state.contains(indicatorCode);
  }
}

/// 최근 본 지표 뷰모델
@riverpod
class RecentIndicatorsViewModel extends _$RecentIndicatorsViewModel {
  @override
  List<RecentIndicator> build() {
    // 로컬 스토리지에서 최근 본 지표 목록 로드 (추후 구현)
    return [];
  }

  /// 최근 본 지표에 추가
  void addRecentIndicator(String indicatorCode, Country country) {
    final newIndicator = RecentIndicator(
      indicatorCode: indicatorCode,
      country: country,
      viewedAt: DateTime.now(),
    );

    // 중복 제거
    final filtered = state
        .where(
          (item) =>
              !(item.indicatorCode == indicatorCode &&
                  item.country.code == country.code),
        )
        .toList();

    // 최신 항목을 맨 앞에 추가 (최대 20개)
    state = [newIndicator, ...filtered].take(20).toList();

    final coreIndicator = CoreIndicators.findByCode(indicatorCode);
    final indicatorName = coreIndicator?.name ?? indicatorCode;
    AppLogger.debug(
      '[RecentIndicatorsViewModel] Added $indicatorName for ${country.nameKo}',
    );
  }

  /// 최근 본 지표 제거
  void removeRecentIndicator(String indicatorCode, Country country) {
    state = state
        .where(
          (item) =>
              !(item.indicatorCode == indicatorCode &&
                  item.country.code == country.code),
        )
        .toList();

    final coreIndicator = CoreIndicators.findByCode(indicatorCode);
    final indicatorName = coreIndicator?.name ?? indicatorCode;
    AppLogger.debug(
      '[RecentIndicatorsViewModel] Removed $indicatorName for ${country.nameKo}',
    );
  }

  /// 모든 최근 본 지표 제거
  void clearRecentIndicators() {
    state = [];
    AppLogger.debug(
      '[RecentIndicatorsViewModel] Cleared all recent indicators',
    );
  }
}

/// 최근 본 지표 데이터 클래스
class RecentIndicator {
  final String indicatorCode;
  final Country country;
  final DateTime viewedAt;

  const RecentIndicator({
    required this.indicatorCode,
    required this.country,
    required this.viewedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentIndicator &&
        other.indicatorCode == indicatorCode &&
        other.country.code == country.code;
  }

  @override
  int get hashCode => indicatorCode.hashCode ^ country.code.hashCode;
}
