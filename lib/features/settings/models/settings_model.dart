class SettingsModel {
  bool darkmode;
  String viewmode;

  SettingsModel({required this.darkmode, required this.viewmode});
  /* 
  SettingsModel copyWith({bool? darkmode, String? viewmode}) {
    return SettingsModel(
      darkmode: darkmode ?? this.darkmode,
      viewmode: viewmode ?? this.viewmode,
    );
  } */
}
