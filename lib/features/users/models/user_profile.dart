import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 프로필 정보
class UserProfile {
  final String uid;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? plan;
  final Map<String, dynamic>? permissions;
  final Map<String, dynamic>? limits;
  final Map<String, dynamic>? usage;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    this.plan,
    this.permissions,
    this.limits,
    this.usage,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? 'anon',
      avatarUrl: data['avatarUrl'],
      role: data['role'] ?? 'free_user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      plan: data['plan'] as Map<String, dynamic>?,
      permissions: data['permissions'] as Map<String, dynamic>?,
      limits: data['limits'] as Map<String, dynamic>?,
      usage: data['usage'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'plan': plan,
      'permissions': permissions,
      'limits': limits,
      'usage': usage,
    };
  }

  UserProfile copyWith({
    String? nickname,
    String? avatarUrl,
    String? role,
    DateTime? lastLogin,
    Map<String, dynamic>? plan,
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? limits,
    Map<String, dynamic>? usage,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      plan: plan ?? this.plan,
      permissions: permissions ?? this.permissions,
      limits: limits ?? this.limits,
      usage: usage ?? this.usage,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isPremium => role == 'premium_user';
  bool get isFree => role == 'free_user';

  String get displayName => nickname.isNotEmpty ? nickname : 'Anonymous';
  
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return '관리자';
      case 'premium_user':
        return '프리미엄';
      case 'free_user':
        return '무료 회원';
      default:
        return '게스트';
    }
  }

  String get planDisplayName {
    if (plan == null) return '무료 플랜';
    
    switch (plan!['type']) {
      case 'basic':
        return '베이직 플랜';
      case 'pro':
        return '프로 플랜';
      default:
        return '무료 플랜';
    }
  }

  // 사용량 정보 헬퍼
  int get currentBookmarks => usage?['currentBookmarks'] ?? 0;
  int get monthlyDownloads => usage?['monthlyDownloads'] ?? 0;
  int get bookmarkLimit => limits?['bookmarkCount'] ?? 0;
  int get downloadLimit => limits?['downloadCount'] ?? 0;

  // 권한 체크 헬퍼
  bool hasPermission(String permission) {
    if (isAdmin) return true;
    return permissions?[permission] == true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          nickname == other.nickname &&
          avatarUrl == other.avatarUrl &&
          role == other.role;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      nickname.hashCode ^
      (avatarUrl?.hashCode ?? 0) ^
      role.hashCode;

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, nickname: $nickname, role: $role)';
  }
}