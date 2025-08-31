import '../services/countries_service.dart';

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

/// OECD 38개국 데이터 (하위 호환성을 위한 래퍼)
/// 실제 데이터는 CountriesService에서 관리
class OECDCountries {
  static List<Country> get countries => CountriesService.instance.countries;
  static Country? findByCode(String code) => CountriesService.instance.findByCode(code);
  static Map<String, List<Country>> get countriesByRegion => CountriesService.instance.countriesByRegion;
  static List<Country> searchCountries(String query) => CountriesService.instance.searchCountries(query);
  static Country get defaultCountry => CountriesService.instance.defaultCountry;
}