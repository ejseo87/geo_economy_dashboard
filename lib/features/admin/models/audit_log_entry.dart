/// CSV 로그 파일의 개별 엔트리를 나타내는 모델
class AuditLogEntry {
  final DateTime auditStartTime;
  final String adminActionType;
  final String issueType;
  final String severity;
  final String description;
  final String location;
  final String? indicatorCode;
  final String? countryCode;
  final DateTime detectedAt;
  final Map<String, dynamic>? additionalData;

  const AuditLogEntry({
    required this.auditStartTime,
    required this.adminActionType,
    required this.issueType,
    required this.severity,
    required this.description,
    required this.location,
    this.indicatorCode,
    this.countryCode,
    required this.detectedAt,
    this.additionalData,
  });

  /// 중복 데이터 문제를 위한 팩토리 생성자
  factory AuditLogEntry.duplicateData({
    required DateTime auditStartTime,
    required String adminActionType,
    required String indicatorCode,
    required String countryCode,
    required List<String> locations,
    required DateTime detectedAt,
  }) {
    return AuditLogEntry(
      auditStartTime: auditStartTime,
      adminActionType: adminActionType,
      issueType: 'duplicate',
      severity: 'warning',
      description: '중복 데이터 발견: $indicatorCode/$countryCode',
      location: locations.join('; '),
      indicatorCode: indicatorCode,
      countryCode: countryCode,
      detectedAt: detectedAt,
      additionalData: {'locations': locations},
    );
  }

  /// 고아 문서 문제를 위한 팩토리 생성자
  factory AuditLogEntry.orphanDocument({
    required DateTime auditStartTime,
    required String adminActionType,
    required String path,
    required String reason,
    required String type,
    required DateTime detectedAt,
  }) {
    return AuditLogEntry(
      auditStartTime: auditStartTime,
      adminActionType: adminActionType,
      issueType: 'orphan',
      severity: 'error',
      description: '고아 문서 발견: $path',
      location: path,
      detectedAt: detectedAt,
      additionalData: {'reason': reason, 'type': type},
    );
  }

  /// 데이터 일관성 문제를 위한 팩토리 생성자
  factory AuditLogEntry.integrityIssue({
    required DateTime auditStartTime,
    required String adminActionType,
    required String type,
    required String severity,
    required String description,
    required String location,
    String? indicatorCode,
    String? countryCode,
    required DateTime detectedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AuditLogEntry(
      auditStartTime: auditStartTime,
      adminActionType: adminActionType,
      issueType: type,
      severity: severity,
      description: description,
      location: location,
      indicatorCode: indicatorCode,
      countryCode: countryCode,
      detectedAt: detectedAt,
      additionalData: metadata,
    );
  }

  /// 오래된 데이터 문제를 위한 팩토리 생성자
  factory AuditLogEntry.outdatedData({
    required DateTime auditStartTime,
    required String adminActionType,
    required String path,
    required DateTime lastUpdated,
    required int daysOld,
    required DateTime detectedAt,
  }) {
    return AuditLogEntry(
      auditStartTime: auditStartTime,
      adminActionType: adminActionType,
      issueType: 'outdated',
      severity: 'info',
      description: '오래된 데이터: $daysOld일 전 업데이트',
      location: path,
      detectedAt: detectedAt,
      additionalData: {'lastUpdated': lastUpdated.toIso8601String(), 'daysOld': daysOld},
    );
  }

  /// CSV 헤더 행 생성
  static String get csvHeader =>
      'auditStartTime,adminActionType,issueType,severity,description,location,indicatorCode,countryCode,detectedAt,additionalData';

  /// CSV 행으로 변환
  String toCsvRow() {
    return [
      auditStartTime.toIso8601String(),
      _escapeCsvField(adminActionType),
      _escapeCsvField(issueType),
      _escapeCsvField(severity),
      _escapeCsvField(description),
      _escapeCsvField(location),
      _escapeCsvField(indicatorCode ?? ''),
      _escapeCsvField(countryCode ?? ''),
      detectedAt.toIso8601String(),
      _escapeCsvField(additionalData?.toString() ?? ''),
    ].join(',');
  }

  /// CSV 필드 이스케이핑 (콤마, 따옴표, 줄바꿈 처리)
  String _escapeCsvField(String field) {
    if (field.isEmpty) return '';

    // 콤마, 따옴표, 줄바꿈이 있으면 따옴표로 감싸고 내부 따옴표는 두 개로 변환
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }

    return field;
  }
}