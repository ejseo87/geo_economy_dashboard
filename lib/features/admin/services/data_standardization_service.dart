import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:geo_economy_dashboard/features/admin/services/admin_audit_service.dart';

class DataStandardizationService {
  static final DataStandardizationService _instance = DataStandardizationService._internal();
  factory DataStandardizationService() => _instance;
  DataStandardizationService._internal();

  static DataStandardizationService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminAuditService _auditService = AdminAuditService.instance;

  // indicators_metadata 컬렉션 초기 데이터 생성
  Future<void> initializeIndicatorsMetadata() async {
    try {
      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'indicators_metadata 컬렉션 초기화 시작',
        status: AdminActionStatus.started,
      );

      // OECD 20개 핵심 지표의 한글 이름 매핑
      final indicatorsMetadata = {
        'GDP_GROWTH': {
          'indicatorCode': 'GDP_GROWTH',
          'nameKorean': 'GDP 성장률',
          'nameEnglish': 'GDP Growth Rate',
          'unit': '%',
          'category': '경제성장',
          'description': '전년 대비 실질 국내총생산 증가율',
          'source': 'World Bank',
          'isPositive': true, // 높을수록 좋은 지표
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'UNEMPLOYMENT_RATE': {
          'indicatorCode': 'UNEMPLOYMENT_RATE',
          'nameKorean': '실업률',
          'nameEnglish': 'Unemployment Rate',
          'unit': '%',
          'category': '고용',
          'description': '경제활동인구 대비 실업자 비율',
          'source': 'World Bank',
          'isPositive': false, // 낮을수록 좋은 지표
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'INFLATION_RATE': {
          'indicatorCode': 'INFLATION_RATE',
          'nameKorean': '인플레이션율',
          'nameEnglish': 'Inflation Rate',
          'unit': '%',
          'category': '물가',
          'description': '전년 대비 소비자물가지수 상승률',
          'source': 'World Bank',
          'isPositive': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'GDP_PER_CAPITA': {
          'indicatorCode': 'GDP_PER_CAPITA',
          'nameKorean': '1인당 GDP',
          'nameEnglish': 'GDP per Capita',
          'unit': 'USD',
          'category': '경제규모',
          'description': '국민 1인당 국내총생산',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'GOVERNMENT_DEBT': {
          'indicatorCode': 'GOVERNMENT_DEBT',
          'nameKorean': '정부부채비율',
          'nameEnglish': 'Government Debt to GDP',
          'unit': '% of GDP',
          'category': '재정',
          'description': 'GDP 대비 정부부채 비율',
          'source': 'World Bank',
          'isPositive': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'CURRENT_ACCOUNT': {
          'indicatorCode': 'CURRENT_ACCOUNT',
          'nameKorean': '경상수지비율',
          'nameEnglish': 'Current Account Balance',
          'unit': '% of GDP',
          'category': '대외거래',
          'description': 'GDP 대비 경상수지 비율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'EXPORTS_GDP': {
          'indicatorCode': 'EXPORTS_GDP',
          'nameKorean': '수출비율',
          'nameEnglish': 'Exports of Goods and Services',
          'unit': '% of GDP',
          'category': '대외거래',
          'description': 'GDP 대비 상품 및 서비스 수출 비율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'FDI_INFLOWS': {
          'indicatorCode': 'FDI_INFLOWS',
          'nameKorean': '외국인직접투자유입',
          'nameEnglish': 'Foreign Direct Investment Inflows',
          'unit': '% of GDP',
          'category': '투자',
          'description': 'GDP 대비 외국인직접투자 유입 비율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'PRODUCTIVITY_GROWTH': {
          'indicatorCode': 'PRODUCTIVITY_GROWTH',
          'nameKorean': '생산성증가율',
          'nameEnglish': 'Labor Productivity Growth',
          'unit': '%',
          'category': '생산성',
          'description': '노동생산성 증가율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'RND_EXPENDITURE': {
          'indicatorCode': 'RND_EXPENDITURE',
          'nameKorean': '연구개발투자비율',
          'nameEnglish': 'R&D Expenditure',
          'unit': '% of GDP',
          'category': '혁신',
          'description': 'GDP 대비 연구개발 투자 비율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'EDUCATION_EXPENDITURE': {
          'indicatorCode': 'EDUCATION_EXPENDITURE',
          'nameKorean': '교육투자비율',
          'nameEnglish': 'Education Expenditure',
          'unit': '% of GDP',
          'category': '사회',
          'description': 'GDP 대비 교육 투자 비율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'HEALTH_EXPENDITURE': {
          'indicatorCode': 'HEALTH_EXPENDITURE',
          'nameKorean': '보건투자비율',
          'nameEnglish': 'Health Expenditure',
          'unit': '% of GDP',
          'category': '사회',
          'description': 'GDP 대비 보건 투자 비율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'GINI_COEFFICIENT': {
          'indicatorCode': 'GINI_COEFFICIENT',
          'nameKorean': '지니계수',
          'nameEnglish': 'Gini Coefficient',
          'unit': 'index',
          'category': '사회',
          'description': '소득불평등 지수 (0=완전평등, 1=완전불평등)',
          'source': 'World Bank',
          'isPositive': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'CO2_EMISSIONS': {
          'indicatorCode': 'CO2_EMISSIONS',
          'nameKorean': '탄소배출량',
          'nameEnglish': 'CO2 Emissions',
          'unit': 'metric tons per capita',
          'category': '환경',
          'description': '1인당 이산화탄소 배출량',
          'source': 'World Bank',
          'isPositive': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'RENEWABLE_ENERGY': {
          'indicatorCode': 'RENEWABLE_ENERGY',
          'nameKorean': '재생에너지비율',
          'nameEnglish': 'Renewable Energy Consumption',
          'unit': '% of total energy',
          'category': '환경',
          'description': '전체 에너지 소비 중 재생에너지 비율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'DIGITAL_ADOPTION': {
          'indicatorCode': 'DIGITAL_ADOPTION',
          'nameKorean': '디지털채택지수',
          'nameEnglish': 'Digital Adoption Index',
          'unit': 'index',
          'category': '디지털',
          'description': '디지털 기술 채택 수준',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'INTERNET_PENETRATION': {
          'indicatorCode': 'INTERNET_PENETRATION',
          'nameKorean': '인터넷보급률',
          'nameEnglish': 'Internet Penetration Rate',
          'unit': '% of population',
          'category': '디지털',
          'description': '인구 대비 인터넷 사용자 비율',
          'source': 'World Bank',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'EASE_DOING_BUSINESS': {
          'indicatorCode': 'EASE_DOING_BUSINESS',
          'nameKorean': '사업용이성지수',
          'nameEnglish': 'Ease of Doing Business Rank',
          'unit': 'rank',
          'category': '규제',
          'description': '사업하기 좋은 정도 순위 (낮을수록 좋음)',
          'source': 'World Bank',
          'isPositive': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'CORRUPTION_INDEX': {
          'indicatorCode': 'CORRUPTION_INDEX',
          'nameKorean': '부패인식지수',
          'nameEnglish': 'Corruption Perceptions Index',
          'unit': 'score',
          'category': '거버넌스',
          'description': '부패 인식 정도 (100점 만점, 높을수록 청렴)',
          'source': 'Transparency International',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'COMPETITIVENESS_INDEX': {
          'indicatorCode': 'COMPETITIVENESS_INDEX',
          'nameKorean': '국가경쟁력지수',
          'nameEnglish': 'Global Competitiveness Index',
          'unit': 'score',
          'category': '경쟁력',
          'description': '국가 경쟁력 종합 점수',
          'source': 'World Economic Forum',
          'isPositive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      };

      // Firestore에 배치로 저장
      final batch = _firestore.batch();
      int count = 0;

      for (final entry in indicatorsMetadata.entries) {
        final docRef = _firestore.collection('indicators_metadata').doc(entry.key);
        batch.set(docRef, entry.value);
        count++;
      }

      await batch.commit();

      AppLogger.info('[DataStandardizationService] Initialized $count indicator metadata records');

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'indicators_metadata 컬렉션 초기화 완료',
        status: AdminActionStatus.completed,
        metadata: {'indicatorCount': count},
      );

    } catch (e) {
      AppLogger.error('[DataStandardizationService] Failed to initialize indicators metadata: $e');

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'indicators_metadata 컬렉션 초기화 실패',
        status: AdminActionStatus.failed,
        metadata: {'error': e.toString()},
      );

      rethrow;
    }
  }

  // 국가명 매핑 가져오기 (oecd_countries에서)
  Future<Map<String, String>> getCountryNameMapping() async {
    try {
      final snapshot = await _firestore.collection('oecd_countries').get();
      final Map<String, String> mapping = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final countryCode = doc.id; // ISO 3자리 코드
        final koreanName = data['nameKorean'] as String?;

        if (koreanName != null) {
          mapping[countryCode] = koreanName;
        }
      }

      AppLogger.info('[DataStandardizationService] Loaded ${mapping.length} country name mappings');
      return mapping;

    } catch (e) {
      AppLogger.error('[DataStandardizationService] Failed to get country name mapping: $e');
      return {};
    }
  }

  // 지표명 매핑 가져오기 (indicators_metadata에서)
  Future<Map<String, String>> getIndicatorNameMapping() async {
    try {
      final snapshot = await _firestore.collection('indicators_metadata').get();
      final Map<String, String> mapping = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final indicatorCode = doc.id;
        final koreanName = data['nameKorean'] as String?;

        if (koreanName != null) {
          mapping[indicatorCode] = koreanName;
        }
      }

      AppLogger.info('[DataStandardizationService] Loaded ${mapping.length} indicator name mappings');
      return mapping;

    } catch (e) {
      AppLogger.error('[DataStandardizationService] Failed to get indicator name mapping: $e');
      return {};
    }
  }

  // oecd_countries 컬렉션에 한글 국가명 추가/업데이트
  Future<void> initializeOecdCountriesKoreanNames() async {
    try {
      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'OECD 국가 한글명 초기화 시작',
        status: AdminActionStatus.started,
      );

      // OECD 38개국 한글명 매핑
      final countryNamesKorean = {
        'AUS': '호주',
        'AUT': '오스트리아',
        'BEL': '벨기에',
        'CAN': '캐나다',
        'CHL': '칠레',
        'CZE': '체코',
        'DNK': '덴마크',
        'EST': '에스토니아',
        'FIN': '핀란드',
        'FRA': '프랑스',
        'DEU': '독일',
        'GRC': '그리스',
        'HUN': '헝가리',
        'ISL': '아이슬란드',
        'IRL': '아일랜드',
        'ISR': '이스라엘',
        'ITA': '이탈리아',
        'JPN': '일본',
        'KOR': '대한민국',
        'LVA': '라트비아',
        'LTU': '리투아니아',
        'LUX': '룩셈부르크',
        'MEX': '멕시코',
        'NLD': '네덜란드',
        'NZL': '뉴질랜드',
        'NOR': '노르웨이',
        'POL': '폴란드',
        'PRT': '포르투갈',
        'SVK': '슬로바키아',
        'SVN': '슬로베니아',
        'ESP': '스페인',
        'SWE': '스웨덴',
        'CHE': '스위스',
        'TUR': '터키',
        'GBR': '영국',
        'USA': '미국',
        'COL': '콜롬비아',
        'CRI': '코스타리카',
      };

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final entry in countryNamesKorean.entries) {
        final docRef = _firestore.collection('oecd_countries').doc(entry.key);

        // 기존 데이터가 있으면 merge, 없으면 새로 생성
        batch.set(docRef, {
          'countryCode': entry.key,
          'nameKorean': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        updatedCount++;
      }

      await batch.commit();

      AppLogger.info('[DataStandardizationService] Updated $updatedCount OECD country Korean names');

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'OECD 국가 한글명 초기화 완료',
        status: AdminActionStatus.completed,
        metadata: {'countryCount': updatedCount},
      );

    } catch (e) {
      AppLogger.error('[DataStandardizationService] Failed to initialize OECD countries Korean names: $e');

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'OECD 국가 한글명 초기화 실패',
        status: AdminActionStatus.failed,
        metadata: {'error': e.toString()},
      );

      rethrow;
    }
  }

  // indicators 컬렉션의 이름들을 한글로 표준화
  Stream<String> standardizeIndicatorsNames() async* {
    yield '[시작] indicators 컬렉션 이름 표준화를 시작합니다...';

    try {
      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'indicators 컬렉션 이름 표준화 시작',
        status: AdminActionStatus.started,
      );

      // 매핑 데이터 로드
      yield '[진행] 매핑 데이터 로드 중...';
      final countryMapping = await getCountryNameMapping();
      final indicatorMapping = await getIndicatorNameMapping();

      if (countryMapping.isEmpty || indicatorMapping.isEmpty) {
        yield '[오류] 매핑 데이터가 없습니다. 먼저 메타데이터를 초기화해주세요.';
        return;
      }

      yield '[정보] 국가명 ${countryMapping.length}개, 지표명 ${indicatorMapping.length}개 로드';

      int updatedCount = 0;
      int totalCount = 0;

      // indicators 컬렉션 처리
      final indicatorsSnapshot = await _firestore.collection('indicators').get();

      for (final indicatorDoc in indicatorsSnapshot.docs) {
        final indicatorCode = indicatorDoc.id;
        final koreanIndicatorName = indicatorMapping[indicatorCode];

        if (koreanIndicatorName == null) {
          yield '[경고] 지표 $indicatorCode의 한글명을 찾을 수 없습니다.';
          continue;
        }

        // series 하위 컬렉션 처리
        final seriesSnapshot = await _firestore
            .collection('indicators')
            .doc(indicatorCode)
            .collection('series')
            .get();

        for (final seriesDoc in seriesSnapshot.docs) {
          totalCount++;
          final countryCode = seriesDoc.id;
          final koreanCountryName = countryMapping[countryCode];

          if (koreanCountryName == null) {
            yield '[경고] 국가 $countryCode의 한글명을 찾을 수 없습니다.';
            continue;
          }

          try {
            await seriesDoc.reference.update({
              'indicatorName': koreanIndicatorName,
              'countryName': koreanCountryName,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            updatedCount++;

            if (updatedCount % 50 == 0) {
              yield '[진행] $updatedCount개 문서 업데이트 완료 (총 $totalCount개 중)';
            }

          } catch (e) {
            yield '[경고] $indicatorCode/$countryCode 업데이트 실패: $e';
          }
        }
      }

      yield '[완료] indicators 컬렉션 이름 표준화 완료';
      yield '[결과] 총 $totalCount개 문서 중 $updatedCount개 업데이트';

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'indicators 컬렉션 이름 표준화 완료',
        status: AdminActionStatus.completed,
        metadata: {
          'totalCount': totalCount,
          'updatedCount': updatedCount,
        },
      );

    } catch (e) {
      yield '[오류] indicators 컬렉션 이름 표준화 중 오류 발생: $e';
      AppLogger.error('[DataStandardizationService] Failed to standardize indicators names: $e');

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'indicators 컬렉션 이름 표준화 실패',
        status: AdminActionStatus.failed,
        metadata: {'error': e.toString()},
      );
    }
  }

  // countries 컬렉션의 이름들을 한글로 표준화
  Stream<String> standardizeCountriesNames() async* {
    yield '[시작] countries 컬렉션 이름 표준화를 시작합니다...';

    try {
      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'countries 컬렉션 이름 표준화 시작',
        status: AdminActionStatus.started,
      );

      // 매핑 데이터 로드
      yield '[진행] 매핑 데이터 로드 중...';
      final countryMapping = await getCountryNameMapping();
      final indicatorMapping = await getIndicatorNameMapping();

      if (countryMapping.isEmpty || indicatorMapping.isEmpty) {
        yield '[오류] 매핑 데이터가 없습니다. 먼저 메타데이터를 초기화해주세요.';
        return;
      }

      yield '[정보] 국가명 ${countryMapping.length}개, 지표명 ${indicatorMapping.length}개 로드';

      int updatedCount = 0;
      int totalCount = 0;

      // countries 컬렉션 처리
      final countriesSnapshot = await _firestore.collection('countries').get();

      for (final countryDoc in countriesSnapshot.docs) {
        final countryCode = countryDoc.id;
        final koreanCountryName = countryMapping[countryCode];

        if (koreanCountryName == null) {
          yield '[경고] 국가 $countryCode의 한글명을 찾을 수 없습니다.';
          continue;
        }

        // indicators 하위 컬렉션 처리
        final indicatorsSnapshot = await _firestore
            .collection('countries')
            .doc(countryCode)
            .collection('indicators')
            .get();

        for (final indicatorDoc in indicatorsSnapshot.docs) {
          totalCount++;
          final indicatorCode = indicatorDoc.id;
          final koreanIndicatorName = indicatorMapping[indicatorCode];

          if (koreanIndicatorName == null) {
            yield '[경고] 지표 $indicatorCode의 한글명을 찾을 수 없습니다.';
            continue;
          }

          try {
            await indicatorDoc.reference.update({
              'indicatorName': koreanIndicatorName,
              'countryName': koreanCountryName,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            updatedCount++;

            if (updatedCount % 50 == 0) {
              yield '[진행] $updatedCount개 문서 업데이트 완료 (총 $totalCount개 중)';
            }

          } catch (e) {
            yield '[경고] $countryCode/$indicatorCode 업데이트 실패: $e';
          }
        }
      }

      yield '[완료] countries 컬렉션 이름 표준화 완료';
      yield '[결과] 총 $totalCount개 문서 중 $updatedCount개 업데이트';

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'countries 컬렉션 이름 표준화 완료',
        status: AdminActionStatus.completed,
        metadata: {
          'totalCount': totalCount,
          'updatedCount': updatedCount,
        },
      );

    } catch (e) {
      yield '[오류] countries 컬렉션 이름 표준화 중 오류 발생: $e';
      AppLogger.error('[DataStandardizationService] Failed to standardize countries names: $e');

      await _auditService.logAdminAction(
        actionType: AdminActionType.systemMaintenance,
        description: 'countries 컬렉션 이름 표준화 실패',
        status: AdminActionStatus.failed,
        metadata: {'error': e.toString()},
      );
    }
  }

  // 전체 데이터 표준화 실행
  Stream<String> standardizeAllData() async* {
    yield '[시작] 전체 데이터 표준화를 시작합니다...';

    try {
      // 1. 메타데이터 초기화
      yield '[단계 1/4] indicators_metadata 초기화 중...';
      await initializeIndicatorsMetadata();
      yield '[완료] indicators_metadata 초기화 완료';

      // 2. OECD 국가 한글명 초기화
      yield '[단계 2/4] OECD 국가 한글명 초기화 중...';
      await initializeOecdCountriesKoreanNames();
      yield '[완료] OECD 국가 한글명 초기화 완료';

      // 3. indicators 컬렉션 표준화
      yield '[단계 3/4] indicators 컬렉션 표준화 중...';
      await for (final message in standardizeIndicatorsNames()) {
        yield message;
      }

      // 4. countries 컬렉션 표준화
      yield '[단계 4/4] countries 컬렉션 표준화 중...';
      await for (final message in standardizeCountriesNames()) {
        yield message;
      }

      yield '[🎉 완료] 전체 데이터 표준화가 완료되었습니다!';

    } catch (e) {
      yield '[❌ 오류] 전체 데이터 표준화 중 오류 발생: $e';
    }
  }
}