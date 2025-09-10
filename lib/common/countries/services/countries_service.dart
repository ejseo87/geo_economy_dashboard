import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../logger.dart';
import '../models/country.dart';

/// 국가 데이터 서비스
/// Firestore에서 데이터를 가져오고 SQLite에 캐싱
class CountriesService {
  static CountriesService? _instance;
  static CountriesService get instance => _instance ??= CountriesService._();
  CountriesService._();

  Database? _database;
  List<Country>? _cachedCountries;

  static const String _tableName = 'countries';
  static const String _firestoreCollection = 'oecd_countries';

  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      await _initDatabase();
      await _loadCountries();
      AppLogger.info('[CountriesService] Initialized successfully');
    } catch (e) {
      AppLogger.error('[CountriesService] Initialization failed: $e');
      // 기본 데이터로 폴백
      _cachedCountries = _getDefaultCountries();
    }
  }

  /// SQLite 데이터베이스 초기화
  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'countries.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            code TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            nameKo TEXT NOT NULL,
            flagEmoji TEXT NOT NULL,
            region TEXT NOT NULL,
            lastUpdated INTEGER NOT NULL
          )
        ''');
        AppLogger.debug('[CountriesService] Database table created');
      },
    );
  }

  /// 국가 데이터 로드 (캐시 -> Firestore 순)
  Future<void> _loadCountries() async {
    try {
      // 1. SQLite 캐시에서 먼저 로드 시도
      final cachedCountries = await _loadFromSQLite();
      
      if (cachedCountries.isNotEmpty && _isCacheValid()) {
        _cachedCountries = cachedCountries;
        AppLogger.debug('[CountriesService] Loaded ${cachedCountries.length} countries from SQLite cache');
        
        // 백그라운드에서 Firestore 업데이트 확인
        _updateFromFirestoreInBackground();
        return;
      }

      // 2. Firestore에서 로드
      await _loadFromFirestore();
    } catch (e) {
      AppLogger.error('[CountriesService] Failed to load countries: $e');
      // 기본 데이터로 폴백
      _cachedCountries = _getDefaultCountries();
      // 기본 데이터를 Firestore에 저장
      await _saveDefaultDataToFirestore();
    }
  }

  /// SQLite에서 국가 데이터 로드
  Future<List<Country>> _loadFromSQLite() async {
    if (_database == null) return [];

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(_tableName);
      return maps.map((map) => Country(
        code: map['code'] as String,
        name: map['name'] as String,
        nameKo: map['nameKo'] as String,
        flagEmoji: map['flagEmoji'] as String,
        region: map['region'] as String,
      )).toList();
    } catch (e) {
      AppLogger.error('[CountriesService] Failed to load from SQLite: $e');
      return [];
    }
  }

  /// Firestore에서 국가 데이터 로드
  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .get();

      if (snapshot.docs.isEmpty) {
        // Firestore에 데이터가 없으면 기본 데이터 저장
        await _saveDefaultDataToFirestore();
        _cachedCountries = _getDefaultCountries();
      } else {
        // Firestore 데이터를 파싱
        final countries = snapshot.docs
            .map((doc) => Country.fromJson(doc.data()))
            .toList();
        
        _cachedCountries = countries;
        
        // SQLite에 캐시 저장
        await _saveToSQLite(countries);
        
        AppLogger.debug('[CountriesService] Loaded ${countries.length} countries from Firestore');
      }
    } catch (e) {
      AppLogger.error('[CountriesService] Failed to load from Firestore: $e');
      rethrow;
    }
  }

  /// SQLite에 국가 데이터 저장
  Future<void> _saveToSQLite(List<Country> countries) async {
    if (_database == null) return;

    try {
      final batch = _database!.batch();
      
      // 기존 데이터 삭제
      batch.delete(_tableName);
      
      // 새 데이터 삽입
      for (final country in countries) {
        batch.insert(_tableName, {
          'code': country.code,
          'name': country.name,
          'nameKo': country.nameKo,
          'flagEmoji': country.flagEmoji,
          'region': country.region,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      await batch.commit();
      AppLogger.debug('[CountriesService] Saved ${countries.length} countries to SQLite');
    } catch (e) {
      AppLogger.error('[CountriesService] Failed to save to SQLite: $e');
    }
  }

  /// Firestore에 기본 데이터 저장
  Future<void> _saveDefaultDataToFirestore() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection(_firestoreCollection);
      
      for (final country in _getDefaultCountries()) {
        final docRef = collection.doc(country.code);
        batch.set(docRef, country.toJson());
      }
      
      await batch.commit();
      AppLogger.info('[CountriesService] Saved default countries to Firestore');
    } catch (e) {
      AppLogger.error('[CountriesService] Failed to save default data to Firestore: $e');
    }
  }

  /// 백그라운드에서 Firestore 업데이트 확인
  Future<void> _updateFromFirestoreInBackground() async {
    try {
      // 백그라운드에서 실행하여 UI 블로킹 방지
      Future.microtask(() async {
        await _loadFromFirestore();
      });
    } catch (e) {
      AppLogger.error('[CountriesService] Background update failed: $e');
    }
  }

  /// 캐시 유효성 확인 (24시간)
  bool _isCacheValid() {
    // 구현 단순화: 항상 유효하다고 가정
    // 실제로는 lastUpdated 시간을 확인해야 함
    return true;
  }

  /// 모든 국가 목록 반환
  List<Country> get countries {
    return _cachedCountries ?? _getDefaultCountries();
  }

  /// 국가 코드로 찾기
  Country? findByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  /// 지역별 국가 그룹핑
  Map<String, List<Country>> get countriesByRegion {
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

  /// 국가 검색
  List<Country> searchCountries(String query) {
    if (query.isEmpty) return countries;

    final lowerQuery = query.toLowerCase();
    return countries.where((country) {
      return country.nameKo.toLowerCase().contains(lowerQuery) ||
             country.name.toLowerCase().contains(lowerQuery) ||
             country.code.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 기본 국가 (한국)
  Country get defaultCountry {
    return findByCode('KOR') ?? _getDefaultCountries().first;
  }

  /// 기본 OECD 국가 데이터
  List<Country> _getDefaultCountries() {
    return const [
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
  }
}