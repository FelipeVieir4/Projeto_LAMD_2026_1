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

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userEmailKey);
  }

  Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userPhoneKey);
  }

  Future<void> _saveSession(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userNameKey, user.name);
    await prefs.setString(AppConstants.userIdKey, user.id);
    await prefs.setString(AppConstants.userEmailKey, user.email);
    if (user.phone != null && user.phone!.isNotEmpty) {
      await prefs.setString(AppConstants.userPhoneKey, user.phone!);
    } else {
      await prefs.remove(AppConstants.userPhoneKey);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userPhoneKey);
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

  Future<User> fetchMe(String token) async {
    final data = await ApiClient(token: token).get('/auth/me');
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    required String token,
    required String name,
    String? phone,
  }) async {
    final data = await ApiClient(token: token).patch('/auth/profile', {
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userNameKey, user.name);
    if (user.phone != null && user.phone!.isNotEmpty) {
      await prefs.setString(AppConstants.userPhoneKey, user.phone!);
    } else {
      await prefs.remove(AppConstants.userPhoneKey);
    }
    return user;
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient(token: token).patch('/auth/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
