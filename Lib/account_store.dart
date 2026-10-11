import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'dart:math';

class UserProfile {
  const UserProfile({
    this.fullName = '',
    this.role = '',
    this.institution = '',
    this.department = '',
    this.phone = '',
    this.employeeId = '',
  });

  final String fullName;
  final String role;
  final String institution;
  final String department;
  final String phone;
  final String employeeId;

  bool get isCreated => fullName.trim().isNotEmpty;

  String get displayName =>
      fullName.trim().isEmpty ? 'Admin User' : fullName.trim();

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fullName': fullName,
    'role': role,
    'institution': institution,
    'department': department,
    'phone': phone,
    'employeeId': employeeId,
  };

  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
    fullName: (json['fullName'] as String?) ?? '',
    role: (json['role'] as String?) ?? '',
    institution: (json['institution'] as String?) ?? '',
    department: (json['department'] as String?) ?? '',
    phone: (json['phone'] as String?) ?? '',
    employeeId: (json['employeeId'] as String?) ?? '',
  );

  UserProfile copyWith({
    String? fullName,
    String? role,
    String? institution,
    String? department,
    String? phone,
    String? employeeId,
  }) => UserProfile(
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    institution: institution ?? this.institution,
    department: department ?? this.department,
    phone: phone ?? this.phone,
    employeeId: employeeId ?? this.employeeId,
  );

  static bool isValidPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    if (!RegExp(r'^[+\d][\d\s\-()]{6,}$').hasMatch(trimmed)) return false;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 && digits.length <= 15;
  }
}

class AccountStore extends ChangeNotifier {
  static const String defaultEmail = 'admin@attendify.com';
  static const String defaultPassword = 'secure123';

  static final AccountStore instance = AccountStore();

  static const String _storageKey = 'account_store_v1';

  bool _loaded = false;
  Future<void>? _persistChain;

  AccountStore() {
    _salt = _newSalt();
    _passwordHash = hashPassword(_password, _salt);
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String _email = defaultEmail;
  String _password = defaultPassword;
  String _salt = '';
  String _passwordHash = '';
  bool _credentialsCustomized = false;
  UserProfile _profile = const UserProfile();

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final storedEmail = (json['email'] as String?) ?? defaultEmail;
      _email = storedEmail;
      _salt = (json['salt'] as String?)?.isNotEmpty == true
          ? json['salt'] as String
          : _salt;
      _passwordHash = (json['passwordHash'] as String?)?.isNotEmpty == true
          ? json['passwordHash'] as String
          : _passwordHash;
      _password = '';
      final savedCustomized = json['credentialsCustomized'];
      _credentialsCustomized = savedCustomized is bool && savedCustomized;
      _profile = UserProfile.fromJson(
        (json['profile'] as Map<String, dynamic>?) ?? const {},
      );
    } catch (_) {}
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    try {
      final snapshot = jsonEncode(_toJson());
      _persistChain = (_persistChain ?? Future<void>.value()).then((_) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_storageKey, snapshot);
        } catch (_) {}
      });
    } catch (_) {}
  }

  Map<String, dynamic> _toJson() => <String, dynamic>{
    'version': 1,
    'email': _email,
    'salt': _salt,
    'passwordHash': _passwordHash,
    'credentialsCustomized': _credentialsCustomized,
    'profile': _profile.toJson(),
  };

  String get email => _email;
  String get password => _password;
  UserProfile get profile => _profile;
  bool get usesDefaultCredentials => !_credentialsCustomized;

  static String _newSalt() {
    final random = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String hashPassword(String password, String salt) {
    return base64Encode(sha256.convert(utf8.encode('$password::$salt')).bytes);
  }

  bool _verifyPassword(String password) {
    return _passwordHash.isNotEmpty &&
        hashPassword(password, _salt) == _passwordHash;
  }

  bool emailExists(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed == _email.trim().toLowerCase();
  }

  bool validateCredentials(String email, String password) {
    return email.trim().toLowerCase() == _email.trim().toLowerCase() &&
        _verifyPassword(password);
  }

  String? changeEmail({
    required String currentPassword,
    required String newEmail,
    String confirmEmail = '',
  }) {
    if (!_verifyPassword(currentPassword)) {
      return 'Your current password is incorrect.';
    }
    final trimmed = newEmail.trim();
    if (trimmed.isEmpty) return 'Enter your new email address.';
    if (!_emailPattern.hasMatch(trimmed)) return 'Enter a valid email address.';
    final confirmation = confirmEmail.trim();
    if (confirmation.isNotEmpty &&
        confirmation.toLowerCase() != trimmed.toLowerCase()) {
      return 'New email confirmation does not match.';
    }
    if (emailExists(trimmed)) {
      return 'That is already your current email address.';
    }
    _email = trimmed;
    _credentialsCustomized = true;
    notifyListeners();
    return null;
  }

  String? changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (!_verifyPassword(currentPassword)) {
      return 'Your current password is incorrect.';
    }
    if (newPassword.isEmpty) return 'Enter a new password.';
    if (newPassword.length < 6) return 'Password must be at least 6 characters';
    if (newPassword != confirmPassword) {
      return 'New password confirmation does not match.';
    }
    if (_verifyPassword(newPassword)) {
      return 'That is already your current password.';
    }
    _password = newPassword;
    _salt = _newSalt();
    _passwordHash = hashPassword(newPassword, _salt);
    _credentialsCustomized = true;
    notifyListeners();
    return null;
  }

  void saveProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void resetToDefaults() {
    _email = defaultEmail;
    _password = defaultPassword;
    _salt = _newSalt();
    _passwordHash = hashPassword(_password, _salt);
    _credentialsCustomized = false;
    _profile = const UserProfile();
    notifyListeners();
  }
}
