import '../../worldbank/models/indicator_codes.dart';
import '../../../common/countries/models/country.dart';

/// 즐겨찾기 아이템 타입
enum FavoriteType {
  countrySummary('국가 요약'),
  indicatorComparison('지표 비교'),
  customComparison('사용자 정의 비교'),
  indicatorDetail('지표 상세');

  const FavoriteType(this.displayName);
  final String displayName;
}

/// 즐겨찾기 아이템
class FavoriteItem {
  final String id;
  final String title;
  final FavoriteType type;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final String? description;
  final String? thumbnailUrl;
  final List<String> tags;

  const FavoriteItem({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.data,
    this.description,
    this.thumbnailUrl,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'data': data,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'tags': tags,
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    id: json['id'] as String,
    title: json['title'] as String,
    type: FavoriteType.values.firstWhere((e) => e.name == json['type']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    data: json['data'] as Map<String, dynamic>,
    description: json['description'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  FavoriteItem copyWith({
    String? id,
    String? title,
    FavoriteType? type,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    String? description,
    String? thumbnailUrl,
    List<String>? tags,
  }) => FavoriteItem(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    data: data ?? this.data,
    description: description ?? this.description,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    tags: tags ?? this.tags,
  );
}

/// 국가 요약 즐겨찾기 데이터
class CountrySummaryFavorite {
  final String countryCode;
  final String countryName;
  final List<String> selectedIndicators;
  final DateTime? lastViewed;

  const CountrySummaryFavorite({
    required this.countryCode,
    required this.countryName,
    required this.selectedIndicators,
    this.lastViewed,
  });

  Map<String, dynamic> toJson() => {
    'countryCode': countryCode,
    'countryName': countryName,
    'selectedIndicators': selectedIndicators,
    'lastViewed': lastViewed?.toIso8601String(),
  };

  factory CountrySummaryFavorite.fromJson(Map<String, dynamic> json) => 
      CountrySummaryFavorite(
    countryCode: json['countryCode'] as String,
    countryName: json['countryName'] as String,
    selectedIndicators: (json['selectedIndicators'] as List<dynamic>).cast<String>(),
    lastViewed: json['lastViewed'] != null 
        ? DateTime.parse(json['lastViewed'] as String) 
        : null,
  );
}

/// 지표 비교 즐겨찾기 데이터
class IndicatorComparisonFavorite {
  final String indicatorCode;
  final String indicatorName;
  final List<String> countryCodes;
  final List<String> countryNames;
  final String? comparisonType;
  final Map<String, dynamic>? settings;
  final DateTime? lastViewed;

  const IndicatorComparisonFavorite({
    required this.indicatorCode,
    required this.indicatorName,
    required this.countryCodes,
    required this.countryNames,
    this.comparisonType,
    this.settings,
    this.lastViewed,
  });

  Map<String, dynamic> toJson() => {
    'indicatorCode': indicatorCode,
    'indicatorName': indicatorName,
    'countryCodes': countryCodes,
    'countryNames': countryNames,
    'comparisonType': comparisonType,
    'settings': settings,
    'lastViewed': lastViewed?.toIso8601String(),
  };

  factory IndicatorComparisonFavorite.fromJson(Map<String, dynamic> json) => 
      IndicatorComparisonFavorite(
    indicatorCode: json['indicatorCode'] as String,
    indicatorName: json['indicatorName'] as String,
    countryCodes: (json['countryCodes'] as List<dynamic>).cast<String>(),
    countryNames: (json['countryNames'] as List<dynamic>).cast<String>(),
    comparisonType: json['comparisonType'] as String?,
    settings: json['settings'] as Map<String, dynamic>?,
    lastViewed: json['lastViewed'] != null 
        ? DateTime.parse(json['lastViewed'] as String) 
        : null,
  );
}

/// 사용자 정의 비교 즐겨찾기 데이터
class CustomComparisonFavorite {
  final String name;
  final List<String> indicatorCodes;
  final List<String> countryCodes;
  final String? chartType;
  final String? timeRange;
  final Map<String, dynamic>? customSettings;
  final DateTime? lastViewed;

  const CustomComparisonFavorite({
    required this.name,
    required this.indicatorCodes,
    required this.countryCodes,
    this.chartType,
    this.timeRange,
    this.customSettings,
    this.lastViewed,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'indicatorCodes': indicatorCodes,
    'countryCodes': countryCodes,
    'chartType': chartType,
    'timeRange': timeRange,
    'customSettings': customSettings,
    'lastViewed': lastViewed?.toIso8601String(),
  };

  factory CustomComparisonFavorite.fromJson(Map<String, dynamic> json) => 
      CustomComparisonFavorite(
    name: json['name'] as String,
    indicatorCodes: (json['indicatorCodes'] as List<dynamic>).cast<String>(),
    countryCodes: (json['countryCodes'] as List<dynamic>).cast<String>(),
    chartType: json['chartType'] as String?,
    timeRange: json['timeRange'] as String?,
    customSettings: json['customSettings'] as Map<String, dynamic>?,
    lastViewed: json['lastViewed'] != null 
        ? DateTime.parse(json['lastViewed'] as String) 
        : null,
  );
}

/// 즐겨찾기 아이템 생성 헬퍼
class FavoriteItemFactory {
  /// 국가 요약 즐겨찾기 생성
  static FavoriteItem createCountrySummary({
    required Country country,
    required List<IndicatorCode> indicators,
  }) {
    final data = CountrySummaryFavorite(
      countryCode: country.code,
      countryName: country.nameKo,
      selectedIndicators: indicators.map((e) => e.code).toList(),
      lastViewed: DateTime.now(),
    );

    return FavoriteItem(
      id: _generateId('country_summary', country.code),
      title: '${country.nameKo} 요약',
      type: FavoriteType.countrySummary,
      createdAt: DateTime.now(),
      data: data.toJson(),
      description: '${country.nameKo}의 핵심 ${indicators.length}개 지표 요약',
      tags: [country.code, 'summary'],
    );
  }

  /// 지표 비교 즐겨찾기 생성
  static FavoriteItem createIndicatorComparison({
    required IndicatorCode indicator,
    required List<Country> countries,
    String? comparisonType,
  }) {
    final data = IndicatorComparisonFavorite(
      indicatorCode: indicator.code,
      indicatorName: indicator.name,
      countryCodes: countries.map((e) => e.code).toList(),
      countryNames: countries.map((e) => e.nameKo).toList(),
      comparisonType: comparisonType,
      lastViewed: DateTime.now(),
    );

    final countryNames = countries.map((e) => e.nameKo).join(', ');
    
    return FavoriteItem(
      id: _generateId('indicator_comparison', '${indicator.code}_${countries.map((e) => e.code).join('_')}'),
      title: '${indicator.name} 비교',
      type: FavoriteType.indicatorComparison,
      createdAt: DateTime.now(),
      data: data.toJson(),
      description: '$countryNames 간 ${indicator.name} 비교',
      tags: [indicator.code, ...countries.map((e) => e.code)],
    );
  }

  /// 사용자 정의 비교 즐겨찾기 생성
  static FavoriteItem createCustomComparison({
    required String name,
    required List<IndicatorCode> indicators,
    required List<Country> countries,
    String? chartType,
    String? timeRange,
    Map<String, dynamic>? customSettings,
  }) {
    final data = CustomComparisonFavorite(
      name: name,
      indicatorCodes: indicators.map((e) => e.code).toList(),
      countryCodes: countries.map((e) => e.code).toList(),
      chartType: chartType,
      timeRange: timeRange,
      customSettings: customSettings,
      lastViewed: DateTime.now(),
    );

    return FavoriteItem(
      id: _generateId('custom_comparison', name.replaceAll(' ', '_').toLowerCase()),
      title: name,
      type: FavoriteType.customComparison,
      createdAt: DateTime.now(),
      data: data.toJson(),
      description: '${indicators.length}개 지표, ${countries.length}개 국가 사용자 정의 비교',
      tags: ['custom', ...indicators.map((e) => e.code), ...countries.map((e) => e.code)],
    );
  }

  /// 고유 ID 생성
  static String _generateId(String prefix, String suffix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_${suffix}_$timestamp';
  }
}

/// 즐겨찾기 아이템 확장 메서드
extension FavoriteItemExtensions on FavoriteItem {
  /// 국가 요약 데이터 가져오기
  CountrySummaryFavorite? get countrySummaryData {
    if (type == FavoriteType.countrySummary) {
      try {
        return CountrySummaryFavorite.fromJson(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 지표 비교 데이터 가져오기
  IndicatorComparisonFavorite? get indicatorComparisonData {
    if (type == FavoriteType.indicatorComparison) {
      try {
        return IndicatorComparisonFavorite.fromJson(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 사용자 정의 비교 데이터 가져오기
  CustomComparisonFavorite? get customComparisonData {
    if (type == FavoriteType.customComparison) {
      try {
        return CustomComparisonFavorite.fromJson(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 마지막 조회 시간으로 정렬을 위한 값
  DateTime get lastViewedTime {
    switch (type) {
      case FavoriteType.countrySummary:
        return countrySummaryData?.lastViewed ?? createdAt;
      case FavoriteType.indicatorComparison:
        return indicatorComparisonData?.lastViewed ?? createdAt;
      case FavoriteType.customComparison:
        return customComparisonData?.lastViewed ?? createdAt;
      case FavoriteType.indicatorDetail:
        return createdAt; // 상세의 경우 생성 시간 사용
    }
  }

  /// 검색용 텍스트 (제목 + 설명 + 태그)
  String get searchableText => 
      '$title ${description ?? ''} ${tags.join(' ')}'.toLowerCase();
}