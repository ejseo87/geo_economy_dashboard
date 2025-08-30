/// 핵심 20개 지표 카탈로그 (World Bank API 코드와 설명)
const Map<String, String> indicatorsCatalog = {
  // 성장/활동 (4개)
  'NY.GDP.MKTP.KD.ZG': 'GDP 실질성장률 (annual %)',
  'NY.GDP.PCAP.PP.KD': '1인당 GDP PPP (constant 2017 international USD)',
  'NV.IND.MANF.ZS': '제조업 부가가치 비중 (% of GDP)',
  'NE.GDI.TOTL.ZS': '총고정자본형성 (% of GDP)',
  
  // 물가/통화 (2개)
  'FP.CPI.TOTL.ZG': '소비자물가상승률 (annual %)',
  'FM.LBL.BMNY.ZG': 'M2 통화량 증가율 (annual %)',
  
  // 고용/노동 (3개)
  'SL.UEM.TOTL.ZS': '실업률 (% of total labor force)',
  'SL.TLF.CACT.ZS': '노동참가율 (% of total population ages 15+)',
  'SL.EMP.TOTL.SP.ZS': '고용률 (% of population ages 15+)',
  
  // 재정/정부 (3개)
  'NE.CON.GOVT.ZS': '정부최종소비지출 (% of GDP)',
  'GC.TAX.TOTL.GD.ZS': '조세수입 (% of GDP)',
  'GC.DOD.TOTL.GD.ZS': '정부부채 (% of GDP)',
  
  // 대외/거시건전성 (4개)
  'BN.CAB.XOKA.GD.ZS': '경상수지 (% of GDP)',
  'NE.EXP.GNFS.ZS': '재화와 서비스 수출 (% of GDP)',
  'NE.IMP.GNFS.ZS': '재화와 서비스 수입 (% of GDP)',
  'FI.RES.TOTL.MO': '외환보유액 (months of imports)',
  
  // 분배/사회 (2개)
  'SI.POV.GINI': '지니계수 (0-100 scale)',
  'SI.POV.NAHC': '국가빈곤선 기준 빈곤율 (% of population)',
  
  // 환경/에너지 (2개)
  'EN.ATM.CO2E.PC': 'CO₂ 배출량 per capita (metric tons)',
  'EG.FEC.RNEW.ZS': '재생에너지 소비 비중 (% of total final energy consumption)',
};

/// 카테고리별 지표 그룹화
const Map<String, List<String>> indicatorsByCategory = {
  '성장/활동': [
    'NY.GDP.MKTP.KD.ZG',  // GDP 실질성장률
    'NY.GDP.PCAP.PP.KD',  // 1인당 GDP PPP
    'NV.IND.MANF.ZS',     // 제조업 부가가치 비중
    'NE.GDI.TOTL.ZS',     // 총고정자본형성
  ],
  '물가/통화': [
    'FP.CPI.TOTL.ZG',     // 소비자물가상승률
    'FM.LBL.BMNY.ZG',     // M2 통화량 증가율
  ],
  '고용/노동': [
    'SL.UEM.TOTL.ZS',     // 실업률
    'SL.TLF.CACT.ZS',     // 노동참가율
    'SL.EMP.TOTL.SP.ZS',  // 고용률
  ],
  '재정/정부': [
    'NE.CON.GOVT.ZS',     // 정부최종소비지출
    'GC.TAX.TOTL.GD.ZS',  // 조세수입
    'GC.DOD.TOTL.GD.ZS',  // 정부부채
  ],
  '대외/거시건전성': [
    'BN.CAB.XOKA.GD.ZS',  // 경상수지
    'NE.EXP.GNFS.ZS',     // 재화와 서비스 수출
    'NE.IMP.GNFS.ZS',     // 재화와 서비스 수입
    'FI.RES.TOTL.MO',     // 외환보유액
  ],
  '분배/사회': [
    'SI.POV.GINI',        // 지니계수
    'SI.POV.NAHC',        // 국가빈곤선 기준 빈곤율
  ],
  '환경/에너지': [
    'EN.ATM.CO2E.PC',     // CO₂ 배출량 per capita
    'EG.FEC.RNEW.ZS',     // 재생에너지 소비 비중
  ],
};

/// 지표별 한국어 이름
const Map<String, String> indicatorKoreanNames = {
  // 성장/활동
  'NY.GDP.MKTP.KD.ZG': 'GDP 실질성장률',
  'NY.GDP.PCAP.PP.KD': '1인당 GDP (PPP)',
  'NV.IND.MANF.ZS': '제조업 부가가치 비중',
  'NE.GDI.TOTL.ZS': '총고정자본형성',
  
  // 물가/통화
  'FP.CPI.TOTL.ZG': '소비자물가상승률',
  'FM.LBL.BMNY.ZG': 'M2 통화량 증가율',
  
  // 고용/노동
  'SL.UEM.TOTL.ZS': '실업률',
  'SL.TLF.CACT.ZS': '노동참가율',
  'SL.EMP.TOTL.SP.ZS': '고용률',
  
  // 재정/정부
  'NE.CON.GOVT.ZS': '정부최종소비지출',
  'GC.TAX.TOTL.GD.ZS': '조세수입',
  'GC.DOD.TOTL.GD.ZS': '정부부채',
  
  // 대외/거시건전성
  'BN.CAB.XOKA.GD.ZS': '경상수지',
  'NE.EXP.GNFS.ZS': '재화·서비스 수출',
  'NE.IMP.GNFS.ZS': '재화·서비스 수입',
  'FI.RES.TOTL.MO': '외환보유액',
  
  // 분배/사회
  'SI.POV.GINI': '지니계수',
  'SI.POV.NAHC': '빈곤율',
  
  // 환경/에너지
  'EN.ATM.CO2E.PC': 'CO₂ 배출량',
  'EG.FEC.RNEW.ZS': '재생에너지 비중',
};

/// 지표별 단위
const Map<String, String> indicatorUnits = {
  // 성장/활동
  'NY.GDP.MKTP.KD.ZG': '%',
  'NY.GDP.PCAP.PP.KD': 'USD',
  'NV.IND.MANF.ZS': '%',
  'NE.GDI.TOTL.ZS': '%',
  
  // 물가/통화
  'FP.CPI.TOTL.ZG': '%',
  'FM.LBL.BMNY.ZG': '%',
  
  // 고용/노동
  'SL.UEM.TOTL.ZS': '%',
  'SL.TLF.CACT.ZS': '%',
  'SL.EMP.TOTL.SP.ZS': '%',
  
  // 재정/정부
  'NE.CON.GOVT.ZS': '%',
  'GC.TAX.TOTL.GD.ZS': '%',
  'GC.DOD.TOTL.GD.ZS': '%',
  
  // 대외/거시건전성
  'BN.CAB.XOKA.GD.ZS': '%',
  'NE.EXP.GNFS.ZS': '%',
  'NE.IMP.GNFS.ZS': '%',
  'FI.RES.TOTL.MO': '개월',
  
  // 분배/사회
  'SI.POV.GINI': '점',
  'SI.POV.NAHC': '%',
  
  // 환경/에너지
  'EN.ATM.CO2E.PC': 'tCO₂',
  'EG.FEC.RNEW.ZS': '%',
};

/// 높을수록 좋은 지표인지 판단
const Map<String, bool> isHigherBetter = {
  // 성장/활동 - 모두 높을수록 좋음
  'NY.GDP.MKTP.KD.ZG': true,   // GDP 성장률
  'NY.GDP.PCAP.PP.KD': true,   // 1인당 GDP
  'NV.IND.MANF.ZS': true,      // 제조업 비중
  'NE.GDI.TOTL.ZS': true,      // 총고정자본형성
  
  // 물가/통화 - 모두 낮을수록 좋음 (안정성)
  'FP.CPI.TOTL.ZG': false,     // 인플레이션
  'FM.LBL.BMNY.ZG': false,     // 통화량 증가율
  
  // 고용/노동
  'SL.UEM.TOTL.ZS': false,     // 실업률 (낮을수록 좋음)
  'SL.TLF.CACT.ZS': true,      // 노동참가율 (높을수록 좋음)
  'SL.EMP.TOTL.SP.ZS': true,   // 고용률 (높을수록 좋음)
  
  // 재정/정부
  'NE.CON.GOVT.ZS': false,     // 정부지출 (낮을수록 효율적)
  'GC.TAX.TOTL.GD.ZS': true,   // 조세수입 (높을수록 좋음)
  'GC.DOD.TOTL.GD.ZS': false,  // 정부부채 (낮을수록 좋음)
  
  // 대외/거시건전성
  'BN.CAB.XOKA.GD.ZS': true,   // 경상수지 (흑자가 좋음)
  'NE.EXP.GNFS.ZS': true,      // 수출 (높을수록 좋음)
  'NE.IMP.GNFS.ZS': false,     // 수입 (낮을수록 자립도 높음)
  'FI.RES.TOTL.MO': true,      // 외환보유액 (높을수록 좋음)
  
  // 분배/사회
  'SI.POV.GINI': false,        // 지니계수 (낮을수록 평등)
  'SI.POV.NAHC': false,        // 빈곤율 (낮을수록 좋음)
  
  // 환경/에너지
  'EN.ATM.CO2E.PC': false,     // CO₂ 배출량 (낮을수록 좋음)
  'EG.FEC.RNEW.ZS': true,      // 재생에너지 (높을수록 좋음)
};

/// 지표별 이모지
const Map<String, String> indicatorEmojis = {
  // 성장/활동
  'NY.GDP.MKTP.KD.ZG': '📈',   // GDP 성장률
  'NY.GDP.PCAP.PP.KD': '💰',   // 1인당 GDP
  'NV.IND.MANF.ZS': '🏭',      // 제조업 비중
  'NE.GDI.TOTL.ZS': '🏗️',      // 총고정자본형성
  
  // 물가/통화
  'FP.CPI.TOTL.ZG': '🛒',      // 소비자물가
  'FM.LBL.BMNY.ZG': '💸',      // 통화량
  
  // 고용/노동
  'SL.UEM.TOTL.ZS': '👥',      // 실업률
  'SL.TLF.CACT.ZS': '🏢',      // 노동참가율
  'SL.EMP.TOTL.SP.ZS': '💼',   // 고용률
  
  // 재정/정부
  'NE.CON.GOVT.ZS': '🏛️',      // 정부지출
  'GC.TAX.TOTL.GD.ZS': '💳',   // 조세수입
  'GC.DOD.TOTL.GD.ZS': '📊',   // 정부부채
  
  // 대외/거시건전성
  'BN.CAB.XOKA.GD.ZS': '⚖️',   // 경상수지
  'NE.EXP.GNFS.ZS': '📦',      // 수출
  'NE.IMP.GNFS.ZS': '📥',      // 수입
  'FI.RES.TOTL.MO': '🏦',      // 외환보유액
  
  // 분배/사회
  'SI.POV.GINI': '📐',         // 지니계수
  'SI.POV.NAHC': '🏠',         // 빈곤율
  
  // 환경/에너지
  'EN.ATM.CO2E.PC': '🌍',      // CO₂ 배출량
  'EG.FEC.RNEW.ZS': '♻️',      // 재생에너지
};

/// 카테고리별 이모지
const Map<String, String> categoryEmojis = {
  '성장/활동': '📊',
  '물가/통화': '💸',
  '고용/노동': '👥',
  '재정/정부': '🏛️',
  '대외/거시건전성': '⚖️',
  '분배/사회': '🤝',
  '환경/에너지': '🌍',
};

/// 유틸리티 함수들
class IndicatorCatalogUtils {
  /// 지표 코드로 한국어 이름 가져오기
  static String getKoreanName(String indicatorCode) {
    return indicatorKoreanNames[indicatorCode] ?? indicatorCode;
  }
  
  /// 지표 코드로 단위 가져오기
  static String getUnit(String indicatorCode) {
    return indicatorUnits[indicatorCode] ?? '';
  }
  
  /// 지표 코드로 이모지 가져오기
  static String getEmoji(String indicatorCode) {
    return indicatorEmojis[indicatorCode] ?? '📈';
  }
  
  /// 카테고리별 이모지 가져오기
  static String getCategoryEmoji(String category) {
    return categoryEmojis[category] ?? '📊';
  }
  
  /// 지표가 높을수록 좋은지 확인
  static bool isIndicatorHigherBetter(String indicatorCode) {
    return isHigherBetter[indicatorCode] ?? true;
  }
  
  /// 전체 지표 개수
  static int get totalIndicatorCount => indicatorsCatalog.length;
  
  /// 카테고리별 지표 개수
  static Map<String, int> get indicatorCountByCategory {
    return indicatorsByCategory.map((category, indicators) => 
      MapEntry(category, indicators.length));
  }
  
  /// 특정 카테고리의 지표 목록
  static List<String> getIndicatorsForCategory(String category) {
    return indicatorsByCategory[category] ?? [];
  }
  
  /// 지표 코드가 유효한지 확인
  static bool isValidIndicatorCode(String indicatorCode) {
    return indicatorsCatalog.containsKey(indicatorCode);
  }
  
  /// 카테고리가 유효한지 확인
  static bool isValidCategory(String category) {
    return indicatorsByCategory.containsKey(category);
  }
}