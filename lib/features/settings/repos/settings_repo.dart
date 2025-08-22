import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _darkmode = "darkmode";
  static const String _viewmode = "viewmode";

  final SharedPreferences _preferences;
  SettingsRepository(this._preferences);

  Future<void> setDarkmode(bool value) async {
    _preferences.setBool(_darkmode, value);
  }

  bool isDarkmode() {
    return _preferences.getBool(_darkmode) ?? false;
  }

  Future<void> setViewmode(String value) async {
    _preferences.setString(_viewmode, value);
  }

  String whatIsViewmode() {
    return _preferences.getString(_viewmode) ?? "all";
  }
}
