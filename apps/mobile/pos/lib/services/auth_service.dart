import 'dart:async';

import '../data/models.dart';

class AuthService {
  PosRole? _currentRole;
  String _staffPin;
  String _managerPin;
  List<UserProfile> _users;

  AuthService({
    String staffPin = '1111',
    String managerPin = '7777',
    List<UserProfile> users = const [],
  })  : _staffPin = staffPin,
        _managerPin = managerPin,
        _users = users;

  PosRole? get currentRole => _currentRole;

  bool get isAuthenticated => _currentRole != null;

  Future<bool> authenticate(String pin) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final user in _users) {
      if (user.pin == pin) {
        _currentRole = user.role;
        return true;
      }
    }
    if (_users.isEmpty && pin == _managerPin) {
      _currentRole = PosRole.manager;
      return true;
    }
    if (_users.isEmpty && pin == _staffPin) {
      _currentRole = PosRole.staff;
      return true;
    }
    return false;
  }

  void signOut() {
    _currentRole = null;
  }

  void updatePins({required String staffPin, required String managerPin}) {
    _staffPin = staffPin;
    _managerPin = managerPin;
  }

  void updateUsers(List<UserProfile> users) {
    _users = users;
  }
}
