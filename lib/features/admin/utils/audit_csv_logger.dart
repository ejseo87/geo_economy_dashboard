import 'dart:typed_data';
import '../models/audit_log_entry.dart';

/// CSV 형식의 감사 로그를 생성하고 관리하는 유틸리티 클래스
class AuditCsvLogger {
  final StringBuffer _buffer = StringBuffer();
  bool _headerWritten = false;
  int _entryCount = 0;

  /// 로거 초기화 (헤더 행 추가)
  void initialize() {
    if (!_headerWritten) {
      _buffer.writeln(AuditLogEntry.csvHeader);
      _headerWritten = true;
    }
  }

  /// 새로운 로그 엔트리 추가
  void addEntry(AuditLogEntry entry) {
    if (!_headerWritten) {
      initialize();
    }

    _buffer.writeln(entry.toCsvRow());
    _entryCount++;
  }

  /// 중복 데이터 로그 추가
  void addDuplicateData({
    required DateTime auditStartTime,
    required String adminActionType,
    required String indicatorCode,
    required String countryCode,
    required List<String> locations,
  }) {
    final entry = AuditLogEntry.duplicateData(
      auditStartTime: auditStartTime,
      adminActionType: adminActionType,
      indicatorCode: indicatorCode,
      countryCode: countryCode,
      locations: locations,
      detectedAt: DateTime.now(),
    );
    addEntry(entry);
  }

  /// 고아 문서 로그 추가
  void addOrphanDocument({
    required DateTime auditStartTime,
    required String adminActionType,
    required String path,
    required String reason,
    required String type,
  }) {
    final entry = AuditLogEntry.orphanDocument(
      auditStartTime: auditStartTime,
      adminActionType: adminActionType,
      path: path,
      reason: reason,
      type: type,
      detectedAt: DateTime.now(),
    );
    addEntry(entry);
  }

  /// 데이터 일관성 문제 로그 추가
  void addIntegrityIssue({
    required DateTime auditStartTime,
    required String adminActionType,
    required String type,
    required String severity,
    required String description,
    required String location,
    String? indicatorCode,
    String? countryCode,
    Map<String, dynamic>? metadata,
  }) {
    final entry = AuditLogEntry.integrityIssue(
      auditStartTime: auditStartTime,
      adminActionType: adminActionType,
      type: type,
      severity: severity,
      description: description,
      location: location,
      indicatorCode: indicatorCode,
      countryCode: countryCode,
      detectedAt: DateTime.now(),
      metadata: metadata,
    );
    addEntry(entry);
  }

  /// 오래된 데이터 로그 추가
  void addOutdatedData({
    required DateTime auditStartTime,
    required String adminActionType,
    required String path,
    required DateTime lastUpdated,
    required int daysOld,
  }) {
    final entry = AuditLogEntry.outdatedData(
      auditStartTime: auditStartTime,
      adminActionType: adminActionType,
      path: path,
      lastUpdated: lastUpdated,
      daysOld: daysOld,
      detectedAt: DateTime.now(),
    );
    addEntry(entry);
  }

  /// 현재까지 추가된 엔트리 수
  int get entryCount => _entryCount;

  /// 헤더가 작성되었는지 여부
  bool get hasHeader => _headerWritten;

  /// CSV 데이터가 비어있는지 여부
  bool get isEmpty => _entryCount == 0;

  /// CSV 문자열 데이터 반환
  String getCsvContent() {
    if (!_headerWritten) {
      initialize();
    }
    return _buffer.toString();
  }

  /// CSV 데이터를 바이트 배열로 반환 (Firebase Storage 업로드용)
  Uint8List getCsvBytes() {
    final csvContent = getCsvContent();
    return Uint8List.fromList(csvContent.codeUnits);
  }

  /// 파일명 생성 (한국 시간 기준 YYYYMMDDHHMMSS_actionType_randomNumber 형식)
  String generateFileName(String adminAuditId) {
    // 한국 시간 (UTC+9)
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final timestamp = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    // actionType 추출 (adminAuditId에서 actionType 부분 가져오기)
    String actionType = 'systemMaintenance'; // 기본값
    if (adminAuditId.contains('_')) {
      final parts = adminAuditId.split('_');
      if (parts.length > 1) {
        actionType = parts[1];
      }
    }

    // 임의의 숫자 생성 (3자리)
    final random = (now.millisecond % 1000).toString().padLeft(3, '0');

    return 'audit-details-${timestamp}_${actionType}_$random.csv';
  }

  /// Firebase Storage 경로 생성
  String generateStoragePath(String adminAuditId) {
    final fileName = generateFileName(adminAuditId);
    return 'audit-logs/$adminAuditId/$fileName';
  }

  /// 로거 상태 초기화 (재사용 시)
  void reset() {
    _buffer.clear();
    _headerWritten = false;
    _entryCount = 0;
  }

  /// 현재 로거의 요약 정보
  Map<String, dynamic> getSummary() {
    return {
      'entryCount': _entryCount,
      'hasHeader': _headerWritten,
      'isEmpty': isEmpty,
      'contentLength': _buffer.length,
    };
  }

  @override
  String toString() {
    return 'AuditCsvLogger(entries: $_entryCount, hasHeader: $_headerWritten, bufferLength: ${_buffer.length})';
  }
}