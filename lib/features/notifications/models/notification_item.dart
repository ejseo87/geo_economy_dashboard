/// 알림 타입
enum NotificationType {
  dataUpdate('데이터 업데이트'),
  thresholdAlert('임계값 알림'),
  rankingChange('순위 변화'),
  periodicReport('정기 리포트'),
  customAlert('사용자 정의 알림');

  const NotificationType(this.displayName);
  final String displayName;
}

/// 알림 우선순위
enum NotificationPriority {
  low('낮음'),
  medium('보통'),
  high('높음'),
  critical('긴급');

  const NotificationPriority(this.displayName);
  final String displayName;

  int get value {
    switch (this) {
      case NotificationPriority.low: return 0;
      case NotificationPriority.medium: return 1;
      case NotificationPriority.high: return 2;
      case NotificationPriority.critical: return 3;
    }
  }
}

/// 알림 아이템
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime scheduledAt;
  final Map<String, dynamic> payload;
  final String? iconPath;
  final String? soundPath;
  final bool isRead;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? deliveredAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.scheduledAt,
    required this.payload,
    this.iconPath,
    this.soundPath,
    this.isRead = false,
    this.isActive = true,
    this.createdAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'priority': priority.name,
    'scheduledAt': scheduledAt.toIso8601String(),
    'payload': payload,
    'iconPath': iconPath,
    'soundPath': soundPath,
    'isRead': isRead,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => 
      NotificationItem(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    type: NotificationType.values.firstWhere((e) => e.name == json['type']),
    priority: NotificationPriority.values.firstWhere((e) => e.name == json['priority']),
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    payload: json['payload'] as Map<String, dynamic>,
    iconPath: json['iconPath'] as String?,
    soundPath: json['soundPath'] as String?,
    isRead: json['isRead'] as bool? ?? false,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    deliveredAt: json['deliveredAt'] != null 
        ? DateTime.parse(json['deliveredAt'] as String)
        : null,
  );

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? scheduledAt,
    Map<String, dynamic>? payload,
    String? iconPath,
    String? soundPath,
    bool? isRead,
    bool? isActive,
    DateTime? createdAt,
    DateTime? deliveredAt,
  }) => NotificationItem(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    type: type ?? this.type,
    priority: priority ?? this.priority,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    payload: payload ?? this.payload,
    iconPath: iconPath ?? this.iconPath,
    soundPath: soundPath ?? this.soundPath,
    isRead: isRead ?? this.isRead,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
  );
}

/// 알림 설정
class NotificationSettings {
  final String id;
  final String name;
  final NotificationType type;
  final bool isEnabled;
  final Map<String, dynamic> conditions;
  final String? description;
  final NotificationPriority priority;
  final List<String> countryCodes;
  final List<String> indicatorCodes;
  final Map<String, dynamic>? customSettings;
  final DateTime? createdAt;
  final DateTime? lastTriggeredAt;

  const NotificationSettings({
    required this.id,
    required this.name,
    required this.type,
    required this.isEnabled,
    required this.conditions,
    this.description,
    this.priority = NotificationPriority.medium,
    this.countryCodes = const [],
    this.indicatorCodes = const [],
    this.customSettings,
    this.createdAt,
    this.lastTriggeredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'isEnabled': isEnabled,
    'conditions': conditions,
    'description': description,
    'priority': priority.name,
    'countryCodes': countryCodes,
    'indicatorCodes': indicatorCodes,
    'customSettings': customSettings,
    'createdAt': createdAt?.toIso8601String(),
    'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => 
      NotificationSettings(
    id: json['id'] as String,
    name: json['name'] as String,
    type: NotificationType.values.firstWhere((e) => e.name == json['type']),
    isEnabled: json['isEnabled'] as bool,
    conditions: json['conditions'] as Map<String, dynamic>,
    description: json['description'] as String?,
    priority: NotificationPriority.values.firstWhere(
        (e) => e.name == (json['priority'] ?? 'medium')),
    countryCodes: (json['countryCodes'] as List<dynamic>?)?.cast<String>() ?? [],
    indicatorCodes: (json['indicatorCodes'] as List<dynamic>?)?.cast<String>() ?? [],
    customSettings: json['customSettings'] as Map<String, dynamic>?,
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    lastTriggeredAt: json['lastTriggeredAt'] != null 
        ? DateTime.parse(json['lastTriggeredAt'] as String)
        : null,
  );
}

/// 임계값 연산자
enum ThresholdOperator {
  greaterThan('초과'),
  lessThan('미만'),
  equalTo('같음'),
  greaterThanOrEqual('이상'),
  lessThanOrEqual('이하');

  const ThresholdOperator(this.displayName);
  final String displayName;
}

/// 리포트 빈도
enum ReportFrequency {
  daily('매일'),
  weekly('매주'),
  monthly('매월');

  const ReportFrequency(this.displayName);
  final String displayName;
}

/// 알림 아이템 팩토리
class NotificationItemFactory {
  /// 데이터 업데이트 알림 생성
  static NotificationItem createDataUpdateNotification({
    required String indicatorName,
    required String countryName,
    required DateTime updateTime,
    String? previousValue,
    String? newValue,
  }) {
    final id = _generateId('data_update', '${indicatorName}_$countryName');
    
    return NotificationItem(
      id: id,
      title: '📊 $indicatorName 데이터 업데이트',
      body: '$countryName의 $indicatorName가 업데이트되었습니다.' +
            (previousValue != null && newValue != null ? ' ($previousValue → $newValue)' : ''),
      type: NotificationType.dataUpdate,
      priority: NotificationPriority.medium,
      scheduledAt: DateTime.now(),
      payload: {
        'indicatorName': indicatorName,
        'countryName': countryName,
        'updateTime': updateTime.toIso8601String(),
        if (previousValue != null) 'previousValue': previousValue,
        if (newValue != null) 'newValue': newValue,
      },
      createdAt: DateTime.now(),
    );
  }

  /// 임계값 알림 생성
  static NotificationItem createThresholdAlert({
    required String indicatorName,
    required String countryName,
    required double currentValue,
    required double threshold,
    required ThresholdOperator operator,
    String? unit,
  }) {
    final id = _generateId('threshold', '${indicatorName}_$countryName');
    final operatorText = _getOperatorText(operator, threshold, unit);
    
    return NotificationItem(
      id: id,
      title: '⚠️ $indicatorName 임계값 도달',
      body: '$countryName의 $indicatorName가 $operatorText 상태입니다. (현재값: $currentValue${unit ?? ''})',
      type: NotificationType.thresholdAlert,
      priority: NotificationPriority.high,
      scheduledAt: DateTime.now(),
      payload: {
        'indicatorName': indicatorName,
        'countryName': countryName,
        'currentValue': currentValue,
        'threshold': threshold,
        'operator': operator.name,
        'unit': unit,
      },
      createdAt: DateTime.now(),
    );
  }

  /// 순위 변화 알림 생성
  static NotificationItem createRankingChangeNotification({
    required String indicatorName,
    required String countryName,
    required int previousRank,
    required int newRank,
    required int totalCountries,
  }) {
    final id = _generateId('ranking', '${indicatorName}_$countryName');
    final isImprovement = newRank < previousRank;
    final changeAmount = (previousRank - newRank).abs();
    final changeText = isImprovement ? '상승' : '하락';
    final emoji = isImprovement ? '📈' : '📉';
    
    return NotificationItem(
      id: id,
      title: '$emoji $indicatorName 순위 변동',
      body: '$countryName의 $indicatorName 순위가 ${previousRank}위에서 ${newRank}위로 $changeAmount계단 $changeText했습니다. (총 $totalCountries개국)',
      type: NotificationType.rankingChange,
      priority: isImprovement ? NotificationPriority.medium : NotificationPriority.high,
      scheduledAt: DateTime.now(),
      payload: {
        'indicatorName': indicatorName,
        'countryName': countryName,
        'previousRank': previousRank,
        'newRank': newRank,
        'totalCountries': totalCountries,
        'isImprovement': isImprovement,
      },
      createdAt: DateTime.now(),
    );
  }

  /// 정기 리포트 알림 생성
  static NotificationItem createPeriodicReportNotification({
    required ReportFrequency frequency,
    required List<String> countries,
    required List<String> indicators,
    Map<String, dynamic>? summaryData,
  }) {
    final id = _generateId('report', frequency.name);
    
    return NotificationItem(
      id: id,
      title: '📈 ${frequency.displayName} 경제지표 리포트',
      body: '${countries.length}개 국가의 ${indicators.length}개 지표에 대한 ${frequency.displayName} 리포트가 준비되었습니다.',
      type: NotificationType.periodicReport,
      priority: NotificationPriority.low,
      scheduledAt: DateTime.now(),
      payload: {
        'frequency': frequency.name,
        'countries': countries,
        'indicators': indicators,
        'summaryData': summaryData ?? {},
      },
      createdAt: DateTime.now(),
    );
  }

  /// 고유 ID 생성
  static String _generateId(String prefix, String suffix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = suffix.hashCode.abs();
    return '${prefix}_${hash}_$timestamp';
  }

  /// 연산자 텍스트 생성
  static String _getOperatorText(ThresholdOperator operator, double threshold, String? unit) {
    final unitText = unit ?? '';
    switch (operator) {
      case ThresholdOperator.greaterThan:
        return '$threshold$unitText 초과';
      case ThresholdOperator.lessThan:
        return '$threshold$unitText 미만';
      case ThresholdOperator.equalTo:
        return '$threshold$unitText와 동일';
      case ThresholdOperator.greaterThanOrEqual:
        return '$threshold$unitText 이상';
      case ThresholdOperator.lessThanOrEqual:
        return '$threshold$unitText 이하';
    }
  }
}

/// 알림 아이템 확장
extension NotificationItemExtensions on NotificationItem {
  /// 알림이 만료되었는지 확인
  bool get isExpired {
    final now = DateTime.now();
    // 7일 후 만료
    return now.isAfter(scheduledAt.add(const Duration(days: 7)));
  }

  /// 알림이 미래에 예약된 것인지 확인
  bool get isScheduledForFuture => scheduledAt.isAfter(DateTime.now());

  /// 알림 아이콘
  String get iconEmoji {
    switch (type) {
      case NotificationType.dataUpdate:
        return '📊';
      case NotificationType.thresholdAlert:
        return '⚠️';
      case NotificationType.rankingChange:
        return '📈';
      case NotificationType.periodicReport:
        return '📋';
      case NotificationType.customAlert:
        return '🔔';
    }
  }

  /// 우선순위 색상
  String get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return 'gray';
      case NotificationPriority.medium:
        return 'blue';
      case NotificationPriority.high:
        return 'orange';
      case NotificationPriority.critical:
        return 'red';
    }
  }
}