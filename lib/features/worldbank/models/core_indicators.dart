import 'package:flutter/material.dart';

/// PRD v1.1 핵심 20개 지표 정의
/// World Bank API 코드와 메타데이터
class CoreIndicators {
  static const List<CoreIndicator> indicators = [
    // 성장/활동
    CoreIndicator(
      code: 'NY.GDP.MKTP.KD.ZG',
      name: '실질 GDP 성장률',
      nameEn: 'GDP Growth (annual %)',
      unit: '%',
      category: CoreIndicatorCategory.growth,
      isPositive: true,
      description: '전년 대비 실질 GDP 성장률',
      priority: 1,
    ),
    CoreIndicator(
      code: 'NY.GDP.PCAP.PP.CD',
      name: '1인당 GDP (PPP)',
      nameEn: 'GDP per capita (PPP)',
      unit: 'USD',
      category: CoreIndicatorCategory.growth,
      isPositive: true,
      description: '구매력평가 기준 1인당 국내총생산',
      priority: 2,
    ),
    CoreIndicator(
      code: 'NV.IND.MANF.ZS',
      name: '제조업 부가가치 비중',
      nameEn: 'Manufacturing, value added (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.growth,
      isPositive: null, // 중립
      description: 'GDP 대비 제조업 부가가치 비중',
      priority: 3,
    ),
    CoreIndicator(
      code: 'NE.GDI.FPRV.ZS',
      name: '고정자본형성',
      nameEn: 'Gross fixed capital formation (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.growth,
      isPositive: true,
      description: 'GDP 대비 총고정자본형성 비중',
      priority: 4,
    ),

    // 물가/통화
    CoreIndicator(
      code: 'FP.CPI.TOTL.ZG',
      name: 'CPI 인플레이션',
      nameEn: 'Inflation, consumer prices (annual %)',
      unit: '%',
      category: CoreIndicatorCategory.inflation,
      isPositive: false,
      description: '소비자물가 상승률',
      priority: 5,
    ),
    CoreIndicator(
      code: 'FM.LBL.MQMY.GD.ZS',
      name: '통화공급량 (M2)',
      nameEn: 'Broad money (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.inflation,
      isPositive: null,
      description: 'GDP 대비 광의통화 비중',
      priority: 6,
    ),

    // 고용/노동
    CoreIndicator(
      code: 'SL.UEM.TOTL.ZS',
      name: '실업률',
      nameEn: 'Unemployment, total (% of total labor force)',
      unit: '%',
      category: CoreIndicatorCategory.employment,
      isPositive: false,
      description: '전체 노동력 대비 실업률',
      priority: 7,
    ),
    CoreIndicator(
      code: 'SL.TLF.CACT.ZS',
      name: '노동참가율',
      nameEn: 'Labor force participation rate, total (%)',
      unit: '%',
      category: CoreIndicatorCategory.employment,
      isPositive: true,
      description: '전체 노동참가율',
      priority: 8,
    ),
    CoreIndicator(
      code: 'SL.EMP.TOTL.SP.ZS',
      name: '고용률',
      nameEn: 'Employment to population ratio, 15+, total (%)',
      unit: '%',
      category: CoreIndicatorCategory.employment,
      isPositive: true,
      description: '15세 이상 고용률',
      priority: 9,
    ),

    // 재정/정부
    CoreIndicator(
      code: 'NE.CON.GOVT.ZS',
      name: '정부소비지출',
      nameEn: 'General government final consumption expenditure (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.fiscal,
      isPositive: null,
      description: 'GDP 대비 일반정부 최종소비지출',
      priority: 10,
    ),
    CoreIndicator(
      code: 'GC.TAX.TOTL.GD.ZS',
      name: '조세수입',
      nameEn: 'Tax revenue (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.fiscal,
      isPositive: null,
      description: 'GDP 대비 조세수입',
      priority: 11,
    ),
    CoreIndicator(
      code: 'GC.DOD.TOTL.GD.ZS',
      name: '정부부채',
      nameEn: 'Central government debt, total (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.fiscal,
      isPositive: false,
      description: 'GDP 대비 중앙정부 총부채',
      priority: 12,
    ),

    // 대외/거시건전성
    CoreIndicator(
      code: 'BN.CAB.XOKA.GD.ZS',
      name: '경상수지',
      nameEn: 'Current account balance (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.external,
      isPositive: true,
      description: 'GDP 대비 경상수지',
      priority: 13,
    ),
    CoreIndicator(
      code: 'NE.EXP.GNFS.ZS',
      name: '상품·서비스 수출',
      nameEn: 'Exports of goods and services (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.external,
      isPositive: null,
      description: 'GDP 대비 상품·서비스 수출액',
      priority: 14,
    ),
    CoreIndicator(
      code: 'NE.IMP.GNFS.ZS',
      name: '상품·서비스 수입',
      nameEn: 'Imports of goods and services (% of GDP)',
      unit: '% of GDP',
      category: CoreIndicatorCategory.external,
      isPositive: null,
      description: 'GDP 대비 상품·서비스 수입액',
      priority: 15,
    ),
    CoreIndicator(
      code: 'FI.RES.TOTL.MO',
      name: '외환보유액',
      nameEn: 'Total reserves in months of imports',
      unit: 'months',
      category: CoreIndicatorCategory.external,
      isPositive: true,
      description: '수입 개월수 대비 외환보유액',
      priority: 16,
    ),

    // 분배/사회
    CoreIndicator(
      code: 'SI.POV.GINI',
      name: '지니계수',
      nameEn: 'Gini index',
      unit: 'index',
      category: CoreIndicatorCategory.social,
      isPositive: false,
      description: '소득불평등 지수 (0=완전평등, 100=완전불평등)',
      priority: 17,
    ),
    CoreIndicator(
      code: 'SI.POV.NAHC',
      name: '빈곤율',
      nameEn: 'Poverty headcount ratio at national poverty lines (%)',
      unit: '%',
      category: CoreIndicatorCategory.social,
      isPositive: false,
      description: '국가 빈곤선 기준 빈곤율',
      priority: 18,
    ),

    // 환경/에너지
    CoreIndicator(
      code: 'EN.ATM.CO2E.PC',
      name: 'CO₂ 배출량',
      nameEn: 'CO2 emissions (metric tons per capita)',
      unit: 'tons per capita',
      category: CoreIndicatorCategory.environment,
      isPositive: false,
      description: '1인당 CO₂ 배출량',
      priority: 19,
    ),
    CoreIndicator(
      code: 'EG.FEC.RNEW.ZS',
      name: '재생에너지 비중',
      nameEn: 'Renewable energy consumption (% of total final energy consumption)',
      unit: '%',
      category: CoreIndicatorCategory.environment,
      isPositive: true,
      description: '최종에너지소비 중 재생에너지 비중',
      priority: 20,
    ),
  ];

  /// Top 5 지표 (우선순위 기준)
  static List<CoreIndicator> get top5Indicators {
    final sorted = List<CoreIndicator>.from(indicators);
    sorted.sort((a, b) => a.priority.compareTo(b.priority));
    return sorted.take(5).toList();
  }

  /// 카테고리별 지표
  static List<CoreIndicator> getIndicatorsByCategory(CoreIndicatorCategory category) {
    return indicators.where((indicator) => indicator.category == category).toList();
  }

  /// 지표 코드로 찾기
  static CoreIndicator? findByCode(String code) {
    try {
      return indicators.firstWhere((indicator) => indicator.code == code);
    } catch (e) {
      return null;
    }
  }
}

/// 핵심 지표 데이터 클래스
class CoreIndicator {
  final String code;           // World Bank API 코드
  final String name;           // 한국어 이름
  final String nameEn;         // 영어 이름
  final String unit;           // 단위
  final CoreIndicatorCategory category;
  final bool? isPositive;      // true: 증가=좋음, false: 감소=좋음, null: 중립
  final String description;    // 설명
  final int priority;          // 우선순위 (1-20)

  const CoreIndicator({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.unit,
    required this.category,
    required this.isPositive,
    required this.description,
    required this.priority,
  });

  /// 색상 가져오기 (PRD 색상 규칙)
  Color getColor() {
    if (isPositive == true) {
      return const Color(0xFF1E88E5); // 파랑 계열
    } else if (isPositive == false) {
      return const Color(0xFFE53935); // 빨강 계열  
    } else {
      return const Color(0xFF26A69A); // 중립 (청록)
    }
  }

  /// 연한 색상 가져오기
  Color getLightColor() {
    if (isPositive == true) {
      return const Color(0xFF90CAF9); // 연한 파랑
    } else if (isPositive == false) {
      return const Color(0xFFFF7043); // 연한 빨강
    } else {
      return const Color(0xFF80CBC4); // 연한 청록
    }
  }

  /// 트렌드 색상 가져오기 (증감에 따라)
  Color getTrendColor(double changeValue) {
    if (changeValue == 0) return const Color(0xFFBDBDBD); // 회색

    final bool isIncrease = changeValue > 0;
    
    if (isPositive == true) {
      // 증가=좋은 지표: 증가시 파랑, 감소시 빨강
      return isIncrease ? const Color(0xFF1E88E5) : const Color(0xFFE53935);
    } else if (isPositive == false) {
      // 감소=좋은 지표: 감소시 파랑, 증가시 빨강  
      return isIncrease ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
    } else {
      // 중립 지표: 항상 청록
      return const Color(0xFF26A69A);
    }
  }
}

/// 지표 카테고리
enum CoreIndicatorCategory {
  growth('성장/활동', 'Growth & Activity'),
  inflation('물가/통화', 'Inflation & Monetary'), 
  employment('고용/노동', 'Employment & Labor'),
  fiscal('재정/정부', 'Fiscal & Government'),
  external('대외/거시건전성', 'External & Macro'),
  social('분배/사회', 'Social & Distribution'),
  environment('환경/에너지', 'Environment & Energy');

  const CoreIndicatorCategory(this.nameKo, this.nameEn);

  final String nameKo;
  final String nameEn;

  Color getColor() {
    switch (this) {
      case CoreIndicatorCategory.growth:
        return const Color(0xFF1E88E5);
      case CoreIndicatorCategory.inflation:
        return const Color(0xFFFF7043);
      case CoreIndicatorCategory.employment:
        return const Color(0xFF26A69A);
      case CoreIndicatorCategory.fiscal:
        return const Color(0xFF7E57C2);
      case CoreIndicatorCategory.external:
        return const Color(0xFF42A5F5);
      case CoreIndicatorCategory.social:
        return const Color(0xFFAB47BC);
      case CoreIndicatorCategory.environment:
        return const Color(0xFF66BB6A);
    }
  }
}