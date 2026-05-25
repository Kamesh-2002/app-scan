import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static const String _usernameKey = 'auth_username';
  static const String _passwordKey = 'auth_password_hash';
  static const String _isLoggedInKey = 'is_logged_in';

  // Default credentials
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin123';

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> initDefaultCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_usernameKey)) {
      await prefs.setString(_usernameKey, defaultUsername);
      await prefs.setString(_passwordKey, _hashPassword(defaultPassword));
    }
  }

  static Future<bool> login(String username, String password) async {
    await initDefaultCredentials();
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString(_usernameKey) ?? defaultUsername;
    final storedPasswordHash = prefs.getString(_passwordKey) ?? _hashPassword(defaultPassword);

    if (username == storedUsername && _hashPassword(password) == storedPasswordHash) {
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<bool> changePassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, _hashPassword(newPassword));
    return true;
  }
}