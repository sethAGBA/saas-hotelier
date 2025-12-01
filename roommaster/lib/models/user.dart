class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? passwordHash;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  final bool is2faEnabled;
  final String twoFaSecret;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.passwordHash,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
    this.is2faEnabled = false,
    this.twoFaSecret = '',
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    bool? is2faEnabled,
    String? twoFaSecret,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      is2faEnabled: is2faEnabled ?? this.is2faEnabled,
      twoFaSecret: twoFaSecret ?? this.twoFaSecret,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.index,
      'passwordHash': passwordHash,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLogin': lastLogin.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'is2faEnabled': is2faEnabled ? 1 : 0,
      'twoFaSecret': twoFaSecret,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    final roleRaw = map['role'];
    UserRole parsedRole;
    if (roleRaw is int) {
      parsedRole =
          UserRole.values[(roleRaw).clamp(0, UserRole.values.length - 1)];
    } else if (roleRaw is String) {
      final lowered = roleRaw.toLowerCase();
      parsedRole = UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == lowered,
        orElse: () => UserRole.admin,
      );
    } else {
      parsedRole = UserRole.admin;
    }

    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      if (v is num) return v.toInt();
      return 0;
    }

    return User(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: parsedRole,
      passwordHash: map['passwordHash'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_toInt(map['createdAt'])),
      lastLogin: DateTime.fromMillisecondsSinceEpoch(_toInt(map['lastLogin'])),
      isActive: _toInt(map['isActive']) == 1,
      is2faEnabled: _toInt(map['is2faEnabled']) == 1,
      twoFaSecret: map['twoFaSecret'] as String? ?? '',
    );
  }
}

enum UserRole { admin, reception, maintenance }
