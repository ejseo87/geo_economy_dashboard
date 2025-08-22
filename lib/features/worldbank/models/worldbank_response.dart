/// World Bank API 응답 모델
class WorldBankApiResponse {
  final List<WorldBankMetadata> metadata;
  final List<WorldBankIndicatorData> data;

  WorldBankApiResponse({
    required this.metadata,
    required this.data,
  });

  factory WorldBankApiResponse.fromJson(List<dynamic> json) {
    if (json.length != 2) {
      throw Exception('Invalid World Bank API response format');
    }

    final metadataJson = json[0] as Map<String, dynamic>;
    final dataJson = json[1] as List<dynamic>;

    return WorldBankApiResponse(
      metadata: [WorldBankMetadata.fromJson(metadataJson)],
      data: dataJson
          .where((item) => item != null)
          .map((item) => WorldBankIndicatorData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// World Bank API 메타데이터
class WorldBankMetadata {
  final int page;
  final int pages;
  final int perPage;
  final int total;
  final String? sourceid;
  final DateTime? lastupdated;

  WorldBankMetadata({
    required this.page,
    required this.pages,
    required this.perPage,
    required this.total,
    this.sourceid,
    this.lastupdated,
  });

  factory WorldBankMetadata.fromJson(Map<String, dynamic> json) {
    return WorldBankMetadata(
      page: json['page'] as int,
      pages: json['pages'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
      sourceid: json['sourceid'] as String?,
      lastupdated: json['lastupdated'] != null 
          ? DateTime.tryParse(json['lastupdated'] as String)
          : null,
    );
  }
}

/// World Bank 지표 데이터
class WorldBankIndicatorData {
  final String? indicatorId;
  final String? indicatorValue;
  final String? countryId;
  final String? countryValue;
  final String? countryiso3code;
  final String? date;
  final double? value;
  final String? unit;
  final String? obsStatus;
  final int? decimal;

  WorldBankIndicatorData({
    this.indicatorId,
    this.indicatorValue,
    this.countryId,
    this.countryValue,
    this.countryiso3code,
    this.date,
    this.value,
    this.unit,
    this.obsStatus,
    this.decimal,
  });

  factory WorldBankIndicatorData.fromJson(Map<String, dynamic> json) {
    return WorldBankIndicatorData(
      indicatorId: json['indicator']?['id'] as String?,
      indicatorValue: json['indicator']?['value'] as String?,
      countryId: json['country']?['id'] as String?,
      countryValue: json['country']?['value'] as String?,
      countryiso3code: json['countryiso3code'] as String?,
      date: json['date'] as String?,
      value: json['value'] != null 
          ? (json['value'] as num).toDouble()
          : null,
      unit: json['unit'] as String?,
      obsStatus: json['obs_status'] as String?,
      decimal: json['decimal'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'indicator': {
        'id': indicatorId,
        'value': indicatorValue,
      },
      'country': {
        'id': countryId,
        'value': countryValue,
      },
      'countryiso3code': countryiso3code,
      'date': date,
      'value': value,
      'unit': unit,
      'obs_status': obsStatus,
      'decimal': decimal,
    };
  }
}

/// World Bank 국가 정보
class WorldBankCountry {
  final String id;
  final String iso2Code;
  final String name;
  final String region;
  final String adminregion;
  final String incomeLevel;
  final String lendingType;
  final String capitalCity;
  final double? longitude;
  final double? latitude;

  WorldBankCountry({
    required this.id,
    required this.iso2Code,
    required this.name,
    required this.region,
    required this.adminregion,
    required this.incomeLevel,
    required this.lendingType,
    required this.capitalCity,
    this.longitude,
    this.latitude,
  });

  factory WorldBankCountry.fromJson(Map<String, dynamic> json) {
    return WorldBankCountry(
      id: json['id'] as String,
      iso2Code: json['iso2Code'] as String,
      name: json['name'] as String,
      region: json['region']?['value'] as String? ?? '',
      adminregion: json['adminregion']?['value'] as String? ?? '',
      incomeLevel: json['incomeLevel']?['value'] as String? ?? '',
      lendingType: json['lendingType']?['value'] as String? ?? '',
      capitalCity: json['capitalCity'] as String? ?? '',
      longitude: json['longitude'] != null 
          ? double.tryParse(json['longitude'].toString())
          : null,
      latitude: json['latitude'] != null 
          ? double.tryParse(json['latitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iso2Code': iso2Code,
      'name': name,
      'region': {'value': region},
      'adminregion': {'value': adminregion},
      'incomeLevel': {'value': incomeLevel},
      'lendingType': {'value': lendingType},
      'capitalCity': capitalCity,
      'longitude': longitude?.toString(),
      'latitude': latitude?.toString(),
    };
  }
}

/// World Bank 지표 메타데이터
class WorldBankIndicatorMeta {
  final String id;
  final String name;
  final String unit;
  final String source;
  final String sourceNote;
  final String sourceOrganization;
  final List<String> topics;

  WorldBankIndicatorMeta({
    required this.id,
    required this.name,
    required this.unit,
    required this.source,
    required this.sourceNote,
    required this.sourceOrganization,
    required this.topics,
  });

  factory WorldBankIndicatorMeta.fromJson(Map<String, dynamic> json) {
    return WorldBankIndicatorMeta(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String? ?? '',
      source: json['source']?['value'] as String? ?? '',
      sourceNote: json['sourceNote'] as String? ?? '',
      sourceOrganization: json['sourceOrganization'] as String? ?? '',
      topics: (json['topics'] as List<dynamic>?)
          ?.map((topic) => topic['value'] as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'source': {'value': source},
      'sourceNote': sourceNote,
      'sourceOrganization': sourceOrganization,
      'topics': topics.map((topic) => {'value': topic}).toList(),
    };
  }
}