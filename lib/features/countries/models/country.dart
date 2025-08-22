/// OECD 국가 정보 모델
class Country {
  final String code; // ISO3 코드 (예: 'KOR', 'USA')
  final String name; // 국가명
  final String nameKo; // 한국어 국가명
  final String flagEmoji; // 국기 이모지
  final String region; // 지역 (예: 'Asia', 'Europe')

  const Country({
    required this.code,
    required this.name,
    required this.nameKo,
    required this.flagEmoji,
    required this.region,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'nameKo': nameKo,
      'flagEmoji': flagEmoji,
      'region': region,
    };
  }

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] as String,
      name: json['name'] as String,
      nameKo: json['nameKo'] as String,
      flagEmoji: json['flagEmoji'] as String,
      region: json['region'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Country(code: $code, nameKo: $nameKo)';
}

/// OECD 38개국 데이터
class OECDCountries {
  static const List<Country> countries = [
    // 아시아-태평양
    Country(
      code: 'AUS',
      name: 'Australia',
      nameKo: '호주',
      flagEmoji: '🇦🇺',
      region: 'Asia-Pacific',
    ),
    Country(
      code: 'JPN',
      name: 'Japan',
      nameKo: '일본',
      flagEmoji: '🇯🇵',
      region: 'Asia-Pacific',
    ),
    Country(
      code: 'KOR',
      name: 'Korea',
      nameKo: '대한민국',
      flagEmoji: '🇰🇷',
      region: 'Asia-Pacific',
    ),
    Country(
      code: 'NZL',
      name: 'New Zealand',
      nameKo: '뉴질랜드',
      flagEmoji: '🇳🇿',
      region: 'Asia-Pacific',
    ),

    // 유럽
    Country(
      code: 'AUT',
      name: 'Austria',
      nameKo: '오스트리아',
      flagEmoji: '🇦🇹',
      region: 'Europe',
    ),
    Country(
      code: 'BEL',
      name: 'Belgium',
      nameKo: '벨기에',
      flagEmoji: '🇧🇪',
      region: 'Europe',
    ),
    Country(
      code: 'CZE',
      name: 'Czech Republic',
      nameKo: '체코',
      flagEmoji: '🇨🇿',
      region: 'Europe',
    ),
    Country(
      code: 'DNK',
      name: 'Denmark',
      nameKo: '덴마크',
      flagEmoji: '🇩🇰',
      region: 'Europe',
    ),
    Country(
      code: 'EST',
      name: 'Estonia',
      nameKo: '에스토니아',
      flagEmoji: '🇪🇪',
      region: 'Europe',
    ),
    Country(
      code: 'FIN',
      name: 'Finland',
      nameKo: '핀란드',
      flagEmoji: '🇫🇮',
      region: 'Europe',
    ),
    Country(
      code: 'FRA',
      name: 'France',
      nameKo: '프랑스',
      flagEmoji: '🇫🇷',
      region: 'Europe',
    ),
    Country(
      code: 'DEU',
      name: 'Germany',
      nameKo: '독일',
      flagEmoji: '🇩🇪',
      region: 'Europe',
    ),
    Country(
      code: 'GRC',
      name: 'Greece',
      nameKo: '그리스',
      flagEmoji: '🇬🇷',
      region: 'Europe',
    ),
    Country(
      code: 'HUN',
      name: 'Hungary',
      nameKo: '헝가리',
      flagEmoji: '🇭🇺',
      region: 'Europe',
    ),
    Country(
      code: 'ISL',
      name: 'Iceland',
      nameKo: '아이슬란드',
      flagEmoji: '🇮🇸',
      region: 'Europe',
    ),
    Country(
      code: 'IRL',
      name: 'Ireland',
      nameKo: '아일랜드',
      flagEmoji: '🇮🇪',
      region: 'Europe',
    ),
    Country(
      code: 'ITA',
      name: 'Italy',
      nameKo: '이탈리아',
      flagEmoji: '🇮🇹',
      region: 'Europe',
    ),
    Country(
      code: 'LVA',
      name: 'Latvia',
      nameKo: '라트비아',
      flagEmoji: '🇱🇻',
      region: 'Europe',
    ),
    Country(
      code: 'LTU',
      name: 'Lithuania',
      nameKo: '리투아니아',
      flagEmoji: '🇱🇹',
      region: 'Europe',
    ),
    Country(
      code: 'LUX',
      name: 'Luxembourg',
      nameKo: '룩셈부르크',
      flagEmoji: '🇱🇺',
      region: 'Europe',
    ),
    Country(
      code: 'NLD',
      name: 'Netherlands',
      nameKo: '네덜란드',
      flagEmoji: '🇳🇱',
      region: 'Europe',
    ),
    Country(
      code: 'NOR',
      name: 'Norway',
      nameKo: '노르웨이',
      flagEmoji: '🇳🇴',
      region: 'Europe',
    ),
    Country(
      code: 'POL',
      name: 'Poland',
      nameKo: '폴란드',
      flagEmoji: '🇵🇱',
      region: 'Europe',
    ),
    Country(
      code: 'PRT',
      name: 'Portugal',
      nameKo: '포르투갈',
      flagEmoji: '🇵🇹',
      region: 'Europe',
    ),
    Country(
      code: 'SVK',
      name: 'Slovak Republic',
      nameKo: '슬로바키아',
      flagEmoji: '🇸🇰',
      region: 'Europe',
    ),
    Country(
      code: 'SVN',
      name: 'Slovenia',
      nameKo: '슬로베니아',
      flagEmoji: '🇸🇮',
      region: 'Europe',
    ),
    Country(
      code: 'ESP',
      name: 'Spain',
      nameKo: '스페인',
      flagEmoji: '🇪🇸',
      region: 'Europe',
    ),
    Country(
      code: 'SWE',
      name: 'Sweden',
      nameKo: '스웨덴',
      flagEmoji: '🇸🇪',
      region: 'Europe',
    ),
    Country(
      code: 'CHE',
      name: 'Switzerland',
      nameKo: '스위스',
      flagEmoji: '🇨🇭',
      region: 'Europe',
    ),
    Country(
      code: 'TUR',
      name: 'Turkey',
      nameKo: '터키',
      flagEmoji: '🇹🇷',
      region: 'Europe',
    ),
    Country(
      code: 'GBR',
      name: 'United Kingdom',
      nameKo: '영국',
      flagEmoji: '🇬🇧',
      region: 'Europe',
    ),

    // 북미
    Country(
      code: 'CAN',
      name: 'Canada',
      nameKo: '캐나다',
      flagEmoji: '🇨🇦',
      region: 'North America',
    ),
    Country(
      code: 'USA',
      name: 'United States',
      nameKo: '미국',
      flagEmoji: '🇺🇸',
      region: 'North America',
    ),

    // 중동
    Country(
      code: 'ISR',
      name: 'Israel',
      nameKo: '이스라엘',
      flagEmoji: '🇮🇱',
      region: 'Middle East',
    ),

    // 라틴 아메리카
    Country(
      code: 'CHL',
      name: 'Chile',
      nameKo: '칠레',
      flagEmoji: '🇨🇱',
      region: 'Latin America',
    ),
    Country(
      code: 'COL',
      name: 'Colombia',
      nameKo: '콜롬비아',
      flagEmoji: '🇨🇴',
      region: 'Latin America',
    ),
    Country(
      code: 'CRI',
      name: 'Costa Rica',
      nameKo: '코스타리카',
      flagEmoji: '🇨🇷',
      region: 'Latin America',
    ),
    Country(
      code: 'MEX',
      name: 'Mexico',
      nameKo: '멕시코',
      flagEmoji: '🇲🇽',
      region: 'Latin America',
    ),
  ];

  /// 국가 코드로 국가 정보 찾기
  static Country? findByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  /// 지역별로 국가들 그룹핑
  static Map<String, List<Country>> get countriesByRegion {
    final Map<String, List<Country>> regionMap = {};
    
    for (final country in countries) {
      if (!regionMap.containsKey(country.region)) {
        regionMap[country.region] = [];
      }
      regionMap[country.region]!.add(country);
    }

    // 각 지역 내에서 한국어 이름순으로 정렬
    for (final region in regionMap.keys) {
      regionMap[region]!.sort((a, b) => a.nameKo.compareTo(b.nameKo));
    }

    return regionMap;
  }

  /// 검색용 국가 목록 (한국어명 + 영어명으로 검색)
  static List<Country> searchCountries(String query) {
    if (query.isEmpty) return countries;

    final lowerQuery = query.toLowerCase();
    return countries.where((country) {
      return country.nameKo.toLowerCase().contains(lowerQuery) ||
             country.name.toLowerCase().contains(lowerQuery) ||
             country.code.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 기본 선택 국가 (한국)
  static Country get defaultCountry {
    return findByCode('KOR')!;
  }
}