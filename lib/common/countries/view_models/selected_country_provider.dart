import 'package:geo_economy_dashboard/common/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/country.dart';

part 'selected_country_provider.g.dart';

/// 선택된 국가 상태 관리 Provider
@riverpod
class SelectedCountry extends _$SelectedCountry {
  static const String _selectedCountryKey = 'selected_country_code';

  @override
  Country build() {
    // 기본값은 한국
    _loadSelectedCountry();
    return OECDCountries.defaultCountry;
  }

  /// SharedPreferences에서 선택된 국가 로드
  Future<void> _loadSelectedCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCountryCode = prefs.getString(_selectedCountryKey);
      
      if (savedCountryCode != null) {
        final country = OECDCountries.findByCode(savedCountryCode);
        if (country != null) {
          state = country;
        }
      }
    } catch (e) {
      AppLogger.error('[SelectedCountry] Failed to load selected country: $e');
    }
  }

  /// 국가 선택 및 저장
  Future<void> selectCountry(Country country) async {
    try {
      // 상태 업데이트
      state = country;
      
      // SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCountryKey, country.code);
      
      AppLogger.info('[SelectedCountry] Country selected: ${country.nameKo} (${country.code})');
    } catch (e) {
      AppLogger.error('[SelectedCountry] Failed to save selected country: $e');
    }
  }

  /// 기본 국가(한국)로 리셋
  Future<void> resetToDefault() async {
    await selectCountry(OECDCountries.defaultCountry);
  }
}

/// 선택된 국가 정보를 제공하는 편의 Provider들
@riverpod
String selectedCountryCode(Ref ref) {
  final selectedCountry = ref.watch(selectedCountryProvider);
  return selectedCountry.code;
}

@riverpod
String selectedCountryName(Ref ref) {
  final selectedCountry = ref.watch(selectedCountryProvider);
  return selectedCountry.nameKo;
}

@riverpod
String selectedCountryFlag(Ref ref) {
  final selectedCountry = ref.watch(selectedCountryProvider);
  return selectedCountry.flagEmoji;
}

/// 국가가 한국인지 확인하는 Provider
@riverpod
bool isKoreaSelected(Ref ref) {
  final selectedCountry = ref.watch(selectedCountryProvider);
  return selectedCountry.code == 'KOR';
}