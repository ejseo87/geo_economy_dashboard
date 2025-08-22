import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/logger.dart';
import '../models/indicator_metadata.dart';
import '../services/indicator_detail_service.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../../countries/models/country.dart';

part 'indicator_detail_view_model.g.dart';

/// 지표 상세 정보 프로바이더
@riverpod
Future<IndicatorDetail> indicatorDetail(
  Ref ref,
  IndicatorCode indicatorCode,
  Country country,
) async {
  final service = IndicatorDetailService();
  
  try {
    AppLogger.debug('[IndicatorDetailProvider] Loading detail for ${indicatorCode.name} in ${country.nameKo}');
    
    final detail = await service.getIndicatorDetail(
      indicatorCode: indicatorCode,
      country: country,
    );
    
    AppLogger.info('[IndicatorDetailProvider] Successfully loaded detail for ${indicatorCode.name}');
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
IndicatorDetailMetadata indicatorMetadata(
  Ref ref,
  IndicatorCode indicatorCode,
) {
  switch (indicatorCode) {
    case IndicatorCode.gdpRealGrowth:
      return IndicatorDetailMetadataFactory.createGDPRealGrowth();
    case IndicatorCode.unemployment:
      return IndicatorDetailMetadataFactory.createUnemploymentRate();
    case IndicatorCode.cpiInflation:
      return IndicatorDetailMetadataFactory.createInflationCPI();
    default:
      return IndicatorDetailMetadata(
        code: indicatorCode.code,
        name: indicatorCode.name,
        nameEn: indicatorCode.name,
        description: '${indicatorCode.name}에 대한 경제 지표입니다.',
        unit: indicatorCode.unit,
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
  @override
  Set<String> build() {
    // 로컬 스토리지에서 북마크 목록 로드 (추후 구현)
    return <String>{};
  }

  /// 북마크 토글
  void toggleBookmark(IndicatorCode indicatorCode, String countryCode) {
    final key = '${indicatorCode.code}_$countryCode';
    final newBookmarks = Set<String>.from(state);
    
    if (newBookmarks.contains(key)) {
      newBookmarks.remove(key);
      AppLogger.debug('[BookmarkViewModel] Removed bookmark: $key');
    } else {
      newBookmarks.add(key);
      AppLogger.debug('[BookmarkViewModel] Added bookmark: $key');
    }
    
    state = newBookmarks;
    // 로컬 스토리지에 저장 (추후 구현)
  }

  /// 북마크 상태 확인
  bool isBookmarked(IndicatorCode indicatorCode, String countryCode) {
    final key = '${indicatorCode.code}_$countryCode';
    return state.contains(key);
  }

  /// 모든 북마크 제거
  void clearAllBookmarks() {
    state = <String>{};
    AppLogger.debug('[BookmarkViewModel] Cleared all bookmarks');
  }
}

/// 지표 비교 뷰모델
@riverpod
class IndicatorComparisonViewModel extends _$IndicatorComparisonViewModel {
  @override
  List<IndicatorCode> build() {
    return [];
  }

  /// 비교 목록에 지표 추가
  void addToComparison(IndicatorCode indicatorCode) {
    if (state.length >= 5) {
      AppLogger.warning('[IndicatorComparisonViewModel] Maximum 5 indicators can be compared');
      return;
    }
    
    if (!state.contains(indicatorCode)) {
      state = [...state, indicatorCode];
      AppLogger.debug('[IndicatorComparisonViewModel] Added ${indicatorCode.name} to comparison');
    }
  }

  /// 비교 목록에서 지표 제거
  void removeFromComparison(IndicatorCode indicatorCode) {
    state = state.where((code) => code != indicatorCode).toList();
    AppLogger.debug('[IndicatorComparisonViewModel] Removed ${indicatorCode.name} from comparison');
  }

  /// 비교 목록 초기화
  void clearComparison() {
    state = [];
    AppLogger.debug('[IndicatorComparisonViewModel] Cleared comparison list');
  }

  /// 지표가 비교 목록에 있는지 확인
  bool isInComparison(IndicatorCode indicatorCode) {
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
  void addRecentIndicator(IndicatorCode indicatorCode, Country country) {
    final newIndicator = RecentIndicator(
      indicatorCode: indicatorCode,
      country: country,
      viewedAt: DateTime.now(),
    );

    // 중복 제거
    final filtered = state.where((item) => 
        !(item.indicatorCode == indicatorCode && item.country.code == country.code)
    ).toList();

    // 최신 항목을 맨 앞에 추가 (최대 20개)
    state = [newIndicator, ...filtered].take(20).toList();
    
    AppLogger.debug('[RecentIndicatorsViewModel] Added ${indicatorCode.name} for ${country.nameKo}');
  }

  /// 최근 본 지표 제거
  void removeRecentIndicator(IndicatorCode indicatorCode, Country country) {
    state = state.where((item) => 
        !(item.indicatorCode == indicatorCode && item.country.code == country.code)
    ).toList();
    
    AppLogger.debug('[RecentIndicatorsViewModel] Removed ${indicatorCode.name} for ${country.nameKo}');
  }

  /// 모든 최근 본 지표 제거
  void clearRecentIndicators() {
    state = [];
    AppLogger.debug('[RecentIndicatorsViewModel] Cleared all recent indicators');
  }
}

/// 최근 본 지표 데이터 클래스
class RecentIndicator {
  final IndicatorCode indicatorCode;
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