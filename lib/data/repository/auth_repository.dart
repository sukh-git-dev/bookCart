import 'dart:convert';

import 'package:bookcart/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  static const _userKey = 'auth_user';
  static const _loggedInKey = 'auth_logged_in';

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_userKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }
    return UserModel.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
    if (!isLoggedIn) {
      return null;
    }
    return getSavedUser();
  }

  Future<void> signUp(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_loggedInKey, true);
  }

  Future<void> updateUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> login({
    required String phone,
    required String password,
  }) async {
    final savedUser = await getSavedUser();
    if (savedUser == null) {
      return null;
    }
    if (savedUser.phone.trim() == phone.trim() &&
        savedUser.password == password) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, true);
      return savedUser;
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_loggedInKey, false);
  }
}
