/// 접근성 설정 모델
class AccessibilitySettings {
  final double fontScale;
  final bool highContrast;
  final bool colorblindMode;
  final ColorblindType colorblindType;
  final bool reduceMotion;
  final bool screenReaderSupport;

  const AccessibilitySettings({
    this.fontScale = 1.0,
    this.highContrast = false,
    this.colorblindMode = false,
    this.colorblindType = ColorblindType.none,
    this.reduceMotion = false,
    this.screenReaderSupport = false,
  });

  AccessibilitySettings copyWith({
    double? fontScale,
    bool? highContrast,
    bool? colorblindMode,
    ColorblindType? colorblindType,
    bool? reduceMotion,
    bool? screenReaderSupport,
  }) {
    return AccessibilitySettings(
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      colorblindMode: colorblindMode ?? this.colorblindMode,
      colorblindType: colorblindType ?? this.colorblindType,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      screenReaderSupport: screenReaderSupport ?? this.screenReaderSupport,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontScale': fontScale,
      'highContrast': highContrast,
      'colorblindMode': colorblindMode,
      'colorblindType': colorblindType.name,
      'reduceMotion': reduceMotion,
      'screenReaderSupport': screenReaderSupport,
    };
  }

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      highContrast: json['highContrast'] as bool? ?? false,
      colorblindMode: json['colorblindMode'] as bool? ?? false,
      colorblindType: ColorblindType.values.firstWhere(
        (e) => e.name == json['colorblindType'],
        orElse: () => ColorblindType.none,
      ),
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      screenReaderSupport: json['screenReaderSupport'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessibilitySettings &&
        other.fontScale == fontScale &&
        other.highContrast == highContrast &&
        other.colorblindMode == colorblindMode &&
        other.colorblindType == colorblindType &&
        other.reduceMotion == reduceMotion &&
        other.screenReaderSupport == screenReaderSupport;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontScale,
      highContrast,
      colorblindMode,
      colorblindType,
      reduceMotion,
      screenReaderSupport,
    );
  }
}

/// 색맹 타입
enum ColorblindType {
  none('정상'),
  protanopia('적색맹'),
  deuteranopia('녹색맹'),
  tritanopia('청색맹'),
  protanomaly('적색약'),
  deuteranomaly('녹색약'),
  tritanomaly('청색약');

  const ColorblindType(this.displayName);
  final String displayName;
}

/// 폰트 크기 프리셋
enum FontSizePreset {
  small('작음', 0.8),
  normal('보통', 1.0),
  large('큼', 1.2),
  extraLarge('아주 큼', 1.5),
  huge('거대', 2.0);

  const FontSizePreset(this.displayName, this.scale);
  final String displayName;
  final double scale;
}