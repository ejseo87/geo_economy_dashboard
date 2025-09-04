/// 관리자 사용자 모델
class AdminUser {
  final String id;
  final String username;
  final String email;
  final AdminRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;

  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: AdminRole.values.firstWhere((e) => e.name == json['role']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'] as int),
      isActive: json['isActive'] as bool,
    );
  }

  AdminUser copyWith({
    String? id,
    String? username,
    String? email,
    AdminRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return AdminUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool hasPermission(AdminPermission permission) {
    return role.permissions.contains(permission);
  }
}

/// 관리자 권한 역할
enum AdminRole {
  superAdmin([
    AdminPermission.userManagement,
    AdminPermission.dataManagement,
    AdminPermission.systemSettings,
    AdminPermission.auditLogs,
  ]),
  dataManager([
    AdminPermission.dataManagement,
    AdminPermission.auditLogs,
  ]),
  viewer([
    AdminPermission.auditLogs,
  ]);

  const AdminRole(this.permissions);
  final List<AdminPermission> permissions;
}

/// 관리자 권한
enum AdminPermission {
  userManagement,
  dataManagement,
  systemSettings,
  auditLogs,
}