import 'package:shared_preferences/shared_preferences.dart';
import '../remote/api_client.dart';
import '../../models/user.dart';
import '../../core/constants.dart';

class AuthRepository {
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<String?> getSavedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userNameKey);
  }

  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<void> _saveSession(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userNameKey, user.name);
    await prefs.setString(AppConstants.userIdKey, user.id);
    await prefs.setString(AppConstants.userEmailKey, user.email);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
  }

  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient().post('/auth/login', {
      'email': email,
      'password': password,
      'program': 'customer',
    });
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await _saveSession(token, user);
    return (user: user, token: token);
  }

  Future<({User user, String token})> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await ApiClient().post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'program': 'customer',
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await _saveSession(token, user);
    return (user: user, token: token);
  }
}
