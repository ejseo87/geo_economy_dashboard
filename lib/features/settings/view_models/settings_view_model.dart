import 'package:geo_economy_dashboard/features/settings/models/settings_model.dart';
import 'package:geo_economy_dashboard/features/settings/repos/settings_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsViewModel extends Notifier<SettingsModel> {
  final SettingsRepository _repository;
  SettingsViewModel(this._repository);

  void setDarkmode(bool value) {
    _repository.setDarkmode(value);
    state = SettingsModel(darkmode: value, viewmode: state.viewmode);
  }

  void setViewmode(String value) {
    _repository.setViewmode(value);
    state = SettingsModel(darkmode: state.darkmode, viewmode: value);
  }

  @override
  SettingsModel build() {
    return SettingsModel(
      darkmode: _repository.isDarkmode(),
      viewmode: _repository.whatIsViewmode(),
    );
  }
}

final settingsProvider = NotifierProvider<SettingsViewModel, SettingsModel>(
  () => throw UnimplementedError(),
);
