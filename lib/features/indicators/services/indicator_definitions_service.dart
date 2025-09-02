import '../../../common/logger.dart';
import '../../worldbank/models/indicator_codes.dart';

/// 지표 정의를 제공하는 서비스
class IndicatorDefinitionsService {
  static final IndicatorDefinitionsService _instance = IndicatorDefinitionsService._internal();
  static IndicatorDefinitionsService get instance => _instance;
  
  IndicatorDefinitionsService._internal();

  /// 지표 정의 데이터
  static const Map<IndicatorCode, IndicatorDefinition> _definitions = {
    IndicatorCode.gdpRealGrowth: IndicatorDefinition(
      name: 'GDP 실질 성장률',
      definition: '전년 동기 대비 실질 국내총생산(GDP)의 증감률을 나타내는 지표입니다. 인플레이션 효과를 제거하여 경제의 실질적인 성장을 측정합니다.',
      unit: '%',
      source: 'World Bank',
      methodology: '실질 GDP 성장률 = (당기 실질 GDP - 전년 동기 실질 GDP) ÷ 전년 동기 실질 GDP × 100',
    ),
    IndicatorCode.gdpPppPerCapita: IndicatorDefinition(
      name: '1인당 GDP (PPP)',
      definition: '구매력 평가(PPP) 기준 1인당 국내총생산으로, 국가 간 생활수준을 비교할 수 있는 지표입니다.',
      unit: 'USD',
      source: 'World Bank',
      methodology: '1인당 GDP (PPP) = PPP 기준 GDP ÷ 총 인구',
    ),
    IndicatorCode.unemployment: IndicatorDefinition(
      name: '실업률',
      definition: '경제활동인구 중에서 실업자가 차지하는 비율을 나타내는 지표입니다.',
      unit: '%',
      source: 'World Bank',
      methodology: '실업률 = 실업자 수 ÷ 경제활동인구 × 100',
    ),
    IndicatorCode.cpiInflation: IndicatorDefinition(
      name: 'CPI 인플레이션',
      definition: '소비자물가지수(CPI)의 전년 동월 대비 상승률로, 물가상승률을 나타내는 대표적인 지표입니다.',
      unit: '%',
      source: 'World Bank',
      methodology: '인플레이션율 = (당월 CPI - 전년 동월 CPI) ÷ 전년 동월 CPI × 100',
    ),
    IndicatorCode.currentAccount: IndicatorDefinition(
      name: '경상수지',
      definition: '한 국가가 다른 나라와의 거래에서 발생하는 상품, 서비스, 소득, 경상이전의 수지를 합한 값입니다.',
      unit: '% of GDP',
      source: 'World Bank',
      methodology: '경상수지 = 상품수지 + 서비스수지 + 본원소득수지 + 이전소득수지',
    ),
    IndicatorCode.govDebt: IndicatorDefinition(
      name: '정부부채',
      definition: '정부의 총 부채를 GDP 대비 비율로 나타낸 지표로, 국가의 재정 건전성을 측정합니다.',
      unit: '% of GDP',
      source: 'World Bank',
      methodology: '정부부채 비율 = 정부 총 부채 ÷ 명목 GDP × 100',
    ),
    IndicatorCode.exportsShare: IndicatorDefinition(
      name: '수출 비중',
      definition: '국내총생산(GDP) 대비 상품 및 서비스 수출액의 비중을 나타내는 지표입니다.',
      unit: '% of GDP',
      source: 'World Bank',
      methodology: '수출 비중 = 수출액 ÷ GDP × 100',
    ),
    IndicatorCode.importsShare: IndicatorDefinition(
      name: '수입 비중',
      definition: '국내총생산(GDP) 대비 상품 및 서비스 수입액의 비중을 나타내는 지표입니다.',
      unit: '% of GDP',
      source: 'World Bank',
      methodology: '수입 비중 = 수입액 ÷ GDP × 100',
    ),
    IndicatorCode.gini: IndicatorDefinition(
      name: '지니계수',
      definition: '소득 불평등의 정도를 나타내는 지표로, 0에 가까울수록 평등, 1에 가까울수록 불평등합니다.',
      unit: 'index',
      source: 'World Bank',
      methodology: '지니계수 = 로렌츠 곡선과 완전평등선 사이의 면적 ÷ 완전평등선 아래 면적',
    ),
  };

  /// 지표 정의 조회
  IndicatorDefinition? getDefinition(IndicatorCode indicatorCode) {
    try {
      return _definitions[indicatorCode];
    } catch (e) {
      AppLogger.error('Failed to get indicator definition for $indicatorCode: $e');
      return null;
    }
  }

  /// 모든 지표 정의 조회
  Map<IndicatorCode, IndicatorDefinition> getAllDefinitions() {
    return Map.from(_definitions);
  }

  /// 지표 검색
  List<IndicatorCode> searchIndicators(String query) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return _definitions.keys.where((code) {
      final definition = _definitions[code]!;
      return definition.name.toLowerCase().contains(lowercaseQuery) ||
             definition.definition.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}

/// 지표 정의 데이터 클래스
class IndicatorDefinition {
  final String name;
  final String definition;
  final String unit;
  final String source;
  final String? methodology;

  const IndicatorDefinition({
    required this.name,
    required this.definition,
    required this.unit,
    required this.source,
    this.methodology,
  });
}