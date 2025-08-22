/// PRD 기준 핵심 20지표 코드 정의
enum IndicatorCode {
  // 성장/활동
  gdpRealGrowth('NY.GDP.MKTP.KD.ZG', 'GDP 성장률', '%', '성장'),
  gdpPppPerCapita('NY.GDP.PCAP.PP.CD', '1인당 GDP (PPP)', 'USD', '성장'),
  manufShare('NV.IND.MANF.ZS', '제조업 부가가치 비중', '% of GDP', '성장'),
  grossFixedCapital('NE.GDI.FPRV.ZS', '총고정자본형성', '% of GDP', '성장'),

  // 물가/통화
  cpiInflation('FP.CPI.TOTL.ZG', 'CPI 인플레이션', '%', '물가'),
  m2Money('FM.LBL.MQMY.GD.ZS', 'M2 통화량', '% of GDP', '물가'),

  // 고용/노동
  unemployment('SL.UEM.TOTL.ZS', '실업률', '%', '고용'),
  laborParticipation('SL.TLF.CACT.ZS', '노동참가율', '%', '고용'),
  employmentRate('SL.EMP.TOTL.SP.ZS', '고용률', '%', '고용'),

  // 재정/정부
  govExpenditure('NE.CON.GOVT.ZS', '정부최종소비지출', '% of GDP', '재정'),
  taxRevenue('GC.TAX.TOTL.GD.ZS', '조세수입', '% of GDP', '재정'),
  govDebt('GC.DOD.TOTL.GD.ZS', '정부부채', '% of GDP', '재정'),

  // 대외/거시건전성
  currentAccount('BN.CAB.XOKA.GD.ZS', '경상수지', '% of GDP', '대외'),
  exportsShare('NE.EXP.GNFS.ZS', '수출 비중', '% of GDP', '대외'),
  importsShare('NE.IMP.GNFS.ZS', '수입 비중', '% of GDP', '대외'),
  reservesMonths('FI.RES.TOTL.MO', '외환보유액', '개월', '대외'),

  // 분배/사회
  gini('SI.POV.GINI', '지니계수', 'index', '분배'),
  povertyNat('SI.POV.NAHC', '빈곤율', '%', '분배'),

  // 환경/에너지
  co2PerCapita('EN.ATM.CO2E.PC', 'CO₂ 배출', 'metric tons per capita', '환경'),
  renewablesShare('EG.FEC.RNEW.ZS', '재생에너지 비중', '%', '환경');

  const IndicatorCode(this.code, this.name, this.unit, this.category);

  final String code;
  final String name;
  final String unit;
  final String category;

  /// 지표 방향성 (높을수록 좋은지, 낮을수록 좋은지)
  IndicatorDirection get direction {
    switch (this) {
      // 높을수록 좋음
      case gdpRealGrowth:
      case gdpPppPerCapita:
      case manufShare:
      case grossFixedCapital:
      case laborParticipation:
      case employmentRate:
      case taxRevenue:
      case currentAccount:
      case exportsShare:
      case reservesMonths:
      case renewablesShare:
        return IndicatorDirection.higher;

      // 낮을수록 좋음
      case unemployment:
      case govDebt:
      case importsShare:
      case gini:
      case povertyNat:
      case co2PerCapita:
        return IndicatorDirection.lower;

      // 중립적 (적정선 존재)
      case cpiInflation:
      case m2Money:
      case govExpenditure:
        return IndicatorDirection.neutral;
    }
  }

  /// 지표 우선순위 (홈화면 KPI 타일 선정용)
  int get priority {
    switch (this) {
      case gdpRealGrowth:
      case unemployment:
      case cpiInflation:
      case currentAccount:
      case gdpPppPerCapita:
        return 1; // 최우선
      case laborParticipation:
      case employmentRate:
      case govDebt:
      case exportsShare:
        return 2; // 중요
      default:
        return 3; // 일반
    }
  }

  /// OECD 38개국 ISO3 코드
  static const List<String> oecdCountries = [
    'AUS', 'AUT', 'BEL', 'CAN', 'CHL', 'COL', 'CRI', 'CZE',
    'DNK', 'EST', 'FIN', 'FRA', 'DEU', 'GRC', 'HUN', 'ISL',
    'IRL', 'ISR', 'ITA', 'JPN', 'KOR', 'LVA', 'LTU', 'LUX',
    'MEX', 'NLD', 'NZL', 'NOR', 'POL', 'PRT', 'SVK', 'SVN',
    'ESP', 'SWE', 'CHE', 'TUR', 'GBR', 'USA'
  ];

  /// 한국과 유사한 경제 수준의 국가들 (비교 우선순위별)
  static const Map<String, List<String>> similarCountries = {
    'KOR': ['JPN', 'DEU', 'FRA', 'GBR', 'ITA'], // 한국 유사국
    'JPN': ['KOR', 'DEU', 'GBR', 'FRA', 'ITA'], // 일본 유사국
    'DEU': ['FRA', 'GBR', 'ITA', 'JPN', 'KOR'], // 독일 유사국
    // 필요시 확장
  };

  /// 지표별 데이터 업데이트 주기 (일 단위)
  int get updateFrequencyDays {
    switch (category) {
      case '물가':
      case '고용':
        return 30; // 월간
      case '성장':
      case '재정':
      case '대외':
        return 90; // 분기
      case '분배':
      case '환경':
        return 365; // 연간
      default:
        return 90;
    }
  }
}

/// 지표 방향성
enum IndicatorDirection {
  higher, // 높을수록 좋음
  lower,  // 낮을수록 좋음
  neutral // 중립적/적정선 존재
}

/// 지표 메타데이터
class IndicatorMetadata {
  final IndicatorCode indicatorCode;
  final String description;
  final String sourceOrganization;
  final String sourceNote;
  final List<String> limitations;

  const IndicatorMetadata({
    required this.indicatorCode,
    required this.description,
    required this.sourceOrganization,
    required this.sourceNote,
    this.limitations = const [],
  });

  static const Map<IndicatorCode, IndicatorMetadata> metadata = {
    IndicatorCode.gdpRealGrowth: IndicatorMetadata(
      indicatorCode: IndicatorCode.gdpRealGrowth,
      description: '실질 GDP의 전년 대비 성장률. 물가상승분을 제외한 실제 경제성장을 측정',
      sourceOrganization: 'World Bank',
      sourceNote: '연간 백분율로 표시되는 현지 통화 기준 실질 GDP 성장률',
      limitations: ['분기별 변동성 높음', '수정치 발표 가능'],
    ),
    IndicatorCode.unemployment: IndicatorMetadata(
      indicatorCode: IndicatorCode.unemployment,
      description: 'ILO 기준 실업률. 경제활동인구 중 실업자 비율',
      sourceOrganization: 'International Labour Organization',
      sourceNote: '15세 이상 경제활동인구 중 구직활동 중인 실업자 비율',
      limitations: ['계절조정 여부 확인 필요', '국가별 정의 차이 존재'],
    ),
    // 필요시 다른 지표들도 추가
  };
}