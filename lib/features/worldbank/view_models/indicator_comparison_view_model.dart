import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/country_indicator.dart';
import '../widgets/indicator_comparison_card.dart';
import '../services/integrated_data_service.dart';
import '../../../common/logger.dart';

part 'indicator_comparison_view_model.g.dart';

/// 지표별 전체 국가 비교 ViewModel
@riverpod
class IndicatorComparisonViewModel extends _$IndicatorComparisonViewModel {
  @override
  Future<IndicatorComparisonResult?> build() async {
    return null; // 초기 상태는 null
  }

  /// 특정 지표의 모든 OECD 국가 데이터를 비교
  Future<void> compareIndicatorAllCountries(String indicatorCode) async {
    try {
      state = const AsyncLoading();
      
      AppLogger.info('[IndicatorComparison] Loading all countries data for $indicatorCode');
      
      final worldBankService = ref.read(worldBankServiceProvider);
      
      // OECD 38개국 리스트 (실제로는 Country 서비스에서 가져와야 함)
      final oecdCountries = [
        'KOR', 'USA', 'JPN', 'DEU', 'GBR', 'FRA', 'CAN', 'ITA', 'AUS', 'ESP',
        'NLD', 'BEL', 'CHE', 'AUT', 'SWE', 'NOR', 'DNK', 'FIN', 'IRL', 'ISR',
        'PRT', 'GRC', 'CZE', 'POL', 'HUN', 'SVK', 'SVN', 'EST', 'LVA', 'LTU',
        'LUX', 'ISL', 'NZL', 'MEX', 'TUR', 'CHL', 'COL', 'CRI'
      ];

      // 모든 국가의 지표 데이터 수집
      final List<CountryIndicator> allCountries = [];
      
      for (final countryCode in oecdCountries) {
        try {
          final indicator = await worldBankService.getIndicatorForCountry(
            countryCode: countryCode,
            indicatorCode: indicatorCode,
          );
          
          if (indicator != null && indicator.latestValue != null) {
            allCountries.add(indicator);
          }
        } catch (e) {
          AppLogger.warning('[IndicatorComparison] Failed to load data for $countryCode: $e');
          // 개별 국가 데이터 로딩 실패는 무시하고 계속 진행
        }
      }
      
      if (allCountries.isEmpty) {
        AppLogger.error('[IndicatorComparison] No data available for indicator $indicatorCode');
        state = AsyncError('해당 지표에 대한 데이터가 없습니다', StackTrace.current);
        return;
      }

      // 순위별로 정렬 (값에 따라 오름차순 또는 내림차순)
      allCountries.sort((a, b) {
        final valueA = a.latestValue ?? 0.0;
        final valueB = b.latestValue ?? 0.0;
        
        // 지표 특성에 따라 정렬 방향 결정
        // 대부분의 경우 높은 값이 좋은 성과 (GDP, 고용률 등)
        // 일부는 낮은 값이 좋은 성과 (실업률, 인플레이션 등)
        final isLowerBetter = _isLowerBetterIndicator(indicatorCode);
        
        if (isLowerBetter) {
          return valueA.compareTo(valueB); // 오름차순
        } else {
          return valueB.compareTo(valueA); // 내림차순  
        }
      });

      // 순위 업데이트
      for (int i = 0; i < allCountries.length; i++) {
        allCountries[i] = allCountries[i].copyWith(oecdRanking: i + 1);
        
        // 백분위 계산
        final percentile = ((allCountries.length - i) / allCountries.length) * 100;
        allCountries[i] = allCountries[i].copyWith(oecdPercentile: percentile);
      }

      final result = IndicatorComparisonResult(
        countries: allCountries,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('[IndicatorComparison] Successfully loaded ${allCountries.length} countries for $indicatorCode');
      state = AsyncData(result);
      
    } catch (e, stackTrace) {
      AppLogger.error('[IndicatorComparison] Failed to load indicator comparison: $e');
      state = AsyncError(e, stackTrace);
    }
  }

  /// 지표 코드에 따라 낮은 값이 좋은 성과인지 판단
  bool _isLowerBetterIndicator(String indicatorCode) {
    final lowerIsBetterCodes = {
      'SL.UEM.TOTL.ZS',     // 실업률
      'FP.CPI.TOTL.ZG',     // 인플레이션
      'GC.DOD.TOTL.GD.ZS',  // 정부부채
      'SP.DYN.IMRT.IN',     // 유아사망률
      'EN.ATM.CO2E.PC',     // CO2 배출량
      'SI.POV.GINI',        // 지니계수
    };
    
    return lowerIsBetterCodes.contains(indicatorCode);
  }

  /// 데이터 새로고침
  Future<void> refresh(String indicatorCode) async {
    await compareIndicatorAllCountries(indicatorCode);
  }
}

/// WorldBank 서비스 Provider (이미 존재한다면 import로 변경)
final worldBankServiceProvider = Provider<WorldBankService>((ref) {
  return WorldBankService(); // 실제 서비스 인스턴스
});

/// WorldBank 서비스 인터페이스 (실제 구현은 별도 파일에)
class WorldBankService {
  Future<CountryIndicator?> getIndicatorForCountry({
    required String countryCode,
    required String indicatorCode,
  }) async {
    // 실제 World Bank API 호출 구현 필요
    // 임시로 더미 데이터 반환
    await Future.delayed(const Duration(milliseconds: 100));
    
    return CountryIndicator(
      countryCode: countryCode,
      countryName: '',
      indicatorCode: indicatorCode,
      indicatorName: '',
      latestValue: _generateDummyValue(indicatorCode),
      latestYear: 2023,
      unit: _getUnitForIndicator(indicatorCode),
      updatedAt: DateTime.now(),
    );
  }
  
  double _generateDummyValue(String indicatorCode) {
    // 지표별로 적절한 범위의 더미 데이터 생성
    switch (indicatorCode) {
      case 'NY.GDP.MKTP.KD.ZG': // GDP 성장률
        return (DateTime.now().millisecondsSinceEpoch % 100) / 10.0 - 5.0;
      case 'SL.UEM.TOTL.ZS': // 실업률  
        return (DateTime.now().millisecondsSinceEpoch % 150) / 10.0;
      case 'FP.CPI.TOTL.ZG': // 인플레이션
        return (DateTime.now().millisecondsSinceEpoch % 100) / 10.0 - 2.0;
      default:
        return (DateTime.now().millisecondsSinceEpoch % 1000) / 10.0;
    }
  }
  
  String _getUnitForIndicator(String indicatorCode) {
    switch (indicatorCode) {
      case 'NY.GDP.MKTP.KD.ZG':
      case 'SL.UEM.TOTL.ZS':
      case 'FP.CPI.TOTL.ZG':
        return '%';
      default:
        return '';
    }
  }
}