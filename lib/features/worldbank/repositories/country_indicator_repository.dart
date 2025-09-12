import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/country_indicator.dart';
import '../models/core_indicators.dart';
import '../../../common/logger.dart';

/// PRD v1.1 - 비정규화된 국가 지표 데이터 저장소
/// 경로: /countries/{countryCode}/indicators/{indicatorCode}
class CountryIndicatorRepository {
  final FirebaseFirestore _firestore;
  static const String _countriesCollection = 'countries';

  CountryIndicatorRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 특정 국가의 지표 데이터 가져오기
  Future<CountryIndicator?> getCountryIndicator({
    required String countryCode,
    required String indicatorCode,
  }) async {
    try {
      AppLogger.debug('[CountryIndicatorRepository] Getting indicator $indicatorCode for country $countryCode');
      
      final docRef = _firestore
          .collection(_countriesCollection)
          .doc(countryCode)
          .collection('indicators')
          .doc(indicatorCode);
      
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        AppLogger.warning('[CountryIndicatorRepository] Indicator $indicatorCode not found for country $countryCode');
        return null;
      }
      
      final data = docSnapshot.data()!;
      return CountryIndicator.fromFirestore(data, countryCode, indicatorCode);
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorRepository] Error getting indicator: $error', stackTrace);
      return null;
    }
  }

  /// 특정 국가의 Top 5 지표 데이터 가져오기
  Future<List<CountryIndicator>> getTop5Indicators({
    required String countryCode,
  }) async {
    try {
      AppLogger.debug('[CountryIndicatorRepository] Getting top 5 indicators for country $countryCode');
      
      final top5Codes = CoreIndicators.top5Indicators.map((indicator) => indicator.code).toList();
      final indicators = <CountryIndicator>[];
      
      for (final indicatorCode in top5Codes) {
        final indicator = await getCountryIndicator(
          countryCode: countryCode,
          indicatorCode: indicatorCode,
        );
        if (indicator != null) {
          indicators.add(indicator);
        }
      }
      
      AppLogger.debug('[CountryIndicatorRepository] Retrieved ${indicators.length}/5 indicators for country $countryCode');
      return indicators;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorRepository] Error getting top 5 indicators: $error', stackTrace);
      return [];
    }
  }

  /// 특정 국가의 모든 지표 데이터 가져오기
  Future<List<CountryIndicator>> getAllCountryIndicators({
    required String countryCode,
  }) async {
    try {
      AppLogger.debug('[CountryIndicatorRepository] Getting all indicators for country $countryCode');
      
      final querySnapshot = await _firestore
          .collection(_countriesCollection)
          .doc(countryCode)
          .collection('indicators')
          .get();
      
      final indicators = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CountryIndicator.fromFirestore(data, countryCode, doc.id);
      }).toList();
      
      AppLogger.debug('[CountryIndicatorRepository] Retrieved ${indicators.length} indicators for country $countryCode');
      return indicators;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorRepository] Error getting all indicators: $error', stackTrace);
      return [];
    }
  }

  /// 지표 데이터 저장
  Future<bool> saveCountryIndicator(CountryIndicator indicator) async {
    try {
      AppLogger.debug('[CountryIndicatorRepository] Saving indicator ${indicator.indicatorCode} for country ${indicator.countryCode}');
      
      final docRef = _firestore
          .collection(_countriesCollection)
          .doc(indicator.countryCode)
          .collection('indicators')
          .doc(indicator.indicatorCode);
      
      await docRef.set(indicator.toFirestore());
      
      AppLogger.debug('[CountryIndicatorRepository] Successfully saved indicator ${indicator.indicatorCode}');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorRepository] Error saving indicator: $error', stackTrace);
      return false;
    }
  }

  /// 여러 지표 데이터 배치 저장
  Future<bool> saveCountryIndicatorsBatch(List<CountryIndicator> indicators) async {
    if (indicators.isEmpty) return true;
    
    try {
      AppLogger.debug('[CountryIndicatorRepository] Batch saving ${indicators.length} indicators');
      
      final batch = _firestore.batch();
      
      for (final indicator in indicators) {
        final docRef = _firestore
            .collection(_countriesCollection)
            .doc(indicator.countryCode)
            .collection('indicators')
            .doc(indicator.indicatorCode);
        
        batch.set(docRef, indicator.toFirestore());
      }
      
      await batch.commit();
      
      AppLogger.debug('[CountryIndicatorRepository] Successfully batch saved ${indicators.length} indicators');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorRepository] Error batch saving indicators: $error', stackTrace);
      return false;
    }
  }

  /// 특정 국가의 지표 데이터 삭제
  Future<bool> deleteCountryIndicator({
    required String countryCode,
    required String indicatorCode,
  }) async {
    try {
      AppLogger.debug('[CountryIndicatorRepository] Deleting indicator $indicatorCode for country $countryCode');
      
      final docRef = _firestore
          .collection(_countriesCollection)
          .doc(countryCode)
          .collection('indicators')
          .doc(indicatorCode);
      
      await docRef.delete();
      
      AppLogger.debug('[CountryIndicatorRepository] Successfully deleted indicator $indicatorCode');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('[CountryIndicatorRepository] Error deleting indicator: $error', stackTrace);
      return false;
    }
  }

  /// 국가의 지표 업데이트 시간 확인
  Future<DateTime?> getLastUpdateTime({
    required String countryCode,
    required String indicatorCode,
  }) async {
    try {
      final indicator = await getCountryIndicator(
        countryCode: countryCode,
        indicatorCode: indicatorCode,
      );
      return indicator?.updatedAt;
    } catch (error) {
      AppLogger.error('[CountryIndicatorRepository] Error getting update time: $error');
      return null;
    }
  }
}